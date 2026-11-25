import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Supabase DTO Models for Tools (Masaüstü Birebir Tablo Şemaları)
public struct BelgeArsivKayit: Identifiable, Codable, Hashable {
    public var id: String
    public var uuid: String
    public var ad: String
    public var kategori: String
    public var tur: String
    public var boyut: String
    public var tarih: String
    public var veri: String?
    public var yol: String?
    public var isDeleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case ad
        case belgeAdi = "belge_adi"
        case kategori
        case tur
        case belgeTuru = "belge_turu"
        case boyut
        case tarih
        case veri
        case yol
        case isDeleted = "is_deleted"
        case tenantId = "tenant_id"
    }
    
    public init(
        id: String = UUID().uuidString,
        uuid: String = UUID().uuidString,
        ad: String,
        kategori: String = "Resmi Belge",
        tur: String = "PDF",
        boyut: String = "120 KB",
        tarih: String = AppFormatters.isoDate.string(from: Date()),
        veri: String? = nil,
        yol: String? = nil,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.uuid = uuid
        self.ad = ad
        self.kategori = kategori
        self.tur = tur
        self.boyut = boyut
        self.tarih = tarih
        self.veri = veri
        self.yol = yol
        self.isDeleted = isDeleted
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
        self.ad = (try? c.decode(String.self, forKey: .ad)) ?? (try? c.decode(String.self, forKey: .belgeAdi)) ?? "Belge"
        self.kategori = (try? c.decode(String.self, forKey: .kategori)) ?? "Diğer"
        self.tur = (try? c.decode(String.self, forKey: .tur)) ?? (try? c.decode(String.self, forKey: .belgeTuru)) ?? "PDF"
        self.boyut = (try? c.decode(String.self, forKey: .boyut)) ?? "-"
        self.tarih = (try? c.decode(String.self, forKey: .tarih)) ?? AppFormatters.isoDate.string(from: Date())
        self.veri = try? c.decode(String.self, forKey: .veri)
        self.yol = try? c.decode(String.self, forKey: .yol)
        self.isDeleted = (try? c.decode(Bool.self, forKey: .isDeleted)) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let intId = Int(id), intId > 0 {
            try c.encode(intId, forKey: .id)
        }
        try c.encode(uuid, forKey: .uuid)
        try c.encode(ad, forKey: .ad)
        try c.encode(ad, forKey: .belgeAdi)
        try c.encode(kategori, forKey: .kategori)
        try c.encode(tur, forKey: .tur)
        try c.encode(tur, forKey: .belgeTuru)
        try c.encode(boyut, forKey: .boyut)
        try c.encode(tarih, forKey: .tarih)
        try c.encodeIfPresent(veri, forKey: .veri)
        try c.encodeIfPresent(yol, forKey: .yol)
        try c.encode(isDeleted, forKey: .isDeleted)
        try c.encode(SupabaseService.shared.tenantId, forKey: .tenantId)
    }
}

public struct PortfoyKartKayit: Identifiable, Codable, Hashable {
    public var id: String
    public var uuid: String
    public var firmaIsmi: String
    public var cariTipi: String
    public var yetkiliKisi: String
    public var vadeGunu: Int
    public var riskLimiti: Double
    public var vkn: String
    public var vergiDairesi: String
    public var gsm: String
    public var telefon: String
    public var email: String
    public var webSitesi: String
    public var il: String
    public var ilce: String
    public var adres: String
    public var sektor: String
    public var aciklama: String
    public var acilisBakiyesi: Double
    public var gorusuldu: Bool
    public var notlar: String
    public var isDeleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case firmaIsmi = "firma_ismi"
        case cariTipi = "cari_tipi"
        case yetkiliKisi = "yetkili_kisi"
        case vadeGunu = "vade_gunu"
        case riskLimiti = "risk_limiti"
        case vkn
        case vergiDairesi = "vergi_dairesi"
        case gsm
        case telefon
        case email
        case webSitesi = "web_sitesi"
        case il
        case ilce
        case adres
        case sektor
        case aciklama
        case acilisBakiyesi = "acilis_bakiyesi"
        case gorusuldu
        case notlar
        case isDeleted = "is_deleted"
        case tenantId = "tenant_id"
    }
    
    public init(
        id: String = UUID().uuidString,
        uuid: String = UUID().uuidString,
        firmaIsmi: String,
        cariTipi: String = "Müşteri",
        yetkiliKisi: String = "",
        vadeGunu: Int = 30,
        riskLimiti: Double = 0.0,
        vkn: String = "",
        vergiDairesi: String = "",
        gsm: String = "",
        telefon: String = "",
        email: String = "",
        webSitesi: String = "",
        il: String = "",
        ilce: String = "",
        adres: String = "",
        sektor: String = "",
        aciklama: String = "",
        acilisBakiyesi: Double = 0.0,
        gorusuldu: Bool = false,
        notlar: String = "",
        isDeleted: Bool = false
    ) {
        self.id = id
        self.uuid = uuid
        self.firmaIsmi = firmaIsmi
        self.cariTipi = cariTipi
        self.yetkiliKisi = yetkiliKisi
        self.vadeGunu = vadeGunu
        self.riskLimiti = riskLimiti
        self.vkn = vkn
        self.vergiDairesi = vergiDairesi
        self.gsm = gsm
        self.telefon = telefon
        self.email = email
        self.webSitesi = webSitesi
        self.il = il
        self.ilce = ilce
        self.adres = adres
        self.sektor = sektor
        self.aciklama = aciklama
        self.acilisBakiyesi = acilisBakiyesi
        self.gorusuldu = gorusuldu
        self.notlar = notlar
        self.isDeleted = isDeleted
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
        self.firmaIsmi = (try? c.decode(String.self, forKey: .firmaIsmi)) ?? ""
        self.cariTipi = (try? c.decode(String.self, forKey: .cariTipi)) ?? "Müşteri"
        self.yetkiliKisi = (try? c.decode(String.self, forKey: .yetkiliKisi)) ?? ""
        self.vadeGunu = (try? c.decode(Int.self, forKey: .vadeGunu)) ?? 30
        self.riskLimiti = (try? c.decode(Double.self, forKey: .riskLimiti)) ?? 0.0
        self.vkn = (try? c.decode(String.self, forKey: .vkn)) ?? ""
        self.vergiDairesi = (try? c.decode(String.self, forKey: .vergiDairesi)) ?? ""
        self.gsm = (try? c.decode(String.self, forKey: .gsm)) ?? ""
        self.telefon = (try? c.decode(String.self, forKey: .telefon)) ?? ""
        self.email = (try? c.decode(String.self, forKey: .email)) ?? ""
        self.webSitesi = (try? c.decode(String.self, forKey: .webSitesi)) ?? ""
        self.il = (try? c.decode(String.self, forKey: .il)) ?? ""
        self.ilce = (try? c.decode(String.self, forKey: .ilce)) ?? ""
        self.adres = (try? c.decode(String.self, forKey: .adres)) ?? ""
        self.sektor = (try? c.decode(String.self, forKey: .sektor)) ?? ""
        self.aciklama = (try? c.decode(String.self, forKey: .aciklama)) ?? ""
        self.acilisBakiyesi = (try? c.decode(Double.self, forKey: .acilisBakiyesi)) ?? 0.0
        self.gorusuldu = (try? c.decode(Bool.self, forKey: .gorusuldu)) ?? false
        self.notlar = (try? c.decode(String.self, forKey: .notlar)) ?? ""
        self.isDeleted = (try? c.decode(Bool.self, forKey: .isDeleted)) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let intId = Int(id), intId > 0 {
            try c.encode(intId, forKey: .id)
        }
        try c.encode(uuid, forKey: .uuid)
        try c.encode(firmaIsmi, forKey: .firmaIsmi)
        try c.encode(cariTipi, forKey: .cariTipi)
        try c.encode(yetkiliKisi, forKey: .yetkiliKisi)
        try c.encode(vadeGunu, forKey: .vadeGunu)
        try c.encode(riskLimiti, forKey: .riskLimiti)
        try c.encode(vkn, forKey: .vkn)
        try c.encode(vergiDairesi, forKey: .vergiDairesi)
        try c.encode(gsm, forKey: .gsm)
        try c.encode(telefon, forKey: .telefon)
        try c.encode(email, forKey: .email)
        try c.encode(webSitesi, forKey: .webSitesi)
        try c.encode(il, forKey: .il)
        try c.encode(ilce, forKey: .ilce)
        try c.encode(adres, forKey: .adres)
        try c.encode(sektor, forKey: .sektor)
        try c.encode(aciklama, forKey: .aciklama)
        try c.encode(acilisBakiyesi, forKey: .acilisBakiyesi)
        try c.encode(gorusuldu, forKey: .gorusuldu)
        try c.encode(notlar, forKey: .notlar)
        try c.encode(isDeleted, forKey: .isDeleted)
        try c.encode(SupabaseService.shared.tenantId, forKey: .tenantId)
    }
}

public struct AylikButceItem: Identifiable {
    public let id: Int
    public let ayAdi: String
    public var hedef: Double
    public var gerceklesen: Double
    public var oran: Double {
        guard hedef > 0 else { return gerceklesen > 0 ? 100.0 : 0.0 }
        return min(100.0, (gerceklesen / hedef) * 100.0)
    }
}

public struct AraclarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataStore = DataStore.shared
    @State private var activeTab: String? = nil
    @State private var statusBanner: String? = nil
    @State private var isLoading: Bool = false
    @State private var pdfPreviewItem: PDFPreviewItem? = nil
    @State private var isGeneratingPDF: Bool = false
    
    // 1. Sistem Sağlığı
    @State private var cacheSizeText: String = "Hesaplanıyor..."
    @State private var supabasePingMs: Int = 42
    
    // 2. Belge Arşivleme
    @State private var belgeler: [BelgeArsivKayit] = []
    @State private var belgeKategori: String = "Tümü"
    @State private var belgeSearch: String = ""
    @State private var showYeniBelgeModal: Bool = false
    @State private var yeniBelgeAd: String = ""
    @State private var yeniBelgeKategori: String = "Sözleşme"
    @State private var yeniBelgeTur: String = "PDF"
    @State private var yeniBelgeIcerik: String = ""
    @State private var yeniBelgeBase64: String = ""
    @State private var yeniBelgeBoyut: String = ""
    @State private var selectedBelgePhotoItem: PhotosPickerItem? = nil
    @State private var showFilePicker: Bool = false
    @State private var previewImage: UIImage? = nil
    @State private var showImagePreviewModal: Bool = false
    
    // 3. Döviz Kurları & Otomasyon
    @State private var usdRate: Double = 34.45
    @State private var eurRate: Double = 37.20
    @State private var gbpRate: Double = 44.10
    @State private var altinRate: Double = 3015.0
    @State private var brentRate: Double = 74.80
    @State private var kurSonGuncelleme: String = "-"
    @State private var autoUpdateRates: Bool = true
    @State private var updateIntervalText: String = "15 Dakikada Bir"
    @State private var cevirTutar: String = "1000"
    @State private var cevirKaynak: String = "USD"
    @State private var cevirHedef: String = "TRY"
    @State private var optBirimMaliyet: String = "100"
    @State private var optDoviz: String = "USD"
    @State private var optKarMarji: String = "25"
    
    // 4. Cari Birleştirme
    @State private var kaynakCari: CariKart? = nil
    @State private var hedefCari: CariKart? = nil
    @State private var showKaynakCariPicker: Bool = false
    @State private var showHedefCariPicker: Bool = false
    @State private var isMergingCari: Bool = false
    
    // 5. Ürün Birleştirme
    @State private var kaynakStok: StokKart? = nil
    @State private var hedefStok: StokKart? = nil
    @State private var showKaynakStokPicker: Bool = false
    @State private var showHedefStokPicker: Bool = false
    @State private var isMergingStok: Bool = false
    
    // 6. Gecikme Faizi Hesaplayıcı
    @State private var anaParaStr: String = ""
    @State private var faizOraniStr: String = "48"
    @State private var gecikmeGunuStr: String = "30"
    
    // 7. Risk Puanlayıcı (CekRiskAnalizViewModel)
    @State private var ceklerList: [Cek] = []
    @State private var genelRiskPuani: Double = 0.0
    @State private var riskAnalizOzeti: String = "Analiz ediliyor..."
    
    // 8. Toplu Fiyat Güncelleme
    @State private var fiyatKategoriFilter: String = "Tümü"
    @State private var fiyatIslemYonu: String = "Zam Yap (Artır)"
    @State private var fiyatDegisimTuru: String = "Yüzde (%)"
    @State private var fiyatOranDegerStr: String = "10"
    @State private var seciliStokIdler: Set<String> = []
    @State private var isUpdatingPrices: Bool = false
    
    // 9. Limit Yönetimi
    @State private var limitSearch: String = ""
    @State private var selectedCariForLimit: CariKart? = nil
    @State private var yeniLimitDegerStr: String = ""
    @State private var showLimitEditSheet: Bool = false
    
    // 10. Bütçe Planlama Merkezi
    @State private var seciliButceYili: Int = Calendar.current.component(.year, from: Date())
    @State private var yillikHedefStr: String = "0"
    @State private var aylikButceler: [AylikButceItem] = []
    @State private var isSavingBudget: Bool = false
    
    // 11. Portföy Listesi (Potansiyel Müşteri CRM)
    @State private var portfoyler: [PortfoyKartKayit] = []
    @State private var portfoySearch: String = ""
    @State private var showPortfoyModal: Bool = false
    @State private var portfoyFormTab: Int = 0
    @State private var pFirmaIsmi: String = ""
    @State private var pCariTipi: String = "Müşteri"
    @State private var pYetkili: String = ""
    @State private var pSektor: String = ""
    @State private var pTelefon: String = ""
    @State private var pEmail: String = ""
    @State private var pIl: String = ""
    @State private var pAdres: String = ""
    @State private var pVadeGunu: String = "30"
    @State private var pRiskLimiti: String = "0"
    @State private var pAcilisBakiyesi: String = "0"
    @State private var pNotlar: String = ""
    
    struct ToolMenuInfo: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let icon: String
        let colorHex: String
    }
    
    private let tools: [ToolMenuInfo] = [
        ToolMenuInfo(id: "sistem", title: "Sistem Sağlığı", subtitle: "Donanım, bellek, bulut ping ve önbellek bakımı", icon: "cpu.fill", colorHex: "10B981"),
        ToolMenuInfo(id: "belge", title: "Belge Arşivleme", subtitle: "Dijital evrak, sözleşme, dekont ve dosya kasası", icon: "archivebox.fill", colorHex: "3B82F6"),
        ToolMenuInfo(id: "kurlar", title: "Döviz Kurları", subtitle: "TCMB/Piyasa canlı kur otomasyonu ve optimal fiyat", icon: "dollarsign.arrow.circlepath", colorHex: "F59E0B"),
        ToolMenuInfo(id: "cariBir", title: "Cari Birleştirme", subtitle: "Mükerrer cari kartları ve tüm hareketlerini birleştir", icon: "person.2.gobackward", colorHex: "8B5CF6"),
        ToolMenuInfo(id: "urunBir", title: "Ürün Birleştirme", subtitle: "Çift açılmış stok kartlarını ve bakiyelerini birleştir", icon: "cube.transparent.fill", colorHex: "EC4899"),
        ToolMenuInfo(id: "faiz", title: "Gecikme Faizi", subtitle: "Yasal, ticari ve TCMB oranlarıyla vade farkı hesabı", icon: "percent", colorHex: "EF4444"),
        ToolMenuInfo(id: "risk", title: "Risk Puanlayıcı", subtitle: "Çek, senet ve cari tahsilat güvenilirlik skoru & PDF", icon: "shield.Checkmark", colorHex: "06B6D4"),
        ToolMenuInfo(id: "fiyat", title: "Toplu Fiyat Güncelleme", subtitle: "Kategori veya tüm stoklarda toplu zam/indirim", icon: "tag.circle.fill", colorHex: "10B981"),
        ToolMenuInfo(id: "limit", title: "Limit Yönetimi", subtitle: "Müşteri kredi ve açık hesap risk limitleri kontrolü", icon: "creditcard.trianglebadge.exclamationmark", colorHex: "F97316"),
        ToolMenuInfo(id: "hedef", title: "Bütçe Planlama Merkezi", subtitle: "Yıllık, aylık ve haftalık satış hedefi yönetimi", icon: "target", colorHex: "0061FF"),
        ToolMenuInfo(id: "portfoy", title: "Portföy Listesi", subtitle: "Potansiyel müşteri adayları ve tek tıkla cariye aktarım", icon: "briefcase.fill", colorHex: "00FF87")
    ]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Button {
                        if activeTab != nil {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTab = nil
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activeToolTitle)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(activeTab == nil ? "Masaüstü Birebir 11 Yardımcı Modül" : "Araçlar & Otomasyon Merkezi")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    
                    Spacer()
                    
                    if isLoading || isGeneratingPDF {
                        ProgressView().tint(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                if let banner = statusBanner {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "10B981"))
                        Text(banner)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Button { statusBanner = nil } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                    }
                    .padding(10)
                    .background(Color(hex: "10B981").opacity(0.18))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if let tab = activeTab {
                            renderActiveTool(tab: tab)
                        } else {
                            renderToolsMenuGrid()
                        }
                        Spacer().frame(height: 90)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .enableSwipeBack {
            if activeTab != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeTab = nil
                }
            } else {
                dismiss()
            }
        }
        .task {
            await loadAllToolsData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .supabaseRealtimeDataChanged)) { _ in
            Task { await loadAllToolsData() }
        }
        .sheet(isPresented: $showKaynakCariPicker) {
            CariPickerSheet { c in kaynakCari = c }
        }
        .sheet(isPresented: $showHedefCariPicker) {
            CariPickerSheet { c in hedefCari = c }
        }
        .sheet(isPresented: $showKaynakStokPicker) {
            StokPickerSheet { s in kaynakStok = s }
        }
        .sheet(isPresented: $showHedefStokPicker) {
            StokPickerSheet { s in hedefStok = s }
        }
        .sheet(isPresented: $showYeniBelgeModal) {
            yeniBelgeSheet()
        }
        .sheet(isPresented: $showPortfoyModal) {
            yeniPortfoySheet()
        }
        .sheet(isPresented: $showLimitEditSheet) {
            limitEditModal()
        }
        .sheet(item: $pdfPreviewItem) { item in
            #if canImport(UIKit)
            PDFViewerModal(title: item.title, pdfData: item.data, fileName: item.fileName)
            #endif
        }
        .fullScreenCover(isPresented: $showImagePreviewModal) {
            #if canImport(UIKit)
            if let img = previewImage {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showImagePreviewModal = false
                                previewImage = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        Spacer()
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .padding()
                        Spacer()
                    }
                }
            }
            #endif
        }
    }
    
    private var activeToolTitle: String {
        guard let tab = activeTab, let found = tools.first(where: { $0.id == tab }) else {
            return "Araçlar & Otomasyon"
        }
        return found.title
    }
    
    // MARK: - Main Grid Menu
    @ViewBuilder
    private func renderToolsMenuGrid() -> some View {
        ForEach(tools) { tool in
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeTab = tool.id
                }
                HardwareService.shared.hapticSelection()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: tool.colorHex).opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: tool.icon == "shield.Checkmark" ? "checkmark.shield.fill" : tool.icon)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(Color(hex: tool.colorHex))
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(tool.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text(tool.subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "64748B"))
                }
                .padding(14)
                .background(Color(hex: "121216"))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
    }
    
    @ViewBuilder
    private func renderActiveTool(tab: String) -> some View {
        switch tab {
        case "sistem":
            renderSistemSagligi()
        case "belge":
            renderBelgeArsivleme()
        case "kurlar":
            renderDovizKurlari()
        case "cariBir":
            renderCariBirlestirme()
        case "urunBir":
            renderUrunBirlestirme()
        case "faiz":
            renderGecikmeFaizi()
        case "risk":
            renderRiskPuanlayici()
        case "fiyat":
            renderTopluFiyatGuncelleme()
        case "limit":
            renderLimitYonetimi()
        case "hedef":
            renderButcePlanlama()
        case "portfoy":
            renderPortfoyListesi()
        default:
            EmptyView()
        }
    }
    
    // MARK: - 1. SİSTEM SAĞLIĞI
    @ViewBuilder
    private func renderSistemSagligi() -> some View {
        #if canImport(UIKit)
        let devModel = UIDevice.current.model
        let sysVer = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        #else
        let devModel = "iOS Device"
        let sysVer = "iOS"
        #endif
        let uptimeSec = Int(ProcessInfo.processInfo.systemUptime)
        let uptimeStr = "\(uptimeSec / 3600) sa \((uptimeSec % 3600) / 60) dk"
        let memMb = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024))
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Canlı Sistem ve Bulut Telemetrisi")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                sysCard(title: "CİHAZ MODELİ", val: devModel, sub: sysVer, color: Color(hex: "3B82F6"))
                sysCard(title: "FİZİKSEL BELLEK", val: "\(memMb) MB", sub: "Aktif RAM", color: Color(hex: "10B981"))
                sysCard(title: "ÇALIŞMA SÜRESİ", val: uptimeStr, sub: "Sistem Uptime", color: Color(hex: "F59E0B"))
                sysCard(title: "SUPABASE BULUT", val: "\(supabasePingMs) ms", sub: "PostgreSQL Aktif", color: Color(hex: "00FF87"))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Senkronize Veritabanı Tablo Özeti")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                HStack {
                    Text("Kayıtlı Cari Hesaplar:")
                        .foregroundColor(Color(hex: "8E8E93"))
                    Spacer()
                    Text("\(dataStore.cariler.count) Kayıt")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .font(.system(size: 12))
                
                HStack {
                    Text("Kayıtlı Stok Kartları:")
                        .foregroundColor(Color(hex: "8E8E93"))
                    Spacer()
                    Text("\(dataStore.stoklar.count) Kayıt")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .font(.system(size: 12))
                
                HStack {
                    Text("Kayıtlı Faturalar:")
                        .foregroundColor(Color(hex: "8E8E93"))
                    Spacer()
                    Text("\(dataStore.faturalar.count) Kayıt")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .font(.system(size: 12))
            }
            .padding(14)
            .background(Color(hex: "121216"))
            .cornerRadius(14)
            
            Button {
                Task {
                    await dataStore.syncAll()
                    await MainActor.run {
                        statusBanner = "Tüm bulut tabloları ve önbellek başarıyla senkronize edildi."
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Tüm Tabloları Şimdi Eşitle & Bakım Yap")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "10B981"))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 2. BELGE ARŞİVLEME (public.belge_arsiv)
    @ViewBuilder
    private func renderBelgeArsivleme() -> some View {
        let katList = ["Tümü", "Sözleşme", "Dekont", "İrsaliye", "Resmi Belge", "Diğer"]
        let filtered = belgeler.filter { b in
            !b.isDeleted &&
            (belgeKategori == "Tümü" || b.kategori == belgeKategori) &&
            (belgeSearch.isEmpty || b.ad.localizedCaseInsensitiveContains(belgeSearch))
        }
        
        HStack {
            TextField("Belge adı ara...", text: $belgeSearch)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(10)
                .background(Color(hex: "121216"))
                .cornerRadius(10)
            
            Button {
                showYeniBelgeModal = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Yeni Belge")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: "2563EB"))
                .cornerRadius(10)
            }
        }
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(katList, id: \.self) { k in
                    let isSel = belgeKategori == k
                    Button {
                        belgeKategori = k
                    } label: {
                        Text(k)
                            .font(.system(size: 11, weight: isSel ? .bold : .medium))
                            .foregroundColor(isSel ? .white : Color(hex: "8E8E93"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSel ? Color(hex: "2563EB") : Color(hex: "121216"))
                            .cornerRadius(8)
                    }
                }
            }
        }
        
        if filtered.isEmpty {
            emptyBox("Arşivde kayıtlı belge bulunmuyor.")
        } else {
            ForEach(filtered) { b in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "3B82F6").opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: b.tur.localizedCaseInsensitiveContains("pdf") ? "doc.richtext.fill" : (b.tur.localizedCaseInsensitiveContains("jpg") || b.tur.localizedCaseInsensitiveContains("png") ? "photo.fill" : "doc.fill"))
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(b.ad)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(b.kategori) • \(b.tur) • \(b.boyut) • \(String(b.tarih.prefix(10)))")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    
                    Spacer()
                    
                    Button {
                        openOrPreviewBelge(b)
                    } label: {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "3B82F6"))
                            .padding(8)
                            .background(Color(hex: "3B82F6").opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        shareBelge(b)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                            .padding(8)
                            .background(Color(hex: "10B981").opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        deleteBelge(b)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(Color(hex: "EF4444"))
                            .padding(8)
                    }
                }
                .padding(14)
                .background(Color(hex: "121216"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
    }
    
    // MARK: - 3. DÖVİZ KURLARI & OTOMASYON (DovizOtomasyonViewModel Birebir)
    @ViewBuilder
    private func renderDovizKurlari() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Canlı Piyasa & TCMB Kurları")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("Son Güncelleme: \(kurSonGuncelleme)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                Spacer()
                Button {
                    Task { await refreshExchangeRates() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Kurları Çek")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "F59E0B"))
                    .cornerRadius(8)
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                sysCard(title: "USD / TRY", val: String(format: "₺%.4f", usdRate), sub: "Amerikan Doları", color: Color(hex: "10B981"))
                sysCard(title: "EUR / TRY", val: String(format: "₺%.4f", eurRate), sub: "Euro", color: Color(hex: "3B82F6"))
                sysCard(title: "GBP / TRY", val: String(format: "₺%.4f", gbpRate), sub: "İngiliz Sterlini", color: Color(hex: "8B5CF6"))
                sysCard(title: "GRAM ALTIN", val: String(format: "₺%.2f", altinRate), sub: "Kapalıçarşı / Ons", color: Color(hex: "F59E0B"))
            }
            
            // Çapraz Kur Çevirici
            VStack(alignment: .leading, spacing: 10) {
                Text("Çapraz Kur Çevirici")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    TextField("1000", text: $cevirTutar)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(8)
                    
                    Picker("Kaynak", selection: $cevirKaynak) {
                        ForEach(["TRY", "USD", "EUR", "GBP"], id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(Color(hex: "F59E0B"))
                    
                    Picker("Hedef", selection: $cevirHedef) {
                        ForEach(["TRY", "USD", "EUR", "GBP"], id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }
                
                Text("Karşılık: \(String(format: "%.2f", convertedCurrencyAmount)) \(cevirHedef)")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Color(hex: "10B981"))
            }
            .padding(14)
            .background(Color(hex: "121216"))
            .cornerRadius(14)
            
            // Optimal Satış Fiyatı Hesaplayıcı (Masaüstü Birebir)
            VStack(alignment: .leading, spacing: 10) {
                Text("Döviz Bazlı Optimal Satış Fiyatı Hesaplayıcı")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    toolInput("Birim Maliyet", text: $optBirimMaliyet)
                    toolInput("Hedef Kar (%)", text: $optKarMarji)
                }
                
                Picker("Döviz", selection: $optDoviz) {
                    ForEach(["USD", "EUR", "GBP", "TRY"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                
                let mVal = Double(optBirimMaliyet.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                let kVal = Double(optKarMarji.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                let rVal = rateForCode(optDoviz)
                let tlMaliyet = mVal * rVal
                let optSatis = tlMaliyet * (1.0 + kVal / 100.0)
                
                HStack {
                    Text("TL Maliyet: \(AppFormatters.money(tlMaliyet))")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8E8E93"))
                    Spacer()
                    Text("Optimal Satış: \(AppFormatters.money(optSatis))")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: "00FF87"))
                }
            }
            .padding(14)
            .background(Color(hex: "121216"))
            .cornerRadius(14)
        }
    }
    
    private func rateForCode(_ code: String) -> Double {
        switch code {
        case "USD": return usdRate
        case "EUR": return eurRate
        case "GBP": return gbpRate
        default: return 1.0
        }
    }
    
    private var convertedCurrencyAmount: Double {
        let amt = Double(cevirTutar.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let inTry = amt * rateForCode(cevirKaynak)
        let targetRate = rateForCode(cevirHedef)
        return targetRate > 0 ? (inTry / targetRate) : 0.0
    }
    
    // MARK: - 4. CARİ BİRLEŞTİRME (CariBirlestirmeViewModel Birebir)
    @ViewBuilder
    private func renderCariBirlestirme() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mükerrer açılmış iki cari hesabı seçin. Kaynak carinin tüm fatura, sipariş, teklif, çek ve cari hareketleri hedef cariye aktarılır ve kaynak cari pasife alınır.")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8E8E93"))
            
            Button {
                showKaynakCariPicker = true
            } label: {
                pickerBox(
                    title: "1. Kaynak Cari (Silinecek / Aktarılacak)",
                    val: kaynakCari != nil ? "\(kaynakCari!.unvan) (\(AppFormatters.money(kaynakCari!.bakiye)))" : "Kaynak Cari Seçiniz...",
                    color: Color(hex: "EF4444")
                )
            }
            
            Button {
                showHedefCariPicker = true
            } label: {
                pickerBox(
                    title: "2. Hedef Cari (Ana Hesap - Korunacak)",
                    val: hedefCari != nil ? "\(hedefCari!.unvan) (\(AppFormatters.money(hedefCari!.bakiye)))" : "Hedef Cari Seçiniz...",
                    color: Color(hex: "10B981")
                )
            }
            
            Button {
                executeCariMerge()
            } label: {
                HStack {
                    if isMergingCari {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.triangle.merge")
                    }
                    Text("Cari Hesapları Şimdi Birleştir")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background((kaynakCari != nil && hedefCari != nil && kaynakCari?.id != hedefCari?.id) ? Color(hex: "8B5CF6") : Color.gray.opacity(0.4))
                .cornerRadius(12)
            }
            .disabled(kaynakCari == nil || hedefCari == nil || kaynakCari?.id == hedefCari?.id || isMergingCari)
        }
    }
    
    private func executeCariMerge() {
        guard let src = kaynakCari, var dst = hedefCari, src.id != dst.id else { return }
        isMergingCari = true
        Task {
            let srcIdInt = Int(src.id) ?? 0
            let dstIdInt = Int(dst.id) ?? 0
            
            // 1. Cari Hareketleri Aktar
            let chPayload: [String: Any] = [
                "cari_id": dstIdInt,
                "cari_unvan": dst.unvan
            ]
            if let d = try? JSONSerialization.data(withJSONObject: chPayload) {
                _ = try? await SupabaseService.shared.updateWhere(table: "cari_hareketler", filter: "cari_id=eq.\(srcIdInt)", data: d)
            }
            
            // 2. Faturaları Aktar
            let fPayload: [String: Any] = [
                "cari_id": dstIdInt,
                "cari_unvan": dst.unvan
            ]
            if let d = try? JSONSerialization.data(withJSONObject: fPayload) {
                _ = try? await SupabaseService.shared.updateWhere(table: "faturalar", filter: "cari_id=eq.\(srcIdInt)", data: d)
            }
            
            // 3. Sipariş ve Teklifleri Aktar
            let stPayload: [String: Any] = [
                "cari_id": dstIdInt,
                "cari_unvan": dst.unvan
            ]
            if let d = try? JSONSerialization.data(withJSONObject: stPayload) {
                _ = try? await SupabaseService.shared.updateWhere(table: "siparisler", filter: "cari_id=eq.\(srcIdInt)", data: d)
                _ = try? await SupabaseService.shared.updateWhere(table: "teklifler", filter: "cari_id=eq.\(srcIdInt)", data: d)
            }
            
            // 4. Çek ve Senetleri Aktar
            let csPayload: [String: Any] = [
                "cari_id": dstIdInt,
                "cari_unvan": dst.unvan
            ]
            if let d = try? JSONSerialization.data(withJSONObject: csPayload) {
                _ = try? await SupabaseService.shared.updateWhere(table: "cekler", filter: "cari_id=eq.\(srcIdInt)", data: d)
                _ = try? await SupabaseService.shared.updateWhere(table: "senetler", filter: "cari_id=eq.\(srcIdInt)", data: d)
            }
            
            // 5. Müşteri Takip Klasör ve Detaylarını Aktar
            let mtPayload: [String: Any] = [
                "cari_id": dstIdInt,
                "cari_unvan": dst.unvan
            ]
            if let d = try? JSONSerialization.data(withJSONObject: mtPayload) {
                _ = try? await SupabaseService.shared.updateWhere(table: "musteri_takip_klasorler", filter: "cari_id=eq.\(srcIdInt)", data: d)
                _ = try? await SupabaseService.shared.updateWhere(table: "musteri_takip_detaylar", filter: "cari_id=eq.\(srcIdInt)", data: d)
            }
            
            // 6. Hedef Cari Bakiyesini Güncelle
            dst.bakiye += src.bakiye
            try? await DataStore.shared.saveCari(dst, isUpdate: true)
            
            // 7. Kaynak Cariyi Kapat / Sil
            try? await SupabaseService.shared.delete(table: "cariler", id: src.id)
            await DataStore.shared.loadCarilerCacheFirst(forceCloudRefresh: true)
            await DataStore.shared.loadFaturalarCacheFirst(forceCloudRefresh: true)
            
            await MainActor.run {
                isMergingCari = false
                kaynakCari = nil
                hedefCari = dst
                statusBanner = "'\(src.unvan)' carisinin tüm hareket, fatura ve belgeleri başarıyla '\(dst.unvan)' hesabına aktarıldı."
            }
        }
    }
    
    // MARK: - 5. ÜRÜN BİRLEŞTİRME (UrunBirlestirmeViewModel Birebir)
    @ViewBuilder
    private func renderUrunBirlestirme() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Çift açılmış stok kartlarını seçin. Kaynak ürünün mevcut stok miktarı ve hareketleri hedef ürüne eklenir ve kaynak ürün pasife alınır.")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8E8E93"))
            
            Button {
                showKaynakStokPicker = true
            } label: {
                pickerBox(
                    title: "1. Kaynak Ürün (Kapatılacak Kart)",
                    val: kaynakStok != nil ? "\(kaynakStok!.stokAdi) (\(String(format: "%.2f", kaynakStok!.mevcutMiktar)) \(kaynakStok!.birim ?? "Adet"))" : "Kaynak Ürün Seçiniz...",
                    color: Color(hex: "EF4444")
                )
            }
            
            Button {
                showHedefStokPicker = true
            } label: {
                pickerBox(
                    title: "2. Hedef Ürün (Birleştirilecek Ana Kart)",
                    val: hedefStok != nil ? "\(hedefStok!.stokAdi) (\(String(format: "%.2f", hedefStok!.mevcutMiktar)) \(hedefStok!.birim ?? "Adet"))" : "Hedef Ürün Seçiniz...",
                    color: Color(hex: "10B981")
                )
            }
            
            Button {
                executeStokMerge()
            } label: {
                HStack {
                    if isMergingStok {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.triangle.merge")
                    }
                    Text("Ürün Kartlarını Şimdi Birleştir")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background((kaynakStok != nil && hedefStok != nil && kaynakStok?.id != hedefStok?.id) ? Color(hex: "EC4899") : Color.gray.opacity(0.4))
                .cornerRadius(12)
            }
            .disabled(kaynakStok == nil || hedefStok == nil || kaynakStok?.id == hedefStok?.id || isMergingStok)
        }
    }
    
    private func executeStokMerge() {
        guard let src = kaynakStok, var dst = hedefStok, src.id != dst.id else { return }
        isMergingStok = true
        Task {
            let srcIdInt = Int(src.id) ?? 0
            let dstIdInt = Int(dst.id) ?? 0

            // 1. Stok Hareketlerini Aktar
            let shPayload: [String: Any] = [
                "stok_id": dstIdInt,
                "stok_kodu": dst.stokKodu ?? "",
                "stok_adi": dst.stokAdi
            ]
            if let d = try? JSONSerialization.data(withJSONObject: shPayload) {
                _ = try? await SupabaseService.shared.updateWhere(table: "stok_hareketler", filter: "stok_id=eq.\(srcIdInt)", data: d)
            }

            // 2. Fatura Kalemlerini Aktar
            let fdPayload: [String: Any] = [
                "stok_id": dstIdInt,
                "stok_kodu": dst.stokKodu ?? "",
                "stok_adi": dst.stokAdi
            ]
            if let d = try? JSONSerialization.data(withJSONObject: fdPayload) {
                _ = try? await SupabaseService.shared.updateWhere(table: "fatura_detaylar", filter: "stok_id=eq.\(srcIdInt)", data: d)
            }

            // 3. Sipariş ve Teklif Kalemlerini Aktar
            let sdPayload: [String: Any] = [
                "stok_id": dstIdInt,
                "stok_adi": dst.stokAdi
            ]
            if let d = try? JSONSerialization.data(withJSONObject: sdPayload) {
                _ = try? await SupabaseService.shared.updateWhere(table: "siparis_detaylar", filter: "stok_id=eq.\(srcIdInt)", data: d)
                _ = try? await SupabaseService.shared.updateWhere(table: "teklif_detaylar", filter: "stok_id=eq.\(srcIdInt)", data: d)
            }

            // 4. Hedef Ürün Stok Miktarını Güncelle
            dst.mevcutMiktar += src.mevcutMiktar
            try? await DataStore.shared.saveStok(dst, isUpdate: true)

            // 5. Kaynak Ürünü Kapat / Sil
            try? await SupabaseService.shared.delete(table: "stoklar", id: src.id)
            await DataStore.shared.loadStoklarCacheFirst(forceCloudRefresh: true)
            await MainActor.run {
                isMergingStok = false
                kaynakStok = nil
                hedefStok = dst
                statusBanner = "'\(src.stokAdi)' ürününün tüm hareket ve fatura detayları başarıyla '\(dst.stokAdi)' kartına aktarıldı."
            }
        }
    }
    
    // MARK: - 6. GECİKME FAİZİ HESAPLAYICI (GecikmeFaiziViewModel Birebir)
    @ViewBuilder
    private func renderGecikmeFaizi() -> some View {
        let anaPara = Double(anaParaStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let oran = Double(faizOraniStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let gun = Double(gecikmeGunuStr) ?? 0.0
        let faizTutar = (anaPara * oran * gun) / 36500.0
        let toplamTutar = anaPara + faizTutar
        
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                presetBtn("Yasal (%24)", rate: "24")
                presetBtn("Ticari (%48)", rate: "48")
                presetBtn("TCMB (%50)", rate: "50")
            }
            
            toolInput("Ana Para Tutarı (₺)", text: $anaParaStr)
            HStack(spacing: 10) {
                toolInput("Yıllık Faiz Oranı (%)", text: $faizOraniStr)
                toolInput("Gecikme Süresi (Gün)", text: $gecikmeGunuStr)
            }
            
            VStack(spacing: 10) {
                HStack {
                    Text("Hesaplanan Gecikme Faizi:")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8E8E93"))
                    Spacer()
                    Text(AppFormatters.money(faizTutar))
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(Color(hex: "EF4444"))
                }
                Divider().background(Color.white.opacity(0.08))
                HStack {
                    Text("Tahsil Edilecek Toplam Tutar:")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(AppFormatters.money(toplamTutar))
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(Color(hex: "10B981"))
                }
            }
            .padding(16)
            .background(Color(hex: "121216"))
            .cornerRadius(16)
        }
    }
    
    private func presetBtn(_ label: String, rate: String) -> some View {
        let isSel = faizOraniStr == rate
        return Button {
            faizOraniStr = rate
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isSel ? .white : Color(hex: "8E8E93"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isSel ? Color(hex: "EF4444") : Color(hex: "121216"))
                .cornerRadius(8)
        }
    }
    
    // MARK: - 7. RİSK PUANLAYICI (CekRiskAnalizViewModel Birebir + QuestPDF)
    @ViewBuilder
    private func renderRiskPuanlayici() -> some View {
        let scoreColor = genelRiskPuani >= 75 ? Color(hex: "10B981") : (genelRiskPuani >= 50 ? Color(hex: "F59E0B") : Color(hex: "EF4444"))
        
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 8) {
                Text("GENEL PORTFÖY GÜVENİLİRLİK SKORU")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "8E8E93"))
                Text("\(Int(genelRiskPuani)) / 100")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(scoreColor)
                Text(riskAnalizOzeti)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(Color(hex: "121216"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(scoreColor.opacity(0.4), lineWidth: 1))
            
            Button {
                exportRiskPDF()
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("QuestPDF Çek & Risk Analiz Raporu İndir")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "06B6D4"))
                .cornerRadius(10)
            }
            
            Text("Portföydeki Çeklerin Risk Dağılımı (\(ceklerList.count))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            if ceklerList.isEmpty {
                emptyBox("Portföyde analiz edilecek çek bulunamadı.")
            } else {
                ForEach(ceklerList) { c in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.cariUnvan ?? c.borclu ?? "Çek")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("Vade: \(String(c.vadeTarihi.prefix(10))) • \(c.banka ?? "-")")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(AppFormatters.money(c.tutar))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text(c.durum)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(c.durum.localizedCaseInsensitiveContains("karşılıksız") ? Color(hex: "EF4444") : Color(hex: "10B981"))
                        }
                    }
                    .padding(12)
                    .background(Color(hex: "121216"))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func exportRiskPDF() {
        #if canImport(UIKit)
        Task { @MainActor in
            isGeneratingPDF = true
            let headers = ["Keşideci / Borçlu", "Banka", "Vade", "Tutar", "Durum"]
            let rows = ceklerList.map { c in
                [c.cariUnvan ?? c.borclu ?? "-", c.banka ?? "-", String(c.vadeTarihi.prefix(10)), AppFormatters.money(c.tutar), c.durum]
            }
            let data = await PDFService.shared.fetchRemoteGenericTablePDF(
                title: "ÇEK RİSK ANALİZ RAPORU",
                headers: headers,
                rows: rows,
                subtitle: "Genel Güvenilirlik Puanı: \(Int(genelRiskPuani))/100 - \(riskAnalizOzeti)"
            ) ?? PDFService.shared.generateGenericReportPDF(
                title: "ÇEK RİSK ANALİZ RAPORU",
                subtitle: "Genel Puan: \(Int(genelRiskPuani))/100",
                headers: headers,
                rows: rows
            )
            isGeneratingPDF = false
            pdfPreviewItem = PDFPreviewItem(title: "Çek Risk Analiz Raporu", data: data, fileName: "Cek_Risk_Raporu.pdf")
        }
        #endif
    }
    
    // MARK: - 8. TOPLU FİYAT GÜNCELLEME (TopluFiyatViewModel Birebir)
    @ViewBuilder
    private func renderTopluFiyatGuncelleme() -> some View {
        let kategoriler = ["Tümü"] + Array(Set(dataStore.stoklar.compactMap { $0.grupAdi }.filter { !$0.isEmpty })).sorted()
        let filteredStoklar = dataStore.stoklar.filter { fiyatKategoriFilter == "Tümü" || $0.grupAdi == fiyatKategoriFilter }
        let oranDeger = Double(fiyatOranDegerStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let isZam = fiyatIslemYonu.contains("Zam")
        let isYuzde = fiyatDegisimTuru.contains("Yüzde")
        
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(kategoriler, id: \.self) { k in
                        let isSel = fiyatKategoriFilter == k
                        Button {
                            fiyatKategoriFilter = k
                        } label: {
                            Text(k)
                                .font(.system(size: 11, weight: isSel ? .bold : .medium))
                                .foregroundColor(isSel ? .white : Color(hex: "8E8E93"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSel ? Color(hex: "2563EB") : Color(hex: "121216"))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            HStack(spacing: 8) {
                Picker("Yön", selection: $fiyatIslemYonu) {
                    Text("Zam Yap (+)").tag("Zam Yap (Artır)")
                    Text("İndirim Yap (-)").tag("İndirim Yap (Azalt)")
                }
                .pickerStyle(.segmented)
                
                Picker("Tür", selection: $fiyatDegisimTuru) {
                    Text("Yüzde (%)").tag("Yüzde (%)")
                    Text("Tutar (₺)").tag("Sabit Tutar (TL)")
                }
                .pickerStyle(.segmented)
            }
            
            toolInput("Uygulanacak Oran veya Tutar", text: $fiyatOranDegerStr)
            
            Button {
                applyBulkPriceUpdate(items: filteredStoklar, oranDeger: oranDeger, isZam: isZam, isYuzde: isYuzde)
            } label: {
                HStack {
                    if isUpdatingPrices {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text("\(filteredStoklar.count) Ürünün Fiyatını Şimdi Güncelle")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "10B981"))
                .cornerRadius(12)
            }
            .disabled(filteredStoklar.isEmpty || isUpdatingPrices)
            
            Text("Fiyat Önizleme Listesi (\(filteredStoklar.count) Ürün)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            
            ForEach(filteredStoklar.prefix(40)) { s in
                let eski = s.satisFiyati
                let fark = isYuzde ? (eski * oranDeger / 100.0) : oranDeger
                let yeni = max(0, isZam ? (eski + fark) : (eski - fark))
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.stokAdi)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text(s.grupAdi ?? "Genel")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    Spacer()
                    Text("\(AppFormatters.money(eski)) → \(AppFormatters.money(yeni))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "00FF87"))
                }
                .padding(10)
                .background(Color(hex: "121216"))
                .cornerRadius(10)
            }
        }
    }
    
    private func applyBulkPriceUpdate(items: [StokKart], oranDeger: Double, isZam: Bool, isYuzde: Bool) {
        guard !items.isEmpty else { return }
        isUpdatingPrices = true
        Task {
            for var s in items {
                let eski = s.satisFiyati
                let fark = isYuzde ? (eski * oranDeger / 100.0) : oranDeger
                s.satisFiyati = max(0, (isZam ? (eski + fark) : (eski - fark)))
                try? await DataStore.shared.saveStok(s, isUpdate: true)
            }
            await DataStore.shared.loadStoklarCacheFirst(forceCloudRefresh: true)
            await MainActor.run {
                isUpdatingPrices = false
                statusBanner = "\(items.count) ürünün satış fiyatı başarıyla güncellendi."
            }
        }
    }
    
    // MARK: - 9. LİMİT YÖNETİMİ (MusteriLimitViewModel Birebir)
    @ViewBuilder
    private func renderLimitYonetimi() -> some View {
        let list = dataStore.cariler.filter {
            limitSearch.isEmpty || $0.unvan.localizedCaseInsensitiveContains(limitSearch)
        }
        
        VStack(alignment: .leading, spacing: 12) {
            TextField("Cari hesap ara...", text: $limitSearch)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(10)
                .background(Color(hex: "121216"))
                .cornerRadius(10)
            
            if list.isEmpty {
                emptyBox("Kayıtlı cari hesap bulunamadı.")
            } else {
                ForEach(list) { c in
                    let risk = max(0, c.bakiye)
                    let limit = c.riskLimiti ?? 0.0
                    let pct = limit > 0 ? min(100.0, (risk / limit) * 100.0) : (risk > 0 ? 100.0 : 0.0)
                    let barColor = pct >= 90 ? Color(hex: "EF4444") : (pct >= 65 ? Color(hex: "F59E0B") : Color(hex: "10B981"))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.unvan)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Mevcut Risk: \(AppFormatters.money(risk)) • Limit: \(AppFormatters.money(limit))")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "8E8E93"))
                            }
                            Spacer()
                            Button {
                                selectedCariForLimit = c
                                yeniLimitDegerStr = String(format: "%.0f", limit)
                                showLimitEditSheet = true
                            } label: {
                                Text("Limit Düzenle")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "2563EB"))
                                    .cornerRadius(8)
                            }
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(barColor)
                                    .frame(width: geo.size.width * CGFloat(pct / 100.0), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(14)
                    .background(Color(hex: "121216"))
                    .cornerRadius(14)
                }
            }
        }
    }
    
    // MARK: - 10. BÜTÇE PLANLAMA MERKEZİ (ButcePlanlamaViewModel Birebir)
    @ViewBuilder
    private func renderButcePlanlama() -> some View {
        let topGerceklesen = aylikButceler.reduce(0.0) { $0 + $1.gerceklesen }
        let topHedef = Double(yillikHedefStr.replacingOccurrences(of: ",", with: ".")) ?? aylikButceler.reduce(0.0) { $0 + $1.hedef }
        
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(seciliButceYili) Yılı Bütçe & Hedef Planlama")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    Task { @MainActor in
                        isGeneratingPDF = true
                        let data = await ReportCalculationService.shared.generateDesktopReportPDF(for: "Bütçe / Hedef Takibi", filter: "All")
                        isGeneratingPDF = false
                        pdfPreviewItem = PDFPreviewItem(title: "Bütçe ve Hedef Analiz Raporu", data: data, fileName: "Butce_Planlama_Raporu.pdf")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.fill")
                        Text("QuestPDF")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "0061FF"))
                    .cornerRadius(8)
                }
            }
            
            HStack(spacing: 10) {
                sysCard(title: "YILLIK HEDEF", val: AppFormatters.money(topHedef), sub: "\(seciliButceYili) Bütçesi", color: Color(hex: "3B82F6"))
                sysCard(title: "GERÇEKLEŞEN CİRO", val: AppFormatters.money(topGerceklesen), sub: topHedef > 0 ? String(format: "%%%.1f Tamamlandı", (topGerceklesen / topHedef) * 100.0) : "Canlı Satış", color: Color(hex: "10B981"))
            }
            
            HStack(spacing: 8) {
                toolInput("Yıllık Toplam Satış Hedefi (₺)", text: $yillikHedefStr)
                Button {
                    let yVal = Double(yillikHedefStr.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                    let perMonth = yVal / 12.0
                    for idx in aylikButceler.indices {
                        aylikButceler[idx].hedef = perMonth
                    }
                    saveBudgetTargetsToSupabase(annualTarget: yVal)
                } label: {
                    Text("12 Aya Dağıt & Kaydet")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color(hex: "10B981"))
                        .cornerRadius(10)
                }
            }
            
            ForEach(aylikButceler) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.ayAdi)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Gerçekleşen: \(AppFormatters.money(item.gerceklesen)) / Hedef: \(AppFormatters.money(item.hedef))")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "10B981"))
                                .frame(width: geo.size.width * CGFloat(item.oran / 100.0), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(12)
                .background(Color(hex: "121216"))
                .cornerRadius(12)
            }
        }
    }
    
    private func saveBudgetTargetsToSupabase(annualTarget: Double) {
        isSavingBudget = true
        Task {
            struct ExistingTargetRow: Decodable {
                let id: Int?
                let uuid: String?
                let ay: Int?
                
                enum CodingKeys: String, CodingKey {
                    case id, uuid, ay
                }
                init(from decoder: Decoder) throws {
                    let c = try decoder.container(keyedBy: CodingKeys.self)
                    if let intId = try? c.decode(Int.self, forKey: .id) {
                        self.id = intId
                    } else if let strId = try? c.decode(String.self, forKey: .id), let parsed = Int(strId) {
                        self.id = parsed
                    } else {
                        self.id = nil
                    }
                    self.uuid = try? c.decode(String.self, forKey: .uuid)
                    self.ay = try? c.decode(Int.self, forKey: .ay)
                }
            }
            
            let tenant = SupabaseService.shared.tenantId
            
            // 1. Yıllık hedef: mevcut kayıt varsa güncelle, yoksa ekle
            let existingYearly: [ExistingTargetRow] = (try? await SupabaseService.shared.fetch(
                from: "yillik_satis_hedefleri",
                filters: ["yil": "eq.\(seciliButceYili)"]
            )) ?? []
            
            if let existing = existingYearly.first {
                let updateDict: [String: Any] = [
                    "hedef_tutar": annualTarget,
                    "hedef_tutari": annualTarget,
                    "is_deleted": false
                ]
                if let d = try? JSONSerialization.data(withJSONObject: updateDict) {
                    let recId = existing.id != nil ? String(existing.id!) : (existing.uuid ?? "yillik_hedef_\(tenant)_\(seciliButceYili)")
                    try? await SupabaseService.shared.updateRaw(table: "yillik_satis_hedefleri", id: recId, data: d)
                }
            } else {
                let yPayload: [String: Any] = [
                    "uuid": "yillik_hedef_\(tenant)_\(seciliButceYili)",
                    "tenant_id": tenant,
                    "yil": seciliButceYili,
                    "hedef_tutar": annualTarget,
                    "hedef_tutari": annualTarget,
                    "is_deleted": false
                ]
                if let d = try? JSONSerialization.data(withJSONObject: yPayload) {
                    try? await SupabaseService.shared.upsertRaw(into: "yillik_satis_hedefleri", data: d, onConflict: "uuid")
                }
            }
            
            // 2. Aylık hedefler: mevcut kayıt varsa güncelle, yoksa ekle
            let existingMonthly: [ExistingTargetRow] = (try? await SupabaseService.shared.fetch(
                from: "satis_hedefleri",
                filters: ["yil": "eq.\(seciliButceYili)"]
            )) ?? []
            
            for m in aylikButceler {
                if let existingM = existingMonthly.first(where: { $0.ay == m.id }) {
                    let updateDict: [String: Any] = [
                        "hedef_tutar": m.hedef,
                        "hedef_tutari": m.hedef,
                        "gerceklesen_tutar": m.gerceklesen,
                        "is_deleted": false
                    ]
                    if let d = try? JSONSerialization.data(withJSONObject: updateDict) {
                        let recId = existingM.id != nil ? String(existingM.id!) : (existingM.uuid ?? "satis_hedef_\(tenant)_\(seciliButceYili)_\(m.id)")
                        try? await SupabaseService.shared.updateRaw(table: "satis_hedefleri", id: recId, data: d)
                    }
                } else {
                    let mPayload: [String: Any] = [
                        "uuid": "satis_hedef_\(tenant)_\(seciliButceYili)_\(m.id)",
                        "tenant_id": tenant,
                        "yil": seciliButceYili,
                        "ay": m.id,
                        "hedef_tutar": m.hedef,
                        "hedef_tutari": m.hedef,
                        "gerceklesen_tutar": m.gerceklesen,
                        "is_deleted": false
                    ]
                    if let d = try? JSONSerialization.data(withJSONObject: mPayload) {
                        try? await SupabaseService.shared.upsertRaw(into: "satis_hedefleri", data: d, onConflict: "uuid")
                    }
                }
            }
            await MainActor.run {
                isSavingBudget = false
                statusBanner = "\(seciliButceYili) yılı bütçe ve aylık hedefleri Supabase'e kaydedildi."
            }
        }
    }
    
    // MARK: - 11. PORTFÖY LİSTESİ (PortfoyListViewModel Birebir - public.portfoy_kartlar)
    @ViewBuilder
    private func renderPortfoyListesi() -> some View {
        let filtered = portfoyler.filter { p in
            !p.isDeleted &&
            (portfoySearch.isEmpty ||
             p.firmaIsmi.localizedCaseInsensitiveContains(portfoySearch) ||
             p.yetkiliKisi.localizedCaseInsensitiveContains(portfoySearch) ||
             p.sektor.localizedCaseInsensitiveContains(portfoySearch))
        }
        
        HStack {
            TextField("Firma, yetkili veya sektör ara...", text: $portfoySearch)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(10)
                .background(Color(hex: "121216"))
                .cornerRadius(10)
            
            Button {
                showPortfoyModal = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Yeni Aday")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: "10B981"))
                .cornerRadius(10)
            }
        }
        
        if filtered.isEmpty {
            emptyBox("Portföy listesinde kayıtlı müşteri adayı bulunmuyor.")
        } else {
            ForEach(filtered) { p in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.firmaIsmi)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(p.yetkiliKisi.isEmpty ? "Yetkili Belirtilmedi" : p.yetkiliKisi) • \(p.telefon.isEmpty ? p.gsm : p.telefon)")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        Spacer()
                        Text(p.gorusuldu ? "Görüşüldü" : "Bekliyor")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(p.gorusuldu ? Color(hex: "10B981") : Color(hex: "F59E0B"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((p.gorusuldu ? Color(hex: "10B981") : Color(hex: "F59E0B")).opacity(0.15))
                            .cornerRadius(6)
                    }
                    
                    Divider().background(Color.white.opacity(0.06))
                    
                    HStack(spacing: 10) {
                        Button {
                            transferPortfoyToCari(p)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                Text("Cariye Aktar")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "00FF87"))
                        }
                        
                        Spacer()
                        
                        Button {
                            deletePortfoy(p)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "EF4444"))
                        }
                    }
                }
                .padding(14)
                .background(Color(hex: "121216"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
    }
    
    private func transferPortfoyToCari(_ p: PortfoyKartKayit) {
        Task {
            let newCari = CariKart(
                id: UUID().uuidString,
                cariKodu: "MB-CR-\(Int.random(in: 100...999))",
                unvan: p.firmaIsmi,
                cariTuru: p.cariTipi,
                yetkili: p.yetkiliKisi,
                grup: p.cariTipi,
                vergiDairesi: p.vergiDairesi,
                vergiNo: p.vkn,
                telefon: p.telefon.isEmpty ? p.gsm : p.telefon,
                gsm: p.gsm,
                email: p.email,
                webSitesi: p.webSitesi,
                adres: p.adres,
                sehir: p.il,
                ilce: p.ilce,
                bakiye: p.acilisBakiyesi,
                riskLimiti: p.riskLimiti,
                vadeGunu: p.vadeGunu
            )
            do {
                try await DataStore.shared.saveCari(newCari, isUpdate: false)
                try await SupabaseService.shared.delete(table: "portfoy_kartlar", id: p.id)
                await MainActor.run {
                    portfoyler.removeAll { $0.id == p.id }
                    statusBanner = "'\(p.firmaIsmi)' başarıyla Cari Hesaplara aktarıldı!"
                }
            } catch {
                await MainActor.run {
                    statusBanner = "Aktarım başarısız: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deletePortfoy(_ p: PortfoyKartKayit) {
        portfoyler.removeAll { $0.id == p.id }
        Task {
            try? await SupabaseService.shared.delete(table: "portfoy_kartlar", id: p.id)
        }
    }
    
    private func openOrPreviewBelge(_ b: BelgeArsivKayit) {
        let veriStr = b.veri ?? ""
        let cleanBase64: String
        if veriStr.contains(",") {
            cleanBase64 = veriStr.components(separatedBy: ",").last ?? veriStr
        } else {
            cleanBase64 = veriStr
        }
        
        if let rawData = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters) {
            #if canImport(UIKit)
            if let img = UIImage(data: rawData) {
                previewImage = img
                showImagePreviewModal = true
                return
            }
            if b.tur.localizedCaseInsensitiveContains("pdf") || String(data: rawData.prefix(5), encoding: .utf8) == "%PDF-" {
                pdfPreviewItem = PDFPreviewItem(title: b.ad, data: rawData, fileName: "\(b.ad).pdf")
                return
            }
            #endif
        }
        
        shareBelge(b)
    }
    
    private func shareBelge(_ b: BelgeArsivKayit) {
        #if canImport(UIKit)
        let veriStr = b.veri ?? ""
        let cleanBase64: String
        if veriStr.contains(",") {
            cleanBase64 = veriStr.components(separatedBy: ",").last ?? veriStr
        } else {
            cleanBase64 = veriStr
        }
        
        var shareItems: [Any] = []
        if let rawData = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters) {
            if let img = UIImage(data: rawData) {
                shareItems.append(img)
            } else {
                let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(b.ad).\(b.tur.lowercased())")
                try? rawData.write(to: tempUrl)
                shareItems.append(tempUrl)
            }
        } else {
            shareItems.append(veriStr.isEmpty ? b.ad : veriStr)
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        
        let activityVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
        }
        rootVC.present(activityVC, animated: true)
        #endif
    }
    
    private func deleteBelge(_ b: BelgeArsivKayit) {
        belgeler.removeAll { $0.id == b.id }
        Task {
            try? await SupabaseService.shared.delete(table: "belge_arsiv", id: b.id)
        }
    }
    
    // MARK: - Modals
    private func yeniBelgeSheet() -> some View {
        NavigationStack {
            ZStack {
                Color(hex: "09090B").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        toolInput("Belge Adı *", text: $yeniBelgeAd)
                        Picker("Kategori", selection: $yeniBelgeKategori) {
                            ForEach(["Sözleşme", "Dekont", "İrsaliye", "Resmi Belge", "Diğer"], id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dosya veya Fotoğraf")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "8E8E93"))
                            
                            HStack(spacing: 12) {
                                PhotosPicker(selection: $selectedBelgePhotoItem, matching: .images) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "photo.badge.plus")
                                        Text("Fotoğraf")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(hex: "1F2937"))
                                    .cornerRadius(10)
                                }
                                
                                Button {
                                    showFilePicker = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.badge.plus")
                                        Text("Dosya (PDF)")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(hex: "1F2937"))
                                    .cornerRadius(10)
                                }
                            }
                            
                            if !yeniBelgeBoyut.isEmpty {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "10B981"))
                                    Text("Seçildi: \(yeniBelgeTur) • \(yeniBelgeBoyut)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "10B981"))
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(12)
                        .background(Color(hex: "121216"))
                        .cornerRadius(10)
                        
                        toolInput("Dosya Türü", text: $yeniBelgeTur)
                        toolInput("Açıklama / Not", text: $yeniBelgeIcerik)
                        
                        Button {
                            guard !yeniBelgeAd.isEmpty else { return }
                            let finalVeri = yeniBelgeBase64.isEmpty ? yeniBelgeIcerik : yeniBelgeBase64
                            let finalBoyut = yeniBelgeBoyut.isEmpty ? "\(max(1, finalVeri.count / 1024)) KB" : yeniBelgeBoyut
                            let b = BelgeArsivKayit(
                                ad: yeniBelgeAd,
                                kategori: yeniBelgeKategori,
                                tur: yeniBelgeTur,
                                boyut: finalBoyut,
                                tarih: AppFormatters.isoDate.string(from: Date()),
                                veri: finalVeri
                            )
                            belgeler.insert(b, at: 0)
                            Task {
                                try? await SupabaseService.shared.insert(into: "belge_arsiv", item: b)
                            }
                            yeniBelgeAd = ""
                            yeniBelgeIcerik = ""
                            yeniBelgeBase64 = ""
                            yeniBelgeBoyut = ""
                            showYeniBelgeModal = false
                        } label: {
                            Text("Belgeyi Arşive Kaydet")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "2563EB"))
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Yeni Belge Arşivle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { showYeniBelgeModal = false }
                }
            }
            .onChange(of: selectedBelgePhotoItem) { newItem in
                Task {
                    guard let item = newItem,
                          let data = try? await item.loadTransferable(type: Data.self) else { return }
                    #if canImport(UIKit)
                    if let image = UIImage(data: data),
                       let compressed = image.jpegData(compressionQuality: 0.7) {
                        await MainActor.run {
                            yeniBelgeBase64 = "data:image/jpeg;base64," + compressed.base64EncodedString()
                            yeniBelgeBoyut = "\(max(1, compressed.count / 1024)) KB"
                            yeniBelgeTur = "JPG"
                            if yeniBelgeAd.isEmpty {
                                yeniBelgeAd = "Görsel-\(Int(Date().timeIntervalSince1970))"
                            }
                        }
                        return
                    }
                    #endif
                    await MainActor.run {
                        yeniBelgeBase64 = data.base64EncodedString()
                        yeniBelgeBoyut = "\(max(1, data.count / 1024)) KB"
                        yeniBelgeTur = "Görsel"
                    }
                }
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .image, .item]) { result in
                switch result {
                case .success(let url):
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        yeniBelgeBase64 = data.base64EncodedString()
                        yeniBelgeBoyut = "\(max(1, data.count / 1024)) KB"
                        yeniBelgeTur = url.pathExtension.uppercased().isEmpty ? "PDF" : url.pathExtension.uppercased()
                        if yeniBelgeAd.isEmpty {
                            yeniBelgeAd = url.deletingPathExtension().lastPathComponent
                        }
                    }
                case .failure:
                    break
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func yeniPortfoySheet() -> some View {
        NavigationStack {
            ZStack {
                Color(hex: "09090B").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Picker("Sekme", selection: $portfoyFormTab) {
                            Text("1. Temel").tag(0)
                            Text("2. İletişim").tag(1)
                            Text("3. Risk & Not").tag(2)
                        }
                        .pickerStyle(.segmented)
                        
                        if portfoyFormTab == 0 {
                            toolInput("Firma / Müşteri Ünvanı *", text: $pFirmaIsmi)
                            toolInput("Yetkili Kişi", text: $pYetkili)
                            toolInput("Sektör", text: $pSektor)
                        } else if portfoyFormTab == 1 {
                            toolInput("Telefon / GSM", text: $pTelefon)
                            toolInput("E-Posta", text: $pEmail)
                            toolInput("İl / Şehir", text: $pIl)
                            toolInput("Adres", text: $pAdres)
                        } else {
                            toolInput("Vade Günü", text: $pVadeGunu)
                            toolInput("Risk Limiti (₺)", text: $pRiskLimiti)
                            toolInput("Açılış Bakiyesi (₺)", text: $pAcilisBakiyesi)
                            toolInput("Özel Notlar", text: $pNotlar)
                        }
                        
                        Button {
                            guard !pFirmaIsmi.isEmpty else { return }
                            let rec = PortfoyKartKayit(
                                firmaIsmi: pFirmaIsmi,
                                cariTipi: pCariTipi,
                                yetkiliKisi: pYetkili,
                                vadeGunu: Int(pVadeGunu) ?? 30,
                                riskLimiti: Double(pRiskLimiti.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                                gsm: pTelefon,
                                telefon: pTelefon,
                                email: pEmail,
                                il: pIl,
                                adres: pAdres,
                                sektor: pSektor,
                                acilisBakiyesi: Double(pAcilisBakiyesi.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                                notlar: pNotlar
                            )
                            portfoyler.insert(rec, at: 0)
                            Task {
                                try? await SupabaseService.shared.insert(into: "portfoy_kartlar", item: rec)
                            }
                            pFirmaIsmi = ""
                            pYetkili = ""
                            pTelefon = ""
                            showPortfoyModal = false
                        } label: {
                            Text("Portföy Kartını Kaydet")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "10B981"))
                                .cornerRadius(12)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Yeni Portföy Kartı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { showPortfoyModal = false }
                }
            }
        }
    }
    
    private func limitEditModal() -> some View {
        NavigationStack {
            ZStack {
                Color(hex: "09090B").ignoresSafeArea()
                VStack(spacing: 14) {
                    Text(selectedCariForLimit?.unvan ?? "Cari")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    toolInput("Yeni Kredi / Risk Limiti (₺)", text: $yeniLimitDegerStr)
                    
                    Button {
                        guard var c = selectedCariForLimit,
                              let val = Double(yeniLimitDegerStr.replacingOccurrences(of: ",", with: ".")) else { return }
                        c.riskLimiti = val
                        Task {
                            try? await DataStore.shared.saveCari(c, isUpdate: true)
                            await DataStore.shared.loadCarilerCacheFirst(forceCloudRefresh: true)
                            await MainActor.run {
                                showLimitEditSheet = false
                                statusBanner = "'\(c.unvan)' risk limiti \(AppFormatters.money(val)) olarak güncellendi."
                            }
                        }
                    } label: {
                        Text("Limiti Kaydet")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "2563EB"))
                            .cornerRadius(12)
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Kredi Limiti Güncelle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { showLimitEditSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Shared UI Helpers
    private func sysCard(title: String, val: String, sub: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "8E8E93"))
            Text(val)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.system(size: 10))
                .foregroundColor(color)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "121216"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.3), lineWidth: 1))
    }
    
    private func pickerBox(title: String, val: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
            HStack {
                Text(val)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(Color(hex: "8E8E93"))
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.35), lineWidth: 1))
    }
    
    private func toolInput(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "8E8E93"))
            TextField(label, text: text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(11)
                .background(Color(hex: "121216"))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }
    
    private func emptyBox(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "8E8E93"))
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(hex: "121216"))
            .cornerRadius(14)
    }
    
    // MARK: - Data Loading (100% Live Supabase)
    private func loadAllToolsData() async {
        await MainActor.run { isLoading = true }
        async let bFetch: [BelgeArsivKayit]? = try? SupabaseService.shared.fetch(from: "belge_arsiv")
        async let pFetch: [PortfoyKartKayit]? = try? SupabaseService.shared.fetch(from: "portfoy_kartlar")
        async let cFetch: [Cek]? = try? SupabaseService.shared.fetch(from: "cekler")
        async let hFetch: [SatisHedefRow]? = try? SupabaseService.shared.fetch(from: "satis_hedefleri")
        async let yhFetch: [SatisHedefRow]? = try? SupabaseService.shared.fetch(from: "yillik_satis_hedefleri")
        async let dFetch: [DovizKuru]? = try? SupabaseService.shared.fetch(from: "doviz_kurlari")
        
        let (bRes, pRes, cRes, hRes, yhRes, dRes) = await (bFetch, pFetch, cFetch, hFetch, yhFetch, dFetch)
        let faturalar = dataStore.faturalar
        let satisFaturalari = faturalar.filter { $0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis") }
        
        let ayAdlari = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
        let hedeflerList = hRes ?? []
        var builtMonths: [AylikButceItem] = []
        for m in 1...12 {
            let matchedHedef = hedeflerList.first { item in
                let itemYil = item.yil ?? seciliButceYili
                return itemYil == seciliButceYili && item.ay == m
            }
            let tgt = matchedHedef?.effectiveHedef ?? 0.0
            let p1 = String(format: "%04d-%02d", seciliButceYili, m)
            let p2 = String(format: ".%02d.%04d", m, seciliButceYili)
            let act = satisFaturalari.filter { f in
                f.tarih.hasPrefix(p1) || f.tarih.hasSuffix(p2)
            }.reduce(0.0) { (sum: Double, f: Fatura) in sum + f.genelToplam }
            builtMonths.append(AylikButceItem(id: m, ayAdi: ayAdlari[m - 1], hedef: tgt, gerceklesen: act))
        }
        let yillikHedeflerList = yhRes ?? []
        let matchedYHedef = yillikHedeflerList.first { $0.yil == seciliButceYili }
        let sumAylikHedef = builtMonths.reduce(0.0) { (sum: Double, item: AylikButceItem) in sum + item.hedef }
        let yHedef = matchedYHedef?.effectiveHedef ?? sumAylikHedef
        
        // Risk Hesaplama (CekRiskAnalizViewModel Birebir)
        let cekList = cRes ?? []
        var score = 85.0
        let karsiliksizCount = cekList.filter { $0.durum.localizedCaseInsensitiveContains("karşılıksız") || $0.durum.localizedCaseInsensitiveContains("protesto") }.count
        let odendiCount = cekList.filter { $0.durum.localizedCaseInsensitiveContains("tahsil") || $0.durum.localizedCaseInsensitiveContains("ödendi") }.count
        score -= Double(karsiliksizCount * 20)
        score += Double(min(15, odendiCount * 2))
        let clampedScore = max(0.0, min(100.0, score))
        let ozet: String
        if clampedScore >= 75 {
            ozet = "Düşük Risk - Yüksek Güvenilirlik (Ödeme Performansı Güçlü)"
        } else if clampedScore >= 50 {
            ozet = "Orta Risk - Standart Takip Önerilir"
        } else {
            ozet = "Yüksek Risk - Vadeli İşlemlerde Teminat Alınmalı!"
        }
        
        await MainActor.run {
            self.belgeler = bRes ?? []
            self.portfoyler = pRes ?? []
            self.ceklerList = cekList
            self.aylikButceler = builtMonths
            self.yillikHedefStr = String(format: "%.0f", yHedef)
            self.genelRiskPuani = clampedScore
            self.riskAnalizOzeti = ozet
            if let kurlar = dRes, !kurlar.isEmpty {
                if let u = kurlar.first(where: { $0.kod == "USD" }), u.satis > 0 { self.usdRate = u.satis }
                if let e = kurlar.first(where: { $0.kod == "EUR" }), e.satis > 0 { self.eurRate = e.satis }
                if let g = kurlar.first(where: { $0.kod == "GBP" }), g.satis > 0 { self.gbpRate = g.satis }
            }
            self.kurSonGuncelleme = AppFormatters.shortDate.string(from: Date())
            self.isLoading = false
        }
    }
    
    private func refreshExchangeRates() async {
        // TCMB / Açık kur API'sinden güncel kurları çekip Supabase doviz_kurlari tablosunu günceller
        if let url = URL(string: "https://open.er-api.com/v6/latest/USD") {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rates = json["rates"] as? [String: Double],
               let tryRate = rates["TRY"], tryRate > 0 {
                let eurToUsd = rates["EUR"] ?? 0.92
                let gbpToUsd = rates["GBP"] ?? 0.78
                let newUsd = tryRate
                let newEur = eurToUsd > 0 ? (tryRate / eurToUsd) : self.eurRate
                let newGbp = gbpToUsd > 0 ? (tryRate / gbpToUsd) : self.gbpRate
                await MainActor.run {
                    self.usdRate = newUsd
                    self.eurRate = newEur
                    self.gbpRate = newGbp
                    self.kurSonGuncelleme = AppFormatters.shortDate.string(from: Date())
                    self.statusBanner = "Canlı döviz kurları başarıyla güncellendi."
                }
            }
        }
    }
}
