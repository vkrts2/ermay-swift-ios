import Foundation

public struct CariKart: Identifiable, Codable, Hashable {
    public var id: String
    public var cariKodu: String?
    public var unvan: String
    public var cariTuru: String? // "MUSTERI", "TEDARIKCI", "DIGER"
    public var yetkili: String?
    public var grup: String?
    public var vergiDairesi: String?
    public var vergiNo: String?
    public var tcKimlikNo: String?
    public var telefon: String?
    public var gsm: String?
    public var email: String?
    public var webSitesi: String?
    public var adres: String?
    public var sehir: String?
    public var ilce: String?
    public var bakiye: Double
    public var bakiyeTuru: String? // "B" (Borçlu) veya "A" (Alacaklı)
    public var riskLimiti: Double?
    public var vadeGunu: Int?
    public var islemTarihi: String?
    public var olusturmaTarihi: String?
    public var aktif: Bool?
    public var syncGuid: String?
    public var tenantId: String?
    public var sevkAdresi: String?
    public var odemePlani: String?
    public var ticaretSicilNo: String?
    public var iban: String?
    
    public var grupAdi: String? {
        get { grup }
        set { grup = newValue }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case cariKodu = "cari_kodu"
        case kod
        case unvan
        case yetkiliKisi = "yetkili_kisi"
        case grup
        case vergiDairesi = "vergi_dairesi"
        case vergiNo = "vergi_no"
        case tcKimlikNo = "tc_kimlik_no"
        case telefon
        case telefon2
        case gsm
        case email
        case eposta
        case webSitesi = "web_sitesi"
        case adres
        case sehir
        case il
        case ilce
        case bakiye
        case bakiyeTuru = "bakiye_turu"
        case krediLimiti = "kredi_limiti"
        case riskLimiti = "risk_limiti"
        case vadeGun = "vade_gun"
        case vadeGunu = "vade_gunu"
        case notlar
        case isActive = "is_active"
        case isDeleted = "is_deleted"
        case syncGuid = "sync_guid"
        case uuid
        case tenantId = "tenant_id"
    }
    
    public init(
        id: String = UUID().uuidString,
        cariKodu: String? = nil,
        unvan: String,
        cariTuru: String? = "Müşteri",
        yetkili: String? = nil,
        grup: String? = "Müşteri",
        vergiDairesi: String? = nil,
        vergiNo: String? = nil,
        tcKimlikNo: String? = nil,
        telefon: String? = nil,
        gsm: String? = nil,
        email: String? = nil,
        webSitesi: String? = nil,
        adres: String? = nil,
        sevkAdresi: String? = nil,
        sehir: String? = nil,
        ilce: String? = nil,
        bakiye: Double = 0.0,
        bakiyeTuru: String? = "A",
        riskLimiti: Double? = nil,
        vadeGunu: Int? = 30,
        odemePlani: String? = nil,
        ticaretSicilNo: String? = nil,
        iban: String? = nil,
        islemTarihi: String? = nil,
        olusturmaTarihi: String? = nil,
        aktif: Bool? = true,
        syncGuid: String? = UUID().uuidString,
        tenantId: String? = nil
    ) {
        self.id = id
        self.cariKodu = cariKodu
        self.unvan = unvan
        self.cariTuru = cariTuru
        self.yetkili = yetkili
        self.grup = grup
        self.vergiDairesi = vergiDairesi
        self.vergiNo = vergiNo
        self.tcKimlikNo = tcKimlikNo
        self.telefon = telefon
        self.gsm = gsm
        self.email = email
        self.webSitesi = webSitesi
        self.adres = adres
        self.sevkAdresi = sevkAdresi
        self.sehir = sehir
        self.ilce = ilce
        self.bakiye = bakiye
        self.bakiyeTuru = bakiyeTuru
        self.riskLimiti = riskLimiti
        self.vadeGunu = vadeGunu
        self.odemePlani = odemePlani
        self.ticaretSicilNo = ticaretSicilNo
        self.iban = iban
        self.islemTarihi = islemTarihi
        self.olusturmaTarihi = olusturmaTarihi
        self.aktif = aktif
        self.syncGuid = syncGuid
        self.tenantId = tenantId
    }
    
    // Robust decoding for Supabase Int/String PK and alias tolerance
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        // id decoding (Int or String)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else if let strId = try? c.decode(String.self, forKey: .id) {
            self.id = strId
        } else {
            self.id = UUID().uuidString
        }
        
        // unvan
        self.unvan = (try? c.decode(String.self, forKey: .unvan)) ?? ""
        
        // cari_kodu or kod
        self.cariKodu = (try? c.decode(String.self, forKey: .cariKodu)) ?? (try? c.decode(String.self, forKey: .kod))
        
        self.cariTuru = (try? c.decode(String.self, forKey: .grup)) ?? "Müşteri"
        self.yetkili = try? c.decode(String.self, forKey: .yetkiliKisi)
        self.grup = (try? c.decode(String.self, forKey: .grup)) ?? "Müşteri"
        self.vergiDairesi = try? c.decode(String.self, forKey: .vergiDairesi)
        self.vergiNo = try? c.decode(String.self, forKey: .vergiNo)
        self.tcKimlikNo = try? c.decode(String.self, forKey: .tcKimlikNo)
        self.telefon = try? c.decode(String.self, forKey: .telefon)
        self.gsm = (try? c.decode(String.self, forKey: .telefon2)) ?? (try? c.decode(String.self, forKey: .gsm))
        self.email = (try? c.decode(String.self, forKey: .email)) ?? (try? c.decode(String.self, forKey: .eposta))
        self.webSitesi = try? c.decode(String.self, forKey: .webSitesi)
        self.adres = try? c.decode(String.self, forKey: .adres)
        self.sevkAdresi = nil
        self.sehir = (try? c.decode(String.self, forKey: .sehir)) ?? (try? c.decode(String.self, forKey: .il))
        self.ilce = try? c.decode(String.self, forKey: .ilce)
        
        // bakiye
        if let dVal = try? c.decode(Double.self, forKey: .bakiye) {
            self.bakiye = dVal
        } else if let iVal = try? c.decode(Int.self, forKey: .bakiye) {
            self.bakiye = Double(iVal)
        } else if let sVal = try? c.decode(String.self, forKey: .bakiye), let p = Double(sVal) {
            self.bakiye = p
        } else {
            self.bakiye = 0.0
        }
        
        self.bakiyeTuru = (try? c.decode(String.self, forKey: .bakiyeTuru)) ?? (self.bakiye >= 0 ? "A" : "B")
        
        if let rVal = try? c.decode(Double.self, forKey: .krediLimiti) {
            self.riskLimiti = rVal
        } else if let rVal2 = try? c.decode(Double.self, forKey: .riskLimiti) {
            self.riskLimiti = rVal2
        } else {
            self.riskLimiti = nil
        }
        
        self.vadeGunu = (try? c.decode(Int.self, forKey: .vadeGun)) ?? (try? c.decode(Int.self, forKey: .vadeGunu))
        self.odemePlani = nil
        self.ticaretSicilNo = nil
        self.iban = nil
        self.islemTarihi = nil
        self.olusturmaTarihi = nil
        self.aktif = (try? c.decode(Bool.self, forKey: .isActive)) ?? true
        self.syncGuid = (try? c.decode(String.self, forKey: .uuid)) ?? (try? c.decode(String.self, forKey: .syncGuid))
        self.tenantId = try? c.decode(String.self, forKey: .tenantId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let intId = Int(id), intId > 0 {
            try container.encode(intId, forKey: .id)
        }
        let finalUuid = syncGuid ?? (Int(id) == nil ? id : UUID().uuidString)
        try container.encode(finalUuid, forKey: .uuid)
        try container.encode(tenantId ?? SupabaseService.shared.tenantId, forKey: .tenantId)
        try container.encodeIfPresent(cariKodu, forKey: .cariKodu)
        try container.encodeIfPresent(cariKodu, forKey: .kod)
        try container.encode(unvan, forKey: .unvan)
        try container.encode(grup ?? cariTuru ?? "Müşteri", forKey: .grup)
        try container.encodeIfPresent(yetkili, forKey: .yetkiliKisi)
        try container.encodeIfPresent(vergiDairesi, forKey: .vergiDairesi)
        try container.encodeIfPresent(vergiNo, forKey: .vergiNo)
        try container.encodeIfPresent(tcKimlikNo, forKey: .tcKimlikNo)
        try container.encodeIfPresent(telefon, forKey: .telefon)
        try container.encodeIfPresent(gsm ?? telefon, forKey: .telefon2)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(email, forKey: .eposta)
        try container.encodeIfPresent(webSitesi, forKey: .webSitesi)
        try container.encodeIfPresent(adres, forKey: .adres)
        try container.encodeIfPresent(sehir, forKey: .sehir)
        try container.encodeIfPresent(sehir, forKey: .il)
        try container.encodeIfPresent(ilce, forKey: .ilce)
        try container.encode(bakiye, forKey: .bakiye)
        try container.encode(bakiyeTuru ?? (bakiye >= 0 ? "A" : "B"), forKey: .bakiyeTuru)
        if let r = riskLimiti {
            try container.encode(r, forKey: .krediLimiti)
        }
        if let v = vadeGunu {
            try container.encode(v, forKey: .vadeGun)
        }
        try container.encode(aktif ?? true, forKey: .isActive)
        try container.encode(false, forKey: .isDeleted)
    }
}

public struct CariBakiyeUpdate: Codable {
    public var bakiye: Double
    public var bakiye_turu: String
    
    public init(bakiye: Double, bakiyeTuru: String) {
        self.bakiye = bakiye
        self.bakiye_turu = bakiyeTuru
    }
}

public struct CariHareket: Identifiable, Codable, Hashable {
    public var id: String
    public var cariId: String?
    public var tarih: String?
    public var belgeNo: String?
    public var islemTuru: String? // "Fatura", "Tahsilat", "Tediye", "Devir"
    public var aciklama: String?
    public var borc: Double
    public var alacak: Double
    public var bakiye: Double
    public var syncGuid: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case cariId = "cari_id"
        case tarih
        case belgeNo = "belge_no"
        case evrakNo = "evrak_no"
        case islemTuru = "islem_turu"
        case aciklama
        case borc
        case alacak
        case bakiye
        case syncGuid = "sync_guid"
        case uuid
    }
    
    public init(
        id: String = UUID().uuidString,
        cariId: String? = nil,
        tarih: String? = nil,
        belgeNo: String? = nil,
        islemTuru: String? = nil,
        aciklama: String? = nil,
        borc: Double = 0.0,
        alacak: Double = 0.0,
        bakiye: Double = 0.0,
        syncGuid: String? = UUID().uuidString
    ) {
        self.id = id
        self.cariId = cariId
        self.tarih = tarih
        self.belgeNo = belgeNo
        self.islemTuru = islemTuru
        self.aciklama = aciklama
        self.borc = borc
        self.alacak = alacak
        self.bakiye = bakiye
        self.syncGuid = syncGuid
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
        
        if let intCariId = try? c.decode(Int.self, forKey: .cariId) {
            self.cariId = String(intCariId)
        } else if let strCariId = try? c.decode(String.self, forKey: .cariId) {
            self.cariId = strCariId
        } else {
            self.cariId = nil
        }
        
        self.tarih = try? c.decode(String.self, forKey: .tarih)
        self.belgeNo = (try? c.decode(String.self, forKey: .belgeNo)) ?? (try? c.decode(String.self, forKey: .evrakNo))
        self.islemTuru = try? c.decode(String.self, forKey: .islemTuru)
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        
        if let dBorc = try? c.decode(Double.self, forKey: .borc) {
            self.borc = dBorc
        } else if let iBorc = try? c.decode(Int.self, forKey: .borc) {
            self.borc = Double(iBorc)
        } else {
            self.borc = 0.0
        }
        
        if let dAlacak = try? c.decode(Double.self, forKey: .alacak) {
            self.alacak = dAlacak
        } else if let iAlacak = try? c.decode(Int.self, forKey: .alacak) {
            self.alacak = Double(iAlacak)
        } else {
            self.alacak = 0.0
        }
        
        if let dBak = try? c.decode(Double.self, forKey: .bakiye) {
            self.bakiye = dBak
        } else if let iBak = try? c.decode(Int.self, forKey: .bakiye) {
            self.bakiye = Double(iBak)
        } else {
            self.bakiye = 0.0
        }
        
        self.syncGuid = (try? c.decode(String.self, forKey: .syncGuid)) ?? (try? c.decode(String.self, forKey: .uuid))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let intId = Int(id) {
            try container.encode(intId, forKey: .id)
        }
        let finalUuid = syncGuid ?? (Int(id) == nil ? id : UUID().uuidString)
        try container.encode(finalUuid, forKey: .uuid)
        try container.encode(SupabaseService.shared.tenantId, forKey: .syncGuid)
        
        if let cid = cariId, let intCid = Int(cid) {
            try container.encode(intCid, forKey: .cariId)
        }
        try container.encodeIfPresent(tarih, forKey: .tarih)
        try container.encodeIfPresent(belgeNo, forKey: .belgeNo)
        try container.encodeIfPresent(belgeNo, forKey: .evrakNo)
        try container.encodeIfPresent(islemTuru, forKey: .islemTuru)
        try container.encodeIfPresent(aciklama, forKey: .aciklama)
        try container.encode(borc, forKey: .borc)
        try container.encode(alacak, forKey: .alacak)
        try container.encode(bakiye, forKey: .bakiye)
    }
}
