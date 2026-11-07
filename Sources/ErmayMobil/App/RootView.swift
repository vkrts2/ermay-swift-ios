import SwiftUI

public struct RootView: View {
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
        .onChange(of: supabaseService.isConfigured) { configured in
            if configured {
                SupabaseService.shared.startRealtimeListener()
            }
        }
        .onAppear {
            if supabaseService.isConfigured {
                SupabaseService.shared.startRealtimeListener()
            }
        }
    }
}

