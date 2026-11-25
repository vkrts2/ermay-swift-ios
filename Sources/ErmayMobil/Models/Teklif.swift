import Foundation

public struct Teklif: Identifiable, Codable, Hashable {
    public var id: String
    public var teklifNo: String
    public var cariId: String?
    public var cariUnvan: String?
    public var tarih: String
    public var gecerlilikTarihi: String?
    public var araToplam: Double
    public var kdvToplami: Double
    public var genelToplam: Double
    public var durum: String // "TASLAK", "GONDERILDI", "ONAYLANDI", "REDDEDILDI"
    public var aciklama: String?
    public var kalemler: [TeklifKalem]?
    public var syncGuid: String?
    public var tenantId: String?
    
    public var idInt: Int? { Int(id) }
    public var uuid: String {
        get { syncGuid ?? (Int(id) == nil ? id : "") }
        set { syncGuid = newValue }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case teklifNo = "teklif_no"
        case cariId = "cari_id"
        case cariUnvan = "cari_unvan"
        case tarih
        case gecerlilikTarihi = "gecerlilik_tarihi"
        case araToplam = "ara_toplam"
        case kdvToplami = "kdv_toplami"
        case kdvToplam = "kdv_toplam"
        case genelToplam = "genel_toplam"
        case durum
        case aciklama
        case kalemler
        case syncGuid = "sync_guid"
        case uuid
        case tenantId = "tenant_id"
    }
    
    public init(
        id: String = UUID().uuidString,
        teklifNo: String = "",
        cariId: String? = nil,
        cariUnvan: String? = nil,
        tarih: String = AppFormatters.isoDate.string(from: Date()),
        gecerlilikTarihi: String? = nil,
        araToplam: Double = 0.0,
        kdvToplami: Double = 0.0,
        genelToplam: Double = 0.0,
        durum: String = "TASLAK",
        aciklama: String? = nil,
        kalemler: [TeklifKalem]? = nil,
        syncGuid: String? = nil,
        tenantId: String? = nil
    ) {
        self.id = id
        self.teklifNo = teklifNo
        self.cariId = cariId
        self.cariUnvan = cariUnvan
        self.tarih = tarih
        self.gecerlilikTarihi = gecerlilikTarihi
        self.araToplam = araToplam
        self.kdvToplami = kdvToplami
        self.genelToplam = genelToplam
        self.durum = durum
        self.aciklama = aciklama
        self.kalemler = kalemler
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
        
        self.teklifNo = (try? c.decode(String.self, forKey: .teklifNo)) ?? ""
        
        if let intCariId = try? c.decode(Int.self, forKey: .cariId) {
            self.cariId = String(intCariId)
        } else {
            self.cariId = try? c.decode(String.self, forKey: .cariId)
        }
        
        self.cariUnvan = try? c.decode(String.self, forKey: .cariUnvan)
        self.tarih = (try? c.decode(String.self, forKey: .tarih)) ?? ""
        self.gecerlilikTarihi = try? c.decode(String.self, forKey: .gecerlilikTarihi)
        
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
        } else {
            self.kdvToplami = 0.0
        }
        
        if let dGen = try? c.decode(Double.self, forKey: .genelToplam) {
            self.genelToplam = dGen
        } else if let iGen = try? c.decode(Int.self, forKey: .genelToplam) {
            self.genelToplam = Double(iGen)
        } else {
            self.genelToplam = 0.0
        }
        
        self.durum = (try? c.decode(String.self, forKey: .durum)) ?? "TASLAK"
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        self.kalemler = try? c.decode([TeklifKalem].self, forKey: .kalemler)
        self.syncGuid = (try? c.decode(String.self, forKey: .syncGuid)) ?? (try? c.decode(String.self, forKey: .uuid))
        self.tenantId = try? c.decode(String.self, forKey: .tenantId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let intId = Int(id), intId > 0 {
            try container.encode(intId, forKey: .id)
        }
        let finalUuid = syncGuid ?? (Int(id) == nil ? id : UUID().uuidString)
        try container.encode(finalUuid, forKey: .uuid)
        try container.encode(teklifNo, forKey: .teklifNo)
        try container.encodeIfPresent(cariId, forKey: .cariId)
        try container.encodeIfPresent(cariUnvan, forKey: .cariUnvan)
        try container.encode(tarih, forKey: .tarih)
        try container.encodeIfPresent(gecerlilikTarihi, forKey: .gecerlilikTarihi)
        try container.encode(araToplam, forKey: .araToplam)
        try container.encode(kdvToplami, forKey: .kdvToplami)
        try container.encode(genelToplam, forKey: .genelToplam)
        try container.encode(durum, forKey: .durum)
        try container.encodeIfPresent(aciklama, forKey: .aciklama)
        try container.encodeIfPresent(kalemler, forKey: .kalemler)
        try container.encodeIfPresent(syncGuid, forKey: .syncGuid)
        try container.encodeIfPresent(tenantId, forKey: .tenantId)
    }
}

public struct TeklifKalem: Identifiable, Codable, Hashable {
    public var id: String
    public var teklifId: String?
    public var stokId: String?
    public var stokKodu: String?
    public var stokAdi: String
    public var miktar: Double {
        didSet { tutar = miktar * birimFiyat }
    }
    public var birim: String?
    public var birimFiyat: Double {
        didSet { tutar = miktar * birimFiyat }
    }
    public var kdvOrani: Double
    public var tutar: Double
    public var aciklama: String?
    public var syncGuid: String?
    
    public var toplamTutar: Double {
        get { tutar }
        set { tutar = newValue }
    }
    
    public var idInt: Int? { Int(id) }
    public var uuid: String {
        get { syncGuid ?? (Int(id) == nil ? id : "") }
        set { syncGuid = newValue }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case syncGuid = "sync_guid"
        case teklifId = "teklif_id"
        case stokId = "stok_id"
        case stokKodu = "stok_kodu"
        case stokAdi = "stok_adi"
        case miktar
        case birim
        case birimFiyat = "birim_fiyat"
        case kdvOrani = "kdv_orani"
        case tutar
        case toplamTutar = "toplam_tutar"
        case aciklama
    }
    
    public init(
        id: String = UUID().uuidString,
        teklifId: String? = nil,
        stokId: String? = nil,
        stokKodu: String? = nil,
        stokAdi: String,
        miktar: Double = 1.0,
        birim: String? = "Adet",
        birimFiyat: Double = 0.0,
        kdvOrani: Double = 20.0,
        tutar: Double = 0.0,
        aciklama: String? = nil,
        syncGuid: String? = nil
    ) {
        self.id = id
        self.teklifId = teklifId
        self.stokId = stokId
        self.stokKodu = stokKodu
        self.stokAdi = stokAdi
        self.miktar = miktar
        self.birim = birim ?? "Adet"
        self.birimFiyat = birimFiyat
        self.kdvOrani = kdvOrani
        self.tutar = tutar > 0 ? tutar : (miktar * birimFiyat)
        self.aciklama = aciklama
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
        
        if let intTId = try? c.decode(Int.self, forKey: .teklifId) {
            self.teklifId = String(intTId)
        } else {
            self.teklifId = try? c.decode(String.self, forKey: .teklifId)
        }
        
        if let intStokId = try? c.decode(Int.self, forKey: .stokId) {
            self.stokId = String(intStokId)
        } else {
            self.stokId = try? c.decode(String.self, forKey: .stokId)
        }
        
        self.stokKodu = try? c.decode(String.self, forKey: .stokKodu)
        self.stokAdi = (try? c.decode(String.self, forKey: .stokAdi)) ?? ""
        self.miktar = (try? c.decode(Double.self, forKey: .miktar)) ?? 1.0
        self.birim = (try? c.decode(String.self, forKey: .birim)) ?? "Adet"
        self.birimFiyat = (try? c.decode(Double.self, forKey: .birimFiyat)) ?? 0.0
        self.kdvOrani = (try? c.decode(Double.self, forKey: .kdvOrani)) ?? 20.0
        if let dTutar = try? c.decode(Double.self, forKey: .tutar), dTutar > 0 {
            self.tutar = dTutar
        } else if let dTop = try? c.decode(Double.self, forKey: .toplamTutar), dTop > 0 {
            self.tutar = dTop
        } else {
            self.tutar = self.miktar * self.birimFiyat
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
        try container.encodeIfPresent(teklifId, forKey: .teklifId)
        try container.encodeIfPresent(stokId, forKey: .stokId)
        try container.encodeIfPresent(stokKodu, forKey: .stokKodu)
        try container.encode(stokAdi, forKey: .stokAdi)
        try container.encode(miktar, forKey: .miktar)
        try container.encodeIfPresent(birim, forKey: .birim)
        try container.encode(birimFiyat, forKey: .birimFiyat)
        try container.encode(kdvOrani, forKey: .kdvOrani)
        try container.encode(tutar, forKey: .tutar)
        try container.encodeIfPresent(aciklama, forKey: .aciklama)
    }
}
