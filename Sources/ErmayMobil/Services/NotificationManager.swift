import SwiftUI

public final class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()
    
    @Published public var bildirimler: [BildirimItem] = []
    
    public var unreadCount: Int {
        bildirimler.filter { !$0.okunduMu }.count
    }
    
    public func markAllAsRead() {
        for idx in bildirimler.indices {
            bildirimler[idx].okunduMu = true
        }
    }
    
    public func deleteAll() {
        bildirimler.removeAll()
    }
    
    public func delete(id: String) {
        bildirimler.removeAll { $0.id == id }
    }
}

extension Notification.Name {
    public static let userToastNotification = Notification.Name("com.ermay.muhasebe.userToastNotification")
}

