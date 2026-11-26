import SwiftUI

public struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var supabaseService = SupabaseService.shared
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var lockService = BiometricLockService.shared
    
    @State private var toastMessage: String? = nil
    @State private var toastWorkItem: DispatchWorkItem? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Group {
                if !supabaseService.isConfigured {
                    SupabaseSetupView()
                } else if !authService.isAuthenticated {
                    LoginView()
                } else if lockService.isLocked {
                    LockView()
                } else {
                    MainTabView()
                }
            }
            
            // App Switcher Privacy Blur Overlay (OWASP MASVS-STORAGE / Privacy Protection)
            if scenePhase == .inactive || scenePhase == .background {
                ZStack {
                    Color(hex: "080A0C").ignoresSafeArea()
                    VStack(spacing: 14) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.primary)
                        Text("ERMAY MUHASEBE")
                            .font(.system(size: 16, weight: .black))
                            .tracking(2)
                            .foregroundColor(.white)
                    }
                }
                .transition(.opacity)
                .zIndex(999)
            }
            
            // Global Error / Info Toast Banner
            if let msg = toastMessage {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text(msg)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                toastMessage = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: "EF4444").opacity(0.95))
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .userToastNotification)) { notification in
            if let message = notification.userInfo?["message"] as? String, !message.isEmpty {
                let title = (notification.userInfo?["title"] as? String) ?? "Sistem Bildirimi"
                let tur = (notification.userInfo?["tur"] as? String) ?? "TEHLIKE"
                NotificationManager.shared.addNotification(baslik: title, mesaj: message, tur: tur)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    toastMessage = message
                }
                toastWorkItem?.cancel()
                let work = DispatchWorkItem {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        toastMessage = nil
                    }
                }
                toastWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: work)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                BiometricLockService.shared.lockIfNeeded()
            } else if newPhase == .active {
                if supabaseService.isConfigured && authService.isAuthenticated {
                    SupabaseService.shared.connectRealtime()
                    Task {
                        await DataStore.shared.loadAll(force: false)
                    }
                }
            }
        }
        .onChange(of: supabaseService.isConfigured) { configured in
            if configured {
                SupabaseService.shared.startRealtimeListener()
                Task { await DataStore.shared.syncAll() }
            }
        }
        .onChange(of: authService.isAuthenticated) { authenticated in
            if authenticated && supabaseService.isConfigured {
                SupabaseService.shared.startRealtimeListener()
                Task { await DataStore.shared.syncAll() }
            }
        }
        .onAppear {
            NetworkMonitor.shared.start()
            if supabaseService.isConfigured {
                SupabaseService.shared.startRealtimeListener()
                if authService.isAuthenticated {
                    Task { await DataStore.shared.syncAll() }
                }
            }
        }
    }
}
