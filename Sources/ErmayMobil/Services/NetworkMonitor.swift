// Sources/ErmayMobil/Services/NetworkMonitor.swift
import Foundation
import Network
import Combine

@MainActor
public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()

    @Published public private(set) var isOnline: Bool = true
    @Published public private(set) var connectionType: String = "Bilinmiyor"

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.ermay.muhasebe.networkmonitor", qos: .utility)
    private var started = false

    private init() {}

    public func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            let type: String
            if path.usesInterfaceType(.wifi) {
                type = "Wi-Fi"
            } else if path.usesInterfaceType(.cellular) {
                type = "Hücresel"
            } else if path.usesInterfaceType(.wiredEthernet) {
                type = "Ethernet"
            } else {
                type = online ? "Çevrimiçi" : "Çevrimdışı"
            }

            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let changed = self.isOnline != online
                self.isOnline = online
                self.connectionType = type
                if changed && online && SupabaseService.shared.isConfigured {
                    SupabaseService.shared.startRealtimeListener()
                }
            }
        }
        monitor.start(queue: queue)
    }

    public func stop() {
        guard started else { return }
        started = false
        monitor.cancel()
    }
}
