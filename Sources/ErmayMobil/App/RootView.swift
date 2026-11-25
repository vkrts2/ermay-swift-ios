import SwiftUI

public struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var supabaseService = SupabaseService.shared
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var lockService = BiometricLockService.shared
    
    public init() {}
    
    public var body: some View {
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
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                BiometricLockService.shared.lockIfNeeded()
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

