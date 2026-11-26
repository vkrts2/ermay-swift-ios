import Foundation

public struct MusteriTakipKlasor: Identifiable, Codable, Hashable {
    public var id: Int
    public var tenantId: String?
    public var cariId: Int
    public var cariUnvan: String
    public var cariKod: String?
    public var telefon: String?
    public var yetkili: String?
    public var etiket: String?
    public var renk: String?
    public var olusturmaTarihi: String
    public var sonIslemTarihi: String
    public var aciklama: String?
    public var isDeleted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case tenantId = "tenant_id"
        case cariId = "cari_id"
        case cariUnvan = "cari_unvan"
        case klasorAdi = "klasor_adi"
        case cariKod = "cari_kod"
        case telefon
        case yetkili
        case etiket
        case renk
        case olusturmaTarihi = "olusturma_tarihi"
        case createdAt = "created_at"
        case sonIslemTarihi = "son_islem_tarihi"
        case updatedAt = "updated_at"
        case aciklama
        case isDeleted = "is_deleted"
    }
    
    public init(
        id: Int,
        tenantId: String? = nil,
        cariId: Int,
        cariUnvan: String,
        cariKod: String? = nil,
        telefon: String? = nil,
        yetkili: String? = nil,
        etiket: String? = "Yeni İletişim",
        renk: String? = "#0A84FF",
        olusturmaTarihi: String = ISO8601DateFormatter().string(from: Date()),
        sonIslemTarihi: String = ISO8601DateFormatter().string(from: Date()),
        aciklama: String? = nil,
        isDeleted: Bool? = false
    ) {
        self.id = id
        self.tenantId = tenantId
        self.cariId = cariId
        self.cariUnvan = cariUnvan
        self.cariKod = cariKod
        self.telefon = telefon
        self.yetkili = yetkili
        self.etiket = etiket
        self.renk = renk
        self.olusturmaTarihi = olusturmaTarihi
        self.sonIslemTarihi = sonIslemTarihi
        self.aciklama = aciklama
        self.isDeleted = isDeleted
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = intId
        } else if let strId = try? c.decode(String.self, forKey: .id), let intVal = Int(strId) {
            self.id = intVal
        } else {
            self.id = Int.random(in: 1...999999)
        }
        self.tenantId = try? c.decode(String.self, forKey: .tenantId)
        if let intCid = try? c.decode(Int.self, forKey: .cariId) {
            self.cariId = intCid
        } else if let strCid = try? c.decode(String.self, forKey: .cariId), let intVal = Int(strCid) {
            self.cariId = intVal
        } else {
            self.cariId = 0
        }
        self.cariUnvan = (try? c.decode(String.self, forKey: .cariUnvan)) ?? (try? c.decode(String.self, forKey: .klasorAdi)) ?? ""
        self.cariKod = try? c.decode(String.self, forKey: .cariKod)
        self.telefon = try? c.decode(String.self, forKey: .telefon)
        self.yetkili = try? c.decode(String.self, forKey: .yetkili)
        self.etiket = (try? c.decode(String.self, forKey: .etiket)) ?? "Yeni İletişim"
        self.renk = (try? c.decode(String.self, forKey: .renk)) ?? "#0A84FF"
        let nowIso = ISO8601DateFormatter().string(from: Date())
        self.olusturmaTarihi = (try? c.decode(String.self, forKey: .olusturmaTarihi)) ?? (try? c.decode(String.self, forKey: .createdAt)) ?? nowIso
        self.sonIslemTarihi = (try? c.decode(String.self, forKey: .sonIslemTarihi)) ?? (try? c.decode(String.self, forKey: .updatedAt)) ?? self.olusturmaTarihi
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        self.isDeleted = (try? c.decode(Bool.self, forKey: .isDeleted)) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(tenantId ?? SupabaseService.shared.tenantId, forKey: .tenantId)
        try c.encode(cariId, forKey: .cariId)
        try c.encode(cariUnvan, forKey: .cariUnvan)
        try c.encode(cariUnvan, forKey: .klasorAdi)
        try c.encodeIfPresent(cariKod, forKey: .cariKod)
        try c.encodeIfPresent(telefon, forKey: .telefon)
        try c.encodeIfPresent(yetkili, forKey: .yetkili)
        try c.encodeIfPresent(etiket, forKey: .etiket)
        try c.encodeIfPresent(renk, forKey: .renk)
        try c.encode(sonIslemTarihi, forKey: .sonIslemTarihi)
        try c.encodeIfPresent(aciklama, forKey: .aciklama)
        try c.encodeIfPresent(isDeleted, forKey: .isDeleted)
    }
}

public struct MusteriTakipDetay: Identifiable, Codable, Hashable {
    public var id: Int
    public var tenantId: String?
    public var klasorId: Int
    public var cariId: Int
    public var baslik: String
    public var icerik: String?
    public var tip: String // "Gorusme" | "Fiyat" | "Gorsel" | "Not"
    public var fiyatBilgisi: Double?
    public var paraBirimi: String?
    public var dosyaYolu: String?
    public var gorselBase64: String?
    public var tarih: String
    public var isDeleted: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case tenantId = "tenant_id"
        case klasorId = "klasor_id"
        case cariId = "cari_id"
        case baslik
        case icerik
        case tip
        case fiyatBilgisi = "fiyat_bilgisi"
        case paraBirimi = "para_birimi"
        case dosyaYolu = "dosya_yolu"
        case gorselBase64 = "gorsel_base64"
        case tarih
        case isDeleted = "is_deleted"
    }
    
    public init(
        id: Int,
        tenantId: String? = nil,
        klasorId: Int,
        cariId: Int,
        baslik: String,
        icerik: String? = nil,
        tip: String,
        fiyatBilgisi: Double? = nil,
        paraBirimi: String? = "₺",
        dosyaYolu: String? = nil,
        gorselBase64: String? = nil,
        tarih: String = ISO8601DateFormatter().string(from: Date()),
        isDeleted: Bool? = false
    ) {
        self.id = id
        self.tenantId = tenantId
        self.klasorId = klasorId
        self.cariId = cariId
        self.baslik = baslik
        self.icerik = icerik
        self.tip = tip
        self.fiyatBilgisi = fiyatBilgisi
        self.paraBirimi = paraBirimi
        self.dosyaYolu = dosyaYolu
        self.gorselBase64 = gorselBase64
        self.tarih = tarih
        self.isDeleted = isDeleted
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = intId
        } else if let strId = try? c.decode(String.self, forKey: .id), let intVal = Int(strId) {
            self.id = intVal
        } else {
            self.id = Int.random(in: 1...999999)
        }
        self.tenantId = try? c.decode(String.self, forKey: .tenantId)
        self.klasorId = (try? c.decode(Int.self, forKey: .klasorId)) ?? 0
        self.cariId = (try? c.decode(Int.self, forKey: .cariId)) ?? 0
        self.baslik = (try? c.decode(String.self, forKey: .baslik)) ?? "Kayıt"
        self.icerik = try? c.decode(String.self, forKey: .icerik)
        self.tip = (try? c.decode(String.self, forKey: .tip)) ?? "Not"
        self.fiyatBilgisi = try? c.decode(Double.self, forKey: .fiyatBilgisi)
        self.paraBirimi = (try? c.decode(String.self, forKey: .paraBirimi)) ?? "₺"
        self.dosyaYolu = try? c.decode(String.self, forKey: .dosyaYolu)
        self.gorselBase64 = try? c.decode(String.self, forKey: .gorselBase64)
        self.tarih = (try? c.decode(String.self, forKey: .tarih)) ?? ISO8601DateFormatter().string(from: Date())
        self.isDeleted = (try? c.decode(Bool.self, forKey: .isDeleted)) ?? false
    }
}

// Legacy DTO compatibility
public struct MusteriTakipKayit: Identifiable, Codable, Hashable {
    public var id: String
    public var cariId: String?
    public var cariUnvan: String
    public var gorusmeTarihi: String
    public var gorusmeTuru: String
    public var konu: String
    public var notlar: String?
    public var sonrakiEylem: String?
    public var sonrakiEylemTarihi: String?
    public var lokasyon: String?
    public var personelAdi: String?
    public var durum: String
    public var syncGuid: String?
    public var tenantId: String?
    
    public init(
        id: String,
        cariId: String? = nil,
        cariUnvan: String,
        gorusmeTarihi: String = "",
        gorusmeTuru: String = "ZIYARET",
        konu: String = "",
        notlar: String? = nil,
        sonrakiEylem: String? = nil,
        sonrakiEylemTarihi: String? = nil,
        lokasyon: String? = nil,
        personelAdi: String? = nil,
        durum: String = "PLANLANDI",
        syncGuid: String? = nil,
        tenantId: String? = nil
    ) {
        self.id = id
        self.cariId = cariId
        self.cariUnvan = cariUnvan
        self.gorusmeTarihi = gorusmeTarihi
        self.gorusmeTuru = gorusmeTuru
        self.konu = konu
        self.notlar = notlar
        self.sonrakiEylem = sonrakiEylem
        self.sonrakiEylemTarihi = sonrakiEylemTarihi
        self.lokasyon = lokasyon
        self.personelAdi = personelAdi
        self.durum = durum
        self.syncGuid = syncGuid
        self.tenantId = tenantId
    }
}

public struct MusteriRisk: Identifiable, Codable, Hashable {
    public var id: String
    public var unvan: String
    public var riskLimiti: Double
    public var guncelBakiye: Double
    
    public var kalanLimit: Double {
        max(0.0, riskLimiti - guncelBakiye)
    }
    
    public var riskSeviyesi: String {
        if riskLimiti > 0 && guncelBakiye > riskLimiti {
            return "LİMİT AŞIMI"
        } else if riskLimiti > 0 && (guncelBakiye / riskLimiti) >= 0.85 {
            return "KRİTİK"
        }
        return "NORMAL"
    }
    
    public init(
        id: String = UUID().uuidString,
        unvan: String,
        riskLimiti: Double,
        guncelBakiye: Double
    ) {
        self.id = id
        self.unvan = unvan
        self.riskLimiti = riskLimiti
        self.guncelBakiye = guncelBakiye
    }
}
