import Foundation

// MARK: - Transaction Request Models
public struct FinancialTransactionRequest {
    public var id: Int?
    public var cari: CariKart
    public var transactionType: String // "Tahsilat", "Ödeme", "Borç Dekontu", "Alacak Dekontu", "Borçlandır", "Alacaklandır"
    public var method: String // "Nakit", "Kredi Kartı", "Havale / EFT", "Çek / Senet"
    public var amount: Double
    public var date: String
    public var description: String
    public var selectedHesap: KasaBanka?
    public var isAcilisFisi: Bool
    
    public init(
        id: Int? = nil,
        cari: CariKart,
        transactionType: String,
        method: String,
        amount: Double,
        date: String = AppFormatters.isoDate.string(from: Date()),
        description: String = "",
        selectedHesap: KasaBanka? = nil,
        isAcilisFisi: Bool = false
    ) {
        self.id = id
        self.cari = cari
        self.transactionType = transactionType
        self.method = method
        self.amount = amount
        self.date = date
        self.description = description
        self.selectedHesap = selectedHesap
        self.isAcilisFisi = isAcilisFisi
    }
}

public struct InvoiceTransactionRequest {
    public var id: Int?
    public var faturaNo: String
    public var tarih: String
    public var vadeTarihi: String?
    public var cari: CariKart
    public var tur: String // "Satış", "Alış"
    public var durum: String // "Açık", "Kapalı"
    public var odemeSekli: String // "Açık Hesap", "Nakit", "Kredi Kartı", "Banka Havalesi"
    public var kasaId: String?
    public var bankaId: String?
    public var dovizTuru: String
    public var dovizKuru: Double
    public var baglantiEvrakNo: String?
    public var aciklama: String?
    public var items: [FaturaKalem]
    
    public init(
        id: Int? = nil,
        faturaNo: String,
        tarih: String,
        vadeTarihi: String? = nil,
        cari: CariKart,
        tur: String = "Satış",
        durum: String = "Açık",
        odemeSekli: String = "Açık Hesap",
        kasaId: String? = nil,
        bankaId: String? = nil,
        dovizTuru: String = "TL",
        dovizKuru: Double = 1.0,
        baglantiEvrakNo: String? = nil,
        aciklama: String? = nil,
        items: [FaturaKalem] = []
    ) {
        self.id = id
        self.faturaNo = faturaNo
        self.tarih = tarih
        self.vadeTarihi = vadeTarihi
        self.cari = cari
        self.tur = tur
        self.durum = durum
        self.odemeSekli = odemeSekli
        self.kasaId = kasaId
        self.bankaId = bankaId
        self.dovizTuru = dovizTuru
        self.dovizKuru = dovizKuru
        self.baglantiEvrakNo = baglantiEvrakNo
        self.aciklama = aciklama
        self.items = items
    }
}

// MARK: - PostgREST Strict Insert Payloads (INTEGER NOT NULL ve Foreign Key Uyumlu)
private struct FaturaInsertPayload: Encodable {
    let id: Int
    let fatura_no: String
    let fatura_turu: String
    let cari_id: Int?
    let cari_unvan: String?
    let tarih: String
    let vade_tarihi: String?
    let ara_toplam: Double
    let kdv_toplam: Double
    let iskonto_toplam: Double
    let genel_toplam: Double
    let odeme_durumu: String
    let durum: String
    let aciklama: String?
    let tenant_id: String
    let uuid: String
    let version: Int
}

private struct FaturaDetayInsertPayload: Encodable {
    let id: Int
    let fatura_id: Int
    let stok_id: Int?
    let stok_kodu: String?
    let stok_adi: String?
    let miktar: Double
    let birim: String
    let birim_fiyat: Double
    let kdv_orani: Double
    let kdv_tutari: Double
    let iskonto_orani: Double
    let iskonto_tutari: Double
    let toplam_tutar: Double
    let aciklama: String?
    let tenant_id: String
    let uuid: String
    let version: Int
}

private struct StokHareketStrictPayload: Encodable {
    let id: Int
    let stok_id: Int?
    let tarih: String
    let islem_turu: String
    let hareket_turu: String
    let hareket_tipi: String
    let giren: Double
    let cikan: Double
    let evrak_no: String
    let miktar: Double
    let birim_fiyat: Double
    let toplam_tutar: Double
    let fatura_id: Int
    let cari_id: Int?
    let aciklama: String?
    let tenant_id: String
    let uuid: String
}

private struct CariHareketStrictPayload: Encodable {
    var id: Int? = nil
    let cari_id: Int?
    let tarih: String
    let evrak_no: String
    let belge_no: String
    let islem_turu: String
    let borc: Double
    let alacak: Double
    let bakiye: Double
    var fatura_id: Int? = nil
    let aciklama: String?
    let tenant_id: String
    let uuid: String
    var device_id: String = "iPhone-App"
    var mali_yil: Int = Int(SupabaseService.shared.activeFiscalYear) ?? Calendar.current.component(.year, from: Date())

    enum CodingKeys: String, CodingKey {
        case id
        case cari_id
        case tarih
        case evrak_no
        case belge_no
        case islem_turu
        case borc
        case alacak
        case bakiye
        case fatura_id
        case aciklama
        case tenant_id
        case uuid
        case device_id
        case mali_yil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let id = id, id > 0 {
            try c.encode(id, forKey: .id)
        }
        try c.encodeIfPresent(cari_id, forKey: .cari_id)
        try c.encode(tarih, forKey: .tarih)
        try c.encode(evrak_no, forKey: .evrak_no)
        try c.encode(belge_no, forKey: .belge_no)
        try c.encode(islem_turu, forKey: .islem_turu)
        try c.encode(borc, forKey: .borc)
        try c.encode(alacak, forKey: .alacak)
        try c.encode(bakiye, forKey: .bakiye)
        if let fid = fatura_id, fid > 0 {
            try c.encode(fid, forKey: .fatura_id)
        }
        try c.encodeIfPresent(aciklama, forKey: .aciklama)
        try c.encode(tenant_id, forKey: .tenant_id)
        try c.encode(uuid, forKey: .uuid)
        try c.encode(device_id, forKey: .device_id)
        try c.encode(mali_yil, forKey: .mali_yil)
    }
}

private struct BankaHareketStrictPayload: Encodable {
    var id: Int? = nil
    let banka_id: Int?
    let cari_id: Int?
    let cari_unvan: String?
    let tarih: String
    let evrak_no: String?
    let belge_no: String?
    let islem_turu: String
    let giren: Double
    let cikan: Double
    let yatan: Double
    let ceken: Double
    let tutar: Double
    let aciklama: String?
    let tenant_id: String
    let uuid: String
    var mali_yil: Int = Int(SupabaseService.shared.activeFiscalYear) ?? Calendar.current.component(.year, from: Date())
    
    enum CodingKeys: String, CodingKey {
        case id
        case banka_id
        case cari_id
        case cari_unvan
        case tarih
        case evrak_no
        case belge_no
        case islem_turu
        case giren
        case cikan
        case yatan
        case ceken
        case tutar
        case aciklama
        case tenant_id
        case uuid
        case mali_yil
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let id = id, id > 0 {
            try c.encode(id, forKey: .id)
        }
        try c.encodeIfPresent(banka_id, forKey: .banka_id)
        try c.encodeIfPresent(cari_id, forKey: .cari_id)
        try c.encodeIfPresent(cari_unvan, forKey: .cari_unvan)
        try c.encode(tarih, forKey: .tarih)
        try c.encodeIfPresent(evrak_no, forKey: .evrak_no)
        try c.encodeIfPresent(belge_no, forKey: .belge_no)
        try c.encode(islem_turu, forKey: .islem_turu)
        try c.encode(giren, forKey: .giren)
        try c.encode(cikan, forKey: .cikan)
        try c.encode(yatan, forKey: .yatan)
        try c.encode(ceken, forKey: .ceken)
        try c.encode(tutar, forKey: .tutar)
        try c.encodeIfPresent(aciklama, forKey: .aciklama)
        try c.encode(tenant_id, forKey: .tenant_id)
        try c.encode(uuid, forKey: .uuid)
        try c.encode(mali_yil, forKey: .mali_yil)
    }
}

// MARK: - Models for save_invoice_atomic RPC
public struct AtomicFaturaDetayData: Codable {
    public var uuid: String
    public var stok_id: Int?
    public var stok_uuid: String?
    public var stok_kodu: String?
    public var stok_adi: String?
    public var miktar: Double
    public var birim: String?
    public var birim_fiyat: Double
    public var kdv_orani: Double
    public var kdv_tutari: Double
    public var iskonto_orani: Double
    public var iskonto_tutari: Double
    public var toplam_tutar: Double
    public var net_tutar: Double

    public init(
        uuid: String = UUID().uuidString,
        stok_id: Int? = nil,
        stok_uuid: String? = nil,
        stok_kodu: String? = nil,
        stok_adi: String? = nil,
        miktar: Double,
        birim: String? = "Adet",
        birim_fiyat: Double,
        kdv_orani: Double = 20.0,
        kdv_tutari: Double = 0.0,
        iskonto_orani: Double = 0.0,
        iskonto_tutari: Double = 0.0,
        toplam_tutar: Double,
        net_tutar: Double? = nil
    ) {
        self.uuid = uuid
        self.stok_id = stok_id
        self.stok_uuid = stok_uuid
        self.stok_kodu = stok_kodu
        self.stok_adi = stok_adi
        self.miktar = miktar
        self.birim = birim
        self.birim_fiyat = birim_fiyat
        self.kdv_orani = kdv_orani
        self.kdv_tutari = kdv_tutari
        self.iskonto_orani = iskonto_orani
        self.iskonto_tutari = iskonto_tutari
        self.toplam_tutar = toplam_tutar
        self.net_tutar = net_tutar ?? toplam_tutar
    }
}

public struct AtomicInvoicePayload: Codable {
    public var id: Int?
    public var tenant_id: String
    public var idempotency_key: String?
    public var uuid: String
    public var fatura_no: String
    public var fatura_turu: String
    public var tur: String?
    public var cari_id: Int?
    public var cari_uuid: String?
    public var cari_unvan: String?
    public var tarih: String
    public var vade_tarihi: String?
    public var ara_toplam: Double
    public var iskonto_toplam: Double
    public var kdv_toplam: Double
    public var genel_toplam: Double
    public var is_kapali: Bool
    public var fatura_tipi: String?
    public var odeme_sekli: String?
    public var kasa_id: Int?
    public var kasa_uuid: String?
    public var banka_id: Int?
    public var banka_uuid: String?
    public var odenen: Double?
    public var aciklama: String?
    public var cihaz_rolu: String?
    public var mali_yil: Int?
    public var detaylar: [AtomicFaturaDetayData]
}

public struct AtomicRpcWrapper: Encodable {
    public var p_payload: AtomicInvoicePayload
}

public struct AtomicRpcResponse: Decodable {
    public var success: Bool
    public var fatura_id: String?
    public var fatura_uuid: String?
    public var fatura_no: String?
    public var is_kapali: Bool?
    public var message: String?
    
    enum CodingKeys: String, CodingKey {
        case success, fatura_id, id, fatura_uuid, fatura_no, is_kapali, message
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.success = try c.decode(Bool.self, forKey: .success)
        if let intId = try? c.decode(Int.self, forKey: .fatura_id) {
            self.fatura_id = String(intId)
        } else if let strId = try? c.decode(String.self, forKey: .fatura_id) {
            self.fatura_id = strId
        } else if let intId2 = try? c.decode(Int.self, forKey: .id) {
            self.fatura_id = String(intId2)
        } else {
            self.fatura_id = nil
        }
        self.fatura_uuid = try? c.decode(String.self, forKey: .fatura_uuid)
        self.fatura_no = try? c.decode(String.self, forKey: .fatura_no)
        self.is_kapali = try? c.decode(Bool.self, forKey: .is_kapali)
        self.message = try? c.decode(String.self, forKey: .message)
    }
}

public final class TransactionService: @unchecked Sendable {
    public static let shared = TransactionService()
    private init() {}
    
    private func getEvrakNoPrefix(method: String) -> String {
        if method.contains("Kredi") { return "MB-KK-" }
        if method.contains("EFT") || method.contains("Havale") { return "MB-EFT-" }
        if method.contains("Çek") { return "MB-CK-" }
        return "MB-TS-"
    }
    
    // MARK: - Save Financial Transaction (Atomic PostgreSQL RPC: api_save_financial_transaction)
    public func saveFinancialTransaction(req: FinancialTransactionRequest) async throws -> Bool {
        guard req.amount > 0 else { return false }

        let tenantId = SupabaseService.shared.tenantId
        let isOdeme = req.transactionType == "Ödeme" || req.transactionType == "Borç Dekontu" || req.transactionType == "Borçlandır"
        let evrakNo = getEvrakNoPrefix(method: req.method) + AppFormatters.isoDate.string(from: Date()).replacingOccurrences(of: "-", with: "") + "\(Int.random(in: 100...999))"
        let isAcilis = req.isAcilisFisi
        let islemTuru = isAcilis ? "\(req.transactionType) (Açılış Fişi)" : "\(req.transactionType) (\(req.method))"
        let aciklama = isAcilis ? "[Açılış Fişi] \(req.description)".trimmingCharacters(in: .whitespaces) : "[\(req.method)] \(req.description)".trimmingCharacters(in: .whitespaces)
        let activeYearInt = Int(SupabaseService.shared.activeFiscalYear) ?? Calendar.current.component(.year, from: Date())
        let cIdInt = Int(req.cari.id)
        let txUuid = UUID().uuidString.lowercased()

        var cariHareket: [String: Any] = [
            "uuid": txUuid,
            "tenant_id": tenantId,
            "cari_unvan": req.cari.unvan,
            "tarih": req.date,
            "evrak_no": evrakNo,
            "belge_no": evrakNo,
            "islem_turu": islemTuru,
            "hareket_turu": isOdeme ? "Borç" : "Alacak",
            "borc": isOdeme ? req.amount : 0.0,
            "alacak": !isOdeme ? req.amount : 0.0,
            "aciklama": aciklama,
            "mali_yil": activeYearInt
        ]
        if let cid = cIdInt, cid > 0 { cariHareket["cari_id"] = cid }
        if let cuuid = req.cari.syncGuid, !cuuid.isEmpty { cariHareket["cari_uuid"] = cuuid }

        var payload: [String: Any] = [
            "tenant_id": tenantId,
            "idempotency_key": "swift-fin-\(txUuid)",
            "mali_yil": activeYearInt,
            "p_cari_hareket": cariHareket
        ]

        let isDekontOrCek = req.method.localizedCaseInsensitiveContains("dekont") ||
                            req.method.localizedCaseInsensitiveContains("çek") ||
                            req.method.localizedCaseInsensitiveContains("cek") ||
                            req.transactionType.localizedCaseInsensitiveContains("dekont")
        if !isAcilis && !isDekontOrCek, let hesap = req.selectedHesap {
            let isKasa = hesap.hesapTuru == "KASA"
            if isKasa {
                var kh: [String: Any] = [
                    "uuid": UUID().uuidString.lowercased(),
                    "tenant_id": tenantId,
                    "hesap_id": hesap.id,
                    "tarih": req.date,
                    "evrak_no": evrakNo,
                    "belge_no": evrakNo,
                    "islem_turu": isOdeme ? "TEDIYE" : "TAHSILAT",
                    "hareket_turu": isOdeme ? "Çıkış" : "Giriş",
                    "giren": !isOdeme ? req.amount : 0.0,
                    "cikan": isOdeme ? req.amount : 0.0,
                    "gelir": !isOdeme ? req.amount : 0.0,
                    "gider": isOdeme ? req.amount : 0.0,
                    "tutar": req.amount,
                    "cari_unvan": req.cari.unvan,
                    "aciklama": aciklama,
                    "mali_yil": activeYearInt
                ]
                if let kid = Int(hesap.id), kid > 0 { kh["kasa_id"] = kid }
                if let cid = cIdInt, cid > 0 { kh["cari_id"] = cid }
                payload["p_kasa_hareket"] = kh
            } else {
                var bh: [String: Any] = [
                    "uuid": UUID().uuidString.lowercased(),
                    "tenant_id": tenantId,
                    "tarih": req.date,
                    "evrak_no": evrakNo,
                    "belge_no": evrakNo,
                    "islem_turu": isOdeme ? "TEDIYE" : "TAHSILAT",
                    "hareket_turu": isOdeme ? "Çıkış" : "Giriş",
                    "giren": !isOdeme ? req.amount : 0.0,
                    "cikan": isOdeme ? req.amount : 0.0,
                    "yatan": !isOdeme ? req.amount : 0.0,
                    "ceken": isOdeme ? req.amount : 0.0,
                    "tutar": req.amount,
                    "cari_unvan": req.cari.unvan,
                    "aciklama": aciklama,
                    "mali_yil": activeYearInt
                ]
                if let bid = Int(hesap.id), bid > 0 { bh["banka_id"] = bid }
                if let cid = cIdInt, cid > 0 { bh["cari_id"] = cid }
                payload["p_banka_hareket"] = bh
            }
        }

        let res = try await SupabaseService.shared.rpcRaw(
            function: "api_save_financial_transaction",
            params: ["payload": payload]
        )
        if let ok = res["success"] as? Bool, !ok {
            let msg = (res["message"] as? String) ?? "Finansal işlem kaydedilemedi."
            throw NSError(domain: "TransactionService", code: 500, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return true
    }

    // MARK: - Build Atomic Invoice Payload (Direct PostgreSQL)
    public func buildAtomicInvoicePayload(req: InvoiceTransactionRequest) -> (fatura: Fatura, payload: AtomicInvoicePayload) {
        let currentId: Int? = req.id
        let isPaid = req.odemeSekli != "Açık Hesap" && req.durum != "Açık"
        let upperTur = req.tur.uppercased(with: Locale(identifier: "tr_TR"))
        let isIade = upperTur.contains("İADE") || upperTur.contains("IADE")
        let isAlisBase = upperTur.contains("ALIŞ") || upperTur.contains("ALIS")
        let isSatis = !isAlisBase

        let resolvedFaturaTuru: String
        let resolvedTurDisplay: String
        if isSatis && isIade {
            resolvedFaturaTuru = "SATIS_IADE"
            resolvedTurDisplay = "Satış İade"
        } else if !isSatis && isIade {
            resolvedFaturaTuru = "ALIS_IADE"
            resolvedTurDisplay = "Alış İade"
        } else if isSatis {
            resolvedFaturaTuru = "SATIS"
            resolvedTurDisplay = "Satış"
        } else {
            resolvedFaturaTuru = "ALIS"
            resolvedTurDisplay = "Alış"
        }

        let subtotal = req.items.reduce(0.0) { $0 + ($1.miktar * $1.birimFiyat) }
        let totalIskonto = req.items.reduce(0.0) { $0 + $1.iskontoTutari }
        let totalKdv = req.items.reduce(0.0) { $0 + $1.kdvTutari }
        let grandTotal = subtotal - totalIskonto + totalKdv

        let cIdInt = Int(req.cari.id)
        let tenantId = SupabaseService.shared.tenantId
        let invoiceUuid = UUID().uuidString.lowercased()

        let fatura = Fatura(
            id: currentId.map(String.init) ?? invoiceUuid,
            faturaNo: req.faturaNo.hasPrefix("MB-") ? req.faturaNo : "MB-\(req.faturaNo)",
            faturaTuru: resolvedFaturaTuru,
            cariId: req.cari.id,
            cariUnvan: req.cari.unvan,
            tarih: req.tarih,
            vadeTarihi: req.vadeTarihi,
            araToplam: subtotal,
            kdvToplami: totalKdv,
            iskontoToplami: totalIskonto,
            genelToplam: grandTotal,
            odemeDurumu: isPaid ? "ODENDI" : "BEKLIYOR",
            durum: isPaid ? "Kapalı" : req.durum,
            aciklama: req.aciklama,
            kalemler: req.items,
            syncGuid: invoiceUuid,
            tenantId: tenantId
        )

        let kIdInt: Int? = req.kasaId != nil ? Int(req.kasaId!) : nil
        let bIdInt: Int? = req.bankaId != nil ? Int(req.bankaId!) : nil
        let cachedStoklar = MainActor.assumeIsolated { DataStore.shared.stoklar }

        let rpcPayload = AtomicInvoicePayload(
            id: currentId,
            tenant_id: tenantId,
            idempotency_key: "swift-\(invoiceUuid)",
            uuid: invoiceUuid,
            fatura_no: fatura.faturaNo,
            fatura_turu: fatura.faturaTuru,
            tur: resolvedTurDisplay,
            cari_id: cIdInt,
            cari_uuid: req.cari.syncGuid ?? (cIdInt == nil ? req.cari.id : nil),
            cari_unvan: req.cari.unvan,
            tarih: req.tarih,
            vade_tarihi: req.vadeTarihi ?? req.tarih,
            ara_toplam: subtotal,
            iskonto_toplam: totalIskonto,
            kdv_toplam: totalKdv,
            genel_toplam: grandTotal,
            is_kapali: isPaid,
            fatura_tipi: isPaid ? "Kapalı" : "Açık",
            odeme_sekli: req.odemeSekli,
            kasa_id: kIdInt,
            kasa_uuid: req.kasaId,
            banka_id: bIdInt,
            banka_uuid: req.bankaId,
            odenen: isPaid ? grandTotal : 0.0,
            aciklama: req.aciklama,
            cihaz_rolu: "Mobil",
            mali_yil: Int(SupabaseService.shared.activeFiscalYear) ?? Calendar.current.component(.year, from: Date()),
            detaylar: req.items.map { it in
                let sIdInt: Int? = it.stokId != nil ? Int(it.stokId!) : nil
                let resolvedStokUuid = it.stokUuid ?? cachedStoklar.first(where: { $0.id == it.stokId || ($0.stokKodu != nil && $0.stokKodu == it.stokKodu) })?.syncGuid
                var itCopy = it
                if let sUuid = resolvedStokUuid, !sUuid.isEmpty {
                    itCopy.syncGuid = sUuid
                }
                return AtomicFaturaDetayData(
                    uuid: UUID().uuidString.lowercased(),
                    stok_id: sIdInt,
                    stok_uuid: itCopy.syncGuid,
                    stok_kodu: it.stokKodu,
                    stok_adi: it.stokAdi,
                    miktar: it.miktar,
                    birim: it.birim ?? "Adet",
                    birim_fiyat: it.birimFiyat,
                    kdv_orani: it.kdvOrani,
                    kdv_tutari: it.kdvTutari,
                    iskonto_orani: it.iskontoOrani,
                    iskonto_tutari: it.iskontoTutari,
                    toplam_tutar: it.netTutar,
                    net_tutar: it.netTutar
                )
            }
        )
        return (fatura, rpcPayload)
    }

    // MARK: - Save Invoice Transaction (Çift Taraflı Tam Muhasebe Kaydı)
    public func saveInvoiceTransaction(req: InvoiceTransactionRequest) async throws -> Fatura {
        let built = buildAtomicInvoicePayload(req: req)
        let fatura = built.fatura
        let rpcPayload = built.payload

        do {
            let res: AtomicRpcResponse = try await SupabaseService.shared.rpc(
                function: "save_invoice_atomic",
                params: AtomicRpcWrapper(p_payload: rpcPayload)
            )
            if res.success {
                print("[TransactionService] Fatura PostgreSQL atomik RPC ile tek ACID transaction'da kaydedildi.")
                var savedFatura = fatura
                if let fid = res.fatura_id {
                    savedFatura.id = fid
                }
                if let fuuid = res.fatura_uuid {
                    savedFatura.syncGuid = fuuid
                }
                await DataStore.shared.loadFaturalarCacheFirst(forceCloudRefresh: true)
                return savedFatura
            } else {
                let errMsg = res.message ?? "Fatura atomik olarak kaydedilemedi."
                print("[TransactionService] Hata: \(errMsg)")
                throw NSError(domain: "TransactionService", code: 500, userInfo: [NSLocalizedDescriptionKey: errMsg])
            }
        } catch {
            print("[TransactionService] Atomik fatura kaydı başarısız: \(error.localizedDescription)")
            throw error
        }
    }
}
