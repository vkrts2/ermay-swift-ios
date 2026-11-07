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
    
    // Masaüstü C# Rfc2898DeriveBytes (PBKDF2-SHA256, 100.000 iterasyon + eski 10.000 iterasyon uyumluluğu) ile %100 uyumlu şifre doğrulama
    private func verifyPassword(plain: String, storedHash: String, saltBase64: String?) -> Bool {
        if storedHash.starts(with: "PBKDF2$"), let saltBase64 = saltBase64, !saltBase64.isEmpty {
            guard let saltData = Data(base64Encoded: saltBase64),
                  let expectedHashData = Data(base64Encoded: storedHash.replacingOccurrences(of: "PBKDF2$", with: "")) else {
                return false
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
                
                if status == kCCSuccess && derivedKey == expectedHashData {
                    return true
                }
            }
        }
        
        // Düz SHA256 kontrolü (fallback)
        let sha256Hex = SHA256.hash(data: Data(plain.utf8)).map { String(format: "%02x", $0) }.joined()
        if sha256Hex.lowercased() == storedHash.lowercased() {
            return true
        }
        
        return false
    }
    
    public func login(username: String, pass: String, tenantId: String = "") async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPass = pass.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanUsername.isEmpty else {
            errorMessage = "Kullanıcı adı boş bırakılamaz."
            isLoading = false
            return false
        }
        guard !cleanPass.isEmpty else {
            errorMessage = "Şifre boş bırakılamaz."
            isLoading = false
            return false
        }
        
        // 1. Supabase __SYS_USERS__ Notlar Havuzundan Canlı Kullanıcı Kontrolü
        do {
            struct SysNote: Decodable {
                let id: Int?
                let baslik: String?
                let title: String?
                let icerik: String?
                let content: String?
            }
            let notes: [SysNote] = try await SupabaseService.shared.fetch(
                from: "notlar",
                filters: ["or": "(id.eq.999999,baslik.eq.__SYS_USERS__,title.eq.__SYS_USERS__)"],
                applyTenantFilter: false
            )
            
            for note in notes {
                guard let jsonStr = note.icerik ?? note.content, let data = jsonStr.data(using: .utf8) else { continue }
                if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    for uDict in jsonArray {
                        let rawName = (uDict["username"] as? String) ?? (uDict["Username"] as? String) ?? ""
                        let uName = rawName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        let uPass = (uDict["password"] as? String) ?? (uDict["Password"] as? String) ?? (uDict["password_hash"] as? String) ?? ""
                        let uSalt = (uDict["password_salt"] as? String) ?? (uDict["PasswordSalt"] as? String)
                        let uEmail = (uDict["email"] as? String) ?? (uDict["Email"] as? String) ?? "\(cleanUsername)@ermay.local"
                        let uRole = (uDict["role"] as? String) ?? (uDict["Role"] as? String) ?? "Admin"
                        
                        // Kullanıcının masaüstünde belirlenmiş gerçek tenant kimliği
                        let rawTenant = (uDict["tenant_id"] as? String) ?? (uDict["TenantId"] as? String) ?? ""
                        var resolvedTenant = rawTenant.trimmingCharacters(in: .whitespacesAndNewlines)
                        let requestedTenant = tenantId.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !requestedTenant.isEmpty && requestedTenant != "default" {
                            resolvedTenant = requestedTenant
                        } else if resolvedTenant.isEmpty || resolvedTenant == "default" {
                            resolvedTenant = "tenant_ermay_master"
                        }
                        
                        if uName == cleanUsername && !uPass.isEmpty && uPass.lowercased() != "temporary" {
                            if verifyPassword(plain: cleanPass, storedHash: uPass, saltBase64: uSalt) || cleanPass == uPass {
                                let user = User(
                                    id: String(describing: uDict["id"] ?? uDict["Id"] ?? "1"),
                                    email: uEmail,
                                    username: cleanUsername,
                                    fullName: cleanUsername.capitalized,
                                    role: uRole,
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
                    }
                }
            }
        } catch {
            print("[AuthService] Supabase kullanıcı kontrolü: \(error)")
        }
        
        // 2. Supabase public.kullanicilar tablosundan kontrol
        do {
            struct RemoteUserRow: Decodable {
                let id: String?
                let username: String?
                let password_hash: String?
                let password_salt: String?
                let email: String?
                let role: String?
                let tenant_id: String?
            }
            
            let users: [RemoteUserRow] = try await SupabaseService.shared.fetch(
                from: "kullanicilar",
                filters: ["username": "eq.\(cleanUsername)"],
                applyTenantFilter: false
            )
            
            for matched in users {
                let storedHash = matched.password_hash ?? ""
                if storedHash.isEmpty || storedHash.lowercased() == "temporary" { continue }
                let storedSalt = matched.password_salt
                let requestedTenant = tenantId.trimmingCharacters(in: .whitespacesAndNewlines)
                var resolvedTenant = (matched.tenant_id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !requestedTenant.isEmpty && requestedTenant != "default" {
                    resolvedTenant = requestedTenant
                } else if resolvedTenant.isEmpty || resolvedTenant == "default" {
                    resolvedTenant = "tenant_ermay_master"
                }
                
                if verifyPassword(plain: cleanPass, storedHash: storedHash, saltBase64: storedSalt) || cleanPass == storedHash {
                    let user = User(
                        id: matched.id ?? UUID().uuidString,
                        email: matched.email ?? "\(cleanUsername)@ermay.local",
                        username: cleanUsername,
                        fullName: cleanUsername.capitalized,
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
            print("[AuthService] public.kullanicilar kontrolü: \(error)")
        }
        
        errorMessage = "Giriş başarısız: Masaüstünde belirlediğiniz kullanıcı adı veya şifre hatalı."
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
