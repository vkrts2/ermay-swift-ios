import Foundation

public struct StokKart: Identifiable, Codable, Hashable {
    public var id: String
    public var stokKodu: String?
    public var stokAdi: String
    public var barkod: String?
    public var grupAdi: String?
    public var birim: String?
    public var alisFiyati: Double
    public var satisFiyati: Double
    public var kdvOrani: Double
    public var mevcutMiktar: Double
    public var kritikMiktar: Double?
    public var aciklama: String?
    public var aktif: Bool?
    public var syncGuid: String?
    public var tenantId: String?
    
    // Compatibility properties
    public var kategori: String? {
        get { grupAdi }
        set { grupAdi = newValue }
    }
    
    public var minimumSeviye: Double? {
        get { kritikMiktar }
        set { kritikMiktar = newValue }
    }

    public var bakiye: Double {
        get { mevcutMiktar }
        set { mevcutMiktar = newValue }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case stokKodu = "stok_kodu"
        case kod
        case stokAdi = "stok_adi"
        case barkod
        case grupAdi = "grup_adi"
        case grup
        case kategori
        case birim
        case alisFiyati = "alis_fiyati"
        case satisFiyati = "satis_fiyati"
        case kdvOrani = "kdv_orani"
        case kdv
        case mevcutMiktar = "mevcut_miktar"
        case miktar
        case kritikMiktar = "kritik_miktar"
        case kritikStok = "kritik_stok"
        case kritikSeviye = "kritik_seviye"
        case aciklama
        case aktif
        case isActive = "is_active"
        case isDeleted = "is_deleted"
        case syncGuid = "sync_guid"
        case uuid
        case tenantId = "tenant_id"
    }
    
    public init(
        id: String = UUID().uuidString,
        stokKodu: String? = nil,
        stokAdi: String,
        barkod: String? = nil,
        grupAdi: String? = "Genel",
        birim: String? = "Adet",
        alisFiyati: Double = 0.0,
        satisFiyati: Double = 0.0,
        kdvOrani: Double = 20.0,
        mevcutMiktar: Double = 0.0,
        kritikMiktar: Double? = 0.0,
        aciklama: String? = nil,
        aktif: Bool? = true,
        syncGuid: String? = UUID().uuidString,
        tenantId: String? = nil
    ) {
        self.id = id
        self.stokKodu = stokKodu
        self.stokAdi = stokAdi
        self.barkod = barkod
        self.grupAdi = grupAdi
        self.birim = birim
        self.alisFiyati = alisFiyati
        self.satisFiyati = satisFiyati
        self.kdvOrani = kdvOrani
        self.mevcutMiktar = mevcutMiktar
        self.kritikMiktar = kritikMiktar
        self.aciklama = aciklama
        self.aktif = aktif
        self.syncGuid = syncGuid
        self.tenantId = tenantId
    }
    
    // Robust decoding for Supabase
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else if let strId = try? c.decode(String.self, forKey: .id) {
            self.id = strId
        } else {
            self.id = UUID().uuidString
        }
        
        self.stokKodu = (try? c.decode(String.self, forKey: .stokKodu)) ?? (try? c.decode(String.self, forKey: .kod))
        self.stokAdi = (try? c.decode(String.self, forKey: .stokAdi)) ?? ""
        self.barkod = try? c.decode(String.self, forKey: .barkod)
        self.grupAdi = (try? c.decode(String.self, forKey: .grupAdi)) ?? (try? c.decode(String.self, forKey: .grup)) ?? (try? c.decode(String.self, forKey: .kategori))
        self.birim = (try? c.decode(String.self, forKey: .birim)) ?? "Adet"
        
        if let dAlis = try? c.decode(Double.self, forKey: .alisFiyati) {
            self.alisFiyati = dAlis
        } else if let iAlis = try? c.decode(Int.self, forKey: .alisFiyati) {
            self.alisFiyati = Double(iAlis)
        } else {
            self.alisFiyati = 0.0
        }
        
        if let dSatis = try? c.decode(Double.self, forKey: .satisFiyati) {
            self.satisFiyati = dSatis
        } else if let iSatis = try? c.decode(Int.self, forKey: .satisFiyati) {
            self.satisFiyati = Double(iSatis)
        } else {
            self.satisFiyati = 0.0
        }
        
        if let dKdv = try? c.decode(Double.self, forKey: .kdvOrani) {
            self.kdvOrani = dKdv
        } else if let iKdv = try? c.decode(Int.self, forKey: .kdvOrani) {
            self.kdvOrani = Double(iKdv)
        } else if let dKdv2 = try? c.decode(Double.self, forKey: .kdv) {
            self.kdvOrani = dKdv2
        } else if let iKdv2 = try? c.decode(Int.self, forKey: .kdv) {
            self.kdvOrani = Double(iKdv2)
        } else {
            self.kdvOrani = 20.0
        }
        
        if let dMiktar = try? c.decode(Double.self, forKey: .mevcutMiktar) {
            self.mevcutMiktar = dMiktar
        } else if let iMiktar = try? c.decode(Int.self, forKey: .mevcutMiktar) {
            self.mevcutMiktar = Double(iMiktar)
        } else if let dMiktar2 = try? c.decode(Double.self, forKey: .miktar) {
            self.mevcutMiktar = dMiktar2
        } else if let iMiktar2 = try? c.decode(Int.self, forKey: .miktar) {
            self.mevcutMiktar = Double(iMiktar2)
        } else {
            self.mevcutMiktar = 0.0
        }
        
        if let dKritik = try? c.decode(Double.self, forKey: .kritikMiktar) {
            self.kritikMiktar = dKritik
        } else if let dKritik2 = try? c.decode(Double.self, forKey: .kritikStok) {
            self.kritikMiktar = dKritik2
        } else if let dKritik3 = try? c.decode(Double.self, forKey: .kritikSeviye) {
            self.kritikMiktar = dKritik3
        } else {
            self.kritikMiktar = 0.0
        }
        
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        self.aktif = (try? c.decode(Bool.self, forKey: .aktif)) ?? (try? c.decode(Bool.self, forKey: .isActive)) ?? true
        self.syncGuid = (try? c.decode(String.self, forKey: .syncGuid)) ?? (try? c.decode(String.self, forKey: .uuid))
        self.tenantId = try? c.decode(String.self, forKey: .tenantId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let intId = Int(id) {
            try container.encode(intId, forKey: .id)
        }
        let finalUuid = syncGuid ?? (Int(id) == nil ? id : UUID().uuidString)
        try container.encode(finalUuid, forKey: .uuid)
        try container.encode(tenantId ?? SupabaseService.shared.tenantId, forKey: .tenantId)
        try container.encodeIfPresent(stokKodu, forKey: .stokKodu)
        try container.encodeIfPresent(stokKodu, forKey: .kod)
        try container.encode(stokAdi, forKey: .stokAdi)
        try container.encodeIfPresent(barkod, forKey: .barkod)
        try container.encodeIfPresent(grupAdi, forKey: .grupAdi)
        try container.encodeIfPresent(grupAdi, forKey: .kategori)
        try container.encodeIfPresent(birim, forKey: .birim)
        try container.encode(alisFiyati, forKey: .alisFiyati)
        try container.encode(satisFiyati, forKey: .satisFiyati)
        try container.encode(kdvOrani, forKey: .kdvOrani)
        try container.encode(mevcutMiktar, forKey: .mevcutMiktar)
        try container.encodeIfPresent(kritikMiktar, forKey: .kritikMiktar)
        try container.encodeIfPresent(aciklama, forKey: .aciklama)
        try container.encode(aktif ?? true, forKey: .aktif)
        try container.encode(aktif ?? true, forKey: .isActive)
        try container.encode(false, forKey: .isDeleted)
    }
}

public struct StokHareket: Identifiable, Codable, Hashable {
    public var id: String
    public var stokId: String
    public var tarih: String?
    public var islemTuru: String? // "GIRIS", "CIKIS", "DEVIR", "SAYIM_FAZLASI", "SAYIM_EKSIGI"
    public var miktar: Double
    public var birimFiyat: Double
    public var kdvOrani: Double?
    public var belgeNo: String?
    public var aciklama: String?
    public var faturaId: String?
    public var cariId: String?
    public var cariUnvan: String?
    public var syncGuid: String?
    
    public var toplamTutar: Double {
        miktar * birimFiyat
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case stokId = "stok_id"
        case tarih
        case islemTuru = "islem_turu"
        case miktar
        case birimFiyat = "birim_fiyat"
        case kdvOrani = "kdv_orani"
        case belgeNo = "belge_no"
        case evrakNo = "evrak_no"
        case aciklama
        case faturaId = "fatura_id"
        case cariId = "cari_id"
        case cariUnvan = "cari_unvan"
        case syncGuid = "sync_guid"
        case uuid
    }
    
    public init(
        id: String = UUID().uuidString,
        stokId: String = "",
        tarih: String? = nil,
        islemTuru: String? = "GIRIS",
        miktar: Double = 0.0,
        birimFiyat: Double = 0.0,
        toplamTutar: Double? = nil,
        kdvOrani: Double? = 20.0,
        belgeNo: String? = nil,
        aciklama: String? = nil,
        faturaId: String? = nil,
        cariId: String? = nil,
        cariUnvan: String? = nil,
        syncGuid: String? = UUID().uuidString
    ) {
        self.id = id
        self.stokId = stokId
        self.tarih = tarih
        self.islemTuru = islemTuru
        self.miktar = miktar
        self.birimFiyat = birimFiyat
        self.kdvOrani = kdvOrani
        self.belgeNo = belgeNo
        self.aciklama = aciklama
        self.faturaId = faturaId
        self.cariId = cariId
        self.cariUnvan = cariUnvan
        self.syncGuid = syncGuid
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
        
        if let intStokId = try? c.decode(Int.self, forKey: .stokId) {
            self.stokId = String(intStokId)
        } else if let strStokId = try? c.decode(String.self, forKey: .stokId) {
            self.stokId = strStokId
        } else {
            self.stokId = ""
        }
        
        self.tarih = try? c.decode(String.self, forKey: .tarih)
        self.islemTuru = try? c.decode(String.self, forKey: .islemTuru)
        
        if let dMiktar = try? c.decode(Double.self, forKey: .miktar) {
            self.miktar = dMiktar
        } else if let iMiktar = try? c.decode(Int.self, forKey: .miktar) {
            self.miktar = Double(iMiktar)
        } else {
            self.miktar = 0.0
        }
        
        if let dFiyat = try? c.decode(Double.self, forKey: .birimFiyat) {
            self.birimFiyat = dFiyat
        } else if let iFiyat = try? c.decode(Int.self, forKey: .birimFiyat) {
            self.birimFiyat = Double(iFiyat)
        } else {
            self.birimFiyat = 0.0
        }
        
        self.kdvOrani = try? c.decode(Double.self, forKey: .kdvOrani)
        self.belgeNo = (try? c.decode(String.self, forKey: .belgeNo)) ?? (try? c.decode(String.self, forKey: .evrakNo))
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        
        if let intFId = try? c.decode(Int.self, forKey: .faturaId) {
            self.faturaId = String(intFId)
        } else {
            self.faturaId = try? c.decode(String.self, forKey: .faturaId)
        }
        
        if let intCId = try? c.decode(Int.self, forKey: .cariId) {
            self.cariId = String(intCId)
        } else {
            self.cariId = try? c.decode(String.self, forKey: .cariId)
        }
        
        self.cariUnvan = try? c.decode(String.self, forKey: .cariUnvan)
        self.syncGuid = (try? c.decode(String.self, forKey: .syncGuid)) ?? (try? c.decode(String.self, forKey: .uuid))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(stokId, forKey: .stokId)
        try container.encodeIfPresent(tarih, forKey: .tarih)
        try container.encodeIfPresent(islemTuru, forKey: .islemTuru)
        try container.encode(miktar, forKey: .miktar)
        try container.encode(birimFiyat, forKey: .birimFiyat)
        try container.encodeIfPresent(kdvOrani, forKey: .kdvOrani)
        try container.encodeIfPresent(belgeNo, forKey: .belgeNo)
        try container.encodeIfPresent(aciklama, forKey: .aciklama)
        try container.encodeIfPresent(faturaId, forKey: .faturaId)
        try container.encodeIfPresent(cariId, forKey: .cariId)
        try container.encodeIfPresent(cariUnvan, forKey: .cariUnvan)
        try container.encodeIfPresent(syncGuid, forKey: .syncGuid)
    }
}

public struct StokGrup: Identifiable, Codable, Hashable {
    public var id: String
    public var grupAdi: String
    public var aciklama: String?
    
    public init(id: String = UUID().uuidString, grupAdi: String, aciklama: String? = nil) {
        self.id = id
        self.grupAdi = grupAdi
        self.aciklama = aciklama
    }
}

