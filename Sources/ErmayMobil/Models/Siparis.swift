import Foundation

public struct Siparis: Identifiable, Codable, Hashable {
    public var id: String
    public var siparisNo: String
    public var siparisTuru: String // "ALINAN", "VERILEN"
    public var cariId: String?
    public var cariUnvan: String?
    public var tarih: String
    public var teslimTarihi: String?
    public var araToplam: Double
    public var kdvToplami: Double
    public var iskontoToplami: Double
    public var genelToplam: Double
    public var durum: String // "BEKLIYOR", "HAZIRLANIYOR", "SEVK_EDILDI", "TAMAMLANDI", "IPTAL"
    public var aciklama: String?
    public var kalemler: [SiparisKalem]?
    public var syncGuid: String?
    public var tenantId: String?
    
    public var idInt: Int? { Int(id) }
    public var uuid: String {
        get { syncGuid ?? (Int(id) == nil ? id : "") }
        set { syncGuid = newValue }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case siparisNo = "siparis_no"
        case siparisTuru = "siparis_turu"
        case cariId = "cari_id"
        case cariUnvan = "cari_unvan"
        case tarih
        case teslimTarihi = "teslim_tarihi"
        case araToplam = "ara_toplam"
        case kdvToplami = "kdv_toplami"
        case kdvToplam = "kdv_toplam"
        case iskontoToplami = "iskonto_toplami"
        case iskontoToplam = "iskonto_toplam"
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
        siparisNo: String = "",
        siparisTuru: String = "ALINAN",
        cariId: String? = nil,
        cariUnvan: String? = nil,
        tarih: String = AppFormatters.isoDate.string(from: Date()),
        teslimTarihi: String? = nil,
        araToplam: Double = 0.0,
        kdvToplami: Double = 0.0,
        iskontoToplami: Double = 0.0,
        genelToplam: Double = 0.0,
        durum: String = "BEKLIYOR",
        aciklama: String? = nil,
        kalemler: [SiparisKalem]? = nil,
        syncGuid: String? = nil,
        tenantId: String? = nil
    ) {
        self.id = id
        self.siparisNo = siparisNo
        self.siparisTuru = siparisTuru
        self.cariId = cariId
        self.cariUnvan = cariUnvan
        self.tarih = tarih
        self.teslimTarihi = teslimTarihi
        self.araToplam = araToplam
        self.kdvToplami = kdvToplami
        self.iskontoToplami = iskontoToplami
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
        
        self.siparisNo = (try? c.decode(String.self, forKey: .siparisNo)) ?? ""
        self.siparisTuru = (try? c.decode(String.self, forKey: .siparisTuru)) ?? "ALINAN"
        
        if let intCariId = try? c.decode(Int.self, forKey: .cariId) {
            self.cariId = String(intCariId)
        } else {
            self.cariId = try? c.decode(String.self, forKey: .cariId)
        }
        
        self.cariUnvan = try? c.decode(String.self, forKey: .cariUnvan)
        self.tarih = (try? c.decode(String.self, forKey: .tarih)) ?? ""
        self.teslimTarihi = try? c.decode(String.self, forKey: .teslimTarihi)
        
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
        
        if let dIsk = try? c.decode(Double.self, forKey: .iskontoToplami) {
            self.iskontoToplami = dIsk
        } else if let dIsk2 = try? c.decode(Double.self, forKey: .iskontoToplam) {
            self.iskontoToplami = dIsk2
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
        
        self.durum = (try? c.decode(String.self, forKey: .durum)) ?? "BEKLIYOR"
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        self.kalemler = try? c.decode([SiparisKalem].self, forKey: .kalemler)
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
        try container.encode(siparisNo, forKey: .siparisNo)
        try container.encode(siparisTuru, forKey: .siparisTuru)
        try container.encodeIfPresent(cariId, forKey: .cariId)
        try container.encodeIfPresent(cariUnvan, forKey: .cariUnvan)
        try container.encode(tarih, forKey: .tarih)
        try container.encodeIfPresent(teslimTarihi, forKey: .teslimTarihi)
        try container.encode(araToplam, forKey: .araToplam)
        try container.encode(kdvToplami, forKey: .kdvToplami)
        try container.encode(iskontoToplami, forKey: .iskontoToplami)
        try container.encode(genelToplam, forKey: .genelToplam)
        try container.encode(durum, forKey: .durum)
        try container.encodeIfPresent(aciklama, forKey: .aciklama)
        try container.encodeIfPresent(kalemler, forKey: .kalemler)
        try container.encodeIfPresent(syncGuid, forKey: .syncGuid)
        try container.encodeIfPresent(tenantId, forKey: .tenantId)
    }
}

public struct SiparisKalem: Identifiable, Codable, Hashable {
    public var id: String
    public var siparisId: String?
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
        case siparisId = "siparis_id"
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
        siparisId: String? = nil,
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
        self.siparisId = siparisId
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
        
        if let intSId = try? c.decode(Int.self, forKey: .siparisId) {
            self.siparisId = String(intSId)
        } else {
            self.siparisId = try? c.decode(String.self, forKey: .siparisId)
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
        try container.encodeIfPresent(siparisId, forKey: .siparisId)
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
