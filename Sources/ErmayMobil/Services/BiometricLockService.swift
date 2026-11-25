import Foundation
import LocalAuthentication
import SwiftUI
#if canImport(KeychainAccess)
import KeychainAccess
#endif

@MainActor
public final class BiometricLockService: ObservableObject {
    public static let shared = BiometricLockService()
    
    @Published public var isLocked: Bool = false
    @Published public var isBiometricsEnabled: Bool = false
    @Published public var pinCode: String? = nil
    
    private let biometricsEnabledKey = "ermay_biometrics_enabled"
    private let pinCodeKey = "ermay_pin_code"
    
    #if canImport(KeychainAccess)
    private let keychain = Keychain(service: "com.ermay.muhasebe").accessibility(.afterFirstUnlock)
    #endif
    
    private init() {
        self.isBiometricsEnabled = UserDefaults.standard.bool(forKey: biometricsEnabledKey)
        
        #if canImport(KeychainAccess)
        self.pinCode = try? keychain.get(pinCodeKey)
        if self.pinCode == nil, let legacyPin = UserDefaults.standard.string(forKey: pinCodeKey) {
            self.pinCode = legacyPin
            try? keychain.set(legacyPin, key: pinCodeKey)
            UserDefaults.standard.removeObject(forKey: pinCodeKey)
        }
        #else
        self.pinCode = UserDefaults.standard.string(forKey: pinCodeKey)
        #endif
        
        if pinCode != nil || isBiometricsEnabled {
            self.isLocked = true
        }
    }
    
    public func setPin(_ pin: String?) {
        self.pinCode = pin
        #if canImport(KeychainAccess)
        if let p = pin {
            try? keychain.set(p, key: pinCodeKey)
        } else {
            try? keychain.remove(pinCodeKey)
        }
        #endif
        // Do not store PIN in plaintext UserDefaults
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
                return true
            }
        } catch {
            print("Biometric error: \(error.localizedDescription)")
        }
        return false
    }
    
    public func verifyPin(_ enteredPin: String) -> Bool {
        guard let savedPin = pinCode, !savedPin.isEmpty else {
            return false
        }
        if savedPin == enteredPin {
            self.isLocked = false
            return true
        }
        return false
    }
    
    public func lockIfNeeded() {
        lockNow()
    }
    
    public func lockNow() {
        if (pinCode != nil && !(pinCode?.isEmpty ?? true)) || isBiometricsEnabled {
            self.isLocked = true
        }
    }
}
