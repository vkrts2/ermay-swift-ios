import SwiftUI

public struct LockView: View {
    @ObservedObject var lockService = BiometricLockService.shared
    @State private var pinInput: String = ""
    @State private var errorText: String? = nil
    @State private var cooldownRemaining: Int = 0
    @State private var cooldownTimer: Timer? = nil
    
    public init() {}
    
    private var targetPinLength: Int {
        min(6, max(4, lockService.pinLength))
    }
    
    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.15))
                        .frame(width: 84, height: 84)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.primary)
                }
                
                VStack(spacing: 8) {
                    Text("Uygulama Kilitli")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(cooldownRemaining > 0
                         ? "Çok fazla hatalı deneme. \(cooldownRemaining) sn bekleyin."
                         : "Devam etmek için \(targetPinLength) haneli PIN kodunuzu girin")
                        .font(.system(size: 13))
                        .foregroundColor(cooldownRemaining > 0 ? AppTheme.danger : AppTheme.textSecondary)
                }
                
                // PIN Noktaları (Dots - Dinamik 4..6 Hane)
                HStack(spacing: 16) {
                    ForEach(0..<targetPinLength, id: \.self) { index in
                        Circle()
                            .fill(index < pinInput.count ? AppTheme.primary : AppTheme.cardSecondary)
                            .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(.vertical, 8)
                
                if let err = errorText {
                    Text(err)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.danger)
                }
                
                // Numpad
                VStack(spacing: 16) {
                    let rows = [
                        ["1", "2", "3"],
                        ["4", "5", "6"],
                        ["7", "8", "9"],
                        ["faceid", "0", "delete"]
                    ]
                    
                    ForEach(rows, id: \.self) { row in
                        HStack(spacing: 24) {
                            ForEach(row, id: \.self) { key in
                                Button {
                                    handleKey(key)
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.cardBackground)
                                            .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                                            .frame(width: 70, height: 70)
                                        
                                        if key == "delete" {
                                            Image(systemName: "delete.left.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(AppTheme.textPrimary)
                                        } else if key == "faceid" {
                                            Image(systemName: "faceid")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppTheme.primary)
                                        } else {
                                            Text(key)
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                    }
                                }
                                .disabled(cooldownRemaining > 0 && key != "faceid")
                                .opacity(cooldownRemaining > 0 && key != "faceid" ? 0.45 : 1.0)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            syncCooldownTimer()
            if lockService.isBiometricsEnabled {
                Task {
                    _ = await lockService.authenticateBiometrics()
                }
            }
        }
        .onDisappear {
            cooldownTimer?.invalidate()
            cooldownTimer = nil
        }
    }
    
    private func syncCooldownTimer() {
        cooldownRemaining = lockService.remainingCooldownSeconds
        cooldownTimer?.invalidate()
        guard cooldownRemaining > 0 else { return }
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                let rem = lockService.remainingCooldownSeconds
                cooldownRemaining = rem
                if rem <= 0 {
                    errorText = nil
                    cooldownTimer?.invalidate()
                    cooldownTimer = nil
                }
            }
        }
    }
    
    private func handleKey(_ key: String) {
        if key == "faceid" {
            Task {
                _ = await lockService.authenticateBiometrics()
            }
            return
        }
        guard lockService.remainingCooldownSeconds == 0 else {
            syncCooldownTimer()
            return
        }
        if key == "delete" {
            if !pinInput.isEmpty {
                pinInput.removeLast()
                errorText = nil
            }
        } else {
            if pinInput.count < targetPinLength {
                pinInput.append(key)
                if pinInput.count == targetPinLength {
                    if lockService.verifyPin(pinInput) {
                        errorText = nil
                    } else {
                        pinInput = ""
                        let rem = lockService.remainingCooldownSeconds
                        if rem > 0 {
                            errorText = "5 hatalı giriş! \(rem) saniye kilitlendi."
                            syncCooldownTimer()
                        } else {
                            let left = max(1, 5 - lockService.failedAttempts)
                            errorText = "Hatalı PIN kodu! (\(left) hak kaldı)"
                        }
                    }
                }
            }
        }
    }
}
