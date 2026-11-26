import Foundation

public struct BankaKart: Identifiable, Codable, Sendable {
    public var id: Int?
    public var uuid: String
    public var bankaAdi: String
    public var subeAdi: String?
    public var subeKodu: String?
    public var hesapNo: String?
    public var iban: String?
    public var dovizTuru: String? // "TL", "USD", "EUR"
    public var yetkili: String?
    public var telefon: String?
    public var bakiye: Double
    public var acilisBakiye: Double?
    public var tenantId: String?
    
    public init(
        id: Int? = nil,
        uuid: String = UUID().uuidString,
        bankaAdi: String,
        subeAdi: String? = nil,
        subeKodu: String? = nil,
        hesapNo: String? = nil,
        iban: String? = nil,
        dovizTuru: String? = "TL",
        yetkili: String? = nil,
        telefon: String? = nil,
        bakiye: Double = 0.0,
        acilisBakiye: Double? = nil,
        tenantId: String? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.bankaAdi = bankaAdi
        self.subeAdi = subeAdi
        self.subeKodu = subeKodu
        self.hesapNo = hesapNo
        self.iban = iban
        self.dovizTuru = dovizTuru
        self.yetkili = yetkili
        self.telefon = telefon
        self.bakiye = bakiye
        self.acilisBakiye = acilisBakiye ?? bakiye
        self.tenantId = tenantId
    }

    public init(
        id: String,
        bankaAdi: String,
        subeAdi: String? = nil,
        subeKodu: String? = nil,
        hesapNo: String? = nil,
        iban: String? = nil,
        dovizTuru: String? = "TL",
        yetkili: String? = nil,
        telefon: String? = nil,
        bakiye: Double = 0.0,
        acilisBakiye: Double? = nil,
        tenantId: String? = nil
    ) {
        self.id = Int(id)
        self.uuid = (Int(id) == nil && !id.isEmpty) ? id : UUID().uuidString
        self.bankaAdi = bankaAdi
        self.subeAdi = subeAdi
        self.subeKodu = subeKodu
        self.hesapNo = hesapNo
        self.iban = iban
        self.dovizTuru = dovizTuru
        self.yetkili = yetkili
        self.telefon = telefon
        self.bakiye = bakiye
        self.acilisBakiye = acilisBakiye ?? bakiye
        self.tenantId = tenantId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case bankaAdi = "banka_adi"
        case subeAdi = "sube_adi"
        case subeKodu = "sube_kodu"
        case hesapNo = "hesap_no"
        case iban
        case dovizTuru = "doviz_turu"
        case paraBirimi = "para_birimi"
        case yetkili
        case telefon
        case bakiye
        case guncelBakiye = "guncel_bakiye"
        case acilisBakiye = "acilis_bakiye"
        case acilisBakiyesi = "acilis_bakiyesi"
        case tenantId = "tenant_id"
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
        self.uuid = (try? c.decode(String.self, forKey: .uuid)) ?? UUID().uuidString
        self.bankaAdi = (try? c.decode(String.self, forKey: .bankaAdi)) ?? ""
        self.subeAdi = try? c.decode(String.self, forKey: .subeAdi)
        self.subeKodu = try? c.decode(String.self, forKey: .subeKodu)
        self.hesapNo = try? c.decode(String.self, forKey: .hesapNo)
        self.iban = try? c.decode(String.self, forKey: .iban)
        self.dovizTuru = (try? c.decode(String.self, forKey: .dovizTuru)) ?? (try? c.decode(String.self, forKey: .paraBirimi)) ?? "TL"
        self.yetkili = try? c.decode(String.self, forKey: .yetkili)
        self.telefon = try? c.decode(String.self, forKey: .telefon)
        let decodedAcilis = (try? c.decode(Double.self, forKey: .acilisBakiye)) ?? (try? c.decode(Double.self, forKey: .acilisBakiyesi))
        self.acilisBakiye = decodedAcilis
        if let b = try? c.decode(Double.self, forKey: .bakiye), b != 0 {
            self.bakiye = b
        } else if let gb = try? c.decode(Double.self, forKey: .guncelBakiye) {
            self.bakiye = gb
        } else if let ab = decodedAcilis {
            self.bakiye = ab
        } else {
            self.bakiye = (try? c.decode(Double.self, forKey: .bakiye)) ?? 0.0
        }
        self.tenantId = try? c.decode(String.self, forKey: .tenantId)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let intId = self.id, intId > 0 {
            try c.encode(intId, forKey: .id)
        }
        try c.encode(uuid.isEmpty ? UUID().uuidString : uuid, forKey: .uuid)
        try c.encode(bankaAdi, forKey: .bankaAdi)
        try c.encodeIfPresent(subeAdi, forKey: .subeAdi)
        try c.encodeIfPresent(subeKodu, forKey: .subeKodu)
        try c.encodeIfPresent(hesapNo, forKey: .hesapNo)
        try c.encodeIfPresent(iban, forKey: .iban)
        try c.encodeIfPresent(dovizTuru, forKey: .dovizTuru)
        try c.encodeIfPresent(dovizTuru, forKey: .paraBirimi)
        try c.encodeIfPresent(yetkili, forKey: .yetkili)
        try c.encodeIfPresent(telefon, forKey: .telefon)
        try c.encode(bakiye, forKey: .bakiye)
        try c.encode(bakiye, forKey: .guncelBakiye)
        let resolvedAcilis = acilisBakiye ?? bakiye
        try c.encode(resolvedAcilis, forKey: .acilisBakiye)
        try c.encode(resolvedAcilis, forKey: .acilisBakiyesi)
        try c.encode(tenantId ?? SupabaseService.shared.currentTenantId, forKey: .tenantId)
    }
}

public struct BankaHareket: Identifiable, Codable, Sendable {
    public var id: Int?
    public var uuid: String
    public var bankaId: String?
    public var bankaAdi: String?
    public var iban: String?
    public var tarih: String
    public var evrakNo: String?
    public var islemTuru: String // "GELEN_HAVALE", "GONDERILEN_EFT", "POS_TAHSILAT", "MASRAF"
    public var aciklama: String?
    public var cariUnvan: String?
    public var tutar: Double
    public var girisCikis: String // "GIRIS", "CIKIS"
    
    public init(
        id: Int? = nil,
        uuid: String = UUID().uuidString,
        bankaId: String? = nil,
        bankaAdi: String? = nil,
        iban: String? = nil,
        tarih: String,
        evrakNo: String? = nil,
        islemTuru: String,
        aciklama: String? = nil,
        cariUnvan: String? = nil,
        tutar: Double,
        girisCikis: String = "GIRIS"
    ) {
        self.id = id
        self.uuid = uuid
        self.bankaId = bankaId
        self.bankaAdi = bankaAdi
        self.iban = iban
        self.tarih = tarih
        self.evrakNo = evrakNo
        self.islemTuru = islemTuru
        self.aciklama = aciklama
        self.cariUnvan = cariUnvan
        self.tutar = tutar
        self.girisCikis = girisCikis
    }

    public init(
        id: String,
        bankaId: String? = nil,
        bankaAdi: String? = nil,
        iban: String? = nil,
        tarih: String,
        evrakNo: String? = nil,
        islemTuru: String,
        aciklama: String? = nil,
        cariUnvan: String? = nil,
        tutar: Double,
        girisCikis: String = "GIRIS"
    ) {
        self.id = Int(id)
        self.uuid = Int(id) == nil ? id : UUID().uuidString
        self.bankaId = bankaId
        self.bankaAdi = bankaAdi
        self.iban = iban
        self.tarih = tarih
        self.evrakNo = evrakNo
        self.islemTuru = islemTuru
        self.aciklama = aciklama
        self.cariUnvan = cariUnvan
        self.tutar = tutar
        self.girisCikis = girisCikis
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case bankaId = "banka_id"
        case bankaAdi = "banka_adi"
        case iban
        case tarih
        case evrakNo = "evrak_no"
        case islemTuru = "islem_turu"
        case aciklama
        case cariUnvan = "cari_unvan"
        case giren
        case cikan
        case yatan
        case ceken
        case tutar
        case girisCikis = "giris_cikis"
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
        self.uuid = (try? c.decode(String.self, forKey: .uuid)) ?? UUID().uuidString
        if let bIntId = try? c.decode(Int.self, forKey: .bankaId) {
            self.bankaId = String(bIntId)
        } else {
            self.bankaId = try? c.decode(String.self, forKey: .bankaId)
        }
        self.bankaAdi = try? c.decode(String.self, forKey: .bankaAdi)
        self.iban = try? c.decode(String.self, forKey: .iban)
        self.tarih = (try? c.decode(String.self, forKey: .tarih)) ?? ""
        self.evrakNo = try? c.decode(String.self, forKey: .evrakNo)
        self.islemTuru = (try? c.decode(String.self, forKey: .islemTuru)) ?? ""
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        self.cariUnvan = try? c.decode(String.self, forKey: .cariUnvan)
        let g = (try? c.decode(Double.self, forKey: .giren)) ?? (try? c.decode(Double.self, forKey: .yatan)) ?? 0.0
        let ck = (try? c.decode(Double.self, forKey: .cikan)) ?? (try? c.decode(Double.self, forKey: .ceken)) ?? 0.0
        let t = (try? c.decode(Double.self, forKey: .tutar)) ?? 0.0
        self.tutar = t > 0 ? t : max(g, ck)
        self.girisCikis = (try? c.decode(String.self, forKey: .girisCikis)) ?? (ck > 0 && g == 0 ? "CIKIS" : "GIRIS")
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let intId = self.id, intId > 0 {
            try c.encode(intId, forKey: .id)
        }
        try c.encode(uuid, forKey: .uuid)
        if let bid = bankaId, let intBid = Int(bid) {
            try c.encode(intBid, forKey: .bankaId)
        } else {
            try c.encodeIfPresent(bankaId, forKey: .bankaId)
        }
        try c.encodeIfPresent(bankaAdi, forKey: .bankaAdi)
        try c.encodeIfPresent(iban, forKey: .iban)
        try c.encode(tarih, forKey: .tarih)
        try c.encodeIfPresent(evrakNo, forKey: .evrakNo)
        try c.encode(islemTuru, forKey: .islemTuru)
        try c.encodeIfPresent(aciklama, forKey: .aciklama)
        try c.encodeIfPresent(cariUnvan, forKey: .cariUnvan)
        try c.encode(girisCikis == "GIRIS" ? tutar : 0.0, forKey: .giren)
        try c.encode(girisCikis == "CIKIS" ? tutar : 0.0, forKey: .cikan)
        try c.encode(tutar, forKey: .tutar)
        try c.encode(girisCikis, forKey: .girisCikis)
    }
}

public struct EftIslem: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var uuid: String
    public var musteriId: Int?
    public var gonderenBankaId: String?
    public var banka: String?
    public var hesapNo: String?
    public var dekontNo: String?
    public var aliciIban: String
    public var aliciUnvan: String
    public var yonlendirilenCariId: Int?
    public var yonlendirilenCariUnvan: String?
    public var tutar: Double
    public var tarih: String
    public var aciklama: String?
    public var durum: String // "BEKLIYOR", "TAMAMLANDI", "IPTAL"
    public var islemTuru: String?
    public var dekontPath: String?
    public var tenantId: String?
    
    public var musteriUnvan: String { aliciUnvan }
    
    public init(
        id: String = UUID().uuidString,
        uuid: String = UUID().uuidString,
        musteriId: Int? = nil,
        gonderenBankaId: String? = nil,
        banka: String? = nil,
        hesapNo: String? = nil,
        dekontNo: String? = nil,
        aliciIban: String = "",
        aliciUnvan: String,
        yonlendirilenCariId: Int? = nil,
        yonlendirilenCariUnvan: String? = nil,
        tutar: Double,
        tarih: String = AppFormatters.isoDate.string(from: Date()),
        aciklama: String? = nil,
        durum: String = "Tamamlandı",
        islemTuru: String? = "Havale/EFT",
        dekontPath: String? = nil,
        tenantId: String? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.musteriId = musteriId
        self.gonderenBankaId = gonderenBankaId
        self.banka = banka
        self.hesapNo = hesapNo
        self.dekontNo = dekontNo
        self.aliciIban = aliciIban
        self.aliciUnvan = aliciUnvan
        self.yonlendirilenCariId = yonlendirilenCariId
        self.yonlendirilenCariUnvan = yonlendirilenCariUnvan
        self.tutar = tutar
        self.tarih = tarih
        self.aciklama = aciklama
        self.durum = durum
        self.islemTuru = islemTuru
        self.dekontPath = dekontPath
        self.tenantId = tenantId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case musteriId = "musteri_id"
        case cariId = "cari_id"
        case musteriUnvan = "musteri_unvan"
        case gonderenBankaId = "gonderen_banka_id"
        case bankaId = "banka_id"
        case banka
        case hesapNo = "hesap_no"
        case dekontNo = "dekont_no"
        case evrakNo = "evrak_no"
        case aliciIban = "alici_iban"
        case aliciUnvan = "alici_unvan"
        case yonlendirilenCariId = "yonlendirilen_cari_id"
        case yonlendirilenCariUnvan = "yonlendirilen_cari_unvan"
        case tutar
        case tarih
        case aciklama
        case durum
        case islemTuru = "islem_turu"
        case dekontPath = "dekont_path"
        case tenantId = "tenant_id"
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
        if let bIntId = try? c.decode(Int.self, forKey: .bankaId) {
            self.gonderenBankaId = String(bIntId)
        } else {
            self.gonderenBankaId = (try? c.decode(String.self, forKey: .gonderenBankaId)) ?? (try? c.decode(String.self, forKey: .bankaId))
        }
        self.banka = try? c.decode(String.self, forKey: .banka)
        self.hesapNo = try? c.decode(String.self, forKey: .hesapNo)
        self.dekontNo = (try? c.decode(String.self, forKey: .dekontNo)) ?? (try? c.decode(String.self, forKey: .evrakNo))
        self.aliciIban = (try? c.decode(String.self, forKey: .aliciIban)) ?? self.hesapNo ?? ""
        self.aliciUnvan = (try? c.decode(String.self, forKey: .musteriUnvan)) ?? (try? c.decode(String.self, forKey: .aliciUnvan)) ?? "-"
        self.yonlendirilenCariId = try? c.decode(Int.self, forKey: .yonlendirilenCariId)
        self.yonlendirilenCariUnvan = try? c.decode(String.self, forKey: .yonlendirilenCariUnvan)
        self.tutar = (try? c.decode(Double.self, forKey: .tutar)) ?? 0.0
        self.tarih = (try? c.decode(String.self, forKey: .tarih)) ?? AppFormatters.isoDate.string(from: Date())
        self.aciklama = try? c.decode(String.self, forKey: .aciklama)
        self.durum = (try? c.decode(String.self, forKey: .durum)) ?? "Tamamlandı"
        self.islemTuru = try? c.decode(String.self, forKey: .islemTuru)
        self.dekontPath = try? c.decode(String.self, forKey: .dekontPath)
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
        try c.encode(aliciUnvan, forKey: .musteriUnvan)
        if let bid = gonderenBankaId, let intBid = Int(bid) {
            try c.encode(intBid, forKey: .bankaId)
        }
        try c.encodeIfPresent(banka, forKey: .banka)
        try c.encodeIfPresent(hesapNo ?? aliciIban, forKey: .hesapNo)
        try c.encodeIfPresent(dekontNo, forKey: .dekontNo)
        try c.encodeIfPresent(yonlendirilenCariId, forKey: .yonlendirilenCariId)
        try c.encodeIfPresent(yonlendirilenCariUnvan, forKey: .yonlendirilenCariUnvan)
        try c.encode(tutar, forKey: .tutar)
        try c.encode(tarih, forKey: .tarih)
        try c.encodeIfPresent(aciklama, forKey: .aciklama)
        try c.encode(durum, forKey: .durum)
        try c.encodeIfPresent(islemTuru, forKey: .islemTuru)
        try c.encodeIfPresent(dekontPath, forKey: .dekontPath)
        try c.encodeIfPresent(tenantId ?? SupabaseService.shared.tenantId, forKey: .tenantId)
    }
}

