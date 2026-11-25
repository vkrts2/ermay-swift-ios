import SwiftUI

@main
public struct ErmayApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            RootView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                BiometricLockService.shared.lockIfNeeded()
            }
        }
    }
}

