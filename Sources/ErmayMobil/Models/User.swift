import Foundation

public struct User: Identifiable, Codable {
    public var id: String
    public var email: String?
    public var username: String
    public var fullName: String?
    public var role: String // "Admin", "Muhasebe", "Satis", "Kullanici"
    public var tenantId: String
    public var token: String?
    
    public init(
        id: String = UUID().uuidString,
        email: String? = nil,
        username: String,
        fullName: String? = nil,
        role: String = "Admin",
        tenantId: String = "tenant_ermay_master",
        token: String? = nil
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.fullName = fullName
        self.role = role
        self.tenantId = tenantId
        self.token = token
    }
}

public struct FirmaProfili: Codable {
    public var id: Int? = 1
    public var firmaAdi: String
    public var unvan: String
    public var vergiDairesi: String?
    public var vergiNo: String?
    public var telefon: String?
    public var email: String?
    public var web: String?
    public var adres: String?
    public var sehir: String?
    public var logoData: String? // Base64
    public var cloudPdfApiUrl: String?
    public var cloudPdfApiKey: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firmaAdi = "firma_adi"
        case unvan
        case vergiDairesi = "vergi_dairesi"
        case vergiNo = "vergi_no"
        case telefon
        case email
        case eposta
        case web
        case adres
        case sehir
        case logoData = "logo_base64"
        case cloudPdfApiUrl = "cloud_pdf_api_url"
        case cloudPdfApiKey = "cloud_pdf_api_key"
    }
    
    public init(
        id: Int? = 1,
        firmaAdi: String,
        unvan: String,
        vergiDairesi: String? = nil,
        vergiNo: String? = nil,
        telefon: String? = nil,
        email: String? = nil,
        web: String? = nil,
        adres: String? = nil,
        sehir: String? = nil,
        logoData: String? = nil,
        cloudPdfApiUrl: String? = nil,
        cloudPdfApiKey: String? = nil
    ) {
        self.id = id
        self.firmaAdi = firmaAdi
        self.unvan = unvan
        self.vergiDairesi = vergiDairesi
        self.vergiNo = vergiNo
        self.telefon = telefon
        self.email = email
        self.web = web
        self.adres = adres
        self.sehir = sehir
        self.logoData = logoData
        self.cloudPdfApiUrl = cloudPdfApiUrl
        self.cloudPdfApiKey = cloudPdfApiKey
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? c.decode(Int.self, forKey: .id)) ?? 1
        self.firmaAdi = (try? c.decode(String.self, forKey: .firmaAdi)) ?? ""
        self.unvan = (try? c.decode(String.self, forKey: .unvan)) ?? self.firmaAdi
        self.vergiDairesi = try? c.decode(String.self, forKey: .vergiDairesi)
        self.vergiNo = try? c.decode(String.self, forKey: .vergiNo)
        self.telefon = try? c.decode(String.self, forKey: .telefon)
        self.email = (try? c.decode(String.self, forKey: .eposta)) ?? (try? c.decode(String.self, forKey: .email))
        self.web = try? c.decode(String.self, forKey: .web)
        self.adres = try? c.decode(String.self, forKey: .adres)
        self.sehir = try? c.decode(String.self, forKey: .sehir)
        self.logoData = try? c.decode(String.self, forKey: .logoData)
        self.cloudPdfApiUrl = try? c.decode(String.self, forKey: .cloudPdfApiUrl)
        self.cloudPdfApiKey = try? c.decode(String.self, forKey: .cloudPdfApiKey)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id ?? 1, forKey: .id)
        try c.encode(firmaAdi, forKey: .firmaAdi)
        try c.encode(unvan, forKey: .unvan)
        try c.encodeIfPresent(vergiDairesi, forKey: .vergiDairesi)
        try c.encodeIfPresent(vergiNo, forKey: .vergiNo)
        try c.encodeIfPresent(telefon, forKey: .telefon)
        try c.encodeIfPresent(email, forKey: .eposta)
        try c.encodeIfPresent(web, forKey: .web)
        try c.encodeIfPresent(adres, forKey: .adres)
        try c.encodeIfPresent(logoData, forKey: .logoData)
        try c.encodeIfPresent(cloudPdfApiUrl, forKey: .cloudPdfApiUrl)
        try c.encodeIfPresent(cloudPdfApiKey, forKey: .cloudPdfApiKey)
    }
    
    public static let varsayilan = FirmaProfili(
        firmaAdi: "",
        unvan: "",
        vergiDairesi: "",
        vergiNo: "",
        telefon: "",
        email: "",
        web: "",
        adres: "",
        sehir: ""
    )
}
