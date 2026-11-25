import Foundation
import SwiftUI
import KeychainAccess
import CryptoKit
import CommonCrypto

@MainActor
public final class AuthService: ObservableObject {
    public static let shared = AuthService()
    
    @Published public var currentUser: User? = nil
    @Published public var isAuthenticated: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    // Secure Keychain Storage (OWASP MASVS-STORAGE-1)
    private let keychain = Keychain(service: "com.ermay.muhasebe").accessibility(.afterFirstUnlock)
    private let keychainUserKey = "ermay_secure_user"
    private let legacyUserDefaultsKey = "ermay_saved_user"
    
    private init() {
        checkSavedSession()
    }
    
    public func checkSavedSession() {
        if let data = try? keychain.getData(keychainUserKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
            SupabaseService.shared.tenantId = user.tenantId
            return
        }
        
        if let oldData = UserDefaults.standard.data(forKey: legacyUserDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: oldData) {
            self.currentUser = user
            self.isAuthenticated = true
            SupabaseService.shared.tenantId = user.tenantId
            try? keychain.set(oldData, key: keychainUserKey)
            UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
        }
    }
    
    // Masaüstü C# Rfc2898DeriveBytes (PBKDF2-SHA256, 100.000 iterasyon + eski 10.000 iterasyon uyumluluğu) ve Base64 SHA256 ile %100 uyumlu şifre doğrulama
    public func verifyPassword(plain: String, storedHash: String, saltBase64: String?) -> Bool {
        guard !storedHash.isEmpty else { return false }
        
        if storedHash.starts(with: "PBKDF2$") {
            let expectedBase64 = String(storedHash.dropFirst("PBKDF2$".count))
            guard let expectedHashData = Data(base64Encoded: expectedBase64) else {
                return false
            }
            
            let saltData: Data
            if let s = saltBase64, !s.isEmpty {
                if let decoded = Data(base64Encoded: s) {
                    saltData = decoded
                } else {
                    saltData = s.data(using: .utf8) ?? Data()
                }
            } else {
                saltData = Data(repeating: 0, count: 16)
            }
            
            let passwordData = plain.data(using: .utf8) ?? Data()
            for iterations: UInt32 in [100_000, 10_000] {
                var derivedKey = Data(repeating: 0, count: 32)
                let status = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
                    saltData.withUnsafeBytes { saltBytes in
                        passwordData.withUnsafeBytes { passwordBytes in
                            CCKeyDerivationPBKDF(
                                CCPBKDFAlgorithm(kCCPBKDF2),
                                passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                                passwordData.count,
                                saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                saltData.count,
                                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                                iterations,
                                derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                32
                            )
                        }
                    }
                }
                
                if status == kCCSuccess && constantTimeEquals(derivedKey, expectedHashData) {
                    return true
                }
            }
            return false
        }
        
        // Legacy Base64-encoded SHA256 (salted: password + salt, unsalted: password)
        guard let expectedBytes = Data(base64Encoded: storedHash) else {
            return false
        }
        
        if let salt = saltBase64, !salt.isEmpty {
            let saltedInput = Data((plain + salt).utf8)
            let saltedDigest = Data(SHA256.hash(data: saltedInput))
            if constantTimeEquals(saltedDigest, expectedBytes) {
                return true
            }
        }
        
        let unsaltedDigest = Data(SHA256.hash(data: Data(plain.utf8)))
        return constantTimeEquals(unsaltedDigest, expectedBytes)
    }
    
    private func constantTimeEquals(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<a.count {
            diff |= a[i] ^ b[i]
        }
        return diff == 0
    }
    
    private func escapePostgrestFilterValue(_ value: String) -> String {
        return value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "\"", with: "")
    }
    
    private func derivePasswordHash(plain: String, saltBase64: String, isPbkdf2: Bool) -> String {
        if isPbkdf2 {
            let saltData: Data
            if !saltBase64.isEmpty {
                saltData = Data(base64Encoded: saltBase64) ?? (saltBase64.data(using: .utf8) ?? Data())
            } else {
                saltData = Data(repeating: 0, count: 16)
            }
            let passwordData = plain.data(using: .utf8) ?? Data()
            var derivedKey = Data(repeating: 0, count: 32)
            let status = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
                saltData.withUnsafeBytes { saltBytes in
                    passwordData.withUnsafeBytes { passwordBytes in
                        CCKeyDerivationPBKDF(
                            CCPBKDFAlgorithm(kCCPBKDF2),
                            passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                            passwordData.count,
                            saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                            saltData.count,
                            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                            100_000,
                            derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                            32
                        )
                    }
                }
            }
            if status == kCCSuccess {
                return "PBKDF2$" + derivedKey.base64EncodedString()
            }
            return ""
        }

        let input = saltBase64.isEmpty ? plain : (plain + saltBase64)
        let digest = Data(SHA256.hash(data: Data(input.utf8)))
        return digest.base64EncodedString()
    }

    public func login(username: String, pass: String, tenantId: String = "") async -> Bool {
        isLoading = true
        errorMessage = nil

        let cleanIdentifier = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPass = pass.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanIdentifier.isEmpty else {
            errorMessage = "Kullanıcı adı veya e-posta boş bırakılamaz."
            isLoading = false
            return false
        }
        guard !cleanPass.isEmpty else {
            errorMessage = "Şifre boş bırakılamaz."
            isLoading = false
            return false
        }

        let requestedTenant = tenantId.trimmingCharacters(in: .whitespacesAndNewlines)
        let tenantParam: Any = (!requestedTenant.isEmpty && requestedTenant != "default") ? requestedTenant : "auto"

        // 1. Direct PostgreSQL Auth via get_user_salt_v2 + verify_user_login_v2 (username OR email + tenant resolution)
        do {
            let saltRes = try await SupabaseService.shared.rpcRaw(
                function: "get_user_salt_v2",
                params: [
                    "p_identifier": cleanIdentifier,
                    "p_tenant_id": tenantParam
                ]
            )

            let found = (saltRes["found"] as? Bool) ?? false
            if found {
                let salt = (saltRes["password_salt"] as? String) ?? ""
                let isPbkdf2 = (saltRes["is_pbkdf2"] as? Bool) ?? true
                let resolvedTenantFromSalt = (saltRes["tenant_id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let computedHash = derivePasswordHash(plain: cleanPass, saltBase64: salt, isPbkdf2: isPbkdf2)

                var verifyParams: [String: Any] = [
                    "p_identifier": cleanIdentifier,
                    "p_password_hash": computedHash
                ]
                if !resolvedTenantFromSalt.isEmpty {
                    verifyParams["p_tenant_id"] = resolvedTenantFromSalt
                }

                let verifyRes = try await SupabaseService.shared.rpcRaw(
                    function: "verify_user_login_v2",
                    params: verifyParams
                )

                if (verifyRes["success"] as? Bool) == true {
                    let finalUsername = ((verifyRes["username"] as? String) ?? cleanIdentifier).trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalEmail = ((verifyRes["email"] as? String) ?? "\(finalUsername)@ermay.local").trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalFullName = ((verifyRes["ad_soyad"] as? String) ?? "").isEmpty ? finalUsername.capitalized : ((verifyRes["ad_soyad"] as? String) ?? finalUsername.capitalized)
                    let finalRole = (verifyRes["role"] as? String) ?? "Admin"
                    let rawTenant = ((verifyRes["tenant_id"] as? String) ?? resolvedTenantFromSalt).trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalTenant = (rawTenant.isEmpty || rawTenant == "default") ? "tenant_ermay_master" : rawTenant
                    let userId = (verifyRes["user_id"] as? String) ?? (verifyRes["user_uuid"] as? String) ?? UUID().uuidString

                    let user = User(
                        id: userId,
                        email: finalEmail,
                        username: finalUsername,
                        fullName: finalFullName,
                        role: finalRole,
                        tenantId: finalTenant
                    )

                    SupabaseService.shared.tenantId = finalTenant
                    if let encoded = try? JSONEncoder().encode(user) {
                        try? keychain.set(encoded, key: keychainUserKey)
                    }
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isLoading = false
                    return true
                } else {
                    self.errorMessage = (verifyRes["message"] as? String) ?? "Geçersiz kullanıcı adı/e-posta veya şifre."
                    self.isLoading = false
                    return false
                }
            }
        } catch {
            print("[AuthService] RPC v2 login fallback: \(error)")
        }

        // 2. Fallback: Direct public.kullanicilar lookup (username OR email, is_deleted=not.is.true)
        do {
            struct RemoteUserRow: Decodable {
                let id: String?
                let username: String?
                let kullanici_adi: String?
                let password_hash: String?
                let password_salt: String?
                let email: String?
                let eposta: String?
                let role: String?
                let tenant_id: String?
                let is_active: Bool?
                let aktif_mi: Bool?
                let is_deleted: Bool?

                enum CodingKeys: String, CodingKey {
                    case id, username, kullanici_adi, password_hash, password_salt, email, eposta, role, tenant_id, is_active, aktif_mi, is_deleted
                }

                init(from decoder: Decoder) throws {
                    let c = try decoder.container(keyedBy: CodingKeys.self)
                    if let intId = try? c.decode(Int.self, forKey: .id) {
                        self.id = String(intId)
                    } else {
                        self.id = try? c.decode(String.self, forKey: .id)
                    }
                    self.username = try? c.decode(String.self, forKey: .username)
                    self.kullanici_adi = try? c.decode(String.self, forKey: .kullanici_adi)
                    self.password_hash = try? c.decode(String.self, forKey: .password_hash)
                    self.password_salt = try? c.decode(String.self, forKey: .password_salt)
                    self.email = try? c.decode(String.self, forKey: .email)
                    self.eposta = try? c.decode(String.self, forKey: .eposta)
                    self.role = try? c.decode(String.self, forKey: .role)
                    self.tenant_id = try? c.decode(String.self, forKey: .tenant_id)
                    self.is_active = try? c.decode(Bool.self, forKey: .is_active)
                    self.aktif_mi = try? c.decode(Bool.self, forKey: .aktif_mi)
                    self.is_deleted = try? c.decode(Bool.self, forKey: .is_deleted)
                }
            }

            let escapedIdent = escapePostgrestFilterValue(cleanIdentifier)
            let users: [RemoteUserRow] = try await SupabaseService.shared.fetch(
                from: "kullanicilar",
                filters: [
                    "or": "(username.ilike.\(escapedIdent),kullanici_adi.ilike.\(escapedIdent),email.ilike.\(escapedIdent),eposta.ilike.\(escapedIdent))",
                    "is_deleted": "not.is.true"
                ],
                applyTenantFilter: false
            )

            for matched in users {
                if matched.is_deleted == true { continue }
                if matched.is_active == false || matched.aktif_mi == false { continue }

                let storedHash = matched.password_hash ?? ""
                if storedHash.isEmpty || storedHash.lowercased() == "temporary" { continue }
                let storedSalt = matched.password_salt
                let rawTenant = (matched.tenant_id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let resolvedTenant = (rawTenant.isEmpty || rawTenant == "default") ? "tenant_ermay_master" : rawTenant

                if verifyPassword(plain: cleanPass, storedHash: storedHash, saltBase64: storedSalt) {
                    let finalUsername = (matched.username ?? matched.kullanici_adi ?? cleanIdentifier).trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalEmail = matched.email ?? matched.eposta ?? "\(finalUsername)@ermay.local"
                    let user = User(
                        id: matched.id ?? UUID().uuidString,
                        email: finalEmail,
                        username: finalUsername,
                        fullName: finalUsername.capitalized,
                        role: matched.role ?? "Admin",
                        tenantId: resolvedTenant
                    )

                    SupabaseService.shared.tenantId = resolvedTenant
                    if let encoded = try? JSONEncoder().encode(user) {
                        try? keychain.set(encoded, key: keychainUserKey)
                    }
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isLoading = false
                    return true
                }
            }
        } catch {
            print("[AuthService] public.kullanicilar fallback error: \(error)")
        }

        errorMessage = "Giriş başarısız: Kullanıcı adı/e-posta veya şifre hatalı."
        isLoading = false
        return false
    }
    
    public func logout() {
        try? keychain.remove(keychainUserKey)
        UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
        self.currentUser = nil
        self.isAuthenticated = false
        SupabaseService.shared.authToken = nil
    }
}
