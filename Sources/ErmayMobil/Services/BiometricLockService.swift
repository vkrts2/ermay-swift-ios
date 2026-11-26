import Foundation
import LocalAuthentication
import SwiftUI
import CryptoKit
#if canImport(KeychainAccess)
import KeychainAccess
#endif

@MainActor
public final class BiometricLockService: ObservableObject {
    public static let shared = BiometricLockService()
    
    @Published public var isLocked: Bool = false
    @Published public var isBiometricsEnabled: Bool = false
    @Published public var pinCode: String? = nil
    @Published public var pinLength: Int = 4
    @Published public var failedAttempts: Int = 0
    @Published public var lockoutUntil: Date? = nil
    
    private let biometricsEnabledKey = "ermay_biometrics_enabled"
    private let pinCodeKey = "ermay_pin_code"
    private let pinHashKey = "ermay_pin_sha256_hash"
    private let pinSaltKey = "ermay_pin_salt"
    private let pinLengthKey = "ermay_pin_length"
    
    #if canImport(KeychainAccess)
    private let keychain = Keychain(service: "com.ermay.muhasebe").accessibility(.whenUnlockedThisDeviceOnly)
    #endif
    
    public var isPinConfigured: Bool {
        !(pinCode?.isEmpty ?? true)
    }
    
    public var remainingCooldownSeconds: Int {
        guard let until = lockoutUntil else { return 0 }
        let diff = Int(ceil(until.timeIntervalSinceNow))
        return max(0, diff)
    }
    
    private init() {
        self.isBiometricsEnabled = UserDefaults.standard.bool(forKey: biometricsEnabledKey)
        let savedLen = UserDefaults.standard.integer(forKey: pinLengthKey)
        if (4...6).contains(savedLen) {
            self.pinLength = savedLen
        }
        
        #if canImport(KeychainAccess)
        if let existingHash = try? keychain.get(pinHashKey), !existingHash.isEmpty {
            self.pinCode = existingHash
            if let lenStr = try? keychain.get(pinLengthKey), let len = Int(lenStr), (4...6).contains(len) {
                self.pinLength = len
            }
        } else if let plainPin = (try? keychain.get(pinCodeKey)) ?? UserDefaults.standard.string(forKey: pinCodeKey),
                  !plainPin.isEmpty {
            // Auto-migrate plaintext 4-6 digit PIN to salted SHA-256 hash
            self.setPin(plainPin)
        }
        #else
        if let legacyPin = UserDefaults.standard.string(forKey: pinCodeKey), !legacyPin.isEmpty {
            self.setPin(legacyPin)
        }
        #endif
        
        if isPinConfigured || isBiometricsEnabled {
            self.isLocked = true
        }
    }
    
    private func hashPin(_ pin: String, salt: String) -> String {
        let input = Data((salt + ":" + pin).utf8)
        let digest = SHA256.hash(data: input)
        return "SHA256$" + Data(digest).base64EncodedString()
    }
    
    public func setPin(_ pin: String?) {
        let trimmed = pin?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            self.pinCode = nil
            self.pinLength = 4
            self.failedAttempts = 0
            self.lockoutUntil = nil
            #if canImport(KeychainAccess)
            try? keychain.remove(pinCodeKey)
            try? keychain.remove(pinHashKey)
            try? keychain.remove(pinSaltKey)
            try? keychain.remove(pinLengthKey)
            #endif
            UserDefaults.standard.removeObject(forKey: pinCodeKey)
            UserDefaults.standard.removeObject(forKey: pinLengthKey)
            return
        }
        
        let clampedLen = min(6, max(4, trimmed.count))
        let normalizedPin = String(trimmed.prefix(clampedLen))
        let salt = UUID().uuidString
        let hashed = hashPin(normalizedPin, salt: salt)
        self.pinLength = normalizedPin.count
        self.pinCode = hashed
        self.failedAttempts = 0
        self.lockoutUntil = nil
        
        #if canImport(KeychainAccess)
        try? keychain.set(hashed, key: pinHashKey)
        try? keychain.set(salt, key: pinSaltKey)
        try? keychain.set(String(self.pinLength), key: pinLengthKey)
        try? keychain.remove(pinCodeKey)
        #endif
        UserDefaults.standard.set(self.pinLength, forKey: pinLengthKey)
        UserDefaults.standard.removeObject(forKey: pinCodeKey)
    }
    
    public func setBiometricsEnabled(_ enabled: Bool) {
        self.isBiometricsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: biometricsEnabledKey)
    }
    
    public func authenticateBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Ermay Muhasebe'ye erişmek için doğrulama yapın"
            )
            if success {
                self.isLocked = false
                self.failedAttempts = 0
                self.lockoutUntil = nil
                return true
            }
        } catch {
            print("Biometric error: \(error.localizedDescription)")
        }
        return false
    }
    
    public func verifyPin(_ enteredPin: String) -> Bool {
        if remainingCooldownSeconds > 0 {
            return false
        }
        guard let saved = pinCode, !saved.isEmpty else {
            return false
        }
        
        let isMatch: Bool
        if saved.hasPrefix("SHA256$") {
            #if canImport(KeychainAccess)
            let salt = (try? keychain.get(pinSaltKey)) ?? ""
            #else
            let salt = ""
            #endif
            let candidate = hashPin(enteredPin, salt: salt)
            isMatch = (candidate == saved)
        } else {
            isMatch = (saved == enteredPin)
        }
        
        if isMatch {
            self.isLocked = false
            self.failedAttempts = 0
            self.lockoutUntil = nil
            return true
        } else {
            self.failedAttempts += 1
            if self.failedAttempts >= 5 {
                self.lockoutUntil = Date().addingTimeInterval(30)
                self.failedAttempts = 0
            }
            return false
        }
    }
    
    public func lockIfNeeded() {
        lockNow()
    }
    
    public func lockNow() {
        if isPinConfigured || isBiometricsEnabled {
            self.isLocked = true
        }
    }
}
