import Foundation

public struct KasaBanka: Identifiable, Codable, Hashable {
    public var id: String
    public var hesapAdi: String
    public var hesapTuru: String // "KASA", "BANKA", "POS"
    public var bankaAdi: String?
    public var subeAdi: String?
    public var hesapNo: String?
    public var iban: String?
    public var dovizCinsi: String?
    public var bakiye: Double
    public var acilisBakiye: Double?
    public var syncGuid: String?
    public var tenantId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case hesapAdi = "hesap_adi"
        case kasaAdi = "kasa_adi"
        case kasaKodu = "kasa_kodu"
        case hesapTuru = "hesap_turu"
        case kartTuru = "kart_turu"
        case bankaAdi = "banka_adi"
        case subeAdi = "sube_adi"
        case hesapNo = "hesap_no"
        case iban
        case dovizCinsi = "doviz_cinsi"
        case paraBirimi = "para_birimi"
        case dovizTuru = "doviz_turu"
        case bakiye
        case guncelBakiye = "guncel_bakiye"
        case acilisBakiye = "acilis_bakiye"
        case acilisBakiyesi = "acilis_bakiyesi"
        case syncGuid = "sync_guid"
        case tenantId = "tenant_id"
    }
    
    public init(
        id: String = UUID().uuidString,
        hesapAdi: String,
        hesapTuru: String = "KASA",
        bankaAdi: String? = nil,
        subeAdi: String? = nil,
        hesapNo: String? = nil,
        iban: String? = nil,
        dovizCinsi: String? = "TRY",
        bakiye: Double = 0.0,
        acilisBakiye: Double? = nil,
        syncGuid: String? = UUID().uuidString,
        tenantId: String? = nil
    ) {
        self.id = id
        self.hesapAdi = hesapAdi
        self.hesapTuru = hesapTuru
        self.bankaAdi = bankaAdi
        self.subeAdi = subeAdi
        self.hesapNo = hesapNo
        self.iban = iban
        self.dovizCinsi = dovizCinsi
        self.bakiye = bakiye
        self.acilisBakiye = acilisBakiye ?? bakiye
        self.syncGuid = syncGuid
        self.tenantId = tenantId
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else if let strId = try? c.decode(String.self, forKey: .id) {
            self.id = strId
        } else {
            self.id = UUID().uuidString
        }
        
        let kAdi = try? c.decode(String.self, forKey: .kasaAdi)
        let hAdi = try? c.decode(String.self, forKey: .hesapAdi)
        let bAdi = try? c.decode(String.self, forKey: .bankaAdi)
        self.hesapAdi = kAdi ?? hAdi ?? bAdi ?? "Merkez Kasa"
        self.bankaAdi = bAdi ?? kAdi ?? hAdi
        self.hesapTuru = (try? c.decode(String.self, forKey: .hesapTuru)) ?? (try? c.decode(String.self, forKey: .kartTuru)) ?? (bAdi != nil && kAdi == nil ? "BANKA" : "KASA")
        self.subeAdi = try? c.decode(String.self, forKey: .subeAdi)
        self.hesapNo = (try? c.decode(String.self, forKey: .hesapNo)) ?? (try? c.decode(String.self, forKey: .kasaKodu))
        self.iban = try? c.decode(String.self, forKey: .iban)
        self.dovizCinsi = (try? c.decode(String.self, forKey: .paraBirimi)) ?? (try? c.decode(String.self, forKey: .dovizTuru)) ?? (try? c.decode(String.self, forKey: .dovizCinsi)) ?? "TRY"
        
        let decodedAcilis = (try? c.decode(Double.self, forKey: .acilisBakiye)) ?? (try? c.decode(Double.self, forKey: .acilisBakiyesi))
        self.acilisBakiye = decodedAcilis
        
        if let b = try? c.decode(Double.self, forKey: .bakiye), b != 0 {
            self.bakiye = b
        } else if let gb = try? c.decode(Double.self, forKey: .guncelBakiye) {
            self.bakiye = gb
        } else if let b = try? c.decode(Double.self, forKey: .bakiye) {
            self.bakiye = b
        } else if let ab = decodedAcilis {
            self.bakiye = ab
        } else {
            self.bakiye = 0.0
        }
        
        self.syncGuid = (try? c.decode(String.self, forKey: .uuid)) ?? (try? c.decode(String.self, forKey: .syncGuid))
        self.tenantId = try? c.decode(String.self, forKey: .tenantId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let intId = Int(id), intId > 0 {
            try c.encode(intId, forKey: .id)
        }
        let finalUuid = syncGuid ?? (Int(id) == nil && !id.isEmpty ? id : UUID().uuidString)
        try c.encode(finalUuid, forKey: .uuid)
        try c.encode(hesapAdi, forKey: .kasaAdi)
        try c.encodeIfPresent(dovizCinsi, forKey: .paraBirimi)
        try c.encode(bakiye, forKey: .bakiye)
        try c.encode(bakiye, forKey: .guncelBakiye)
        let resolvedAcilis = acilisBakiye ?? bakiye
        try c.encode(resolvedAcilis, forKey: .acilisBakiye)
        try c.encode(resolvedAcilis, forKey: .acilisBakiyesi)
        try c.encode(tenantId ?? SupabaseService.shared.currentTenantId, forKey: .tenantId)
    }
}

public struct KasaHareket: Identifiable, Codable, Hashable {
    public var id: Int?
    public var uuid: String
    public var hesapId: String?
    public var tarih: String
    public var islemTuru: String // "TAHSILAT", "TEDIYE", "VIRMAN"
    public var cariId: String?
    public var cariUnvan: String?
    public var belgeNo: String?
    public var giren: Double = 0.0
    public var cikan: Double = 0.0
    public var tutar: Double
    public var aciklama: String?
    public var yonlendirilenCariId: Int? = nil
    public var yonlendirilenCariUnvan: String? = nil
    public var syncGuid: String?
    public var tenantId: String?
    public var maliYil: Int? = nil
    
    // M-02 UYUMLULUK ALIAS'LARI (PostgreSQL & Desktop Eşleştirmesi):
    public var kasaId: String? {
        get { hesapId }
        set { hesapId = newValue }
    }
    public var evrakNo: String? {
        get { belgeNo }
        set { belgeNo = newValue }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case kasaId = "kasa_id"
        case evrakNo = "evrak_no"
        case hesapId = "hesap_id"
        case belgeNo = "belge_no"
        case tarih
        case islemTuru = "islem_turu"
        case hareketTuru = "hareket_turu"
        case cariId = "cari_id"
        case cariUnvan = "cari_unvan"
        case giren
        case cikan
        case gelir
        case gider
        case tutar
        case aciklama
        case yonlendirilenCariId = "yonlendirilen_cari_id"
        case yonlendirilenCariUnvan = "yonlendirilen_cari_unvan"
        case syncGuid = "sync_guid"
        case tenantId = "tenant_id"
        case maliYil = "mali_yil"
    }
    
    public init(
        id: Int? = nil,
        uuid: String = UUID().uuidString,
        hesapId: String? = nil,
        tarih: String = AppFormatters.isoDate.string(from: Date()),
        islemTuru: String = "TAHSILAT",
        cariId: String? = nil,
        cariUnvan: String? = nil,
        belgeNo: String? = nil,
        giren: Double? = nil,
        cikan: Double? = nil,
        tutar: Double = 0.0,
        aciklama: String? = nil,
        syncGuid: String? = nil,
        tenantId: String? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.hesapId = hesapId
        self.tarih = tarih
        self.islemTuru = islemTuru
        self.cariId = cariId
        self.cariUnvan = cariUnvan
        self.belgeNo = belgeNo
        let upper = islemTuru.uppercased()
        let isOut = upper.contains("ÖDEME") || upper.contains("ODEME") || upper.contains("TEDİYE") || upper.contains("TEDIYE") || upper.contains("ÇIKIŞ") || upper.contains("CIKIS")
        self.giren = giren ?? (isOut ? 0.0 : tutar)
        self.cikan = cikan ?? (isOut ? tutar : 0.0)
        self.tutar = tutar != 0 ? tutar : max(self.giren, self.cikan)
        self.aciklama = aciklama
        self.syncGuid = syncGuid ?? uuid
        self.tenantId = tenantId
    }

    public init(
        id: String,
        hesapId: String? = nil,
        tarih: String = AppFormatters.isoDate.string(from: Date()),
        islemTuru: String = "TAHSILAT",
        cariId: String? = nil,
        cariUnvan: String? = nil,
        belgeNo: String? = nil,
        giren: Double? = nil,
        cikan: Double? = nil,
        tutar: Double = 0.0,
        aciklama: String? = nil,
        syncGuid: String? = nil,
        tenantId: String? = nil
    ) {
        self.id = Int(id)
        self.uuid = Int(id) == nil ? id : (syncGuid ?? UUID().uuidString)
        self.hesapId = hesapId
        self.tarih = tarih
        self.islemTuru = islemTuru
        self.cariId = cariId
        self.cariUnvan = cariUnvan
        self.belgeNo = belgeNo
        let upper = islemTuru.uppercased()
        let isOut = upper.contains("ÖDEME") || upper.contains("ODEME") || upper.contains("TEDİYE") || upper.contains("TEDIYE") || upper.contains("ÇIKIŞ") || upper.contains("CIKIS")
        self.giren = giren ?? (isOut ? 0.0 : tutar)
        self.cikan = cikan ?? (isOut ? tutar : 0.0)
        self.tutar = tutar != 0 ? tutar : max(self.giren, self.cikan)
        self.aciklama = aciklama
        self.syncGuid = syncGuid ?? self.uuid
        self.tenantId = tenantId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = intId
        } else if let strId = try? c.decode(String.self, forKey: .id), let intVal = Int(strId) {
            self.id = intVal
        } else {
            self.id = nil
        }
        self.uuid = (try? c.decode(String.self, forKey: .uuid)) ?? (try? c.decode(String.self, forKey: .syncGuid)) ?? UUID().uuidString
        if let kId = try? c.decode(String.self, forKey: .kasaId) {
            self.hesapId = kId
        } else if let kIntId = try? c.decode(Int.self, forKey: .kasaId) {
            self.hesapId = String(kIntId)
        } else {
            self.hesapId = try? c.decode(String.self, forKey: .hesapId)
        }
        self.tarih = (try? c.decode(String.self, forKey: .tarih)) ?? AppFormatters.isoDate.string(from: Date())
        if let cIntId = try? c.decode(Int.self, forKey: .cariId) {
            self.cariId = String(cIntId)
        } else {
            self.cariId = try? c.decode(String.self, forKey: .cariId)
        }
        self.cariUnvan = try? c.decode(String.self, forKey: .cariUnvan)
        self.belgeNo = (try? c.decode(String.self, forKey: .evrakNo)) ?? (try? c.decode(String.self, forKey: .belgeNo))
        let gVal = (try? c.decode(Double.self, forKey: .giren)) ?? (try? c.decode(Double.self, forKey: .gelir)) ?? 0.0
        let cVal = (try? c.decode(Double.self, forKey: .cikan)) ?? (try? c.decode(Double.self, forKey: .gider)) ?? 0.0
        let tVal = (try? c.decode(Double.self, forKey: .tutar)) ?? 0.0
        let rawTuru = (try? c.decode(String.self, forKey: .islemTuru)) ?? (try? c.decode(String.self, forKey: .hareketTuru)) ?? (cVal > 0 && gVal == 0 ? "Ödeme" : "Tahsilat")
        self.islemTuru = rawTuru
        if gVal == 0 && cVal == 0 && tVal > 0 {
            let upper = rawTuru.uppercased()
            if upper.contains("ÖDEME") || upper.contains("ODEME") || upper.contains("TEDİYE") || upper.contains("TEDIYE") || upper.contains("ÇIKIŞ") || upper.contains("CIKIS") {
                self.giren = 0.0
                self.cikan = tVal
            } else {
                self.giren = tVal
                self.cikan = 0.0
            }
        } else {
            self.giren = gVal
            self.cikan = cVal
        }
        self.tutar = tVal > 0 ? tVal : max(self.giren, self.cikan)
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        self.yonlendirilenCariId = try? c.decode(Int.self, forKey: .yonlendirilenCariId)
        self.yonlendirilenCariUnvan = try? c.decode(String.self, forKey: .yonlendirilenCariUnvan)
        self.syncGuid = (try? c.decode(String.self, forKey: .syncGuid)) ?? self.uuid
        self.tenantId = try? c.decode(String.self, forKey: .tenantId)
        self.maliYil = try? c.decode(Int.self, forKey: .maliYil)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let intId = self.id, intId > 0 {
            try c.encode(intId, forKey: .id)
        }
        try c.encode(uuid, forKey: .uuid)
        if let kid = hesapId {
            if let intKid = Int(kid) {
                try c.encode(intKid, forKey: .kasaId)
            } else {
                try c.encode(kid, forKey: .kasaId)
            }
        }
        try c.encode(tarih, forKey: .tarih)
        try c.encode(islemTuru, forKey: .islemTuru)
        if let cid = cariId, let intCid = Int(cid) {
            try c.encode(intCid, forKey: .cariId)
        }
        try c.encodeIfPresent(cariUnvan, forKey: .cariUnvan)
        try c.encodeIfPresent(belgeNo, forKey: .evrakNo)
        try c.encode(giren, forKey: .giren)
        try c.encode(cikan, forKey: .cikan)
        try c.encode(tutar, forKey: .tutar)
        try c.encodeIfPresent(aciklama, forKey: .aciklama)
        try c.encodeIfPresent(yonlendirilenCariId, forKey: .yonlendirilenCariId)
        try c.encodeIfPresent(yonlendirilenCariUnvan, forKey: .yonlendirilenCariUnvan)
        try c.encodeIfPresent(tenantId ?? SupabaseService.shared.tenantId, forKey: .tenantId)
        let resolvedYear = maliYil ?? Int(SupabaseService.shared.activeFiscalYear) ?? Calendar.current.component(.year, from: Date())
        try c.encode(resolvedYear, forKey: .maliYil)
    }
}

public struct KrediKartiIslem: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var uuid: String
    public var musteriId: Int?
    public var musteriUnvan: String?
    public var yonlendirilenCariId: Int?
    public var yonlendirilenCariUnvan: String?
    public var tarih: String
    public var vadeTarihi: String?
    public var tutar: Double
    public var komisyonOrani: Double
    public var netTutar: Double
    public var banka: String?
    public var kartNo: String?
    public var onayKodu: String?
    public var durum: String?
    public var islemTuru: String?
    public var aciklama: String?
    public var slipDosyaYolu: String?
    public var tenantId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case musteriId = "musteri_id"
        case cariId = "cari_id"
        case musteriUnvan = "musteri_unvan"
        case yonlendirilenCariId = "yonlendirilen_cari_id"
        case yonlendirilenCariUnvan = "yonlendirilen_cari_unvan"
        case tarih
        case vadeTarihi = "vade_tarihi"
        case tutar
        case komisyonOrani = "komisyon_orani"
        case netTutar = "net_tutar"
        case banka
        case kartNo = "kart_no"
        case onayKodu = "onay_kodu"
        case durum
        case islemTuru = "islem_turu"
        case aciklama
        case slipDosyaYolu = "slip_dosya_yolu"
        case tenantId = "tenant_id"
    }
    
    public init(
        id: String = UUID().uuidString,
        uuid: String = UUID().uuidString,
        musteriId: Int? = nil,
        musteriUnvan: String? = nil,
        yonlendirilenCariId: Int? = nil,
        yonlendirilenCariUnvan: String? = nil,
        tarih: String = AppFormatters.isoDate.string(from: Date()),
        vadeTarihi: String? = nil,
        tutar: Double = 0.0,
        komisyonOrani: Double = 0.0,
        netTutar: Double? = nil,
        banka: String? = nil,
        kartNo: String? = nil,
        onayKodu: String? = nil,
        durum: String? = "Portföyde",
        islemTuru: String? = "Tahsilat",
        aciklama: String? = nil,
        slipDosyaYolu: String? = nil,
        tenantId: String? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.musteriId = musteriId
        self.musteriUnvan = musteriUnvan
        self.yonlendirilenCariId = yonlendirilenCariId
        self.yonlendirilenCariUnvan = yonlendirilenCariUnvan
        self.tarih = tarih
        self.vadeTarihi = vadeTarihi
        self.tutar = tutar
        self.komisyonOrani = komisyonOrani
        self.netTutar = netTutar ?? (tutar * (1.0 - komisyonOrani / 100.0))
        self.banka = banka
        self.kartNo = kartNo
        self.onayKodu = onayKodu
        self.durum = durum
        self.islemTuru = islemTuru
        self.aciklama = aciklama
        self.slipDosyaYolu = slipDosyaYolu
        self.tenantId = tenantId
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else if let strId = try? c.decode(String.self, forKey: .id) {
            self.id = strId
        } else {
            self.id = UUID().uuidString
        }
        self.uuid = (try? c.decode(String.self, forKey: .uuid)) ?? UUID().uuidString
        self.musteriId = (try? c.decode(Int.self, forKey: .musteriId)) ?? (try? c.decode(Int.self, forKey: .cariId))
        self.musteriUnvan = try? c.decode(String.self, forKey: .musteriUnvan)
        self.yonlendirilenCariId = try? c.decode(Int.self, forKey: .yonlendirilenCariId)
        self.yonlendirilenCariUnvan = try? c.decode(String.self, forKey: .yonlendirilenCariUnvan)
        self.tarih = (try? c.decode(String.self, forKey: .tarih)) ?? AppFormatters.isoDate.string(from: Date())
        self.vadeTarihi = try? c.decode(String.self, forKey: .vadeTarihi)
        self.tutar = (try? c.decode(Double.self, forKey: .tutar)) ?? 0.0
        self.komisyonOrani = (try? c.decode(Double.self, forKey: .komisyonOrani)) ?? 0.0
        self.netTutar = (try? c.decode(Double.self, forKey: .netTutar)) ?? self.tutar
        self.banka = try? c.decode(String.self, forKey: .banka)
        self.kartNo = try? c.decode(String.self, forKey: .kartNo)
        self.onayKodu = try? c.decode(String.self, forKey: .onayKodu)
        self.durum = (try? c.decode(String.self, forKey: .durum)) ?? "Portföyde"
        self.islemTuru = try? c.decode(String.self, forKey: .islemTuru)
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        self.slipDosyaYolu = try? c.decode(String.self, forKey: .slipDosyaYolu)
        self.tenantId = try? c.decode(String.self, forKey: .tenantId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let intId = Int(id), intId > 0 {
            try c.encode(intId, forKey: .id)
        }
        try c.encode(uuid, forKey: .uuid)
        try c.encodeIfPresent(musteriId, forKey: .musteriId)
        try c.encodeIfPresent(musteriId, forKey: .cariId)
        try c.encodeIfPresent(musteriUnvan, forKey: .musteriUnvan)
        try c.encodeIfPresent(yonlendirilenCariId, forKey: .yonlendirilenCariId)
        try c.encodeIfPresent(yonlendirilenCariUnvan, forKey: .yonlendirilenCariUnvan)
        try c.encode(tarih, forKey: .tarih)
        try c.encodeIfPresent(vadeTarihi, forKey: .vadeTarihi)
        try c.encode(tutar, forKey: .tutar)
        try c.encode(komisyonOrani, forKey: .komisyonOrani)
        try c.encode(netTutar, forKey: .netTutar)
        try c.encodeIfPresent(banka, forKey: .banka)
        try c.encodeIfPresent(kartNo, forKey: .kartNo)
        try c.encodeIfPresent(onayKodu, forKey: .onayKodu)
        try c.encodeIfPresent(durum, forKey: .durum)
        try c.encodeIfPresent(islemTuru, forKey: .islemTuru)
        try c.encodeIfPresent(aciklama, forKey: .aciklama)
        try c.encodeIfPresent(slipDosyaYolu, forKey: .slipDosyaYolu)
        try c.encodeIfPresent(tenantId ?? SupabaseService.shared.tenantId, forKey: .tenantId)
    }
}
