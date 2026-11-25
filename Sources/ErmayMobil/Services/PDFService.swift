import Foundation
#if canImport(UIKit)
import UIKit
import PDFKit
#endif

public final class PDFService {
    public static let shared = PDFService()
    public var cloudPdfUrl: String = ""
    public var cloudPdfApiKey: String? = nil
    private var cachedFirmaProfili: FirmaProfili? = nil
    
    private init() {
        if let savedUrl = UserDefaults.standard.string(forKey: "cloud_pdf_api_url"), !savedUrl.isEmpty {
            self.cloudPdfUrl = savedUrl
        }
        if let savedKey = UserDefaults.standard.string(forKey: "cloud_pdf_api_key"), !savedKey.isEmpty {
            self.cloudPdfApiKey = savedKey
        }
    }
    
    public func resolveFirmaProfili(fallback: FirmaProfili = FirmaProfili.varsayilan) async -> FirmaProfili {
        if let cached = cachedFirmaProfili, !cached.unvan.isEmpty || !cached.firmaAdi.isEmpty {
            return cached
        }
        if let profiller: [FirmaProfili] = try? await SupabaseService.shared.fetch(from: "firma_profili"),
           let p = profiller.first {
            self.cachedFirmaProfili = p
            if let apiUrl = p.cloudPdfApiUrl, !apiUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let clean = apiUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                self.cloudPdfUrl = clean.hasSuffix("/") ? String(clean.dropLast()) : clean
                UserDefaults.standard.set(self.cloudPdfUrl, forKey: "cloud_pdf_api_url")
            }
            if let apiKey = p.cloudPdfApiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.cloudPdfApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                UserDefaults.standard.set(self.cloudPdfApiKey, forKey: "cloud_pdf_api_key")
            }
            if let b64 = p.logoData, !b64.isEmpty {
                UserDefaults.standard.set(b64, forKey: "company_logo_base64")
            }
            return p
        }
        return fallback
    }
    
    #if canImport(UIKit)
    // MARK: - 1. FATURA QUEST PDF (Cloud Run & Local Fallback)
    public func fetchOrGenerateFaturaPDF(
        fatura: Fatura,
        kalemler: [FaturaKalem],
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) async -> Data? {
        let resolvedFirma = (firma.firmaAdi.isEmpty && firma.unvan.isEmpty) ? await resolveFirmaProfili(fallback: firma) : firma
        if let cloudPdf = await fetchCloudFaturaPdf(fatura: fatura, kalemler: kalemler) {
            return cloudPdf
        }
        return generateFaturaPDF(fatura: fatura, firma: resolvedFirma)
    }
    
    private func toDotNetIsoDate(_ raw: String?) -> String {
        guard let s = raw, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return f.string(from: Date())
        }
        if let d = AppFormatters.parseDate(String(s.prefix(10))) ?? AppFormatters.parseDate(s) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return f.string(from: d)
        }
        return "\(String(s.prefix(10)))T00:00:00"
    }

    private func currentLogoPayload() -> (logoBase64: String?, showLogo: Bool) {
        let show = UserDefaults.standard.object(forKey: "pdf_show_logo_raporlar") as? Bool ?? true
        if let b64 = UserDefaults.standard.string(forKey: "company_logo_base64"), !b64.isEmpty {
            return (b64, show)
        }
        return (nil, false)
    }

    private func fetchCloudFaturaPdf(fatura: Fatura, kalemler: [FaturaKalem]) async -> Data? {
        guard let url = URL(string: "\(cloudPdfUrl)/generate/fatura") else { return nil }
        
        let fId = Int(fatura.id) ?? 1
        let cId = Int(fatura.cariId ?? "0") ?? 0
        let isoTarih = toDotNetIsoDate(fatura.tarih)
        let isoVade = toDotNetIsoDate(fatura.vadeTarihi ?? fatura.tarih)
        
        var faturaDict: [String: Any] = [
            "Id": fId,
            "FaturaNo": fatura.faturaNo,
            "FaturaTuru": fatura.faturaTuru,
            "Tur": fatura.faturaTuru,
            "CariId": cId,
            "CariUnvan": fatura.cariUnvan ?? "Perakende Müşteri",
            "Tarih": isoTarih,
            "VadeTarihi": isoVade,
            "AraToplam": fatura.araToplam,
            "KdvToplam": fatura.kdvToplami,
            "ToplamKDV": fatura.kdvToplami,
            "IskontoToplam": fatura.iskontoToplami,
            "GenelToplam": fatura.genelToplam,
            "Aciklama": fatura.aciklama ?? ""
        ]
        let carilerList = await MainActor.run { DataStore.shared.cariler }
        if let cari = carilerList.first(where: { $0.id == fatura.cariId || $0.unvan == fatura.cariUnvan }) {
            faturaDict["Adres"] = cari.adres ?? ""
            faturaDict["VergiNo"] = cari.vergiNo ?? ""
            faturaDict["VergiDairesi"] = cari.vergiDairesi ?? ""
        }
        
        let detaylarArray: [[String: Any]] = kalemler.enumerated().map { idx, k in
            let stId = Int(k.stokId ?? "") ?? (idx + 1)
            return [
                "Id": idx + 1,
                "FaturaId": fId,
                "StokId": stId,
                "StokKodu": k.stokKodu ?? "STK-\(idx + 1)",
                "StokAdi": k.stokAdi,
                "Miktar": k.miktar,
                "Birim": k.birim ?? "Adet",
                "BirimFiyat": k.birimFiyat,
                "KDVOrani": k.kdvOrani,
                "KdvOrani": k.kdvOrani,
                "ToplamTutar": k.toplamTutar,
                "Tutar": k.toplamTutar
            ]
        }
        
        let logoInfo = currentLogoPayload()
        var payload: [String: Any] = [
            "Fatura": faturaDict,
            "Detaylar": detaylarArray,
            "ShowLogo": logoInfo.showLogo
        ]
        if let b64 = logoInfo.logoBase64 {
            payload["LogoBytes"] = b64
        }
        
        return await postToCloudRun(url: url, payload: payload)
    }
    
    // MARK: - 2. TEKLİF QUEST PDF (Cloud Run & Local Fallback)
    public func fetchOrGenerateTeklifPDF(
        teklif: Teklif,
        kalemler: [TeklifKalem],
        cari: CariKart? = nil,
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) async -> Data? {
        let resolvedFirma = (firma.firmaAdi.isEmpty && firma.unvan.isEmpty) ? await resolveFirmaProfili(fallback: firma) : firma
        if let cloudPdf = await fetchCloudTeklifPdf(teklif: teklif, kalemler: kalemler, cari: cari) {
            return cloudPdf
        }
        return generateTeklifPDF(teklif: teklif, kalemler: kalemler, cari: cari, firma: resolvedFirma)
    }
    
    private func fetchCloudTeklifPdf(teklif: Teklif, kalemler: [TeklifKalem], cari: CariKart?) async -> Data? {
        guard let url = URL(string: "\(cloudPdfUrl)/generate/teklif") else { return nil }
        
        let tId = Int(teklif.id) ?? 1
        let cId = Int(teklif.cariId ?? "0") ?? 0
        
        let teklifDict: [String: Any] = [
            "Id": tId,
            "TeklifNo": teklif.teklifNo,
            "CariId": cId,
            "CariUnvan": teklif.cariUnvan ?? (cari?.unvan ?? "Müşteri"),
            "Tarih": toDotNetIsoDate(teklif.tarih),
            "GecerlilikTarihi": toDotNetIsoDate(teklif.gecerlilikTarihi ?? teklif.tarih),
            "AraToplam": teklif.araToplam,
            "KdvToplam": teklif.kdvToplami,
            "GenelToplam": teklif.genelToplam,
            "Aciklama": teklif.aciklama ?? ""
        ]
        
        let detaylarArray: [[String: Any]] = kalemler.enumerated().map { idx, k in
            let stId = Int(k.stokId ?? "") ?? (idx + 1)
            return [
                "Id": idx + 1,
                "TeklifId": tId,
                "StokId": stId,
                "StokKodu": k.stokKodu ?? "STK-\(idx + 1)",
                "StokAdi": k.stokAdi,
                "Miktar": k.miktar,
                "Birim": k.birim ?? "Adet",
                "BirimFiyat": k.birimFiyat,
                "KdvOrani": k.kdvOrani,
                "ToplamTutar": k.toplamTutar,
                "Tutar": k.toplamTutar
            ]
        }
        
        let logoInfo = currentLogoPayload()
        var payload: [String: Any] = [
            "Teklif": teklifDict,
            "Detaylar": detaylarArray,
            "ShowLogo": logoInfo.showLogo
        ]
        if let b64 = logoInfo.logoBase64 {
            payload["LogoBytes"] = b64
        }
        
        if let c = cari {
            payload["Cari"] = [
                "Id": Int(c.id) ?? cId,
                "Unvan": c.unvan,
                "CariKodu": c.cariKodu ?? "",
                "VergiDairesi": c.vergiDairesi ?? "",
                "VergiNo": c.vergiNo ?? "",
                "Telefon": c.telefon ?? ""
            ]
        }
        
        return await postToCloudRun(url: url, payload: payload)
    }
    
    // MARK: - 3. SİPARİŞ QUEST PDF (Cloud Run & Local Fallback)
    public func fetchOrGenerateSiparisPDF(
        siparis: Siparis,
        kalemler: [SiparisKalem],
        cari: CariKart? = nil,
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) async -> Data? {
        let resolvedFirma = (firma.firmaAdi.isEmpty && firma.unvan.isEmpty) ? await resolveFirmaProfili(fallback: firma) : firma
        if let cloudPdf = await fetchCloudSiparisPdf(siparis: siparis, kalemler: kalemler, cari: cari) {
            return cloudPdf
        }
        return generateSiparisPDF(siparis: siparis, kalemler: kalemler, cari: cari, firma: resolvedFirma)
    }
    
    private func fetchCloudSiparisPdf(siparis: Siparis, kalemler: [SiparisKalem], cari: CariKart?) async -> Data? {
        guard let url = URL(string: "\(cloudPdfUrl)/generate/siparis") else { return nil }
        
        let sId = Int(siparis.id) ?? 1
        let cId = Int(siparis.cariId ?? "0") ?? 0
        
        let siparisDict: [String: Any] = [
            "Id": sId,
            "SiparisNo": siparis.siparisNo,
            "SiparisTuru": siparis.siparisTuru,
            "CariId": cId,
            "CariUnvan": siparis.cariUnvan ?? (cari?.unvan ?? "Müşteri"),
            "Tarih": toDotNetIsoDate(siparis.tarih),
            "TeslimTarihi": toDotNetIsoDate(siparis.teslimTarihi ?? siparis.tarih),
            "AraToplam": siparis.araToplam,
            "KdvToplam": siparis.kdvToplami,
            "GenelToplam": siparis.genelToplam,
            "Aciklama": siparis.aciklama ?? ""
        ]
        
        let detaylarArray: [[String: Any]] = kalemler.enumerated().map { idx, k in
            let stId = Int(k.stokId ?? "") ?? (idx + 1)
            return [
                "Id": idx + 1,
                "SiparisId": sId,
                "StokId": stId,
                "StokKodu": k.stokKodu ?? "STK-\(idx + 1)",
                "StokAdi": k.stokAdi,
                "Miktar": k.miktar,
                "Birim": k.birim ?? "Adet",
                "BirimFiyat": k.birimFiyat,
                "KdvOrani": k.kdvOrani,
                "ToplamTutar": k.toplamTutar,
                "Tutar": k.toplamTutar
            ]
        }
        
        let logoInfo = currentLogoPayload()
        var payload: [String: Any] = [
            "Siparis": siparisDict,
            "Detaylar": detaylarArray,
            "ShowLogo": logoInfo.showLogo
        ]
        if let b64 = logoInfo.logoBase64 {
            payload["LogoBytes"] = b64
        }
        
        if let c = cari {
            payload["Cari"] = [
                "Id": Int(c.id) ?? cId,
                "Unvan": c.unvan,
                "CariKodu": c.cariKodu ?? "",
                "VergiDairesi": c.vergiDairesi ?? "",
                "VergiNo": c.vergiNo ?? "",
                "Telefon": c.telefon ?? ""
            ]
        }
        
        return await postToCloudRun(url: url, payload: payload)
    }
    
    // MARK: - 4. CARİ EKSTRE & DETAYLI EKSTRE (Cloud Run & Local Fallback)
    public func fetchOrGenerateCariEkstrePDF(
        cari: CariKart,
        hareketler: [CariHareket],
        detayli: Bool = false,
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) async -> Data? {
        let resolvedFirma = (firma.firmaAdi.isEmpty && firma.unvan.isEmpty) ? await resolveFirmaProfili(fallback: firma) : firma
        if let cloudPdf = await fetchCloudQuestPdf(cari: cari, hareketler: hareketler, detayli: detayli) {
            return cloudPdf
        }
        return generateCariEkstrePDF(cari: cari, hareketler: hareketler, detayli: detayli, firma: resolvedFirma)
    }
    
    private func fetchCloudQuestPdf(
        cari: CariKart,
        hareketler: [CariHareket],
        detayli: Bool
    ) async -> Data? {
        let endpoint = detayli ? "ekstre-detayli" : "ekstre"
        guard let url = URL(string: "\(cloudPdfUrl)/generate/\(endpoint)") else {
            return nil
        }
        
        let cId = Int(cari.id) ?? 1
        let cariDict: [String: Any] = [
            "Id": cId,
            "Unvan": cari.unvan,
            "CariKodu": cari.cariKodu ?? "",
            "VergiDairesi": cari.vergiDairesi ?? "",
            "VergiNo": cari.vergiNo ?? "",
            "Telefon": cari.telefon ?? "",
            "Email": cari.email ?? "",
            "Yetkili": cari.yetkili ?? "",
            "Bakiye": cari.bakiye
        ]
        
        let hareketlerArray: [[String: Any]] = hareketler.enumerated().map { idx, h in
            var dict: [String: Any] = [
                "Id": idx + 1,
                "CariId": cId,
                "Tarih": toDotNetIsoDate(h.tarih),
                "IslemTuru": h.islemTuru ?? "İşlem",
                "Aciklama": h.aciklama ?? "-",
                "Borc": h.borc,
                "Alacak": h.alacak,
                "Bakiye": h.bakiye,
                "EvrakNo": h.belgeNo ?? ""
            ]
            if let fIdStr = h.belgeNo?.replacingOccurrences(of: "FT-", with: "").replacingOccurrences(of: "MB-", with: "").replacingOccurrences(of: "FTR-", with: ""),
               let fId = Int(fIdStr) {
                dict["FaturaId"] = fId
            } else {
                dict["FaturaId"] = idx + 100
            }
            return dict
        }
        
        let logoInfo = currentLogoPayload()
        var requestPayload: [String: Any] = [
            "Cari": cariDict,
            "Hareketler": hareketlerArray,
            "ShowLogo": logoInfo.showLogo
        ]
        if let b64 = logoInfo.logoBase64 {
            requestPayload["LogoBytes"] = b64
        }
        
        if detayli {
            var detayDict: [String: [[String: Any]]] = [:]
            let cachedFaturalar = await MainActor.run { DataStore.shared.faturalar }
            for (idx, h) in hareketler.enumerated() {
                let fId: Int
                if let fIdStr = h.belgeNo?.replacingOccurrences(of: "FT-", with: "").replacingOccurrences(of: "MB-", with: "").replacingOccurrences(of: "FTR-", with: ""),
                   let parsed = Int(fIdStr) {
                    fId = parsed
                } else {
                    fId = idx + 100
                }
                
                var realKalemler: [FaturaKalem] = []
                if let matchedFatura = cachedFaturalar.first(where: { $0.id == String(fId) || ($0.faturaNo == h.belgeNo && !(h.belgeNo ?? "").isEmpty) }) {
                    if let k = matchedFatura.kalemler, !k.isEmpty {
                        realKalemler = k
                    } else if let fetched: [FaturaKalem] = try? await SupabaseService.shared.fetch(from: "fatura_detaylar", filters: ["fatura_id": "eq.\(matchedFatura.id)"]) {
                        realKalemler = fetched
                    }
                }
                if realKalemler.isEmpty, let fetchedById: [FaturaKalem] = try? await SupabaseService.shared.fetch(from: "fatura_detaylar", filters: ["fatura_id": "eq.\(fId)"]), !fetchedById.isEmpty {
                    realKalemler = fetchedById
                }
                
                if !realKalemler.isEmpty {
                    detayDict["\(fId)"] = realKalemler.enumerated().map { kIdx, k in
                        [
                            "StokAdi": k.stokAdi,
                            "StokKodu": k.stokKodu ?? "STK-\(kIdx + 1)",
                            "Miktar": k.miktar,
                            "Birim": k.birim ?? "Adet",
                            "BirimFiyat": k.birimFiyat,
                            "KdvOrani": k.kdvOrani,
                            "ToplamTutar": k.toplamTutar
                        ]
                    }
                } else {
                    let isSale = h.borc > 0
                    let tutar = isSale ? h.borc : h.alacak
                    let item: [String: Any] = [
                        "StokAdi": h.aciklama ?? (isSale ? "Hizmet / Satış Kalemi" : "İşlem Kalemi"),
                        "StokKodu": h.belgeNo ?? "STK-\(idx + 1)",
                        "Miktar": 1.0,
                        "Birim": "Adet",
                        "BirimFiyat": tutar,
                        "KdvOrani": 20,
                        "ToplamTutar": tutar
                    ]
                    detayDict["\(fId)"] = [item]
                }
            }
            requestPayload["DetayDictionary"] = detayDict
        }
        
        return await postToCloudRun(url: url, payload: requestPayload)
    }
    
    // MARK: - 5. GENERİC RAPOR QUEST PDF (31+ Rapor)
    public func fetchOrGenerateReportPDF(
        title: String,
        category: String,
        headers: [String],
        rows: [[String]],
        dateFilter: String,
        cariName: String? = nil,
        isHeatmap: Bool = false,
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) async -> Data? {
        return await fetchOrGenerateGenericReportPDF(
            title: title,
            category: category,
            headers: headers,
            rows: rows,
            dateFilter: dateFilter,
            cariName: cariName,
            isHeatmap: isHeatmap,
            firma: firma
        )
    }

    public func fetchOrGenerateGenericReportPDF(
        title: String,
        category: String,
        headers: [String],
        rows: [[String]],
        dateFilter: String,
        cariName: String? = nil,
        isHeatmap: Bool = false,
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) async -> Data? {
        if let cloudPdf = await fetchCloudGenericReportPdf(title: title, headers: headers, rows: rows, subtitle: "Dönem: \(dateFilter)") {
            return cloudPdf
        }
        return generateReportPDF(
            title: title,
            category: category,
            headers: headers,
            rows: rows,
            dateFilter: dateFilter,
            cariName: cariName,
            isHeatmap: isHeatmap,
            firma: firma
        )
    }
    
    public func fetchRemoteGenericTablePDF(
        title: String,
        headers: [String],
        rows: [[String]],
        subtitle: String? = nil
    ) async -> Data? {
        return await fetchCloudGenericReportPdf(
            title: title,
            headers: headers,
            rows: rows,
            subtitle: subtitle ?? "Tüm Zamanlar"
        )
    }

    public func fetchRemoteConsolidatedReportPDF(
        title: String,
        sections: [[String: Any]]
    ) async -> Data? {
        guard let url = URL(string: "\(cloudPdfUrl)/generate/consolidated") else { return nil }
        let logoInfo = currentLogoPayload()
        var payload: [String: Any] = [
            "Title": title,
            "Sections": sections,
            "ShowLogo": logoInfo.showLogo
        ]
        if let b64 = logoInfo.logoBase64 {
            payload["LogoBytes"] = b64
        }
        return await postToCloudRun(url: url, payload: payload)
    }

    public func fetchRemoteBudgetReportPDF(
        title: String,
        annual: [[String: Any]],
        monthly: [[String: Any]],
        weekly: [[String: Any]]
    ) async -> Data? {
        guard let url = URL(string: "\(cloudPdfUrl)/generate/budget") else { return nil }
        let logoInfo = currentLogoPayload()
        var payload: [String: Any] = [
            "Title": title,
            "Annual": annual,
            "Monthly": monthly,
            "Weekly": weekly,
            "ShowLogo": logoInfo.showLogo
        ]
        if let b64 = logoInfo.logoBase64 {
            payload["LogoBytes"] = b64
        }
        return await postToCloudRun(url: url, payload: payload)
    }

    public func fetchOrGenerateStokListPDF(stoklar: [StokKart]) async -> Data {
        if let url = URL(string: "\(cloudPdfUrl)/generate/stok-list") {
            let logoInfo = currentLogoPayload()
            let stokArr: [[String: Any]] = stoklar.enumerated().map { idx, s in
                [
                    "Id": Int(s.id) ?? (idx + 1),
                    "StokKodu": s.stokKodu ?? "",
                    "StokAdi": s.stokAdi,
                    "Barkod": s.barkod ?? "",
                    "Grup": s.grupAdi ?? "",
                    "Kategori": s.grupAdi ?? "",
                    "Birim": s.birim ?? "Adet",
                    "Miktar": s.mevcutMiktar,
                    "AlisFiyati": s.alisFiyati,
                    "OrtalamaAlisFiyati": s.alisFiyati,
                    "OrtalamaSatisFiyati": s.satisFiyati,
                    "SatisFiyati": s.satisFiyati
                ]
            }
            var payload: [String: Any] = [
                "Stoklar": stokArr,
                "ShowLogo": logoInfo.showLogo
            ]
            if let b64 = logoInfo.logoBase64 {
                payload["LogoBytes"] = b64
            }
            if let data = await postToCloudRun(url: url, payload: payload) {
                return data
            }
        }
        let headers = ["Kod", "Stok Adı", "Grup", "Birim", "Miktar", "Alış F.", "Satış F.", "T. Maliyet"]
        let rows: [[String]] = stoklar.map { s in
            [
                s.stokKodu ?? "-",
                s.stokAdi,
                s.grupAdi ?? "-",
                s.birim ?? "Adet",
                String(format: "%.2f", s.mevcutMiktar),
                AppFormatters.money(s.alisFiyati),
                AppFormatters.money(s.satisFiyati),
                AppFormatters.money(s.mevcutMiktar * s.alisFiyati)
            ]
        }
        return generateGenericReportPDF(title: "TOPLU STOK RAPORU", subtitle: AppFormatters.shortDate.string(from: Date()), headers: headers, rows: rows)
    }

    public func fetchOrGenerateStokHareketPDF(stok: StokKart, hareketler: [StokHareket]) async -> Data {
        if let url = URL(string: "\(cloudPdfUrl)/generate/stok-hareket") {
            let logoInfo = currentLogoPayload()
            let stokDict: [String: Any] = [
                "Id": Int(stok.id) ?? 1,
                "StokKodu": stok.stokKodu ?? "",
                "StokAdi": stok.stokAdi,
                "Birim": stok.birim ?? "Adet",
                "Miktar": stok.mevcutMiktar,
                "AlisFiyati": stok.alisFiyati,
                "SatisFiyati": stok.satisFiyati
            ]
            let harArr: [[String: Any]] = hareketler.enumerated().map { idx, h in
                let isGiris = h.giren > 0 || (h.cikan == 0 && !(h.islemTuru ?? "").localizedCaseInsensitiveContains("çıkış") && !(h.islemTuru ?? "").localizedCaseInsensitiveContains("satış"))
                return [
                    "Id": Int(h.id) ?? (idx + 1),
                    "StokId": Int(stok.id) ?? 1,
                    "Tarih": toDotNetIsoDate(h.tarih),
                    "IslemTuru": h.islemTuru ?? (isGiris ? "GİRİŞ" : "ÇIKIŞ"),
                    "Aciklama": h.aciklama ?? h.cariUnvan ?? "-",
                    "Miktar": h.miktar,
                    "Giren": isGiris ? max(h.giren, h.miktar) : 0.0,
                    "Cikan": !isGiris ? max(h.cikan, h.miktar) : 0.0,
                    "Fiyat": h.birimFiyat
                ]
            }
            var payload: [String: Any] = [
                "Stok": stokDict,
                "Hareketler": harArr,
                "ShowLogo": logoInfo.showLogo
            ]
            if let b64 = logoInfo.logoBase64 {
                payload["LogoBytes"] = b64
            }
            if let data = await postToCloudRun(url: url, payload: payload) {
                return data
            }
        }
        let headers = ["Tarih", "İşlem Türü", "Açıklama", "Giren", "Çıkan", "Fiyat"]
        let rows: [[String]] = hareketler.map { h in
            let isGiris = h.giren > 0 || (h.cikan == 0 && !(h.islemTuru ?? "").localizedCaseInsensitiveContains("çıkış") && !(h.islemTuru ?? "").localizedCaseInsensitiveContains("satış"))
            return [
                String((h.tarih ?? "-").prefix(10)),
                h.islemTuru ?? (isGiris ? "GİRİŞ" : "ÇIKIŞ"),
                h.aciklama ?? h.cariUnvan ?? "-",
                isGiris ? String(format: "%.2f", max(h.giren, h.miktar)) : "-",
                !isGiris ? String(format: "%.2f", max(h.cikan, h.miktar)) : "-",
                AppFormatters.money(h.birimFiyat)
            ]
        }
        return generateGenericReportPDF(title: "STOK HAREKET RAPORU", subtitle: "\(stok.stokKodu ?? "") - \(stok.stokAdi)", headers: headers, rows: rows)
    }

    public func fetchOrGenerateFaturaListPDF(faturalar: [Fatura], startDate: Date = Date(), endDate: Date = Date()) async -> Data {
        if let url = URL(string: "\(cloudPdfUrl)/generate/fatura-list") {
            let logoInfo = currentLogoPayload()
            let fArr: [[String: Any]] = faturalar.enumerated().map { idx, f in
                [
                    "Id": Int(f.id) ?? (idx + 1),
                    "FaturaNo": f.faturaNo,
                    "Tur": f.faturaTuru,
                    "FaturaTuru": f.faturaTuru,
                    "Tarih": toDotNetIsoDate(f.tarih),
                    "CariUnvan": f.cariUnvan ?? "-",
                    "AraToplam": f.araToplam,
                    "ToplamKDV": f.kdvToplami,
                    "GenelToplam": f.genelToplam
                ]
            }
            let isoF = DateFormatter()
            isoF.locale = Locale(identifier: "en_US_POSIX")
            isoF.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            var payload: [String: Any] = [
                "Faturalar": fArr,
                "StartDate": isoF.string(from: startDate),
                "EndDate": isoF.string(from: endDate),
                "ShowLogo": logoInfo.showLogo
            ]
            if let b64 = logoInfo.logoBase64 {
                payload["LogoBytes"] = b64
            }
            if let data = await postToCloudRun(url: url, payload: payload) {
                return data
            }
        }
        let headers = ["Fatura No", "Tarih", "Cari Hesap", "Tür", "Tutar"]
        let rows: [[String]] = faturalar.map { f in
            [f.faturaNo, String(f.tarih.prefix(10)), f.cariUnvan ?? "-", f.faturaTuru, AppFormatters.money(f.genelToplam)]
        }
        return generateGenericReportPDF(title: "FATURA LİSTESİ", subtitle: AppFormatters.shortDate.string(from: Date()), headers: headers, rows: rows)
    }

    public func sharePDF(data: Data, fileName: String) {
        let safeFileName = fileName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let finalName = safeFileName.lowercased().hasSuffix(".pdf") ? safeFileName : "\(safeFileName).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(finalName)
        do {
            try data.write(to: tempURL, options: .atomic)
            let av = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController {
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                if let popover = av.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                topVC.present(av, animated: true)
            }
        } catch {
            print("[PDFService] PDF paylaşım hatası: \(error)")
        }
    }

    private func fetchCloudGenericReportPdf(
        title: String,
        headers: [String],
        rows: [[String]],
        subtitle: String
    ) async -> Data? {
        guard let url = URL(string: "\(cloudPdfUrl)/generate/generic") else { return nil }
        let logoInfo = currentLogoPayload()
        var safeRows = rows
        if safeRows.isEmpty && !headers.isEmpty {
            var emptyRow = Array(repeating: "-", count: headers.count)
            emptyRow[0] = "Kayıt bulunamadı"
            safeRows = [emptyRow]
        }
        var payload: [String: Any] = [
            "Title": title.uppercased(with: Locale(identifier: "tr_TR")),
            "Headers": headers,
            "Rows": safeRows,
            "Subtitle": subtitle,
            "ShowLogo": logoInfo.showLogo
        ]
        if let b64 = logoInfo.logoBase64 {
            payload["LogoBytes"] = b64
        }
        
        return await postToCloudRun(url: url, payload: payload)
    }
    
    // MARK: - 6. MAKBUZ QUEST PDF
    public func fetchOrGenerateMakbuzPDF(
        makbuzTipi: String?,
        cariUnvan: String?,
        tarih: String,
        tutar: Double,
        aciklama: String?,
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) async -> Data? {
        guard let url = URL(string: "\(cloudPdfUrl)/generate/makbuz") else { return nil }
        let logoInfo = currentLogoPayload()
        var payload: [String: Any] = [
            "MakbuzTipi": makbuzTipi ?? "Tahsilat",
            "CariUnvan": cariUnvan ?? "Cari",
            "Tarih": toDotNetIsoDate(tarih),
            "Tutar": tutar,
            "Aciklama": aciklama ?? "",
            "ShowLogo": logoInfo.showLogo
        ]
        if let b64 = logoInfo.logoBase64 {
            payload["LogoBytes"] = b64
        }
        if let cloud = await postToCloudRun(url: url, payload: payload) {
            return cloud
        }
        // Fallback generic makbuz
        return generateReportPDF(
            title: "\(makbuzTipi ?? "Tahsilat") Makbuzu",
            category: "Finans",
            headers: ["Cari Ünvan", "Tarih", "Açıklama", "Tutar"],
            rows: [[cariUnvan ?? "-", tarih, aciklama ?? "-", "₺\(String(format: "%.2f", tutar))"]],
            dateFilter: "Bugün",
            firma: firma
        )
    }
    
    // MARK: - Universal Cloud Run POST Worker
    private func postToCloudRun(url: URL, payload: [String: Any]) async -> Data? {
        if cachedFirmaProfili == nil {
            _ = await resolveFirmaProfili()
        }
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return nil
        }
        
        let resolvedApiKey = cloudPdfApiKey ?? UserDefaults.standard.string(forKey: "cloud_pdf_api_key") ?? ProcessInfo.processInfo.environment["PDF_API_KEY"]
        
        for attempt in 1...2 {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let apiKey = resolvedApiKey, !apiKey.isEmpty {
                request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            }
            request.httpBody = httpBody
            request.timeoutInterval = attempt == 1 ? 20.0 : 30.0
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200, data.count > 500 {
                    if let prefix = String(data: data.prefix(5), encoding: .ascii), prefix.hasPrefix("%PDF") {
                        print("[PDFService] Cloud QuestPDF başarıyla üretildi: \(url.lastPathComponent) (\(data.count) bytes).")
                        return data
                    }
                } else if let httpRes = response as? HTTPURLResponse {
                    print("[PDFService] Cloud QuestPDF status code: \(httpRes.statusCode)")
                }
            } catch {
                print("[PDFService] Cloud QuestPDF hatası (deneme \(attempt)): \(error.localizedDescription)")
            }
        }
        return nil
    }
    
    // MARK: - Local Fallback PDF Renderers
    public func generateFaturaPDF(fatura: Fatura, firma: FirmaProfili = FirmaProfili.varsayilan) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Ermay Muhasebe Mobil",
            kCGPDFContextAuthor: firma.firmaAdi,
            kCGPDFContextTitle: "Fatura - \(fatura.faturaNo)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 595.2 // A4 portrait
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 20)
            let bodyFont = UIFont.systemFont(ofSize: 10)
            let boldFont = UIFont.boldSystemFont(ofSize: 10)
            
            // Firma Başlığı
            let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
            (firma.firmaAdi as NSString).draw(at: CGPoint(x: 36, y: 36), withAttributes: titleAttributes)
            
            let firmaSub = "\(firma.unvan)\nVergi No: \(firma.vergiNo ?? "-") | VD: \(firma.vergiDairesi ?? "-")\nTel: \(firma.telefon ?? "-")"
            (firmaSub as NSString).draw(at: CGPoint(x: 36, y: 64), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.darkGray])
            
            // Belge Bilgileri
            let docInfo = "FATURA NO: \(fatura.faturaNo)\nTARİH: \(fatura.tarih)\nVADE: \(fatura.vadeTarihi ?? "-")\nTÜR: \(fatura.faturaTuru)"
            let docInfoRect = CGRect(x: 350, y: 36, width: 210, height: 70)
            (docInfo as NSString).draw(in: docInfoRect, withAttributes: [.font: boldFont, .foregroundColor: UIColor.black])
            
            // Müşteri Bilgileri
            let cariBox = CGRect(x: 36, y: 130, width: 523, height: 60)
            let path = UIBezierPath(roundedRect: cariBox, cornerRadius: 4)
            UIColor.systemGray6.setFill()
            path.fill()
            
            let cariTitle = "SAYIN: \(fatura.cariUnvan ?? "Perakende Müşteri")"
            (cariTitle as NSString).draw(at: CGPoint(x: 48, y: 140), withAttributes: [.font: boldFont, .foregroundColor: UIColor.black])
            
            // Kalemler Tablosu
            let tableHeaderY: CGFloat = 205
            let headerBg = CGRect(x: 36, y: tableHeaderY, width: 523, height: 24)
            UIColor(red: 0/255, green: 97/255, blue: 255/255, alpha: 1.0).setFill()
            UIBezierPath(rect: headerBg).fill()
            
            let headerAttributes: [NSAttributedString.Key: Any] = [.font: boldFont, .foregroundColor: UIColor.white]
            ("ÜRÜN / AÇIKLAMA" as NSString).draw(at: CGPoint(x: 44, y: tableHeaderY + 6), withAttributes: headerAttributes)
            ("MİKTAR" as NSString).draw(at: CGPoint(x: 280, y: tableHeaderY + 6), withAttributes: headerAttributes)
            ("B.FİYAT" as NSString).draw(at: CGPoint(x: 360, y: tableHeaderY + 6), withAttributes: headerAttributes)
            ("KDV" as NSString).draw(at: CGPoint(x: 430, y: tableHeaderY + 6), withAttributes: headerAttributes)
            ("TUTAR" as NSString).draw(at: CGPoint(x: 485, y: tableHeaderY + 6), withAttributes: headerAttributes)
            
            var currentY = tableHeaderY + 30
            if let kalemler = fatura.kalemler {
                for item in kalemler {
                    (item.stokAdi as NSString).draw(at: CGPoint(x: 44, y: currentY), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
                    ("\(String(format: "%.2f", item.miktar)) \(item.birim ?? "Adet")" as NSString).draw(at: CGPoint(x: 280, y: currentY), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
                    ("₺\(String(format: "%.2f", item.birimFiyat))" as NSString).draw(at: CGPoint(x: 360, y: currentY), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
                    ("%\(Int(item.kdvOrani))" as NSString).draw(at: CGPoint(x: 430, y: currentY), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
                    ("₺\(String(format: "%.2f", item.toplamTutar))" as NSString).draw(at: CGPoint(x: 485, y: currentY), withAttributes: [.font: boldFont, .foregroundColor: UIColor.black])
                    currentY += 20
                }
            }
            
            // Dip Toplamlar
            let totalsY = max(currentY + 20, 680)
            let totalsBox = CGRect(x: 350, y: totalsY, width: 210, height: 90)
            let tPath = UIBezierPath(roundedRect: totalsBox, cornerRadius: 4)
            UIColor.systemGray6.setFill()
            tPath.fill()
            
            ("Ara Toplam: ₺\(String(format: "%.2f", fatura.araToplam))" as NSString).draw(at: CGPoint(x: 360, y: totalsY + 12), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
            ("KDV Toplamı: ₺\(String(format: "%.2f", fatura.kdvToplami))" as NSString).draw(at: CGPoint(x: 360, y: totalsY + 32), withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
            ("GENEL TOPLAM: ₺\(String(format: "%.2f", fatura.genelToplam))" as NSString).draw(at: CGPoint(x: 360, y: totalsY + 56), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor(red: 0/255, green: 97/255, blue: 255/255, alpha: 1.0)])
        }
        
        return data
    }
    
    public func generateTeklifPDF(
        teklif: Teklif,
        kalemler: [TeklifKalem],
        cari: CariKart?,
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) -> Data? {
        let dummyFatura = Fatura(
            id: teklif.id,
            faturaNo: teklif.teklifNo,
            faturaTuru: "Teklif",
            cariId: teklif.cariId,
            cariUnvan: teklif.cariUnvan ?? cari?.unvan,
            tarih: teklif.tarih,
            vadeTarihi: teklif.gecerlilikTarihi,
            araToplam: teklif.araToplam,
            kdvToplami: teklif.kdvToplami,
            iskontoToplami: 0,
            genelToplam: teklif.genelToplam,
            kalemler: kalemler.map { FaturaKalem(stokId: $0.stokId, stokKodu: $0.stokKodu, stokAdi: $0.stokAdi, miktar: $0.miktar, birim: $0.birim ?? "Adet", birimFiyat: $0.birimFiyat, kdvOrani: $0.kdvOrani, toplamTutar: $0.toplamTutar) }
        )
        return generateFaturaPDF(fatura: dummyFatura, firma: firma)
    }
    
    public func generateSiparisPDF(
        siparis: Siparis,
        kalemler: [SiparisKalem],
        cari: CariKart?,
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) -> Data? {
        let dummyFatura = Fatura(
            id: siparis.id,
            faturaNo: siparis.siparisNo,
            faturaTuru: "Sipariş",
            cariId: siparis.cariId,
            cariUnvan: siparis.cariUnvan ?? cari?.unvan,
            tarih: siparis.tarih,
            vadeTarihi: siparis.teslimTarihi,
            araToplam: siparis.araToplam,
            kdvToplami: siparis.kdvToplami,
            iskontoToplami: siparis.iskontoToplami,
            genelToplam: siparis.genelToplam,
            kalemler: kalemler.map { FaturaKalem(stokId: $0.stokId, stokKodu: $0.stokKodu, stokAdi: $0.stokAdi, miktar: $0.miktar, birim: $0.birim ?? "Adet", birimFiyat: $0.birimFiyat, kdvOrani: $0.kdvOrani, toplamTutar: $0.toplamTutar) }
        )
        return generateFaturaPDF(fatura: dummyFatura, firma: firma)
    }
    
    public func generateGenericReportPDF(
        title: String,
        subtitle: String,
        headers: [String],
        rows: [[String]]
    ) -> Data {
        return generateReportPDF(
            title: title,
            category: "Rapor",
            headers: headers,
            rows: rows,
            dateFilter: subtitle
        ) ?? Data()
    }

    public func generateReportPDF(
        title: String,
        category: String,
        headers: [String],
        rows: [[String]],
        dateFilter: String,
        cariName: String? = nil,
        isHeatmap: Bool = false,
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "VK Ön Muhasebe Yönetim Sistemi (QuestPDF)",
            kCGPDFContextAuthor: "VK Ön Muhasebe",
            kCGPDFContextTitle: "\(title)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let isLandscape = headers.count >= 6
        let pageWidth: CGFloat = isLandscape ? 841.8 : 595.2
        let pageHeight: CGFloat = isLandscape ? 595.2 : 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            let margin: CGFloat = 28.35 // 1 cm QuestPDF exact margin
            let tableWidth = pageWidth - (margin * 2)
            let colCount = max(headers.count, 1)
            let colWidth = tableWidth / CGFloat(colCount)
            
            let titleColor = UIColor(red: 30/255, green: 58/255, blue: 138/255, alpha: 1.0) // #1E3A8A
            let lineColor = UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1.0)  // #2563EB
            let subColor = UIColor(red: 71/255, green: 85/255, blue: 105/255, alpha: 1.0)   // #475569
            let metaColor = UIColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1.0)// #64748B
            let rowAltBg = UIColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0) // #F8FAFC
            let borderColor = UIColor(red: 226/255, green: 232/255, blue: 240/255, alpha: 1.0) // #E2E8F0
            
            let titleFont = UIFont.boldSystemFont(ofSize: 16)
            let subFont = UIFont.systemFont(ofSize: 9)
            let metaFont = UIFont.systemFont(ofSize: 8)
            let metaBoldFont = UIFont.boldSystemFont(ofSize: 8)
            let headerFont = UIFont.boldSystemFont(ofSize: 8)
            let cellFont = UIFont.systemFont(ofSize: 8)
            
            let nowFmt = DateFormatter()
            nowFmt.dateFormat = "dd.MM.yyyy HH:mm"
            let nowStr = nowFmt.string(from: Date())
            
            var pageNum = 0
            var currentY: CGFloat = 0
            
            let beginNewPage = {
                context.beginPage()
                pageNum += 1
                currentY = margin
                
                let rTitle = title.uppercased(with: Locale(identifier: "tr_TR"))
                (rTitle as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: [.font: titleFont, .foregroundColor: titleColor])
                let subText = dateFilter == "All" ? "Tüm Zamanlar" : dateFilter
                (subText as NSString).draw(at: CGPoint(x: margin, y: currentY + 20), withAttributes: [.font: subFont, .foregroundColor: subColor])
                
                let meta1 = "Tarih: \(nowStr)"
                let meta2 = "Kayıt Sayısı: \(rows.count) Satır"
                let m1Size = (meta1 as NSString).size(withAttributes: [.font: metaFont])
                let m2Size = (meta2 as NSString).size(withAttributes: [.font: metaBoldFont])
                (meta1 as NSString).draw(at: CGPoint(x: pageWidth - margin - m1Size.width, y: currentY + 2), withAttributes: [.font: metaFont, .foregroundColor: metaColor])
                (meta2 as NSString).draw(at: CGPoint(x: pageWidth - margin - m2Size.width, y: currentY + 14), withAttributes: [.font: metaBoldFont, .foregroundColor: titleColor])
                
                currentY += 36
                lineColor.setStroke()
                let accentLine = UIBezierPath()
                accentLine.move(to: CGPoint(x: margin, y: currentY))
                accentLine.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
                accentLine.lineWidth = 1.5
                accentLine.stroke()
                
                currentY += 10
                
                // Table Header (#1E3A8A background, white bold text)
                let thRect = CGRect(x: margin, y: currentY, width: tableWidth, height: 22)
                titleColor.setFill()
                UIBezierPath(rect: thRect).fill()
                for (idx, h) in headers.enumerated() {
                    let colX = margin + (CGFloat(idx) * colWidth) + 6
                    (h as NSString).draw(
                        in: CGRect(x: colX, y: currentY + 6, width: colWidth - 12, height: 14),
                        withAttributes: [.font: headerFont, .foregroundColor: UIColor.white]
                    )
                }
                currentY += 22
                
                // Footer
                let footerY = pageHeight - margin - 12
                borderColor.setStroke()
                let fLine = UIBezierPath()
                fLine.move(to: CGPoint(x: margin, y: footerY - 4))
                fLine.addLine(to: CGPoint(x: pageWidth - margin, y: footerY - 4))
                fLine.lineWidth = 0.5
                fLine.stroke()
                ("VK Ön Muhasebe Yönetim Sistemi" as NSString).draw(at: CGPoint(x: margin, y: footerY), withAttributes: [.font: UIFont.systemFont(ofSize: 7), .foregroundColor: metaColor])
                let pStr = "Sayfa \(pageNum)"
                let pSize = (pStr as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 7)])
                (pStr as NSString).draw(at: CGPoint(x: pageWidth - margin - pSize.width, y: footerY), withAttributes: [.font: UIFont.systemFont(ofSize: 7), .foregroundColor: metaColor])
            }
            
            beginNewPage()
            
            for (rowIndex, row) in rows.enumerated() {
                if currentY + 20 > pageHeight - margin - 24 {
                    beginNewPage()
                }
                let rowRect = CGRect(x: margin, y: currentY, width: tableWidth, height: 19)
                (rowIndex % 2 == 0 ? UIColor.white : rowAltBg).setFill()
                UIBezierPath(rect: rowRect).fill()
                
                for (colIdx, val) in row.enumerated() where colIdx < colCount {
                    let colX = margin + (CGFloat(colIdx) * colWidth) + 6
                    (val as NSString).draw(
                        in: CGRect(x: colX, y: currentY + 4, width: colWidth - 12, height: 14),
                        withAttributes: [.font: cellFont, .foregroundColor: UIColor.black]
                    )
                }
                
                borderColor.setStroke()
                let line = UIBezierPath()
                line.move(to: CGPoint(x: margin, y: currentY + 19))
                line.addLine(to: CGPoint(x: margin + tableWidth, y: currentY + 19))
                line.lineWidth = 0.5
                line.stroke()
                
                currentY += 19
            }
        }
        return data
    }
    
    public func generateCariEkstrePDF(
        cari: CariKart,
        hareketler: [CariHareket],
        detayli: Bool = false,
        firma: FirmaProfili = FirmaProfili.varsayilan
    ) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Ermay Muhasebe Mobil (QuestPDF Engine)",
            kCGPDFContextAuthor: firma.firmaAdi,
            kCGPDFContextTitle: "\(detayli ? "Detaylı Cari Ekstresi" : "Cari Hesap Ekstresi") - \(cari.unvan)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 595.2 // A4 portrait
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            let margin: CGFloat = 28
            let usableWidth = pageWidth - (margin * 2)
            
            let fontBrand = UIFont.boldSystemFont(ofSize: 14)
            let fontSub = UIFont.systemFont(ofSize: 8)
            let fontTitle = UIFont.boldSystemFont(ofSize: 11)
            let fontBold9 = UIFont.boldSystemFont(ofSize: 9)
            let fontReg9 = UIFont.systemFont(ofSize: 9)
            let fontBold8 = UIFont.boldSystemFont(ofSize: 8)
            let fontReg8 = UIFont.systemFont(ofSize: 8)
            let fontBadge = UIFont.boldSystemFont(ofSize: 7.5)
            let fontSubBold = UIFont.boldSystemFont(ofSize: 7.5)
            
            let colorPrimary = UIColor(red: 47/255, green: 111/255, blue: 237/255, alpha: 1.0)
            let colorCardBg = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1.0)
            let colorCardBorder = UIColor(red: 221/255, green: 221/255, blue: 221/255, alpha: 1.0)
            let colorHeaderBg = UIColor(red: 249/255, green: 249/255, blue: 249/255, alpha: 1.0)
            let colorBorder = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1.0)
            let colorMuted = UIColor(red: 102/255, green: 102/255, blue: 102/255, alpha: 1.0)
            let colorRed = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
            let colorGreen = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1.0)
            
            var toplamBorc: Double = 0
            var toplamAlacak: Double = 0
            for h in hareketler {
                toplamBorc += h.borc
                toplamAlacak += h.alacak
            }
            let netBakiye = toplamBorc - toplamAlacak
            
            // Üst Başlık
            let headerY: CGFloat = margin
            (firma.firmaAdi as NSString).draw(
                at: CGPoint(x: margin, y: headerY),
                withAttributes: [.font: fontBrand, .foregroundColor: colorPrimary]
            )
            
            let brandSub = "\(firma.unvan) • \(firma.telefon ?? "")"
            (brandSub as NSString).draw(
                at: CGPoint(x: margin, y: headerY + 18),
                withAttributes: [.font: fontSub, .foregroundColor: colorMuted]
            )
            
            let docTitle = (detayli ? "DETAYLI CARİ HESAP EKSTRESİ" : "CARİ HESAP EKSTRESİ").uppercased(with: Locale(identifier: "tr_TR"))
            let docTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1.0)
            ]
            let docTitleSize = (docTitle as NSString).size(withAttributes: docTitleAttrs)
            (docTitle as NSString).draw(
                at: CGPoint(x: pageWidth - margin - docTitleSize.width, y: headerY),
                withAttributes: docTitleAttrs
            )
            
            let dateStr = "Tarih: \(ISO8601DateFormatter().string(from: Date()).prefix(10))"
            let dateAttrs: [NSAttributedString.Key: Any] = [.font: fontReg8, .foregroundColor: colorMuted]
            let dateSize = (dateStr as NSString).size(withAttributes: dateAttrs)
            (dateStr as NSString).draw(
                at: CGPoint(x: pageWidth - margin - dateSize.width, y: headerY + 18),
                withAttributes: dateAttrs
            )
            
            var currentY = headerY + 38
            
            // Genel Bilgiler Kartı
            let cardHeight: CGFloat = 82
            let cardRect = CGRect(x: margin, y: currentY, width: usableWidth, height: cardHeight)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 4)
            colorCardBg.setFill()
            cardPath.fill()
            colorCardBorder.setStroke()
            cardPath.lineWidth = 0.5
            cardPath.stroke()
            
            ("Genel Bilgiler" as NSString).draw(
                at: CGPoint(x: margin + 10, y: currentY + 8),
                withAttributes: [.font: fontTitle, .foregroundColor: UIColor.black]
            )
            
            let infoY = currentY + 28
            let col1X = margin + 10
            let col1ValX = margin + 85
            let col2X = margin + 280
            let col2ValX = margin + 360
            
            ("Müşteri Adı:" as NSString).draw(at: CGPoint(x: col1X, y: infoY), withAttributes: [.font: fontBold9, .foregroundColor: UIColor.black])
            (cari.unvan as NSString).draw(in: CGRect(x: col1ValX, y: infoY, width: 180, height: 16), withAttributes: [.font: fontReg9, .foregroundColor: UIColor.black])
            
            ("Toplam Satış:" as NSString).draw(at: CGPoint(x: col2X, y: infoY), withAttributes: [.font: fontBold9, .foregroundColor: UIColor.black])
            ("₺\(String(format: "%.2f", toplamBorc))" as NSString).draw(at: CGPoint(x: col2ValX, y: infoY), withAttributes: [.font: fontReg9, .foregroundColor: UIColor.black])
            
            ("Toplam Ödeme:" as NSString).draw(at: CGPoint(x: col1X, y: infoY + 20), withAttributes: [.font: fontBold9, .foregroundColor: UIColor.black])
            ("₺\(String(format: "%.2f", toplamAlacak))" as NSString).draw(at: CGPoint(x: col1ValX, y: infoY + 20), withAttributes: [.font: fontReg9, .foregroundColor: UIColor.black])
            
            ("Bakiye:" as NSString).draw(at: CGPoint(x: col2X, y: infoY + 20), withAttributes: [.font: fontBold9, .foregroundColor: UIColor.black])
            let bColor = netBakiye > 0 ? colorRed : colorGreen
            let bLabel = netBakiye > 0 ? " (Borçlu)" : " (Alacaklı)"
            let bakiyeString = "₺\(String(format: "%.2f", abs(netBakiye)))\(bLabel)"
            (bakiyeString as NSString).draw(at: CGPoint(x: col2ValX, y: infoY + 20), withAttributes: [.font: fontBold9, .foregroundColor: bColor])
            
            currentY += cardHeight + 12
            
            // Tablo Kolonları
            let colTarihW: CGFloat = usableWidth * 0.12
            let colTipW: CGFloat = usableWidth * 0.11
            let colAciklamaW: CGFloat = usableWidth * 0.37
            let colBorcW: CGFloat = usableWidth * 0.13
            let colAlacakW: CGFloat = usableWidth * 0.13
            let colBakiyeW: CGFloat = usableWidth * 0.14
            
            let xTarih = margin
            let xTip = xTarih + colTarihW
            let xAciklama = xTip + colTipW
            let xBorc = xAciklama + colAciklamaW
            let xAlacak = xBorc + colBorcW
            let xBakiye = xAlacak + colAlacakW
            
            let thHeight: CGFloat = 20
            let thRect = CGRect(x: margin, y: currentY, width: usableWidth, height: thHeight)
            colorHeaderBg.setFill()
            UIBezierPath(rect: thRect).fill()
            colorBorder.setStroke()
            let thBorder = UIBezierPath(rect: thRect)
            thBorder.lineWidth = 0.5
            thBorder.stroke()
            
            let thAttrs: [NSAttributedString.Key: Any] = [.font: fontBold8, .foregroundColor: UIColor.black]
            ("Tarih" as NSString).draw(at: CGPoint(x: xTarih + 4, y: currentY + 4), withAttributes: thAttrs)
            ("İşlem Tipi" as NSString).draw(at: CGPoint(x: xTip + 4, y: currentY + 4), withAttributes: thAttrs)
            ("Açıklama" as NSString).draw(at: CGPoint(x: xAciklama + 4, y: currentY + 4), withAttributes: thAttrs)
            
            let drawR = { (text: String, x: CGFloat, y: CGFloat, attrs: [NSAttributedString.Key: Any]) in
                let sz = (text as NSString).size(withAttributes: attrs)
                (text as NSString).draw(at: CGPoint(x: x - sz.width, y: y), withAttributes: attrs)
            }
            
            drawR("Borç", xBorc + colBorcW - 4, currentY + 4, thAttrs)
            drawR("Alacak", xAlacak + colAlacakW - 4, currentY + 4, thAttrs)
            drawR("Bakiye", xBakiye + colBakiyeW - 4, currentY + 4, thAttrs)
            
            currentY += thHeight
            
            var runningBalance: Double = 0
            for (_, h) in hareketler.enumerated() {
                if currentY > pageHeight - margin - 50 {
                    context.beginPage()
                    currentY = margin + 10
                }
                
                let isSale = h.borc > 0
                runningBalance += (h.borc - h.alacak)
                
                let rowHeight: CGFloat = detayli ? 34 : 20
                
                colorBorder.setStroke()
                let line = UIBezierPath()
                line.move(to: CGPoint(x: margin, y: currentY + rowHeight))
                line.addLine(to: CGPoint(x: margin + usableWidth, y: currentY + rowHeight))
                line.lineWidth = 0.5
                line.stroke()
                
                let dateDisplay = String((h.tarih ?? "-").prefix(10))
                (dateDisplay as NSString).draw(at: CGPoint(x: xTarih + 4, y: currentY + 4), withAttributes: [.font: fontReg8, .foregroundColor: UIColor.black])
                
                let (badgeColor, badgeTitle) = self.resolveBadge(rawTuru: h.islemTuru ?? "")
                let badgeRect = CGRect(x: xTip + 2, y: currentY + 3, width: colTipW - 6, height: 14)
                let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: 3)
                badgeColor.setFill()
                badgePath.fill()
                
                let badgeTitleAttrs: [NSAttributedString.Key: Any] = [.font: fontBadge, .foregroundColor: UIColor.white]
                let bTextSize = (badgeTitle as NSString).size(withAttributes: badgeTitleAttrs)
                (badgeTitle as NSString).draw(
                    at: CGPoint(x: badgeRect.midX - (bTextSize.width / 2), y: badgeRect.midY - (bTextSize.height / 2)),
                    withAttributes: badgeTitleAttrs
                )
                
                var desc = h.aciklama ?? "-"
                (desc as NSString).draw(
                    in: CGRect(x: xAciklama + 4, y: currentY + 4, width: colAciklamaW - 8, height: 14),
                    withAttributes: [.font: fontReg8, .foregroundColor: UIColor.black]
                )
                
                if isSale {
                    drawR("₺\(String(format: "%.2f", h.borc))", xBorc + colBorcW - 4, currentY + 4, [.font: fontBold8, .foregroundColor: colorRed])
                    drawR("-", xAlacak + colAlacakW - 4, currentY + 4, [.font: fontReg8, .foregroundColor: UIColor.gray])
                } else {
                    drawR("-", xBorc + colBorcW - 4, currentY + 4, [.font: fontReg8, .foregroundColor: UIColor.gray])
                    drawR("₺\(String(format: "%.2f", h.alacak))", xAlacak + colAlacakW - 4, currentY + 4, [.font: fontBold8, .foregroundColor: colorGreen])
                }
                
                drawR("₺\(String(format: "%.2f", runningBalance))", xBakiye + colBakiyeW - 4, currentY + 4, [.font: fontBold8, .foregroundColor: UIColor.black])
                
                if detayli {
                    let subY = currentY + 18
                    let subTh = "• Kalemler: \(desc) | Miktar: 1 Adet | KDV: %20 | Tutar: ₺\(String(format: "%.2f", isSale ? h.borc : h.alacak))"
                    (subTh as NSString).draw(
                        in: CGRect(x: margin + 25, y: subY, width: usableWidth - 40, height: 12),
                        withAttributes: [.font: fontSubBold, .foregroundColor: UIColor(white: 0.35, alpha: 1.0)]
                    )
                }
                
                currentY += rowHeight
            }
            
            // Footer
            let footerText = "Ermay Muhasebe • QuestPDF Engine"
            let footerAttrs: [NSAttributedString.Key: Any] = [.font: fontSub, .foregroundColor: colorMuted]
            let footerSize = (footerText as NSString).size(withAttributes: footerAttrs)
            (footerText as NSString).draw(
                at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - margin),
                withAttributes: footerAttrs
            )
        }
        return data
    }
    
    private func resolveBadge(rawTuru: String) -> (UIColor, String) {
        let t = rawTuru.uppercased(with: Locale(identifier: "tr_TR"))
        if t.contains("SATIŞ") || t.contains("SATIS") || t.contains("FATURA") || t.contains("GİRİŞ") || t.contains("GIRIS") {
            return (UIColor(red: 47/255, green: 111/255, blue: 237/255, alpha: 1.0), "Satış")
        } else if t.contains("ALIŞ") || t.contains("ALIS") || t.contains("ÇIKIŞ") || t.contains("CIKIS") {
            return (UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1.0), "Alış")
        } else if t.contains("TAHSİLAT") || t.contains("TAHSILAT") {
            return (UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1.0), "Tahsilat")
        } else if t.contains("ÖDEME") || t.contains("ODEME") {
            return (UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0), "Ödeme")
        } else if t.contains("ÇEK") || t.contains("CEK") || t.contains("SENET") {
            return (UIColor(red: 139/255, green: 92/255, blue: 246/255, alpha: 1.0), "Çek/Senet")
        } else {
            return (UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1.0), "İşlem")
        }
    }
    #endif
}
