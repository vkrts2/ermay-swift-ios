import Foundation

public struct Fatura: Identifiable, Codable, Hashable {
    public var id: String
    public var faturaNo: String
    public var faturaTuru: String // "SATIS", "ALIS", "SATIS_IADE", "ALIS_IADE"
    public var cariId: String?
    public var cariUnvan: String?
    public var tarih: String
    public var vadeTarihi: String?
    public var araToplam: Double
    public var kdvToplami: Double
    public var iskontoToplami: Double
    public var genelToplam: Double
    public var tevkifatTutari: Double?
    public var odemeDurumu: String? // "ODENDI", "BEKLIYOR", "PARCIAL"
    public var aciklama: String?
    public var kalemler: [FaturaKalem]?
    public var syncGuid: String?
    public var tenantId: String?
    public var isDeleted: Bool = false
    public var deletedAt: String? = nil
    
    public var idInt: Int? { Int(id) }
    public var uuid: String {
        get { syncGuid ?? (Int(id) == nil ? id : "") }
        set { syncGuid = newValue }
    }

    public var durum: String {
        get { odemeDurumu ?? "Açık" }
        set { odemeDurumu = newValue }
    }
    
    public var isKapali: Bool {
        let d = durum.trimmingCharacters(in: .whitespacesAndNewlines)
        let u = d.uppercased(with: Locale(identifier: "tr_TR"))
        let l = d.lowercased(with: Locale(identifier: "tr_TR"))
        return u == "ODENDI" || u == "ÖDENDİ" || u == "KAPALI" || l == "kapalı" || l == "kapali" || l == "ödendi" || l == "odendi"
    }
    
    public var isKapaliOrPaid: Bool {
        isKapali
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case faturaNo = "fatura_no"
        case faturaTuru = "fatura_turu"
        case cariId = "cari_id"
        case cariUnvan = "cari_unvan"
        case tarih
        case vadeTarihi = "vade_tarihi"
        case araToplam = "ara_toplam"
        case kdvToplami = "kdv_toplami"
        case kdvToplam = "kdv_toplam"
        case iskontoToplami = "iskonto_toplami"
        case iskontoToplam = "iskonto_toplam"
        case genelToplam = "genel_toplam"
        case tevkifatTutari = "tevkifat_tutari"
        case odemeDurumu = "odeme_durumu"
        case aciklama
        case kalemler
        case syncGuid = "sync_guid"
        case uuid
        case tenantId = "tenant_id"
        case isDeleted = "is_deleted"
        case deletedAt = "deleted_at"
    }
    
    public init(
        id: String = UUID().uuidString,
        faturaNo: String = "",
        faturaTuru: String = "SATIS",
        cariId: String? = nil,
        cariUnvan: String? = nil,
        tarih: String = AppFormatters.isoDate.string(from: Date()),
        vadeTarihi: String? = nil,
        araToplam: Double = 0.0,
        kdvToplami: Double = 0.0,
        iskontoToplami: Double = 0.0,
        genelToplam: Double = 0.0,
        tevkifatTutari: Double? = 0.0,
        odemeDurumu: String? = "BEKLIYOR",
        durum: String? = nil,
        aciklama: String? = nil,
        kalemler: [FaturaKalem]? = nil,
        syncGuid: String? = nil,
        tenantId: String? = nil,
        isDeleted: Bool = false,
        deletedAt: String? = nil
    ) {
        self.id = id
        self.faturaNo = faturaNo
        self.faturaTuru = faturaTuru
        self.cariId = cariId
        self.cariUnvan = cariUnvan
        self.tarih = tarih
        self.vadeTarihi = vadeTarihi
        self.araToplam = araToplam
        self.kdvToplami = kdvToplami
        self.iskontoToplami = iskontoToplami
        self.genelToplam = genelToplam
        self.tevkifatTutari = tevkifatTutari
        self.odemeDurumu = durum ?? odemeDurumu
        self.aciklama = aciklama
        self.kalemler = kalemler
        self.syncGuid = syncGuid
        self.tenantId = tenantId
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
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
        
        self.faturaNo = (try? c.decode(String.self, forKey: .faturaNo)) ?? ""
        self.faturaTuru = (try? c.decode(String.self, forKey: .faturaTuru)) ?? "SATIS"
        
        if let intCariId = try? c.decode(Int.self, forKey: .cariId) {
            self.cariId = String(intCariId)
        } else {
            self.cariId = try? c.decode(String.self, forKey: .cariId)
        }
        
        self.cariUnvan = try? c.decode(String.self, forKey: .cariUnvan)
        self.tarih = (try? c.decode(String.self, forKey: .tarih)) ?? ""
        self.vadeTarihi = try? c.decode(String.self, forKey: .vadeTarihi)
        
        if let dAra = try? c.decode(Double.self, forKey: .araToplam) {
            self.araToplam = dAra
        } else if let iAra = try? c.decode(Int.self, forKey: .araToplam) {
            self.araToplam = Double(iAra)
        } else {
            self.araToplam = 0.0
        }
        
        if let dKdv = try? c.decode(Double.self, forKey: .kdvToplami) {
            self.kdvToplami = dKdv
        } else if let dKdv2 = try? c.decode(Double.self, forKey: .kdvToplam) {
            self.kdvToplami = dKdv2
        } else if let iKdv = try? c.decode(Int.self, forKey: .kdvToplami) {
            self.kdvToplami = Double(iKdv)
        } else if let iKdv2 = try? c.decode(Int.self, forKey: .kdvToplam) {
            self.kdvToplami = Double(iKdv2)
        } else {
            self.kdvToplami = 0.0
        }
        
        if let dIsk = try? c.decode(Double.self, forKey: .iskontoToplami) {
            self.iskontoToplami = dIsk
        } else if let dIsk2 = try? c.decode(Double.self, forKey: .iskontoToplam) {
            self.iskontoToplami = dIsk2
        } else if let iIsk = try? c.decode(Int.self, forKey: .iskontoToplami) {
            self.iskontoToplami = Double(iIsk)
        } else {
            self.iskontoToplami = 0.0
        }
        
        if let dGen = try? c.decode(Double.self, forKey: .genelToplam) {
            self.genelToplam = dGen
        } else if let iGen = try? c.decode(Int.self, forKey: .genelToplam) {
            self.genelToplam = Double(iGen)
        } else {
            self.genelToplam = 0.0
        }
        
        self.tevkifatTutari = try? c.decode(Double.self, forKey: .tevkifatTutari)
        self.odemeDurumu = try? c.decode(String.self, forKey: .odemeDurumu)
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        self.kalemler = try? c.decode([FaturaKalem].self, forKey: .kalemler)
        self.syncGuid = (try? c.decode(String.self, forKey: .syncGuid)) ?? (try? c.decode(String.self, forKey: .uuid))
        self.tenantId = try? c.decode(String.self, forKey: .tenantId)
        self.isDeleted = (try? c.decode(Bool.self, forKey: .isDeleted)) ?? false
        self.deletedAt = try? c.decode(String.self, forKey: .deletedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let intId = Int(id), intId > 0 {
            try container.encode(intId, forKey: .id)
        }
        let finalUuid = syncGuid ?? (Int(id) == nil ? id : UUID().uuidString)
        try container.encode(finalUuid, forKey: .uuid)
        try container.encode(faturaNo, forKey: .faturaNo)
        try container.encode(faturaTuru, forKey: .faturaTuru)
        try container.encodeIfPresent(cariId, forKey: .cariId)
        try container.encodeIfPresent(cariUnvan, forKey: .cariUnvan)
        try container.encode(tarih, forKey: .tarih)
        try container.encodeIfPresent(vadeTarihi, forKey: .vadeTarihi)
        try container.encode(araToplam, forKey: .araToplam)
        try container.encode(kdvToplami, forKey: .kdvToplami)
        try container.encode(iskontoToplami, forKey: .iskontoToplami)
        try container.encode(genelToplam, forKey: .genelToplam)
        try container.encodeIfPresent(tevkifatTutari, forKey: .tevkifatTutari)
        try container.encodeIfPresent(odemeDurumu, forKey: .odemeDurumu)
        try container.encodeIfPresent(aciklama, forKey: .aciklama)
        try container.encodeIfPresent(kalemler, forKey: .kalemler)
        try container.encodeIfPresent(syncGuid, forKey: .syncGuid)
        try container.encodeIfPresent(tenantId, forKey: .tenantId)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)
    }
}

public struct FaturaKalem: Identifiable, Codable, Hashable {
    public var id: String
    public var faturaId: String?
    public var stokId: String?
    public var stokUuid: String?
    public var stokKodu: String?
    public var stokAdi: String
    public var birim: String?
    public var miktar: Double {
        didSet { recalculateTotals() }
    }
    public var birimFiyat: Double {
        didSet { recalculateTotals() }
    }
    public var kdvOrani: Double {
        didSet { recalculateTotals() }
    }
    public var kdvTutari: Double
    public var iskontoOrani: Double {
        didSet { recalculateTotals() }
    }
    public var iskontoTutari: Double
    public var netTutar: Double
    public var aciklama: String?
    public var syncGuid: String?
    
    public mutating func recalculateTotals() {
        let brut = miktar * birimFiyat
        let isk = brut * (iskontoOrani / 100.0)
        let matrah = brut - isk
        let kdv = matrah * (kdvOrani / 100.0)
        self.iskontoTutari = isk
        self.kdvTutari = kdv
        self.netTutar = matrah + kdv
    }
    
    public var toplamTutar: Double {
        get { netTutar }
        set { netTutar = newValue }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case faturaId = "fatura_id"
        case stokId = "stok_id"
        case stokUuid = "stok_uuid"
        case stokKodu = "stok_kodu"
        case stokAdi = "stok_adi"
        case birim
        case miktar
        case birimFiyat = "birim_fiyat"
        case kdvOrani = "kdv_orani"
        case kdvTutari = "kdv_tutari"
        case iskontoOrani = "iskonto_orani"
        case iskontoTutari = "iskonto_tutari"
        case netTutar = "net_tutar"
        case toplamTutar = "toplam_tutar"
        case tutar
        case aciklama
        case syncGuid = "sync_guid"
        case uuid
    }
    
    public init(
        id: String = UUID().uuidString,
        faturaId: String? = nil,
        stokId: String? = nil,
        stokUuid: String? = nil,
        stokKodu: String? = nil,
        stokAdi: String = "",
        birim: String? = "Adet",
        miktar: Double = 1.0,
        birimFiyat: Double = 0.0,
        kdvOrani: Double = 20.0,
        iskontoOrani: Double = 0.0,
        aciklama: String? = nil,
        syncGuid: String? = nil
    ) {
        self.id = id
        self.faturaId = faturaId
        self.stokId = stokId
        self.stokUuid = stokUuid
        self.stokKodu = stokKodu
        self.stokAdi = stokAdi
        self.birim = birim
        self.miktar = miktar
        self.birimFiyat = birimFiyat
        self.kdvOrani = kdvOrani
        self.iskontoOrani = iskontoOrani
        self.aciklama = aciklama
        
        let brüt = miktar * birimFiyat
        let isk = brüt * (iskontoOrani / 100.0)
        let matrah = brüt - isk
        let kdv = matrah * (kdvOrani / 100.0)
        
        self.iskontoTutari = isk
        self.kdvTutari = kdv
        self.netTutar = matrah + kdv
        self.syncGuid = syncGuid ?? UUID().uuidString
    }
    
    // Convenience init with explicit toplamTutar
    public init(
        id: String = UUID().uuidString,
        faturaId: String? = nil,
        stokId: String? = nil,
        stokUuid: String? = nil,
        stokKodu: String? = nil,
        stokAdi: String,
        miktar: Double = 1.0,
        birim: String = "Adet",
        birimFiyat: Double = 0.0,
        kdvOrani: Double = 20.0,
        iskontoOrani: Double = 0.0,
        toplamTutar: Double = 0.0,
        kdvTutari: Double? = nil,
        syncGuid: String? = nil
    ) {
        self.id = id
        self.faturaId = faturaId
        self.stokId = stokId
        self.stokUuid = stokUuid
        self.stokKodu = stokKodu
        self.stokAdi = stokAdi
        self.miktar = miktar
        self.birim = birim
        self.birimFiyat = birimFiyat
        self.kdvOrani = kdvOrani
        self.iskontoOrani = iskontoOrani
        
        let brüt = miktar * birimFiyat
        let isk = brüt * (iskontoOrani / 100.0)
        let matrah = brüt - isk
        let calculatedKdv = matrah * (kdvOrani / 100.0)
        
        self.iskontoTutari = isk
        self.kdvTutari = kdvTutari ?? calculatedKdv
        self.netTutar = toplamTutar > 0 ? toplamTutar : (matrah + self.kdvTutari)
        self.syncGuid = syncGuid ?? UUID().uuidString
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
        
        if let intFId = try? c.decode(Int.self, forKey: .faturaId) {
            self.faturaId = String(intFId)
        } else {
            self.faturaId = try? c.decode(String.self, forKey: .faturaId)
        }
        
        if let intSId = try? c.decode(Int.self, forKey: .stokId) {
            self.stokId = String(intSId)
        } else {
            self.stokId = try? c.decode(String.self, forKey: .stokId)
        }
        
        self.stokUuid = try? c.decode(String.self, forKey: .stokUuid)
        self.stokKodu = try? c.decode(String.self, forKey: .stokKodu)
        self.stokAdi = (try? c.decode(String.self, forKey: .stokAdi)) ?? ""
        self.birim = (try? c.decode(String.self, forKey: .birim)) ?? "Adet"
        
        if let dMiktar = try? c.decode(Double.self, forKey: .miktar) {
            self.miktar = dMiktar
        } else if let iMiktar = try? c.decode(Int.self, forKey: .miktar) {
            self.miktar = Double(iMiktar)
        } else {
            self.miktar = 1.0
        }
        
        if let dFiyat = try? c.decode(Double.self, forKey: .birimFiyat) {
            self.birimFiyat = dFiyat
        } else if let iFiyat = try? c.decode(Int.self, forKey: .birimFiyat) {
            self.birimFiyat = Double(iFiyat)
        } else {
            self.birimFiyat = 0.0
        }
        
        if let dKdv = try? c.decode(Double.self, forKey: .kdvOrani) {
            self.kdvOrani = dKdv
        } else if let iKdv = try? c.decode(Int.self, forKey: .kdvOrani) {
            self.kdvOrani = Double(iKdv)
        } else {
            self.kdvOrani = 20.0
        }
        
        self.iskontoOrani = (try? c.decode(Double.self, forKey: .iskontoOrani)) ?? 0.0
        self.iskontoTutari = (try? c.decode(Double.self, forKey: .iskontoTutari)) ?? ((self.miktar * self.birimFiyat) * (self.iskontoOrani / 100.0))
        self.kdvTutari = (try? c.decode(Double.self, forKey: .kdvTutari)) ?? (((self.miktar * self.birimFiyat) - self.iskontoTutari) * (self.kdvOrani / 100.0))
        
        if let dTop = try? c.decode(Double.self, forKey: .netTutar), dTop > 0 {
            self.netTutar = dTop
        } else if let dTop2 = try? c.decode(Double.self, forKey: .toplamTutar), dTop2 > 0 {
            self.netTutar = dTop2
        } else if let dTop3 = try? c.decode(Double.self, forKey: .tutar), dTop3 > 0 {
            self.netTutar = dTop3
        } else {
            self.netTutar = (self.miktar * self.birimFiyat) - self.iskontoTutari + self.kdvTutari
        }
        
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        self.syncGuid = (try? c.decode(String.self, forKey: .syncGuid)) ?? (try? c.decode(String.self, forKey: .uuid))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let intId = Int(id), intId > 0 {
            try container.encode(intId, forKey: .id)
        }
        let finalUuid = syncGuid ?? (Int(id) == nil ? id : UUID().uuidString)
        try container.encode(finalUuid, forKey: .uuid)
        try container.encodeIfPresent(faturaId, forKey: .faturaId)
        try container.encodeIfPresent(stokId, forKey: .stokId)
        try container.encodeIfPresent(stokUuid, forKey: .stokUuid)
        try container.encodeIfPresent(stokKodu, forKey: .stokKodu)
        try container.encode(stokAdi, forKey: .stokAdi)
        try container.encodeIfPresent(birim, forKey: .birim)
        try container.encode(miktar, forKey: .miktar)
        try container.encode(birimFiyat, forKey: .birimFiyat)
        try container.encode(kdvOrani, forKey: .kdvOrani)
        try container.encode(kdvTutari, forKey: .kdvTutari)
        try container.encode(iskontoOrani, forKey: .iskontoOrani)
        try container.encode(iskontoTutari, forKey: .iskontoTutari)
        try container.encode(netTutar, forKey: .netTutar)
        try container.encode(netTutar, forKey: .toplamTutar)
        try container.encodeIfPresent(aciklama, forKey: .aciklama)
        try container.encodeIfPresent(syncGuid, forKey: .syncGuid)
    }
}
