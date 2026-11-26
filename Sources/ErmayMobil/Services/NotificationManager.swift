import SwiftUI

public final class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()
    
    @Published public var bildirimler: [BildirimItem] = []
    
    public var unreadCount: Int {
        bildirimler.filter { !$0.okunduMu }.count
    }
    
    public func addNotification(baslik: String, mesaj: String, tur: String = "UYARI") {
        let nowStr = AppFormatters.shortDate.string(from: Date())
        let item = BildirimItem(
            id: UUID().uuidString,
            baslik: baslik,
            mesaj: mesaj,
            zaman: nowStr,
            tur: tur,
            okunduMu: false
        )
        if !bildirimler.contains(where: { $0.baslik == baslik && $0.mesaj == mesaj }) {
            bildirimler.insert(item, at: 0)
            if bildirimler.count > 100 {
                bildirimler = Array(bildirimler.prefix(100))
            }
        }
    }
    
    public func refreshAccountingAlerts(stoklar: [StokKart], faturalar: [Fatura]) {
        let nowStr = AppFormatters.shortDate.string(from: Date())
        // Preserve manual/system error notifications (where id doesn't start with "auto-")
        var updated = bildirimler.filter { !$0.id.hasPrefix("auto-") }
        let readIds = Set(bildirimler.filter { $0.okunduMu }.map { $0.id })
        
        // 1. Kritik / Eksi Stok Uyarıları
        for s in stoklar where !s.isDeleted {
            let kritik = s.kritikMiktar ?? 0.0
            if s.mevcutMiktar < 0 || (kritik > 0 && s.mevcutMiktar <= kritik) {
                let nId = "auto-stok-\(s.id)"
                let msg = s.mevcutMiktar < 0
                    ? "\(s.stokAdi) stoğu eksiye düştü (\(String(format: "%.2f", s.mevcutMiktar)) \(s.birim ?? "Adet"))."
                    : "\(s.stokAdi) kritik seviyenin altında (\(String(format: "%.2f", s.mevcutMiktar)) / \(String(format: "%.2f", kritik)))."
                updated.append(BildirimItem(
                    id: nId,
                    baslik: s.mevcutMiktar < 0 ? "Eksi Stok Uyarısı" : "Kritik Stok Seviyesi",
                    mesaj: msg,
                    zaman: nowStr,
                    tur: s.mevcutMiktar < 0 ? "TEHLIKE" : "UYARI",
                    okunduMu: readIds.contains(nId)
                ))
            }
        }
        
        // 2. Vadesi Geçmiş Açık Faturalar
        let today = Calendar.current.startOfDay(for: Date())
        for f in faturalar where !f.isDeleted && !f.isKapaliOrPaid {
            let vStr = f.vadeTarihi ?? f.tarih
            if let vd = AppFormatters.parseDate(String(vStr.prefix(10))) ?? AppFormatters.parseDate(vStr) {
                let diff = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: vd), to: today).day ?? 0
                if diff > 0 {
                    let nId = "auto-fatura-\(f.id)"
                    let isSatis = f.faturaTuru.localizedCaseInsensitiveContains("satış") || f.faturaTuru.localizedCaseInsensitiveContains("satis")
                    updated.append(BildirimItem(
                        id: nId,
                        baslik: isSatis ? "Gecikmiş Tahsilat (\(diff) Gün)" : "Gecikmiş Ödeme (\(diff) Gün)",
                        mesaj: "\(f.cariUnvan ?? f.faturaNo) - \(f.faturaNo): \(AppFormatters.money(f.genelToplam))",
                        zaman: String(vStr.prefix(10)),
                        tur: "TEHLIKE",
                        okunduMu: readIds.contains(nId)
                    ))
                }
            }
        }
        
        self.bildirimler = Array(updated.prefix(100))
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
