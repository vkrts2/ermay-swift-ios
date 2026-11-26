import Foundation

public struct SatisHedefRow: Codable {
    public var id: Int?
    public var yil: Int?
    public var ay: Int?
    public var hafta: Int?
    public var haftaNo: Int?
    public var hedefTutar: Double?
    public var hedefTutari: Double?
    public var gerceklesenTutar: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case yil
        case ay
        case hafta
        case haftaNo = "hafta_no"
        case hedefTutar = "hedef_tutar"
        case hedefTutari = "hedef_tutari"
        case gerceklesenTutar = "gerceklesen_tutar"
    }
    
    public var effectiveHedef: Double {
        if let h1 = hedefTutari, h1 > 0 { return h1 }
        if let h2 = hedefTutar, h2 > 0 { return h2 }
        return hedefTutari ?? hedefTutar ?? 0.0
    }
    
    public var effectiveHafta: Int {
        hafta ?? haftaNo ?? 1
    }
}

public final class ReportCalculationService {
    public static let shared = ReportCalculationService()
    
    private init() {}
    
    public func parseDateRange(filter: String) -> (startDay: Date, endDay: Date, isAll: Bool) {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        let f = filter.lowercased()
        
        if f == "all" || f == "tümü" || f == "tumu" {
            let start = cal.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? today
            let end = cal.date(from: DateComponents(year: 2099, month: 12, day: 31)) ?? today
            return (start, end, true)
        } else if f == "weekly" || f == "bu hafta" {
            let start = cal.date(byAdding: .day, value: -7, to: today) ?? today
            return (start, today, false)
        } else if f == "yearly" || f == "bu yıl" || f == "bu yil" {
            let year = cal.component(.year, from: today)
            let start = cal.date(from: DateComponents(year: year, month: 1, day: 1)) ?? today
            let end = cal.date(from: DateComponents(year: year, month: 12, day: 31)) ?? today
            return (start, end, false)
        } else {
            // Monthly / Bu Ay
            let comps = cal.dateComponents([.year, .month], from: today)
            let start = cal.date(from: comps) ?? today
            let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? today
            return (start, end, false)
        }
    }
    
    private func isDateInRange(_ dateStr: String?, startDay: Date, endDay: Date, isAll: Bool) -> Bool {
        if isAll { return true }
        guard let dStr = dateStr, !dStr.isEmpty else { return true }
        guard let d = AppFormatters.parseDate(String(dStr.prefix(10))) ?? AppFormatters.parseDate(dStr) else { return true }
        let day = Calendar.current.startOfDay(for: d)
        return day >= startDay && day <= endDay
    }
    
    private func formatDisplayDate(_ dateStr: String?) -> String {
        guard let s = dateStr, !s.isEmpty else { return "-" }
        if let d = AppFormatters.parseDate(String(s.prefix(10))) ?? AppFormatters.parseDate(s) {
            return AppFormatters.shortDate.string(from: d)
        }
        return String(s.prefix(10))
    }
    
    public func calculateRows(for title: String, filter: String = "Tümü", selectedCari: CariKart? = nil) async -> [[String]] {
        let res = await calculateReportData(for: title, filter: filter, selectedCari: selectedCari)
        return res.rows
    }
    
    public func calculateReportData(for title: String, filter: String = "Tümü", selectedCari: CariKart? = nil) async -> (title: String, headers: [String], rows: [[String]]) {
        let (startDay, endDay, isAll) = parseDateRange(filter: filter)
        let dateSuffix = isAll ? "" : " (\(AppFormatters.shortDate.string(from: startDay)) - \(AppFormatters.shortDate.string(from: endDay)))"
        
        let defaultCariler = await MainActor.run { DataStore.shared.cariler }
        let defaultStoklar = await MainActor.run { DataStore.shared.stoklar }
        let defaultFaturalar = await MainActor.run { DataStore.shared.faturalar }

        let cariler: [CariKart] = (try? await SupabaseService.shared.fetch(from: "cariler")) ?? defaultCariler
        let stoklar: [StokKart] = (try? await SupabaseService.shared.fetch(from: "stoklar")) ?? defaultStoklar
        let faturalar: [Fatura] = (try? await SupabaseService.shared.fetch(from: "faturalar")) ?? defaultFaturalar
        let kasaHareketler: [KasaHareket] = (try? await SupabaseService.shared.fetch(from: "kasa_hareketler")) ?? []
        let cariHareketler: [CariHareket] = (try? await SupabaseService.shared.fetch(from: "cari_hareketler")) ?? []
        let bankalar: [BankaKart] = (try? await SupabaseService.shared.fetch(from: "bankalar")) ?? []
        let kasalar: [KasaBanka] = (try? await SupabaseService.shared.fetch(from: "kasalar")) ?? []
        let cekler: [Cek] = (try? await SupabaseService.shared.fetch(from: "cekler")) ?? []
        
        var reportTitle = title
        var headers: [String] = []
        var rows: [[String]] = []
        
        switch title {
        case "Genel Özet":
            headers = ["Rapor Kalemi", "Tutar"]
            let stokHareketler: [StokHareket] = (try? await SupabaseService.shared.fetch(from: "stok_hareketler")) ?? []
            let donemStokH = stokHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
            let aktifStokIdler = Set(donemStokH.map { $0.stokId })
            let aktifStoklar = (isAll || aktifStokIdler.isEmpty) ? stoklar : stoklar.filter { aktifStokIdler.contains($0.id) }
            
            let recv: Double
            let pay: Double
            if isAll {
                recv = cariler.filter { $0.bakiye > 0 }.reduce(0.0) { $0 + $1.bakiye }
                pay = cariler.filter { $0.bakiye < 0 }.reduce(0.0) { $0 + abs($1.bakiye) }
            } else {
                let donemCH = cariHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: false) }
                recv = donemCH.reduce(0.0) { $0 + $1.borc }
                pay = donemCH.reduce(0.0) { $0 + $1.alacak }
            }
            let totalCash = bankalar.reduce(0.0) { $0 + $1.bakiye } + kasalar.reduce(0.0) { $0 + $1.bakiye }
            let totalStokQty = aktifStoklar.reduce(0.0) { $0 + $1.mevcutMiktar }
            let totalStokVal = aktifStoklar.reduce(0.0) { $0 + ($1.mevcutMiktar * $1.alisFiyati) }
            
            rows = [
                ["Toplam Alacaklar\(dateSuffix)", formatCurrency(recv)],
                ["Toplam Borçlar\(dateSuffix)", formatCurrency(pay)],
                ["Kasa / Banka Mevcudu", formatCurrency(totalCash)],
                ["Toplam Stok Miktarı", String(format: "%.2f", totalStokQty)],
                ["Stok Maliyet Değeri", formatCurrency(totalStokVal)]
            ]
            
        case "Cari Bakiye Raporu":
            headers = ["Ünvan", "Şehir", "Borç", "Alacak", "Bakiye", "Durum"]
            var groupedCH: [String: (borc: Double, alacak: Double)] = [:]
            for h in cariHareketler where isDateInRange(h.tarih, startDay: startDay, endDay: endDay, isAll: isAll) {
                if let cid = h.cariId {
                    let cur = groupedCH[cid] ?? (0.0, 0.0)
                    groupedCH[cid] = (cur.borc + h.borc, cur.alacak + h.alacak)
                }
            }
            for c in cariler {
                let borc: Double
                let alacak: Double
                if !isAll {
                    guard let g = groupedCH[c.id] else { continue }
                    borc = g.borc
                    alacak = g.alacak
                } else if let g = groupedCH[c.id], (g.borc > 0 || g.alacak > 0) {
                    borc = g.borc
                    alacak = g.alacak
                } else {
                    borc = c.bakiye > 0 ? c.bakiye : 0
                    alacak = c.bakiye < 0 ? abs(c.bakiye) : 0
                }
                let bakiye = isAll ? c.bakiye : (borc - alacak)
                let durum = bakiye > 0 ? "Borçlu" : (bakiye < 0 ? "Alacaklı" : "Dengede")
                rows.append([c.unvan, c.sehir ?? "-", formatCurrency(borc), formatCurrency(alacak), formatCurrency(bakiye), durum])
            }
            
        case "Cari Hareket Dökümü":
            headers = ["Tarih", "Ünvan", "İşlem", "Borç", "Alacak"]
            var filtered = cariHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
            if let sel = selectedCari {
                filtered = filtered.filter { $0.cariId == sel.id || $0.cariUnvan == sel.unvan }
                reportTitle = "\(sel.unvan) - Hareket Dökümü"
            }
            for h in filtered.sorted(by: { ($0.tarih ?? "") > ($1.tarih ?? "") }).prefix(500) {
                let unvan = h.cariUnvan ?? cariler.first(where: { $0.id == h.cariId })?.unvan ?? "-"
                rows.append([formatDisplayDate(h.tarih), unvan, h.islemTuru ?? "İşlem", formatCurrency(h.borc), formatCurrency(h.alacak)])
            }
            
        case "Bütçe / Hedef Takibi":
            headers = ["Dönem", "Hedef", "Gerçekleşen", "Fark", "%"]
            let hedefler: [SatisHedefRow] = (try? await SupabaseService.shared.fetch(from: "satis_hedefleri")) ?? []
            let satisFaturalari = faturalar.filter { $0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis") }
            if !hedefler.isEmpty {
                let sorted = hedefler.sorted {
                    if ($0.yil ?? 0) != ($1.yil ?? 0) { return ($0.yil ?? 0) > ($1.yil ?? 0) }
                    return ($0.ay ?? 0) > ($1.ay ?? 0)
                }
                for h in sorted {
                    let yil = h.yil ?? Calendar.current.component(.year, from: Date())
                    let ay = h.ay ?? 1
                    let prefix = String(format: "%04d-%02d", yil, ay)
                    let suffix = String(format: ".%02d.%04d", ay, yil)
                    let actual = satisFaturalari.filter { $0.tarih.hasPrefix(prefix) || $0.tarih.hasSuffix(suffix) }.reduce(0.0) { $0 + $1.genelToplam }
                    let target = h.effectiveHedef
                    let diff = actual - target
                    let pct = target > 0 ? (actual / target * 100.0) : 0.0
                    rows.append(["\(ay)/\(yil)", formatCurrency(target), formatCurrency(actual), formatCurrency(diff), String(format: "%.1f", pct)])
                }
            } else {
                let curYear = Calendar.current.component(.year, from: Date())
                for ay in 1...12 {
                    let prefix = String(format: "%04d-%02d", curYear, ay)
                    let suffix = String(format: ".%02d.%04d", ay, curYear)
                    let actual = satisFaturalari.filter { $0.tarih.hasPrefix(prefix) || $0.tarih.hasSuffix(suffix) }.reduce(0.0) { $0 + $1.genelToplam }
                    if actual > 0 {
                        rows.append(["\(ay)/\(curYear)", formatCurrency(0), formatCurrency(actual), formatCurrency(actual), "100.0"])
                    }
                }
            }
            
        case "Yaşlandırma Raporu":
            headers = ["Ünvan", "0-30 Gün", "31-60 Gün", "61-90 Gün", "90+ Gün", "Toplam"]
            let refDate = min(endDay, Calendar.current.startOfDay(for: Date()))
            for c in cariler where c.bakiye > 0 {
                let cHar = cariHareketler.filter { $0.cariId == c.id && ($0.borc - $0.alacak) > 0 }
                var d0_30 = 0.0, d31_60 = 0.0, d61_90 = 0.0, d90plus = 0.0
                if !cHar.isEmpty {
                    for h in cHar {
                        let net = h.borc - h.alacak
                        if let d = AppFormatters.parseDate(String((h.tarih ?? "").prefix(10))) ?? AppFormatters.parseDate(h.tarih) {
                            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: d), to: refDate).day ?? 0
                            if days < 0 { continue }
                            if days <= 30 { d0_30 += net }
                            else if days <= 60 { d31_60 += net }
                            else if days <= 90 { d61_90 += net }
                            else { d90plus += net }
                        } else {
                            d0_30 += net
                        }
                    }
                } else {
                    d0_30 = c.bakiye
                }
                let total = d0_30 + d31_60 + d61_90 + d90plus
                if total > 0 {
                    rows.append([c.unvan, formatCurrency(d0_30), formatCurrency(d31_60), formatCurrency(d61_90), formatCurrency(d90plus), formatCurrency(total)])
                }
            }
            
        case "Hareketsiz Cariler":
            headers = ["Ünvan", "Grup", "Telefon", "Son İşlem", "Gün"]
            let now = Date()
            for c in cariler {
                let hasMovement = cariHareketler.contains { $0.cariId == c.id && isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
                if !hasMovement || isAll {
                    let lastTx = cariHareketler.filter { $0.cariId == c.id }.sorted(by: { ($0.tarih ?? "") > ($1.tarih ?? "") }).first
                    if isAll && lastTx != nil {
                        if let d = AppFormatters.parseDate(lastTx?.tarih), (Calendar.current.dateComponents([.day], from: d, to: now).day ?? 0) < 30 {
                            continue
                        }
                    }
                    var daysStr = "İşlem Yok"
                    if let lDateStr = lastTx?.tarih, let d = AppFormatters.parseDate(String(lDateStr.prefix(10))) ?? AppFormatters.parseDate(lDateStr) {
                        daysStr = "\((Calendar.current.dateComponents([.day], from: d, to: now).day ?? 0))"
                    }
                    rows.append([c.unvan, c.grup ?? "Müşteri", c.telefon ?? "-", lastTx != nil ? formatDisplayDate(lastTx?.tarih) : "Hiç", daysStr])
                }
            }
            
        case "Stok Mevcudu":
            headers = ["Stok Kodu", "Stok Adı", "Kategori", "Miktar", "Ort. Alış F.", "Ort. Satış F.", "Satış F."]
            let stokHareketler: [StokHareket] = (try? await SupabaseService.shared.fetch(from: "stok_hareketler")) ?? []
            let donemH = stokHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
            let aktifIds = Set(donemH.map { $0.stokId })
            let listToUse = (isAll || aktifIds.isEmpty) ? stoklar : stoklar.filter { aktifIds.contains($0.id) }
            for s in listToUse {
                rows.append([
                    s.stokKodu ?? "-",
                    s.stokAdi,
                    s.grupAdi ?? "-",
                    String(format: "%.2f", s.mevcutMiktar),
                    formatCurrency(s.alisFiyati),
                    formatCurrency(s.satisFiyati),
                    formatCurrency(s.satisFiyati)
                ])
            }
            
        case "Stok Hareketleri":
            headers = ["Tarih", "Stok Adı", "İşlem", "Giren", "Çıkan", "Birim Fiyat", "Kalan"]
            let stokHareketler: [StokHareket] = (try? await SupabaseService.shared.fetch(from: "stok_hareketler")) ?? []
            let ordered = stokHareketler.sorted { ($0.tarih ?? "") < ($1.tarih ?? "") }
            var balances: [String: Double] = [:]
            var enriched: [(h: StokHareket, giren: Double, cikan: Double, kalan: Double)] = []
            for h in ordered {
                let isGiris = h.giren > 0 || (h.cikan == 0 && !(h.islemTuru ?? "").localizedCaseInsensitiveContains("çıkış") && !(h.islemTuru ?? "").localizedCaseInsensitiveContains("satış"))
                let g = h.giren > 0 ? h.giren : (isGiris ? h.miktar : 0.0)
                let ck = h.cikan > 0 ? h.cikan : (!isGiris ? h.miktar : 0.0)
                let cur = (balances[h.stokId] ?? 0.0) + (g - ck)
                balances[h.stokId] = cur
                enriched.append((h, g, ck, cur))
            }
            let filtered = enriched.filter { isDateInRange($0.h.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }.reversed().prefix(500)
            for item in filtered {
                let sAdi = item.h.stokAdi ?? stoklar.first(where: { $0.id == item.h.stokId })?.stokAdi ?? "-"
                rows.append([
                    formatDisplayDate(item.h.tarih),
                    sAdi,
                    item.h.islemTuru ?? "Hareket",
                    String(format: "%.2f", item.giren),
                    String(format: "%.2f", item.cikan),
                    formatCurrency(item.h.birimFiyat),
                    String(format: "%.2f", item.kalan)
                ])
            }
            
        case "Kritik Stok Seviyesi":
            headers = ["Stok Kodu", "Stok Adı", "Mevcut", "Min. Seviye", "Durum", "Satış Fiyatı"]
            let kritikList = stoklar.filter { $0.mevcutMiktar < 0 || (($0.kritikMiktar ?? 0) > 0 && $0.mevcutMiktar <= ($0.kritikMiktar ?? 0)) }
            for s in kritikList {
                let durum = s.mevcutMiktar < 0 ? "Eksiye Düşmüş!" : (s.mevcutMiktar == 0 ? "Tükenmiş" : "Kritik")
                rows.append([
                    s.stokKodu ?? "-",
                    s.stokAdi,
                    String(format: "%.2f", s.mevcutMiktar),
                    String(format: "%.2f", s.kritikMiktar ?? 0),
                    durum,
                    formatCurrency(s.satisFiyati)
                ])
            }
            
        case "Ölü Stok Raporu":
            headers = ["Stok Kodu", "Stok Adı", "Kategori", "Mevcut Miktar", "Maliyet Değeri", "Durum"]
            let stokHareketler: [StokHareket] = (try? await SupabaseService.shared.fetch(from: "stok_hareketler")) ?? []
            let detaylar: [FaturaKalem] = (try? await SupabaseService.shared.fetch(from: "fatura_detaylar")) ?? []
            var soldStokIds = Set<String>()
            var soldStokNames = Set<String>()
            for h in stokHareketler where isDateInRange(h.tarih, startDay: startDay, endDay: endDay, isAll: isAll) {
                let ck = h.cikan > 0 ? h.cikan : ((h.islemTuru ?? "").localizedCaseInsensitiveContains("satış") || (h.islemTuru ?? "").localizedCaseInsensitiveContains("çıkış") ? h.miktar : 0.0)
                if ck > 0 {
                    if !h.stokId.isEmpty { soldStokIds.insert(h.stokId) }
                    if let sAdi = h.stokAdi?.lowercased(), !sAdi.isEmpty { soldStokNames.insert(sAdi) }
                }
            }
            for d in detaylar {
                if let sid = d.stokId, !sid.isEmpty { soldStokIds.insert(sid) }
                if !d.stokAdi.isEmpty { soldStokNames.insert(d.stokAdi.lowercased()) }
            }
            let deadStocks = stoklar.filter { s in
                s.mevcutMiktar > 0 && !soldStokIds.contains(s.id) && !soldStokNames.contains(s.stokAdi.lowercased())
            }
            for s in deadStocks {
                rows.append([
                    s.stokKodu ?? "-",
                    s.stokAdi,
                    s.grupAdi ?? "-",
                    String(format: "%.2f", s.mevcutMiktar),
                    formatCurrency(s.mevcutMiktar * s.alisFiyati),
                    "Hareketsiz (Satış Yok)"
                ])
            }
            if rows.isEmpty {
                rows.append(["-", "-", "-", "0.00", formatCurrency(0), "Ölü stok bulunamadı"])
            }
            
        case "Stok Devir Hızı":
            headers = ["Stok Adı", "Mevcut Stok", "Toplam Satış (Çıkan)", "Stok Devir Hızı", "Kategori"]
            let stokHareketler: [StokHareket] = (try? await SupabaseService.shared.fetch(from: "stok_hareketler")) ?? []
            let donemH = stokHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
            var satisDict: [String: Double] = [:]
            for h in donemH {
                let cikan = h.cikan > 0 ? h.cikan : ((h.islemTuru ?? "").localizedCaseInsensitiveContains("satış") || (h.islemTuru ?? "").localizedCaseInsensitiveContains("çıkış") ? h.miktar : 0.0)
                if cikan > 0 {
                    satisDict[h.stokId, default: 0.0] += cikan
                }
            }
            let aktifStoklar = (isAll || satisDict.isEmpty) ? stoklar : stoklar.filter { satisDict[$0.id] != nil }
            for s in aktifStoklar {
                let sold = satisDict[s.id] ?? 0.0
                let speed = s.mevcutMiktar > 0 ? (sold / s.mevcutMiktar) : 0.0
                rows.append([s.stokAdi, String(format: "%.2f", s.mevcutMiktar), String(format: "%.2f", sold), String(format: "%.2f", speed), s.grupAdi ?? "-"])
            }
            
        case "Satış Faturası Dökümü":
            headers = ["Fatura No", "Tarih", "Müşteri", "Ara Toplam", "KDV", "Genel Toplam"]
            let satisF = faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }.sorted { $0.tarih > $1.tarih }
            for f in satisF.prefix(500) {
                rows.append([f.faturaNo, formatDisplayDate(f.tarih), f.cariUnvan ?? "-", formatCurrency(f.araToplam), formatCurrency(f.kdvToplami), formatCurrency(f.genelToplam)])
            }
            
        case "Ürün Karlılık Raporu":
            headers = ["Ürün Adı", "Alış Fiyatı", "Satış Fiyatı", "Kar", "Kar Marjı %"]
            for s in stoklar where s.satisFiyati > 0 {
                let profit = s.satisFiyati - s.alisFiyati
                let margin = s.satisFiyati > 0 ? (profit / s.satisFiyati * 100.0) : 0.0
                rows.append([s.stokAdi, formatCurrency(s.alisFiyati), formatCurrency(s.satisFiyati), formatCurrency(profit), String(format: "%.2f", margin)])
            }
            
        case "Müşteri Karlılık Analizi":
            headers = ["Müşteri", "Toplam Satış", "Tahmini Maliyet", "Net Kar", "Kar Marjı (%)", "Fatura Sayısı"]
            let detaylar: [FaturaKalem] = (try? await SupabaseService.shared.fetch(from: "fatura_detaylar")) ?? []
            let stokDict = Dictionary(uniqueKeysWithValues: stoklar.map { ($0.id, $0) })
            let satisF = faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }
            let grouped = Dictionary(grouping: satisF, by: { $0.cariUnvan ?? "Bilinmeyen" })
            let sortedGroups = grouped.sorted {
                $0.value.reduce(0.0, { $0 + $1.genelToplam }) > $1.value.reduce(0.0, { $0 + $1.genelToplam })
            }
            for (unvan, list) in sortedGroups.prefix(100) {
                let totalSales = list.reduce(0.0) { $0 + $1.genelToplam }
                var totalCost = 0.0
                for f in list {
                    let fDetay = detaylar.filter { $0.faturaId == f.id }
                    if !fDetay.isEmpty {
                        for d in fDetay {
                            let cost = (d.stokId != nil ? stokDict[d.stokId!]?.alisFiyati : nil) ?? (d.birimFiyat * 0.75)
                            totalCost += cost * d.miktar
                        }
                    } else {
                        totalCost += f.araToplam * 0.75
                    }
                }
                let netKar = totalSales - totalCost
                let marj = totalSales > 0 ? (netKar / totalSales * 100.0) : 0.0
                rows.append([unvan, formatCurrency(totalSales), formatCurrency(totalCost), formatCurrency(netKar), String(format: "%.1f%%", marj), "\(list.count)"])
            }
            
        case "Bölge Bazlı Satış":
            headers = ["Şehir", "Müşteri Sayısı", "Toplam Satış", "Ortalama Satış"]
            let satisF = faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }
            let grouped = Dictionary(grouping: satisF) { f -> String in
                let c = cariler.first(where: { $0.id == f.cariId || $0.unvan == f.cariUnvan })
                let il = (c?.sehir ?? "").trimmingCharacters(in: .whitespaces)
                return il.isEmpty ? "Bilinmiyor" : il
            }
            for (city, list) in grouped.sorted(by: { $0.value.reduce(0.0, { $0 + $1.genelToplam }) > $1.value.reduce(0.0, { $0 + $1.genelToplam }) }) {
                let total = list.reduce(0.0) { $0 + $1.genelToplam }
                let custCount = max(1, Set(list.map { $0.cariId ?? $0.cariUnvan ?? "" }).count)
                let avg = total / Double(custCount)
                rows.append([city, "\(custCount)", formatCurrency(total), formatCurrency(avg)])
            }
            
        case "Bölgesel Satış Analizi":
            headers = ["Bölge", "Satış Tutarı", "Fatura Sayısı", "Ort. Fatura"]
            let satisF = faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }
            let grouped = Dictionary(grouping: satisF) { f -> String in
                let c = cariler.first(where: { $0.id == f.cariId || $0.unvan == f.cariUnvan })
                let il = (c?.sehir ?? "").trimmingCharacters(in: .whitespaces)
                return il.isEmpty ? "Bilinmiyor" : il
            }
            for (city, list) in grouped.sorted(by: { $0.value.reduce(0.0, { $0 + $1.genelToplam }) > $1.value.reduce(0.0, { $0 + $1.genelToplam }) }) {
                let total = list.reduce(0.0) { $0 + $1.genelToplam }
                let count = list.count
                let avg = count > 0 ? total / Double(count) : 0.0
                rows.append([city, formatCurrency(total), "\(count)", formatCurrency(avg)])
            }
            
        case "En Çok Satan Ürünler":
            headers = ["Sıra", "Ürün Adı", "Satılan Miktar", "Satış Tutarı", "Kategori"]
            let stokHareketler: [StokHareket] = (try? await SupabaseService.shared.fetch(from: "stok_hareketler")) ?? []
            let detaylar: [FaturaKalem] = (try? await SupabaseService.shared.fetch(from: "fatura_detaylar")) ?? []
            let satisFIds = Set(faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }.map { $0.id })
            
            var salesByProduct: [String: (name: String, qty: Double, revenue: Double, category: String)] = [:]
            let stokById = Dictionary(uniqueKeysWithValues: stoklar.map { ($0.id, $0) })
            
            for d in detaylar where d.faturaId == nil || satisFIds.contains(d.faturaId!) {
                let key = d.stokId ?? d.stokAdi
                guard !key.isEmpty else { continue }
                let matchedStok = d.stokId != nil ? stokById[d.stokId!] : stoklar.first(where: { $0.stokAdi == d.stokAdi })
                let cur = salesByProduct[key] ?? (name: !d.stokAdi.isEmpty ? d.stokAdi : (matchedStok?.stokAdi ?? "Ürün"), qty: 0.0, revenue: 0.0, category: matchedStok?.grupAdi ?? "-")
                salesByProduct[key] = (cur.name, cur.qty + d.miktar, cur.revenue + d.toplamTutar, cur.category)
            }
            
            if salesByProduct.isEmpty {
                let donemH = stokHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
                for h in donemH {
                    let ck = h.cikan > 0 ? h.cikan : ((h.islemTuru ?? "").localizedCaseInsensitiveContains("satış") || (h.islemTuru ?? "").localizedCaseInsensitiveContains("çıkış") ? h.miktar : 0.0)
                    guard ck > 0 else { continue }
                    let key = !h.stokId.isEmpty ? h.stokId : (h.stokAdi ?? "")
                    guard !key.isEmpty else { continue }
                    let matchedStok = stokById[h.stokId] ?? stoklar.first(where: { $0.stokAdi == h.stokAdi })
                    let price = h.birimFiyat > 0 ? h.birimFiyat : (matchedStok?.satisFiyati ?? 0.0)
                    let cur = salesByProduct[key] ?? (name: h.stokAdi ?? matchedStok?.stokAdi ?? "Ürün", qty: 0.0, revenue: 0.0, category: matchedStok?.grupAdi ?? "-")
                    salesByProduct[key] = (cur.name, cur.qty + ck, cur.revenue + (ck * price), cur.category)
                }
            }
            
            let sortedSales = salesByProduct.values.sorted {
                if $0.qty != $1.qty { return $0.qty > $1.qty }
                return $0.revenue > $1.revenue
            }.prefix(50)
            
            if !sortedSales.isEmpty {
                for (idx, item) in sortedSales.enumerated() {
                    rows.append(["\(idx + 1)", item.name, String(format: "%.2f", item.qty), formatCurrency(item.revenue), item.category])
                }
            } else {
                for (idx, s) in stoklar.prefix(50).enumerated() {
                    rows.append(["\(idx + 1)", s.stokAdi, "0.00", formatCurrency(s.satisFiyati), s.grupAdi ?? "-"])
                }
            }
            
        case "Gelir Tablosu":
            reportTitle = isAll ? "Gelir Tablosu (Tüm Zamanlar)" : "Gelir Tablosu\(dateSuffix)"
            headers = ["Kalem", "Tutar"]
            let detaylar: [FaturaKalem] = (try? await SupabaseService.shared.fetch(from: "fatura_detaylar")) ?? []
            let stokDict = Dictionary(uniqueKeysWithValues: stoklar.map { ($0.id, $0) })
            let satisF = faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }
            let alisF = faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("alış") || $0.faturaTuru.localizedCaseInsensitiveContains("alis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }
            let totalRevenue = satisF.reduce(0.0) { $0 + $1.genelToplam }
            let totalAlis = alisF.reduce(0.0) { $0 + $1.genelToplam }
            var smmMaliyet = 0.0
            for f in satisF {
                let fDetay = detaylar.filter { $0.faturaId == f.id }
                for d in fDetay {
                    if let sid = d.stokId, let s = stokDict[sid] {
                        smmMaliyet += s.alisFiyati * d.miktar
                    }
                }
            }
            let grossProfit = totalRevenue - smmMaliyet
            rows = [
                ["Satış Gelirleri (Toplam Satış)", formatCurrency(totalRevenue)],
                ["Satılan Malın Maliyeti (SMM)", formatCurrency(smmMaliyet)],
                ["Brüt Kar (Kazanılan Net Para)", formatCurrency(grossProfit)],
                ["Dönem İçi Toplam Alış (Satın Alma)", formatCurrency(totalAlis)],
                ["Net Dönem Karı", formatCurrency(grossProfit)]
            ]
            
        case "Detaylı Gelir ve Maliyet Analizi":
            reportTitle = isAll ? "Detaylı Gelir ve Maliyet Analizi" : "Detaylı Gelir ve Maliyet Analizi\(dateSuffix)"
            headers = [
                "Tarih", "Ürün Adı", "Müşteri (Kime)", "Miktar", "Satış Fiyatı",
                "Tutar (Net/KDV)", "Tahsilat Yöntemi & Süresi", "En Son Tedarikçi",
                "Alış Fiyatı & Değişim", "Maliyet", "Net Kar & Durum", "Marj", "Ödeme Yöntemi & Süresi"
            ]
            let detaylar: [FaturaKalem] = (try? await SupabaseService.shared.fetch(from: "fatura_detaylar")) ?? []
            let stokDict = Dictionary(uniqueKeysWithValues: stoklar.map { ($0.id, $0) })
            let satisF = faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }.sorted { $0.tarih < $1.tarih }
            
            for f in satisF.prefix(200) {
                let fDetay = detaylar.filter { $0.faturaId == f.id }
                if fDetay.isEmpty {
                    let cost = f.araToplam * 0.75
                    let kar = f.araToplam - cost
                    let marj = f.araToplam > 0 ? (kar / f.araToplam * 100.0) : 0.0
                    let durum = kar < 0 ? "ZARAR" : (marj < 10 ? "Dusuk Kar" : (marj > 25 ? "Yuksek Kar" : "Normal Kar"))
                    rows.append([
                        formatDisplayDate(f.tarih),
                        "Fatura Kalemi (\(f.faturaNo))",
                        f.cariUnvan ?? "Bilinmeyen Müşteri",
                        "1,00",
                        formatCurrency(f.araToplam),
                        "\(formatCurrency(f.araToplam)) (+\(formatCurrency(f.kdvToplami)) KDV)",
                        "Açık Hesap",
                        "Stok Tanımlı",
                        formatCurrency(cost),
                        formatCurrency(cost),
                        "\(formatCurrency(kar)) (\(durum))",
                        String(format: "%.1f%%", marj),
                        "Açık Hesap"
                    ])
                } else {
                    for d in fDetay {
                        let s = d.stokId != nil ? stokDict[d.stokId!] : nil
                        let urunAdi = !d.stokAdi.isEmpty ? d.stokAdi : (s?.stokAdi ?? "Ürün")
                        let unitCost = s?.alisFiyati ?? (d.birimFiyat * 0.75)
                        let satisTutar = d.birimFiyat * d.miktar
                        let kdvTutar = satisTutar * (d.kdvOrani / 100.0)
                        let maliyetTutar = unitCost * d.miktar
                        let netKar = satisTutar - maliyetTutar
                        let marj = satisTutar > 0 ? (netKar / satisTutar * 100.0) : 0.0
                        let durum = netKar < 0 ? "ZARAR" : (marj < 10 ? "Dusuk Kar" : (marj > 25 ? "Yuksek Kar" : "Normal Kar"))
                        rows.append([
                            formatDisplayDate(f.tarih),
                            urunAdi,
                            f.cariUnvan ?? "Bilinmeyen Müşteri",
                            String(format: "%.2f", d.miktar),
                            formatCurrency(d.birimFiyat),
                            "\(formatCurrency(satisTutar)) (+\(formatCurrency(kdvTutar)) KDV)",
                            "Açık Hesap",
                            "Stok Tanımlı",
                            formatCurrency(unitCost),
                            formatCurrency(maliyetTutar),
                            "\(formatCurrency(netKar)) (\(durum))",
                            String(format: "%.1f%%", marj),
                            "Açık Hesap"
                        ])
                    }
                }
            }
            
        case "Nakit Akış Tablosu":
            headers = ["Tarih", "Açıklama", "Giren", "Çıkan", "Bakiye"]
            var running = 0.0
            let filtered = kasaHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
                .sorted { $0.tarih < $1.tarih }
            for h in filtered {
                running += (h.giren - h.cikan)
                rows.append([formatDisplayDate(h.tarih), h.aciklama ?? h.cariUnvan ?? "-", formatCurrency(h.giren), formatCurrency(h.cikan), formatCurrency(running)])
            }
            
        case "Kasa Hareketleri":
            headers = ["Tarih", "Kasa", "İşlem", "Giren", "Çıkan"]
            let filtered = kasaHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
                .sorted { $0.tarih > $1.tarih }
                .prefix(500)
            for h in filtered {
                let kasaAdi = kasalar.first(where: { $0.id == h.hesapId })?.hesapAdi ?? "Merkez Kasa"
                rows.append([formatDisplayDate(h.tarih), kasaAdi, h.islemTuru, formatCurrency(h.giren), formatCurrency(h.cikan)])
            }
            
        case "Banka Hareketleri":
            let bankaHareketler: [BankaHareket] = (try? await SupabaseService.shared.fetch(from: "banka_hareketler")) ?? []
            let filteredBH = bankaHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
                .sorted { $0.tarih > $1.tarih }
                .prefix(500)
            if !filteredBH.isEmpty {
                headers = ["Tarih", "Banka", "Cari / Açıklama", "İşlem", "Giren", "Çıkan"]
                for bh in filteredBH {
                    let bAdi = bh.bankaAdi ?? bankalar.first(where: { String($0.id ?? 0) == bh.bankaId })?.bankaAdi ?? "Banka"
                    let isIn = bh.girisCikis != "CIKIS"
                    rows.append([
                        formatDisplayDate(bh.tarih),
                        bAdi,
                        bh.cariUnvan ?? bh.aciklama ?? "-",
                        bh.islemTuru,
                        formatCurrency(isIn ? bh.tutar : 0.0),
                        formatCurrency(!isIn ? bh.tutar : 0.0)
                    ])
                }
            } else {
                headers = ["Banka Adı", "Hesap No", "Güncel Bakiye", "Döviz"]
                for b in bankalar {
                    rows.append([b.bankaAdi, b.hesapNo ?? b.iban ?? "-", formatCurrency(b.bakiye), b.dovizTuru ?? "TL"])
                }
            }
            
        case "Kapsamlı Gider Raporu":
            headers = ["Kategori", "Tutar", "Adet"]
            let alisF = faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("alış") || $0.faturaTuru.localizedCaseInsensitiveContains("alis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }
            let kHar = kasaHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
            let faturaGider = alisF.reduce(0.0) { $0 + $1.genelToplam }
            let kasaCikis = kHar.reduce(0.0) { $0 + $1.cikan }
            rows = [
                ["Alış Faturaları", formatCurrency(faturaGider), "\(alisF.count)"],
                ["Kasa Çıkışları", formatCurrency(kasaCikis), "\(kHar.filter { $0.cikan > 0 }.count)"],
                ["Toplam Giderler", formatCurrency(faturaGider + kasaCikis), "-"]
            ]
            
        case "Banka/Kasa Nakit Durumu":
            headers = ["Hesap Adı", "Tür", "Bakiye", "Döviz"]
            var totalNakit = 0.0
            for k in kasalar {
                totalNakit += k.bakiye
                rows.append([k.hesapAdi, "Kasa", formatCurrency(k.bakiye), k.dovizCinsi ?? "TL"])
            }
            for b in bankalar {
                totalNakit += b.bakiye
                rows.append([b.bankaAdi, "Banka", formatCurrency(b.bakiye), b.dovizTuru ?? "TL"])
            }
            rows.append(["TOPLAM NAKİT", "", formatCurrency(totalNakit), "TL"])
            
        case "Aylık Tahsilat ve Ödeme Analizi":
            headers = ["Ay/Yıl", "Nakit (Alınan)", "Nakit (Yönl.)", "K.Kartı (Alınan)", "K.Kartı (Yönl.)", "Havale (Alınan)", "Havale (Yönl.)", "Çek (Alınan)", "Çek (Yönl.)"]
            let kkList: [KrediKartiIslem] = (try? await SupabaseService.shared.fetch(from: "kredi_karti_islemler")) ?? []
            let eftList: [EftIslem] = (try? await SupabaseService.shared.fetch(from: "eft_islemler")) ?? []
            let cal = Calendar.current
            for i in 0..<6 {
                guard let mDate = cal.date(byAdding: .month, value: -i, to: Date()) else { continue }
                let y = cal.component(.year, from: mDate)
                let m = cal.component(.month, from: mDate)
                let prefix = String(format: "%04d-%02d", y, m)
                let suffix = String(format: ".%02d.%04d", m, y)
                let matchDate: (String) -> Bool = { s in s.hasPrefix(prefix) || s.hasSuffix(suffix) }
                
                let nAl = kasaHareketler.filter { matchDate($0.tarih) }.reduce(0.0) { $0 + $1.giren }
                let nYon = kasaHareketler.filter { matchDate($0.tarih) }.reduce(0.0) { $0 + $1.cikan }
                let kkAl = kkList.filter { matchDate($0.tarih) }.reduce(0.0) { $0 + $1.tutar }
                let kkYon = kkList.filter { matchDate($0.tarih) && $0.yonlendirilenCariId != nil }.reduce(0.0) { $0 + $1.tutar }
                let efAl = eftList.filter { matchDate($0.tarih) }.reduce(0.0) { $0 + $1.tutar }
                let efYon = eftList.filter { matchDate($0.tarih) && $0.yonlendirilenCariId != nil }.reduce(0.0) { $0 + $1.tutar }
                let cAl = cekler.filter { matchDate($0.vadeTarihi) }.reduce(0.0) { $0 + $1.tutar }
                let cYon = cekler.filter { matchDate($0.vadeTarihi) && ($0.durum.localizedCaseInsensitiveContains("ciro") || $0.durum.localizedCaseInsensitiveContains("tedarikçi")) }.reduce(0.0) { $0 + $1.tutar }
                
                if nAl > 0 || nYon > 0 || kkAl > 0 || efAl > 0 || cAl > 0 || i == 0 {
                    rows.append([
                        String(format: "%02d/%04d", m, y),
                        formatCurrency(nAl), formatCurrency(nYon),
                        formatCurrency(kkAl), formatCurrency(kkYon),
                        formatCurrency(efAl), formatCurrency(efYon),
                        formatCurrency(cAl), formatCurrency(cYon)
                    ])
                }
            }
            
        case "Kredi Kartı Detay Raporu":
            headers = ["Tarih", "Kimden Alındı", "Banka/Kart", "Kime Yönlendirildi", "Tutar", "Durum"]
            let kkList: [KrediKartiIslem] = (try? await SupabaseService.shared.fetch(from: "kredi_karti_islemler")) ?? []
            let filtered = kkList.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }.sorted { $0.tarih > $1.tarih }
            for k in filtered {
                rows.append([
                    formatDisplayDate(k.tarih),
                    k.musteriUnvan ?? "-",
                    k.banka ?? "-",
                    k.yonlendirilenCariUnvan ?? "-",
                    formatCurrency(k.tutar),
                    k.durum ?? "Portföyde"
                ])
            }
            
        case "Nakit İşlem Detay Raporu":
            headers = ["Tarih", "Cari Ünvan", "İşlem", "Açıklama", "Giren", "Çıkan"]
            let filtered = kasaHareketler.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }.sorted { $0.tarih > $1.tarih }
            for h in filtered {
                rows.append([
                    formatDisplayDate(h.tarih),
                    h.cariUnvan ?? "-",
                    h.islemTuru,
                    h.aciklama ?? "-",
                    formatCurrency(h.giren),
                    formatCurrency(h.cikan)
                ])
            }
            
        case "Çek Detay Raporu":
            headers = ["Vade", "Çek No", "Cari Ünvan", "Banka/Şube", "Tutar", "Durum"]
            let filtered = cekler.filter { isDateInRange($0.vadeTarihi, startDay: startDay, endDay: endDay, isAll: isAll) }.sorted { $0.vadeTarihi < $1.vadeTarihi }
            for c in filtered {
                rows.append([
                    formatDisplayDate(c.vadeTarihi),
                    c.cekSenetNo,
                    c.cariUnvan ?? c.borclu ?? "-",
                    "\(c.banka ?? "")/\(c.sube ?? "")",
                    formatCurrency(c.tutar),
                    c.durum
                ])
            }
            
        case "Havale / EFT Detay Raporu":
            headers = ["Tarih", "Müşteri", "Banka/Hesap", "Dekont No", "Tutar", "Durum"]
            let eftList: [EftIslem] = (try? await SupabaseService.shared.fetch(from: "eft_islemler")) ?? []
            let filtered = eftList.filter { isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }.sorted { $0.tarih > $1.tarih }
            if !filtered.isEmpty {
                for e in filtered {
                    rows.append([
                        formatDisplayDate(e.tarih),
                        e.aliciUnvan,
                        "\(e.banka ?? "")/\(e.hesapNo ?? e.aliciIban)",
                        e.dekontNo ?? "-",
                        formatCurrency(e.tutar),
                        e.durum
                    ])
                }
            } else {
                let bankaHar: [BankaHareket] = (try? await SupabaseService.shared.fetch(from: "banka_hareketler")) ?? []
                for bh in bankaHar.filter({ isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }).sorted(by: { $0.tarih > $1.tarih }) {
                    rows.append([
                        formatDisplayDate(bh.tarih),
                        bh.cariUnvan ?? "-",
                        bh.bankaAdi ?? "-",
                        bh.evrakNo ?? "-",
                        formatCurrency(bh.tutar),
                        bh.girisCikis == "GIRIS" ? "Gelen Havale" : "Gönderilen EFT"
                    ])
                }
            }
            
        case "Müşteri ABC Analizi":
            headers = ["Müşteri", "Toplam Satış", "Yüzde", "Sınıf"]
            let satisF = faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }
            let grouped = Dictionary(grouping: satisF, by: { $0.cariUnvan ?? "Bilinmeyen" })
                .map { (musteri: $0.key, total: $0.value.reduce(0.0, { $0 + $1.genelToplam })) }
                .sorted { $0.total > $1.total }
            let grandTotal = grouped.reduce(0.0) { $0 + $1.total }
            var cumulative = 0.0
            for item in grouped {
                cumulative += item.total
                let pct = grandTotal > 0 ? (item.total / grandTotal * 100.0) : 0.0
                let cumPct = grandTotal > 0 ? (cumulative / grandTotal * 100.0) : 0.0
                let cls = cumPct <= 80 ? "A" : (cumPct <= 95 ? "B" : "C")
                rows.append([item.musteri, formatCurrency(item.total), String(format: "%.2f", pct), cls])
            }
            if !rows.isEmpty {
                rows.append(["", "", "", ""])
                rows.append(["A Sınıfı: %80 Ciro", "B Sınıfı: %15 Ciro", "C Sınıfı: %5 Ciro", ""])
            }
            
        case "Kar-Zarar Mukayesesi":
            headers = ["Dönem", "Satış Tutarı", "Alış Tutarı", "Net Kar/Zarar"]
            let cal = Calendar.current
            let now = Date()
            let curYear = cal.component(.year, from: now)
            rows.append(["--- YILLIK ANALİZ ---", "", "", ""])
            let years = Set(faturalar.compactMap { Int($0.tarih.prefix(4)) } + [curYear]).sorted()
            for y in years {
                let yStr = "\(y)"
                let s = faturalar.filter { ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) && $0.tarih.hasPrefix(yStr) }.reduce(0.0) { $0 + $1.genelToplam }
                let a = faturalar.filter { ($0.faturaTuru.localizedCaseInsensitiveContains("alış") || $0.faturaTuru.localizedCaseInsensitiveContains("alis")) && $0.tarih.hasPrefix(yStr) }.reduce(0.0) { $0 + $1.genelToplam }
                rows.append([yStr, formatCurrency(s), formatCurrency(a), formatCurrency(s - a)])
            }
            rows.append(["--- AYLIK ANALİZ (SON 6 AY) ---", "", "", ""])
            for i in (0..<6).reversed() {
                if let mDate = cal.date(byAdding: .month, value: -i, to: now) {
                    let y = cal.component(.year, from: mDate)
                    let m = cal.component(.month, from: mDate)
                    let prefix = String(format: "%04d-%02d", y, m)
                    let suffix = String(format: ".%02d.%04d", m, y)
                    let s = faturalar.filter { ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) && ($0.tarih.hasPrefix(prefix) || $0.tarih.hasSuffix(suffix)) }.reduce(0.0) { $0 + $1.genelToplam }
                    let a = faturalar.filter { ($0.faturaTuru.localizedCaseInsensitiveContains("alış") || $0.faturaTuru.localizedCaseInsensitiveContains("alis")) && ($0.tarih.hasPrefix(prefix) || $0.tarih.hasSuffix(suffix)) }.reduce(0.0) { $0 + $1.genelToplam }
                    rows.append([String(format: "%02d/%04d", m, y), formatCurrency(s), formatCurrency(a), formatCurrency(s - a)])
                }
            }
            rows.append(["--- HAFTALIK ANALİZ (SON 4 HAFTA) ---", "", "", ""])
            for i in (0..<4).reversed() {
                let hStart = cal.date(byAdding: .day, value: -(i * 7 + 7), to: now) ?? now
                let hEnd = cal.date(byAdding: .day, value: -(i * 7), to: now) ?? now
                let s = faturalar.filter { ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) && isDateInRange($0.tarih, startDay: cal.startOfDay(for: hStart), endDay: cal.startOfDay(for: hEnd), isAll: false) }.reduce(0.0) { $0 + $1.genelToplam }
                let a = faturalar.filter { ($0.faturaTuru.localizedCaseInsensitiveContains("alış") || $0.faturaTuru.localizedCaseInsensitiveContains("alis")) && isDateInRange($0.tarih, startDay: cal.startOfDay(for: hStart), endDay: cal.startOfDay(for: hEnd), isAll: false) }.reduce(0.0) { $0 + $1.genelToplam }
                let fmt = DateFormatter()
                fmt.dateFormat = "dd.MM"
                rows.append(["\(fmt.string(from: hStart)) - \(fmt.string(from: hEnd))", formatCurrency(s), formatCurrency(a), formatCurrency(s - a)])
            }
            
        case "Vadesi Geçmiş Alacaklar":
            headers = ["Müşteri", "Cari Bakiyesi", "Ort. Gecikme Günü", "Fatura / Evrak No", "Fatura Bakiyesi", "Gecikme (Gün)"]
            let today = Calendar.current.startOfDay(for: Date())
            for c in cariler where c.bakiye > 0 {
                let cFaturalar = faturalar.filter {
                    !$0.isKapaliOrPaid &&
                    ($0.cariId == c.id || $0.cariUnvan == c.unvan) &&
                    ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis"))
                }
                var overdueList: [(evrak: String, tutar: Double, gun: Int)] = []
                for f in cFaturalar {
                    let vStr = f.vadeTarihi ?? f.tarih
                    if let vDate = AppFormatters.parseDate(String(vStr.prefix(10))) ?? AppFormatters.parseDate(vStr) {
                        let gun = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: vDate), to: today).day ?? 0
                        if gun > 0 {
                            overdueList.append((f.faturaNo, f.genelToplam, gun))
                        }
                    }
                }
                if overdueList.isEmpty {
                    let vGun = c.vadeGunu ?? 30
                    overdueList.append(("Açık Bakiye", c.bakiye, vGun))
                }
                let totTutar = overdueList.reduce(0.0) { $0 + $1.tutar }
                let weightedDays = overdueList.reduce(0.0) { $0 + ($1.tutar * Double($1.gun)) }
                let avgGun = totTutar > 0 ? Int(weightedDays / totTutar) : 0
                for (idx, item) in overdueList.enumerated() {
                    rows.append([
                        idx == 0 ? c.unvan : "",
                        idx == 0 ? formatCurrency(c.bakiye) : "",
                        idx == 0 ? "\(avgGun) Gün" : "",
                        item.evrak,
                        formatCurrency(item.tutar),
                        "\(item.gun) Gün"
                    ])
                }
            }
            
        case "Müşteri Kayıp (Churn)":
            headers = ["Müşteri", "Son İşlem", "Geçen Gün", "Kayıp Riski"]
            let now = Date()
            for c in cariler where !(c.grup ?? "").localizedCaseInsensitiveContains("satıcı") && !(c.grup ?? "").localizedCaseInsensitiveContains("tedarikçi") {
                let lastTx = cariHareketler.filter { $0.cariId == c.id }.sorted(by: { ($0.tarih ?? "") > ($1.tarih ?? "") }).first
                if let lStr = lastTx?.tarih, let d = AppFormatters.parseDate(String(lStr.prefix(10))) ?? AppFormatters.parseDate(lStr) {
                    let days = Calendar.current.dateComponents([.day], from: d, to: now).day ?? 0
                    if days >= 30 {
                        let risk = days > 180 ? "Kritik Kayıp (180+ Gün)" : (days > 90 ? "Yüksek Risk (90+ Gün)" : "Orta Risk (30+ Gün)")
                        rows.append([c.unvan, formatDisplayDate(lStr), "\(days)", risk])
                    }
                } else {
                    rows.append([c.unvan, "İşlem Yok", "-", "Düşük Risk"])
                }
            }
            
        case "Fiyat Dalgalanma Raporu":
            headers = ["Ürün", "Min Fiyat", "Max Fiyat", "Ort Fiyat", "Fark %"]
            let stokHareketler: [StokHareket] = (try? await SupabaseService.shared.fetch(from: "stok_hareketler")) ?? []
            let pulse = stokHareketler.filter { $0.birimFiyat > 0 && isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll) }
            if !pulse.isEmpty {
                let grouped = Dictionary(grouping: pulse, by: { h in h.stokAdi ?? stoklar.first(where: { $0.id == h.stokId })?.stokAdi ?? "Ürün" })
                for (sAdi, list) in grouped {
                    let prices = list.map { $0.birimFiyat }
                    let minP = prices.min() ?? 0.0
                    let maxP = prices.max() ?? 0.0
                    let avgP = prices.reduce(0.0, +) / Double(max(1, prices.count))
                    let variance = minP > 0 ? ((maxP - minP) / minP * 100.0) : 0.0
                    rows.append([sAdi, formatCurrency(minP), formatCurrency(maxP), formatCurrency(avgP), String(format: "%.2f", variance)])
                }
            } else {
                for s in stoklar where s.alisFiyati > 0 || s.satisFiyati > 0 {
                    let minP = min(s.alisFiyati, s.satisFiyati)
                    let maxP = max(s.alisFiyati, s.satisFiyati)
                    let avgP = (minP + maxP) / 2.0
                    let variance = minP > 0 ? ((maxP - minP) / minP * 100.0) : 0.0
                    rows.append([s.stokAdi, formatCurrency(minP), formatCurrency(maxP), formatCurrency(avgP), String(format: "%.2f", variance)])
                }
            }
            
        case "Müşteri Sadakat (LTV)":
            headers = ["Müşteri", "İlk Alışveriş", "Son Alışveriş", "Toplam Harcama", "Ortalama Sepet"]
            let satisF = faturalar.filter {
                ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) &&
                isDateInRange($0.tarih, startDay: startDay, endDay: endDay, isAll: isAll)
            }
            let grouped = Dictionary(grouping: satisF, by: { $0.cariUnvan ?? "Bilinmeyen" })
            for (unvan, list) in grouped.sorted(by: { $0.value.reduce(0.0, { $0 + $1.genelToplam }) > $1.value.reduce(0.0, { $0 + $1.genelToplam }) }).prefix(100) {
                let dates = list.map { $0.tarih }.sorted()
                let firstD = formatDisplayDate(dates.first)
                let lastD = formatDisplayDate(dates.last)
                let tot = list.reduce(0.0) { $0 + $1.genelToplam }
                let avg = list.isEmpty ? 0.0 : (tot / Double(list.count))
                rows.append([unvan, firstD, lastD, formatCurrency(tot), formatCurrency(avg)])
            }
            
        case "Finansal Isı Haritası":
            headers = ["Tarih", "Satış", "Alış", "Kasa Giren", "Kasa Çıkan", "Net Akış"]
            let cal = Calendar.current
            let heatEnd = isAll ? cal.startOfDay(for: Date()) : min(endDay, cal.startOfDay(for: Date()))
            let heatStart = isAll ? (cal.date(byAdding: .day, value: -30, to: heatEnd) ?? heatEnd) : startDay
            let daysCount = min(90, max(0, cal.dateComponents([.day], from: heatStart, to: heatEnd).day ?? 30))
            for i in 0...daysCount {
                guard let d = cal.date(byAdding: .day, value: i, to: heatStart) else { continue }
                let isoPrefix = AppFormatters.isoDate.string(from: d)
                let trStr = AppFormatters.shortDate.string(from: d)
                let matchDay: (String) -> Bool = { s in s.hasPrefix(isoPrefix) || s.hasPrefix(trStr) }
                let satis = faturalar.filter { ($0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")) && matchDay($0.tarih) }.reduce(0.0) { $0 + $1.genelToplam }
                let alis = faturalar.filter { ($0.faturaTuru.localizedCaseInsensitiveContains("alış") || $0.faturaTuru.localizedCaseInsensitiveContains("alis")) && matchDay($0.tarih) }.reduce(0.0) { $0 + $1.genelToplam }
                let kIn = kasaHareketler.filter { matchDay($0.tarih) }.reduce(0.0) { $0 + $1.giren }
                let kOut = kasaHareketler.filter { matchDay($0.tarih) }.reduce(0.0) { $0 + $1.cikan }
                let net = satis - alis + kIn - kOut
                if satis > 0 || alis > 0 || kIn > 0 || kOut > 0 {
                    rows.append([trStr, formatCurrency(satis), formatCurrency(alis), formatCurrency(kIn), formatCurrency(kOut), formatCurrency(net)])
                }
            }
            
        case "Tahsilat Süresi (DSO)":
            headers = ["Müşteri", "Ortalama Tahsilat Süresi (Gün)", "Toplam Alacak", "Durum"]
            let satisFaturalari = faturalar.filter {
                $0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")
            }
            for c in cariler where c.signedBakiye > 0 {
                let receivable = c.signedBakiye
                let custSales = satisFaturalari
                    .filter { $0.cariId == c.id || $0.cariUnvan == c.unvan }
                    .reduce(0.0) { $0 + $1.genelToplam }
                let avgDays: Int
                if custSales > 0 {
                    // Standard DSO formula: (Accounts Receivable / Total Credit Sales) * 365
                    let computedDso = Int(round((receivable / custSales) * 365.0))
                    avgDays = max(1, min(365, computedDso))
                } else {
                    avgDays = c.vadeGunu ?? 30
                }
                let status = avgDays > 60 ? "Riskli" : (avgDays > 30 ? "Normal" : "İyi")
                rows.append([c.unvan, "\(avgDays)", formatCurrency(receivable), status])
            }
            
        default:
            headers = ["Bilgi", "Detay"]
            rows = [[title, "Kayıt bulunamadı"]]
        }
        
        return (reportTitle, headers, rows)
    }
    
    // MARK: - Masaüstü QuestPDF Rapor Üretimi (Consolidated, Budget ve Generic Birebir Eşleşme)
    public func generateDesktopReportPDF(for reportTitle: String, filter: String, selectedCari: CariKart? = nil) async -> Data {
        let (startDay, endDay, isAll) = parseDateRange(filter: filter)
        let dateSuffix = isAll ? "" : " (\(AppFormatters.shortDate.string(from: startDay)) - \(AppFormatters.shortDate.string(from: endDay)))"
        let dateSubtitle = isAll ? "Tüm Zamanlar" : "Tarih Aralığı: \(AppFormatters.shortDate.string(from: startDay)) - \(AppFormatters.shortDate.string(from: endDay))"
        
        if reportTitle == "Genel Özet" && selectedCari == nil {
            let summaryData = await calculateReportData(for: "Genel Özet", filter: filter)
            let summaryMetrics: [[String: Any]] = summaryData.rows.prefix(4).map { r in
                ["Label": r[0], "Actual": parseMoney(r.count > 1 ? r[1] : "0"), "Target": 0, "Value": 0]
            }
            let summaryChart = summaryMetrics.filter { !(($0["Label"] as? String ?? "").contains("Miktar")) }
            var sections: [[String: Any]] = [
                [
                    "Title": "\(summaryData.title)\(dateSuffix)",
                    "Headers": summaryData.headers,
                    "Rows": summaryData.rows,
                    "KeyMetrics": summaryMetrics,
                    "ChartData": summaryChart,
                    "LeftChartTitle": "VARLIK VE YÜKÜMLÜLÜK DAĞILIMI\(dateSuffix)",
                    "NewPage": false
                ]
            ]
            
            let budgetRes = await calculateReportData(for: "Bütçe / Hedef Takibi", filter: filter)
            let budgetGraph = await getBudgetChartData()
            sections.append([
                "Title": "BÜTÇE VE HEDEF ANALİZİ (AYLIK)",
                "Headers": budgetRes.headers,
                "Rows": budgetRes.rows,
                "ChartData": budgetGraph.monthly,
                "KeyMetrics": Array(budgetGraph.monthly.prefix(4)),
                "NewPage": true
            ])
            if !budgetGraph.weekly.isEmpty {
                sections.append([
                    "Title": "BÜTÇE VE HEDEF ANALİZİ (HAFTALIK)",
                    "Headers": [String](),
                    "Rows": [[String]](),
                    "ChartData": Array(budgetGraph.weekly.suffix(12)),
                    "NewPage": false
                ])
            }
            
            let includedTitles = [
                "Cari Bakiye Raporu", "Yaşlandırma Raporu", "Vadesi Geçmiş Alacaklar",
                "Hareketsiz Cariler", "Stok Mevcudu", "Kritik Stok Seviyesi",
                "Ölü Stok Raporu", "Stok Devir Hızı", "Ürün Karlılık Raporu",
                "Müşteri Karlılık Analizi", "Bölge Bazlı Satış", "En Çok Satan Ürünler",
                "Gelir Tablosu", "Detaylı Gelir ve Maliyet Analizi", "Nakit Akış Tablosu",
                "Kasa Hareketleri", "Banka Hareketleri", "Kapsamlı Gider Raporu",
                "Banka/Kasa Nakit Durumu", "Aylık Tahsilat ve Ödeme Analizi",
                "Kredi Kartı Detay Raporu", "Nakit İşlem Detay Raporu", "Çek Detay Raporu",
                "Havale / EFT Detay Raporu", "Müşteri ABC Analizi", "Kar-Zarar Mukayesesi",
                "Bölgesel Satış Analizi", "Müşteri Kayıp (Churn)", "Fiyat Dalgalanma Raporu",
                "Müşteri Sadakat (LTV)", "Finansal Isı Haritası", "Tahsilat Süresi (DSO)"
            ]
            
            for rTitle in includedTitles {
                let (t, h, r) = await calculateReportData(for: rTitle, filter: filter)
                if h.isEmpty { continue }
                var finalRows = r
                if finalRows.isEmpty {
                    var emptyRow = Array(repeating: "", count: h.count)
                    emptyRow[0] = "Kayıt bulunamadı"
                    finalRows = [emptyRow]
                }
                sections.append([
                    "Title": t,
                    "Headers": h,
                    "Rows": finalRows,
                    "NewPage": true
                ])
            }
            
            if let data = await PDFService.shared.fetchRemoteConsolidatedReportPDF(title: "ERMAY MUHASEBE - GENEL RAPOR PAKETİ", sections: sections) {
                return data
            }
        } else if reportTitle == "Bütçe / Hedef Takibi" {
            let budgetGraph = await getBudgetChartData()
            if let data = await PDFService.shared.fetchRemoteBudgetReportPDF(
                title: "BÜTÇE VE HEDEF ANALİZ RAPORU",
                annual: budgetGraph.annual,
                monthly: budgetGraph.monthly,
                weekly: budgetGraph.weekly
            ) {
                return data
            }
        } else if reportTitle == "Kar-Zarar Mukayesesi" {
            let (t, h, r) = await calculateReportData(for: reportTitle, filter: filter)
            var yillik: [[String: Any]] = []
            var aylik: [[String: Any]] = []
            var haftalik: [[String: Any]] = []
            var currentGroup = ""
            for row in r {
                if row[0].contains("---") { currentGroup = row[0]; continue }
                guard row.count >= 4 else { continue }
                let item: [String: Any] = ["Label": row[0], "Actual": parseMoney(row[1]), "Target": parseMoney(row[2]), "Value": 0]
                if currentGroup.contains("YILLIK") { yillik.append(item) }
                else if currentGroup.contains("AYLIK") { aylik.append(item) }
                else if currentGroup.contains("HAFTALIK") { haftalik.append(item) }
            }
            var extraCharts: [[String: Any]] = []
            if !yillik.isEmpty {
                extraCharts.append(["Title": "YILLIK KAR-ZARAR KIYASLAMASI (SATIŞ VS ALIŞ)", "BarData": yillik, "ActualLabel": "Satış", "TargetLabel": "Alış", "Color": "#3b82f6"])
            }
            if !aylik.isEmpty {
                extraCharts.append(["Title": "AYLIK KAR-ZARAR KIYASLAMASI (SON 6 AY)", "BarData": aylik, "ActualLabel": "Satış", "TargetLabel": "Alış", "Color": "#10b981"])
            }
            if !haftalik.isEmpty {
                extraCharts.append(["Title": "HAFTALIK KAR-ZARAR KIYASLAMASI (SON 4 HAFTA)", "BarData": haftalik, "ActualLabel": "Satış", "TargetLabel": "Alış", "Color": "#f59e0b"])
            }
            let section: [String: Any] = [
                "Title": t,
                "Headers": h,
                "Rows": r,
                "ExtraCharts": extraCharts,
                "NewPage": false
            ]
            if let data = await PDFService.shared.fetchRemoteConsolidatedReportPDF(title: "KAR-ZARAR MUKAYESE RAPORU", sections: [section]) {
                return data
            }
        }
        
        let (rTitle, rHeaders, rRows) = await calculateReportData(for: reportTitle, filter: filter, selectedCari: selectedCari)
        var safeRows = rRows
        if safeRows.isEmpty && !rHeaders.isEmpty {
            var emptyRow = Array(repeating: "-", count: rHeaders.count)
            emptyRow[0] = "Kayıt bulunamadı"
            safeRows = [emptyRow]
        }
        if let remoteData = await PDFService.shared.fetchRemoteGenericTablePDF(
            title: rTitle,
            headers: rHeaders,
            rows: safeRows,
            subtitle: dateSubtitle
        ) {
            return remoteData
        }
        return PDFService.shared.generateGenericReportPDF(
            title: rTitle,
            subtitle: dateSubtitle,
            headers: rHeaders,
            rows: safeRows
        )
    }
    
    private func getBudgetChartData() async -> (annual: [[String: Any]], monthly: [[String: Any]], weekly: [[String: Any]]) {
        let curYear = Calendar.current.component(.year, from: Date())
        let yillikHedefler: [SatisHedefRow] = (try? await SupabaseService.shared.fetch(from: "yillik_satis_hedefleri")) ?? []
        let aylikHedefler: [SatisHedefRow] = (try? await SupabaseService.shared.fetch(from: "satis_hedefleri")) ?? []
        let haftalikHedefler: [SatisHedefRow] = (try? await SupabaseService.shared.fetch(from: "haftalik_satis_hedefleri")) ?? []
        let defaultFaturalar = await MainActor.run { DataStore.shared.faturalar }
        let faturalar: [Fatura] = (try? await SupabaseService.shared.fetch(from: "faturalar")) ?? defaultFaturalar
        let satisFaturalari = faturalar.filter { $0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis") }
        
        var annual: [[String: Any]] = []
        let years = Set(yillikHedefler.compactMap { $0.yil } + [curYear]).sorted(by: >)
        for y in years {
            let t = yillikHedefler.first(where: { $0.yil == y })?.effectiveHedef ?? 0.0
            let a = satisFaturalari.filter { $0.tarih.hasPrefix("\(y)") || $0.tarih.hasSuffix(".\(y)") }.reduce(0.0) { $0 + $1.genelToplam }
            annual.append(["Label": "\(y)", "Target": t, "Actual": a, "Value": 0])
        }
        
        var monthly: [[String: Any]] = []
        let yearTargets = aylikHedefler.filter { ($0.yil ?? curYear) == curYear }
        for m in 1...12 {
            let t = yearTargets.first(where: { $0.ay == m })?.effectiveHedef ?? 0.0
            let p1 = String(format: "%04d-%02d", curYear, m)
            let p2 = String(format: ".%02d.%04d", m, curYear)
            let a = satisFaturalari.filter { $0.tarih.hasPrefix(p1) || $0.tarih.hasSuffix(p2) }.reduce(0.0) { $0 + $1.genelToplam }
            monthly.append(["Label": "\(m)", "Target": t, "Actual": a, "Value": 0])
        }
        
        var weekly: [[String: Any]] = []
        let cal = Calendar(identifier: .iso8601)
        for w in 1...52 {
            let wt = haftalikHedefler.first(where: { ($0.yil ?? curYear) == curYear && $0.effectiveHafta == w })?.effectiveHedef ?? 0.0
            let wa = satisFaturalari.filter { f in
                guard let d = AppFormatters.parseDate(String(f.tarih.prefix(10))) ?? AppFormatters.parseDate(f.tarih) else { return false }
                return cal.component(.yearForWeekOfYear, from: d) == curYear && cal.component(.weekOfYear, from: d) == w
            }.reduce(0.0) { $0 + $1.genelToplam }
            if wt > 0 || wa > 0 {
                weekly.append(["Label": "\(w)", "Target": wt, "Actual": wa, "Value": 0])
            }
        }
        return (annual, monthly, weekly)
    }
    
    private func parseMoney(_ s: String) -> Double {
        let clean = s
            .replacingOccurrences(of: "₺", with: "")
            .replacingOccurrences(of: "TL", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.contains(".") && clean.contains(",") {
            let normalized = clean.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            return Double(normalized) ?? 0.0
        } else if clean.contains(",") {
            return Double(clean.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        }
        return Double(clean) ?? 0.0
    }
    
    private func formatCurrency(_ val: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: val)) ?? String(format: "₺%.2f", val)
    }
}
