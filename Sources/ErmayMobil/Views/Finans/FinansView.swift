import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct FinansProjeksiyonKalemi: Identifiable {
    public let id = UUID()
    public let vadeTarihi: String
    public let gunKaldi: Int
    public let unvan: String
    public let islemTuru: String
    public let tutar: Double
    public let isGiris: Bool
}

public struct FinansView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var activeTab: String = "dashboard" // "dashboard", "nakit", "cekler", "kredikarti", "havale"
    @State private var isLoading: Bool = false
    
    // Canlı Veriler (Supabase)
    @State private var kasalar: [KasaBanka] = []
    @State private var bankalar: [BankaKart] = []
    @State private var kasaHareketler: [KasaHareket] = []
    @State private var bankaHareketler: [BankaHareket] = []
    @State private var cekler: [Cek] = []
    @State private var senetler: [Senet] = []
    @State private var kkIslemler: [KrediKartiIslem] = []
    @State private var eftIslemler: [EftIslem] = []
    @State private var faturalar: [Fatura] = []
    @State private var cariler: [CariKart] = []
    
    // Modals & Forms
    @State private var showTahsilatSheet: Bool = false
    @State private var isTahsilatMode: Bool = true
    @State private var showKasaSayim: Bool = false
    @State private var showYeniKasaSheet: Bool = false
    @State private var showYeniBankaSheet: Bool = false
    @State private var showYeniCekSheet: Bool = false
    @State private var showYeniKKSheet: Bool = false
    @State private var showYeniEftSheet: Bool = false
    @State private var pdfPreviewItem: PDFPreviewItem? = nil
    @State private var isGeneratingPDF: Bool = false
    
    // Yeni Kasa Form
    @State private var yeniKasaAdi: String = ""
    @State private var yeniKasaDoviz: String = "TRY"
    @State private var yeniKasaAcilis: String = "0"
    
    // Yeni Banka Form
    @State private var yeniBankaAdi: String = ""
    @State private var yeniBankaSube: String = ""
    @State private var yeniBankaIban: String = ""
    @State private var yeniBankaDoviz: String = "TL"
    @State private var yeniBankaAcilis: String = "0"
    
    // Yeni Çek Form
    @State private var yeniCekNo: String = ""
    @State private var yeniCekCari: CariKart? = nil
    @State private var yeniCekBanka: String = ""
    @State private var yeniCekSube: String = ""
    @State private var yeniCekTutar: String = ""
    @State private var yeniCekVade: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var yeniCekTuru: String = "Alınan"
    @State private var showCariPickerForCek: Bool = false
    
    // Yeni Kredi Kartı Form
    @State private var yeniKKCari: CariKart? = nil
    @State private var yeniKKYonlendirilenCari: CariKart? = nil
    @State private var yeniKKBanka: String = ""
    @State private var yeniKKKartNo: String = ""
    @State private var yeniKKOnayKodu: String = ""
    @State private var yeniKKTutar: String = ""
    @State private var yeniKKAciklama: String = ""
    @State private var showCariPickerForKK: Bool = false
    @State private var showYonCariPickerForKK: Bool = false
    
    // Yeni EFT Form
    @State private var yeniEftCari: CariKart? = nil
    @State private var yeniEftYonlendirilenCari: CariKart? = nil
    @State private var yeniEftBanka: String = ""
    @State private var yeniEftHesapNo: String = ""
    @State private var yeniEftDekontNo: String = ""
    @State private var yeniEftTutar: String = ""
    @State private var yeniEftDurum: String = "Tamamlandı"
    @State private var yeniEftAciklama: String = ""
    @State private var showCariPickerForEft: Bool = false
    @State private var showYonCariPickerForEft: Bool = false
    
    public init() {}
    
    // MARK: - Masaüstü FinansDashboardViewModel Birebir Hesaplamalar
    private var kasaToplam: Double {
        kasalar.reduce(0.0) { $0 + $1.bakiye }
    }
    private var bankaToplam: Double {
        bankalar.reduce(0.0) { $0 + $1.bakiye }
    }
    private var cekSenetToplam: Double {
        cekler.filter { !$0.durum.localizedCaseInsensitiveContains("tahsil") && !$0.durum.localizedCaseInsensitiveContains("iptal") }
            .reduce(0.0) { $0 + $1.tutar } +
        senetler.filter { !$0.durum.localizedCaseInsensitiveContains("tahsil") }
            .reduce(0.0) { $0 + $1.tutar }
    }
    
    private var kendiNakitTahsilat: Double {
        kasaHareketler.filter { $0.yonlendirilenCariId == nil }.reduce(0.0) { $0 + $1.giren }
    }
    private var yonlendirilenNakit: Double {
        kasaHareketler.filter { $0.yonlendirilenCariId != nil }.reduce(0.0) { $0 + max($1.giren, $1.cikan) }
    }
    private var kendiKKTahsilat: Double {
        kkIslemler.filter { $0.yonlendirilenCariId == nil }.reduce(0.0) { $0 + $1.tutar }
    }
    private var yonlendirilenKK: Double {
        kkIslemler.filter { $0.yonlendirilenCariId != nil }.reduce(0.0) { $0 + $1.tutar }
    }
    private var kendiEftTahsilat: Double {
        eftIslemler.filter { $0.yonlendirilenCariId == nil }.reduce(0.0) { $0 + $1.tutar }
    }
    private var yonlendirilenEft: Double {
        eftIslemler.filter { $0.yonlendirilenCariId != nil }.reduce(0.0) { $0 + $1.tutar }
    }
    private var kendiCekTahsilat: Double {
        cekler.filter { !$0.durum.localizedCaseInsensitiveContains("ciro") }.reduce(0.0) { $0 + $1.tutar }
    }
    private var yonlendirilenCek: Double {
        cekler.filter { $0.durum.localizedCaseInsensitiveContains("ciro") }.reduce(0.0) { $0 + $1.tutar }
    }
    
    private var kendiKasamizdaKalanToplam: Double {
        kendiNakitTahsilat + kendiKKTahsilat + kendiEftTahsilat + kendiCekTahsilat
    }
    private var yonlendirilenTedarikciToplam: Double {
        yonlendirilenNakit + yonlendirilenKK + yonlendirilenEft + yonlendirilenCek
    }
    private var musteriTahsilatToplam: Double {
        kendiKasamizdaKalanToplam + yonlendirilenTedarikciToplam
    }
    private var tedarikciOdemeToplam: Double {
        kasaHareketler.reduce(0.0) { $0 + $1.cikan } + yonlendirilenTedarikciToplam
    }
    private var netBakiye: Double {
        musteriTahsilatToplam - tedarikciOdemeToplam
    }
    
    private var toplamSatisCirosu: Double {
        faturalar.filter { $0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis") }
            .reduce(0.0) { $0 + $1.genelToplam }
    }
    private var toplamAlisTutari: Double {
        faturalar.filter { $0.faturaTuru.localizedCaseInsensitiveContains("alış") || $0.faturaTuru.localizedCaseInsensitiveContains("alis") }
            .reduce(0.0) { $0 + $1.genelToplam }
    }
    private var kalanAlisBorcu: Double {
        max(0, toplamAlisTutari - tedarikciOdemeToplam)
    }
    private var alisTamamlanmaYuzdesi: Double {
        guard toplamAlisTutari > 0 else { return 0 }
        return min(100.0, (tedarikciOdemeToplam / toplamAlisTutari) * 100.0)
    }
    private var kendiKasamizdaKalanYuzdesi: Double {
        let base = max(toplamSatisCirosu, musteriTahsilatToplam)
        guard base > 0 else { return 0 }
        return min(100.0, (kendiKasamizdaKalanToplam / base) * 100.0)
    }
    
    private var gelecekProjeksiyon: [FinansProjeksiyonKalemi] {
        var list: [FinansProjeksiyonKalemi] = []
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for c in cekler where !c.durum.localizedCaseInsensitiveContains("tahsil") {
            if let vd = AppFormatters.parseDate(String(c.vadeTarihi.prefix(10))) ?? AppFormatters.parseDate(c.vadeTarihi) {
                let diff = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: vd)).day ?? 0
                if diff >= 0 && diff <= 30 {
                    let isGiris = !(c.cekTuru ?? "").localizedCaseInsensitiveContains("verilen") && !(c.cekTuru ?? "").localizedCaseInsensitiveContains("firma")
                    list.append(FinansProjeksiyonKalemi(
                        vadeTarihi: AppFormatters.shortDate.string(from: vd),
                        gunKaldi: diff,
                        unvan: c.cariUnvan ?? c.borclu ?? "Çek",
                        islemTuru: isGiris ? "Alınan Çek Vadesi" : "Verilen Çek Ödemesi",
                        tutar: c.tutar,
                        isGiris: isGiris
                    ))
                }
            }
        }
        for f in faturalar {
            let vStr = f.vadeTarihi ?? f.tarih
            if let vd = AppFormatters.parseDate(String(vStr.prefix(10))) ?? AppFormatters.parseDate(vStr) {
                let diff = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: vd)).day ?? 0
                if diff >= 0 && diff <= 30 {
                    let isSatis = f.faturaTuru.localizedCaseInsensitiveContains("satış") || f.faturaTuru.localizedCaseInsensitiveContains("satis")
                    list.append(FinansProjeksiyonKalemi(
                        vadeTarihi: AppFormatters.shortDate.string(from: vd),
                        gunKaldi: diff,
                        unvan: f.cariUnvan ?? f.faturaNo,
                        islemTuru: isSatis ? "Satış Faturası Vadesi" : "Alış Faturası Vadesi",
                        tutar: f.genelToplam,
                        isGiris: isSatis
                    ))
                }
            }
        }
        return list.sorted { $0.gunKaldi < $1.gunKaldi }
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Button {
                        if activeTab != "dashboard" {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTab = "dashboard"
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
                        Text("Finans & Hazine")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Masaüstü Birebir Finans Yönetimi")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    
                    Spacer()
                    
                    if isLoading || isGeneratingPDF {
                        ProgressView().tint(.white).padding(.trailing, 6)
                    }
                    
                    Button {
                        exportFinansPDF()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text.fill")
                            Text("PDF")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(hex: "0061FF"))
                        .cornerRadius(8)
                    }
                    
                    Button {
                        isTahsilatMode = true
                        showTahsilatSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("İşlem")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(hex: "10B981"))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                // 5 Masaüstü Sekmesi: Genel Özet | Nakit | Çekler | Kredi Kartı | Havale/EFT
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        tabButton(id: "dashboard", label: "Genel Özet", icon: "chart.pie.fill")
                        tabButton(id: "nakit", label: "Nakit / Kasa", icon: "banknote.fill")
                        tabButton(id: "cekler", label: "Çek / Senet", icon: "doc.plaintext.fill")
                        tabButton(id: "kredikarti", label: "Kredi Kartı", icon: "creditcard.fill")
                        tabButton(id: "havale", label: "Havale / EFT", icon: "building.columns.fill")
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        switch activeTab {
                        case "dashboard":
                            renderDashboardTab()
                        case "nakit":
                            renderNakitTab()
                        case "cekler":
                            renderCeklerTab()
                        case "kredikarti":
                            renderKrediKartiTab()
                        case "havale":
                            renderHavaleEftTab()
                        default:
                            renderDashboardTab()
                        }
                        Spacer().frame(height: 90)
                    }
                    .padding(.horizontal, 16)
                }
                .refreshable {
                    await loadFinansData()
                }
            }
        }
        .navigationBarHidden(true)
        .enableSwipeBack {
            if activeTab != "dashboard" {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeTab = "dashboard"
                }
            } else {
                dismiss()
            }
        }
        .task {
            await loadFinansData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .supabaseRealtimeDataChanged)) { _ in
            Task { await loadFinansData() }
        }
        .sheet(isPresented: $showTahsilatSheet) {
            TahsilatFormView(isTahsilat: isTahsilatMode) { _ in
                Task { await loadFinansData() }
            }
        }
        .sheet(isPresented: $showKasaSayim) {
            KasaSayimView(sistemBakiye: kasalar.first?.bakiye ?? kasaToplam, kasalar: kasalar)
        }
        .sheet(isPresented: $showYeniKasaSheet) {
            yeniKasaModal()
        }
        .sheet(isPresented: $showYeniBankaSheet) {
            yeniBankaModal()
        }
        .sheet(isPresented: $showYeniCekSheet) {
            yeniCekModal()
        }
        .sheet(isPresented: $showYeniKKSheet) {
            yeniKKModal()
        }
        .sheet(isPresented: $showYeniEftSheet) {
            yeniEftModal()
        }
        .sheet(item: $pdfPreviewItem) { item in
            #if canImport(UIKit)
            PDFViewerModal(title: item.title, pdfData: item.data, fileName: item.fileName)
            #endif
        }
    }
    
    private func tabButton(id: String, label: String, icon: String) -> some View {
        let isSel = activeTab == id
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeTab = id
            }
            HardwareService.shared.hapticSelection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: isSel ? .bold : .medium))
            }
            .foregroundColor(isSel ? .white : Color(hex: "8E8E93"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSel ? Color(hex: "2563EB") : Color(hex: "121216"))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSel ? Color(hex: "3B82F6") : Color.white.opacity(0.08), lineWidth: 1))
        }
    }
    
    // MARK: - 1. DASHBOARD SEKME (FinansDashboardViewModel Birebir)
    @ViewBuilder
    private func renderDashboardTab() -> some View {
        // Hızlı İşlem Satırı
        HStack(spacing: 8) {
            Button {
                isTahsilatMode = true
                showTahsilatSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.left.circle.fill")
                    Text("Tahsilat Ekle")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "10B981"))
                .cornerRadius(10)
            }
            
            Button {
                isTahsilatMode = false
                showTahsilatSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.circle.fill")
                    Text("Ödeme Ekle")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "EF4444"))
                .cornerRadius(10)
            }
            
            Button {
                showKasaSayim = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.forwardslash.minus")
                    Image(systemName: "banknote")
                    Text("Kasa Sayım")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: "3B82F6"))
                .cornerRadius(10)
            }
        }
        
        // 6 KPI Kartı (Masaüstü FinansDashboardViewModel Birebir)
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            kpiCard(title: "MÜŞTERİ TAHSİLAT", value: AppFormatters.money(musteriTahsilatToplam), sub: "Toplam Giriş", color: Color(hex: "10B981"), icon: "arrow.down.left.circle.fill")
            kpiCard(title: "TEDARİKÇİ ÖDEME", value: AppFormatters.money(tedarikciOdemeToplam), sub: "Toplam Çıkış", color: Color(hex: "EF4444"), icon: "arrow.up.right.circle.fill")
            kpiCard(title: "KASA TOPLAM", value: AppFormatters.money(kasaToplam), sub: "\(kasalar.count) Aktif Kasa", color: Color(hex: "30D158"), icon: "banknote.fill")
            kpiCard(title: "BANKA TOPLAM", value: AppFormatters.money(bankaToplam), sub: "\(bankalar.count) Banka Hesabı", color: Color(hex: "3B82F6"), icon: "building.columns.fill")
            kpiCard(title: "ÇEK / SENET PORTFÖY", value: AppFormatters.money(cekSenetToplam), sub: "\(cekler.count) Çek • \(senetler.count) Senet", color: Color(hex: "F59E0B"), icon: "doc.plaintext.fill")
            kpiCard(title: "NET FİNANSAL AKIŞ", value: AppFormatters.money(netBakiye), sub: netBakiye >= 0 ? "Pozitif Nakit Dengesi" : "Negatif Nakit Dengesi", color: netBakiye >= 0 ? Color(hex: "00FF87") : Color(hex: "FF453A"), icon: "waveform.path.ecg")
        }
        
        // Ciro vs Kendi Kasamızda Kalan Analizi (Masaüstü Özel Bölüm)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(Color(hex: "10B981"))
                Text("Ciro & Kendi Kasamızda Kalan Analizi")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "%%%.1f Öz Nakit", kendiKasamizdaKalanYuzdesi))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "10B981"))
            }
            
            HStack(spacing: 10) {
                miniMetric(label: "Satış Cirosu", val: AppFormatters.money(toplamSatisCirosu), color: .white)
                miniMetric(label: "Kasada Kalan", val: AppFormatters.money(kendiKasamizdaKalanToplam), color: Color(hex: "10B981"))
                miniMetric(label: "Yönlendirilen", val: AppFormatters.money(yonlendirilenTedarikciToplam), color: Color(hex: "F59E0B"))
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            VStack(spacing: 6) {
                flowCompareRow(label: "Nakit", kendi: kendiNakitTahsilat, yon: yonlendirilenNakit)
                flowCompareRow(label: "Kredi Kartı", kendi: kendiKKTahsilat, yon: yonlendirilenKK)
                flowCompareRow(label: "Havale / EFT", kendi: kendiEftTahsilat, yon: yonlendirilenEft)
                flowCompareRow(label: "Çek / Senet", kendi: kendiCekTahsilat, yon: yonlendirilenCek)
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        
        // Alış Faturaları Kapatma Durumu (Masaüstü Birebir)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Color(hex: "3B82F6"))
                Text("Alış Faturaları Kapatma Durumu")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "%%%.1f Ödendi", alisTamamlanmaYuzdesi))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "60A5FA"))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "3B82F6"))
                        .frame(width: geo.size.width * CGFloat(alisTamamlanmaYuzdesi / 100.0), height: 10)
                }
            }
            .frame(height: 10)
            
            HStack {
                Text("Toplam Alış: \(AppFormatters.money(toplamAlisTutari))")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8E8E93"))
                Spacer()
                Text("Kalan Borç: \(AppFormatters.money(kalanAlisBorcu))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "EF4444"))
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        
        // 30 Günlük Gelecek Projeksiyon Takvimi (Masaüstü Birebir)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(Color(hex: "F59E0B"))
                Text("30 Günlük Gelecek Projeksiyon Takvimi")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(gelecekProjeksiyon.count) Kayıt")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            if gelecekProjeksiyon.isEmpty {
                Text("Önümüzdeki 30 gün içinde vadesi gelen çek, senet veya fatura bulunmuyor.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .padding(.vertical, 8)
            } else {
                ForEach(gelecekProjeksiyon.prefix(8)) { p in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.unvan)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("\(p.islemTuru) • \(p.vadeTarihi) (\(p.gunKaldi) gün kaldı)")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        Spacer()
                        Text("\(p.isGiris ? "+" : "-")\(AppFormatters.money(p.tutar))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(p.isGiris ? Color(hex: "10B981") : Color(hex: "EF4444"))
                    }
                    .padding(.vertical, 6)
                    Divider().background(Color.white.opacity(0.05))
                }
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    // MARK: - 2. NAKİT / KASA SEKME
    @ViewBuilder
    private func renderNakitTab() -> some View {
        HStack {
            Text("Kasa Hesapları (\(kasalar.count))")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button {
                showYeniKasaSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Yeni Kasa")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "10B981"))
            }
        }
        
        if kasalar.isEmpty {
            emptyStateBox(text: "Kayıtlı kasa hesabı bulunamadı.")
        } else {
            ForEach(kasalar) { k in
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "10B981").opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "banknote.fill")
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(k.hesapAdi)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("Döviz: \(k.dovizCinsi ?? "TRY")")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    Spacer()
                    Text(AppFormatters.money(k.bakiye))
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(Color(hex: "10B981"))
                }
                .padding(14)
                .background(Color(hex: "121216"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
        
        HStack {
            Text("Kasa Nakit Hareketleri (\(kasaHareketler.count))")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.top, 6)
        
        if kasaHareketler.isEmpty {
            emptyStateBox(text: "Kayıtlı kasa hareketi bulunmuyor.")
        } else {
            ForEach(kasaHareketler.sorted(by: { $0.tarih > $1.tarih })) { h in
                let isIn = h.giren >= h.cikan && h.giren > 0
                HStack {
                    Image(systemName: isIn ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isIn ? Color(hex: "10B981") : Color(hex: "EF4444"))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(h.cariUnvan ?? h.aciklama ?? h.islemTuru)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(String(h.tarih.prefix(10))) • \(h.islemTuru)")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(isIn ? "+" : "-")\(AppFormatters.money(h.tutar))")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(isIn ? Color(hex: "10B981") : Color(hex: "EF4444"))
                        
                        Button {
                            openMakbuzPDF(hareket: h)
                        } label: {
                            Text("Makbuz PDF")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "60A5FA"))
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: "121216"))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
            }
        }
    }
    
    // MARK: - 3. ÇEK / SENET SEKME
    @ViewBuilder
    private func renderCeklerTab() -> some View {
        HStack {
            Text("Çek & Senet Portföyü (\(cekler.count + senetler.count))")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button {
                showYeniCekSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Yeni Çek Ekle")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "F59E0B"))
            }
        }
        
        if cekler.isEmpty && senetler.isEmpty {
            emptyStateBox(text: "Kayıtlı çek veya senet bulunmuyor.")
        } else {
            ForEach(cekler) { c in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(c.cariUnvan ?? c.borclu ?? "Çek Kaydı")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(c.durum)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "F59E0B"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "F59E0B").opacity(0.15))
                            .cornerRadius(6)
                    }
                    
                    HStack {
                        Text("\(c.banka ?? "-") • No: \(c.cekSenetNo) • Vade: \(String(c.vadeTarihi.prefix(10)))")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                        Text(AppFormatters.money(c.tutar))
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                }
                .padding(14)
                .background(Color(hex: "121216"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            
            ForEach(senetler) { s in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(s.cariUnvan ?? s.borclu ?? "Senet Kaydı")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(s.durum)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "60A5FA"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "60A5FA").opacity(0.15))
                            .cornerRadius(6)
                    }
                    
                    HStack {
                        Text("SENET • No: \(s.senetNo ?? "-") • Vade: \(String(s.vadeTarihi.prefix(10)))")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                        Text(AppFormatters.money(s.tutar))
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                }
                .padding(14)
                .background(Color(hex: "121216"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
    }
    
    // MARK: - 4. KREDİ KARTI SEKME
    @ViewBuilder
    private func renderKrediKartiTab() -> some View {
        HStack(spacing: 10) {
            miniMetric(label: "Toplam Çekim", val: AppFormatters.money(kendiKKTahsilat + yonlendirilenKK), color: Color(hex: "10B981"))
            miniMetric(label: "Kasada Kalan", val: AppFormatters.money(kendiKKTahsilat), color: Color(hex: "3B82F6"))
            miniMetric(label: "Yönlendirilen", val: AppFormatters.money(yonlendirilenKK), color: Color(hex: "F59E0B"))
        }
        
        HStack {
            Text("Kredi Kartı / POS İşlemleri (\(kkIslemler.count))")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button {
                showYeniKKSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Yeni POS / KK")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "3B82F6"))
            }
        }
        
        if kkIslemler.isEmpty {
            emptyStateBox(text: "Kayıtlı kredi kartı işlemi bulunmuyor.")
        } else {
            ForEach(kkIslemler.sorted(by: { $0.tarih > $1.tarih })) { k in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(k.musteriUnvan ?? "Müşteri")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(AppFormatters.money(k.tutar))
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    HStack {
                        Text("\(String(k.tarih.prefix(10))) • \(k.banka ?? "POS") • Onay: \(k.onayKodu ?? "-")")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                        if let yon = k.yonlendirilenCariUnvan, !yon.isEmpty {
                            Text("Yönl: \(yon)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "F59E0B"))
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
    
    // MARK: - 5. HAVALE / EFT & BANKA SEKME
    @ViewBuilder
    private func renderHavaleEftTab() -> some View {
        HStack {
            Text("Banka Hesapları (\(bankalar.count))")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button {
                showYeniBankaSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Yeni Banka")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "3B82F6"))
            }
        }
        
        if bankalar.isEmpty {
            emptyStateBox(text: "Kayıtlı banka hesabı bulunmuyor.")
        } else {
            ForEach(bankalar) { b in
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "3B82F6").opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "building.columns.fill")
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(b.bankaAdi)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text(b.iban ?? b.hesapNo ?? b.subeAdi ?? "-")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    Spacer()
                    Text(AppFormatters.money(b.bakiye))
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Color(hex: "60A5FA"))
                }
                .padding(14)
                .background(Color(hex: "121216"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
        
        HStack {
            Text("Havale / EFT İşlemleri (\(eftIslemler.count))")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button {
                showYeniEftSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Yeni Havale/EFT")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "10B981"))
            }
        }
        .padding(.top, 6)
        
        if eftIslemler.isEmpty {
            emptyStateBox(text: "Kayıtlı Havale / EFT işlemi bulunmuyor.")
        } else {
            ForEach(eftIslemler.sorted(by: { $0.tarih > $1.tarih })) { e in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(e.aliciUnvan)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(AppFormatters.money(e.tutar))
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    HStack {
                        Text("\(String(e.tarih.prefix(10))) • \(e.banka ?? "Banka") • Dekont: \(e.dekontNo ?? "-")")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                        Text(e.durum)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "60A5FA"))
                    }
                }
                .padding(14)
                .background(Color(hex: "121216"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
    }
    
    // MARK: - Form Modals (Supabase Senkronize)
    private func yeniKasaModal() -> some View {
        NavigationStack {
            ZStack {
                Color(hex: "09090B").ignoresSafeArea()
                VStack(spacing: 14) {
                    modalInput("Kasa Adı *", text: $yeniKasaAdi, placeholder: "Örn: Merkez Kasa")
                    modalInput("Para Birimi", text: $yeniKasaDoviz, placeholder: "TRY")
                    modalInput("Açılış Bakiyesi", text: $yeniKasaAcilis, placeholder: "0.00")
                    
                    Button {
                        guard !yeniKasaAdi.isEmpty else { return }
                        let b = Double(yeniKasaAcilis.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                        let newK = KasaBanka(id: "", hesapAdi: yeniKasaAdi, hesapTuru: "KASA", dovizCinsi: yeniKasaDoviz, bakiye: b)
                        kasalar.append(newK)
                        Task {
                            try? await SupabaseService.shared.insert(into: "kasalar", item: newK)
                            await loadFinansData()
                        }
                        yeniKasaAdi = ""
                        yeniKasaAcilis = "0"
                        showYeniKasaSheet = false
                    } label: {
                        Text("Kasayı Kaydet")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "10B981"))
                            .cornerRadius(12)
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Yeni Kasa Hesabı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { showYeniKasaSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func yeniBankaModal() -> some View {
        NavigationStack {
            ZStack {
                Color(hex: "09090B").ignoresSafeArea()
                VStack(spacing: 14) {
                    modalInput("Banka Adı *", text: $yeniBankaAdi, placeholder: "Örn: Garanti BBVA")
                    modalInput("Şube Adı", text: $yeniBankaSube, placeholder: "Ticari Şube")
                    modalInput("IBAN / Hesap No", text: $yeniBankaIban, placeholder: "TR...")
                    modalInput("Bakiye", text: $yeniBankaAcilis, placeholder: "0.00")
                    
                    Button {
                        guard !yeniBankaAdi.isEmpty else { return }
                        let b = Double(yeniBankaAcilis.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                        let newB = BankaKart(id: nil, bankaAdi: yeniBankaAdi, subeAdi: yeniBankaSube, hesapNo: yeniBankaIban, iban: yeniBankaIban, dovizTuru: yeniBankaDoviz, bakiye: b)
                        bankalar.append(newB)
                        Task {
                            try? await SupabaseService.shared.insert(into: "bankalar", item: newB)
                            await loadFinansData()
                        }
                        yeniBankaAdi = ""
                        yeniBankaIban = ""
                        yeniBankaAcilis = "0"
                        showYeniBankaSheet = false
                    } label: {
                        Text("Banka Hesabını Kaydet")
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
            .navigationTitle("Yeni Banka Hesabı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { showYeniBankaSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func yeniCekModal() -> some View {
        NavigationStack {
            ZStack {
                Color(hex: "09090B").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Button {
                            showCariPickerForCek = true
                        } label: {
                            HStack {
                                Text(yeniCekCari?.unvan ?? "Cari Seçiniz *")
                                    .foregroundColor(yeniCekCari == nil ? Color(hex: "8E8E93") : .white)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(12)
                            .background(Color(hex: "121216"))
                            .cornerRadius(10)
                        }
                        modalInput("Çek / Portföy No", text: $yeniCekNo, placeholder: "ÇK-001")
                        modalInput("Banka Adı", text: $yeniCekBanka, placeholder: "Banka")
                        modalInput("Şube", text: $yeniCekSube, placeholder: "Şube")
                        modalInput("Tutar (₺) *", text: $yeniCekTutar, placeholder: "0.00")
                        DatePicker("Vade Tarihi", selection: $yeniCekVade, displayedComponents: .date)
                            .colorScheme(.dark)
                            .foregroundColor(.white)
                        
                        Button {
                            guard let t = Double(yeniCekTutar.replacingOccurrences(of: ",", with: ".")), t > 0 else { return }
                            let todayIso = AppFormatters.isoDate.string(from: Date())
                            let cekBelgeNo = yeniCekNo.isEmpty ? "MB-CK-\(Int.random(in: 100...999))" : yeniCekNo
                            let newCek = Cek(
                                id: "",
                                cekNo: cekBelgeNo,
                                cariId: Int(yeniCekCari?.id ?? ""),
                                cariUnvan: yeniCekCari?.unvan ?? "Müşteri",
                                islemTarihi: todayIso,
                                portfoyNo: yeniCekNo,
                                vadeTarihi: AppFormatters.isoDate.string(from: yeniCekVade),
                                tutar: t,
                                borclu: yeniCekCari?.unvan,
                                banka: yeniCekBanka,
                                sube: yeniCekSube,
                                cekTuru: yeniCekTuru,
                                durum: "Portföyde"
                            )
                            let selectedCari = yeniCekCari
                            let isVerilen = yeniCekTuru.localizedCaseInsensitiveContains("verilen")
                            cekler.insert(newCek, at: 0)
                            Task {
                                try? await SupabaseService.shared.insert(into: "cekler", item: newCek)
                                if let c = selectedCari {
                                    let activeYearInt = Int(SupabaseService.shared.activeFiscalYear) ?? Calendar.current.component(.year, from: Date())
                                    let borcVal = isVerilen ? t : 0.0
                                    let alacakVal = isVerilen ? 0.0 : t
                                    let newSigned = c.signedBakiye + (borcVal - alacakVal)
                                    var chPayload: [String: Any] = [
                                        "uuid": UUID().uuidString.lowercased(),
                                        "tenant_id": SupabaseService.shared.tenantId,
                                        "mali_yil": activeYearInt,
                                        "cari_unvan": c.unvan,
                                        "evrak_no": cekBelgeNo,
                                        "belge_no": cekBelgeNo,
                                        "islem_turu": isVerilen ? "Ödeme (Çek)" : "Tahsilat (Çek)",
                                        "hareket_turu": isVerilen ? "Ödeme" : "Tahsilat",
                                        "odeme_sekli": "Çek",
                                        "borc": borcVal,
                                        "alacak": alacakVal,
                                        "bakiye": newSigned,
                                        "tarih": todayIso,
                                        "aciklama": "Çek Girişi (\(cekBelgeNo))",
                                        "is_deleted": false
                                    ]
                                    if let cIdInt = Int(c.id) { chPayload["cari_id"] = cIdInt }
                                    if let cUuid = c.syncGuid { chPayload["cari_uuid"] = cUuid }
                                    if let chData = try? JSONSerialization.data(withJSONObject: chPayload) {
                                        try? await SupabaseService.shared.insertRaw(into: "cari_hareketler", data: chData)
                                    }
                                    try? await SupabaseService.shared.update(
                                        table: "cariler",
                                        id: c.id,
                                        item: CariBakiyeUpdate(bakiye: newSigned, bakiyeTuru: newSigned >= 0 ? "B" : "A")
                                    )
                                }
                                await loadFinansData()
                            }
                            yeniCekTutar = ""
                            showYeniCekSheet = false
                        } label: {
                            Text("Çeki Kaydet")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "F59E0B"))
                                .cornerRadius(12)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Yeni Çek Girişi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { showYeniCekSheet = false }
                }
            }
            .sheet(isPresented: $showCariPickerForCek) {
                CariPickerSheet { c in yeniCekCari = c }
            }
        }
    }
    
    private func yeniKKModal() -> some View {
        NavigationStack {
            ZStack {
                Color(hex: "09090B").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Button {
                            showCariPickerForKK = true
                        } label: {
                            HStack {
                                Text(yeniKKCari?.unvan ?? "Müşteri Seçiniz *")
                                    .foregroundColor(yeniKKCari == nil ? Color(hex: "8E8E93") : .white)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(12)
                            .background(Color(hex: "121216"))
                            .cornerRadius(10)
                        }
                        Button {
                            showYonCariPickerForKK = true
                        } label: {
                            HStack {
                                Text(yeniKKYonlendirilenCari?.unvan ?? "Yönlendirilen Tedarikçi (Opsiyonel)")
                                    .foregroundColor(yeniKKYonlendirilenCari == nil ? Color(hex: "8E8E93") : Color(hex: "F59E0B"))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(12)
                            .background(Color(hex: "121216"))
                            .cornerRadius(10)
                        }
                        modalInput("Banka / POS", text: $yeniKKBanka, placeholder: "Banka")
                        modalInput("Kart No (Son 4)", text: $yeniKKKartNo, placeholder: "**** 1234")
                        modalInput("Onay Kodu", text: $yeniKKOnayKodu, placeholder: "123456")
                        modalInput("Tutar (₺) *", text: $yeniKKTutar, placeholder: "0.00")
                        modalInput("Açıklama", text: $yeniKKAciklama, placeholder: "Kredi kartı tahsilatı")
                        
                        Button {
                            guard let t = Double(yeniKKTutar.replacingOccurrences(of: ",", with: ".")), t > 0 else { return }
                            let todayIso = AppFormatters.isoDate.string(from: Date())
                            let kkEvrakNo = yeniKKOnayKodu.isEmpty ? "MB-KK-\(Int.random(in: 1000...9999))" : yeniKKOnayKodu
                            let item = KrediKartiIslem(
                                id: "",
                                musteriId: Int(yeniKKCari?.id ?? ""),
                                musteriUnvan: yeniKKCari?.unvan ?? "Müşteri",
                                yonlendirilenCariId: Int(yeniKKYonlendirilenCari?.id ?? ""),
                                yonlendirilenCariUnvan: yeniKKYonlendirilenCari?.unvan,
                                tarih: todayIso,
                                tutar: t,
                                banka: yeniKKBanka,
                                kartNo: yeniKKKartNo,
                                onayKodu: yeniKKOnayKodu,
                                durum: yeniKKYonlendirilenCari != nil ? "Yönlendirildi" : "Portföyde",
                                aciklama: yeniKKAciklama
                            )
                            let selectedCari = yeniKKCari
                            let selectedYonCari = yeniKKYonlendirilenCari
                            let targetBanka = bankalar.first(where: { $0.bankaAdi.localizedCaseInsensitiveContains(yeniKKBanka) }) ?? bankalar.first
                            kkIslemler.insert(item, at: 0)
                            Task {
                                let activeYearInt = Int(SupabaseService.shared.activeFiscalYear) ?? Calendar.current.component(.year, from: Date())
                                try? await SupabaseService.shared.insert(into: "kredi_karti_islemler", item: item)
                                if let c = selectedCari {
                                    let newSigned = c.signedBakiye - t
                                    var chPayload: [String: Any] = [
                                        "uuid": UUID().uuidString.lowercased(),
                                        "tenant_id": SupabaseService.shared.tenantId,
                                        "mali_yil": activeYearInt,
                                        "cari_unvan": c.unvan,
                                        "evrak_no": kkEvrakNo,
                                        "belge_no": kkEvrakNo,
                                        "islem_turu": "Tahsilat (Kredi Kartı)",
                                        "hareket_turu": "Tahsilat",
                                        "odeme_sekli": "Kredi Kartı",
                                        "borc": 0.0,
                                        "alacak": t,
                                        "bakiye": newSigned,
                                        "tarih": todayIso,
                                        "aciklama": yeniKKAciklama.isEmpty ? "Kredi Kartı Tahsilatı" : yeniKKAciklama,
                                        "is_deleted": false
                                    ]
                                    if let cIdInt = Int(c.id) { chPayload["cari_id"] = cIdInt }
                                    if let cUuid = c.syncGuid { chPayload["cari_uuid"] = cUuid }
                                    if let chData = try? JSONSerialization.data(withJSONObject: chPayload) {
                                        try? await SupabaseService.shared.insertRaw(into: "cari_hareketler", data: chData)
                                    }
                                    try? await SupabaseService.shared.update(
                                        table: "cariler",
                                        id: c.id,
                                        item: CariBakiyeUpdate(bakiye: newSigned, bakiyeTuru: newSigned >= 0 ? "B" : "A")
                                    )
                                }
                                if selectedYonCari == nil, let b = targetBanka {
                                    var bhPayload: [String: Any] = [
                                        "uuid": UUID().uuidString.lowercased(),
                                        "tenant_id": SupabaseService.shared.tenantId,
                                        "mali_yil": activeYearInt,
                                        "banka_id": b.id ?? 1,
                                        "cari_unvan": selectedCari?.unvan ?? "Müşteri",
                                        "evrak_no": kkEvrakNo,
                                        "belge_no": kkEvrakNo,
                                        "islem_turu": "TAHSILAT",
                                        "hareket_turu": "Tahsilat",
                                        "giren": t,
                                        "cikan": 0.0,
                                        "yatan": t,
                                        "ceken": 0.0,
                                        "tutar": t,
                                        "tarih": todayIso,
                                        "aciklama": yeniKKAciklama.isEmpty ? "POS / Kredi Kartı Tahsilatı" : yeniKKAciklama,
                                        "is_deleted": false
                                    ]
                                    if let cIdStr = selectedCari?.id, let cIdInt = Int(cIdStr) { bhPayload["cari_id"] = cIdInt }
                                    if let bhData = try? JSONSerialization.data(withJSONObject: bhPayload) {
                                        try? await SupabaseService.shared.insertRaw(into: "banka_hareketler", data: bhData)
                                    }
                                }
                                await loadFinansData()
                            }
                            yeniKKTutar = ""
                            yeniKKYonlendirilenCari = nil
                            showYeniKKSheet = false
                        } label: {
                            Text("Kredi Kartı İşlemini Kaydet")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "2563EB"))
                                .cornerRadius(12)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Yeni Kredi Kartı İşlemi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { showYeniKKSheet = false }
                }
            }
            .sheet(isPresented: $showCariPickerForKK) {
                CariPickerSheet { c in yeniKKCari = c }
            }
            .sheet(isPresented: $showYonCariPickerForKK) {
                CariPickerSheet { c in yeniKKYonlendirilenCari = c }
            }
        }
    }
    
    private func yeniEftModal() -> some View {
        NavigationStack {
            ZStack {
                Color(hex: "09090B").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Button {
                            showCariPickerForEft = true
                        } label: {
                            HStack {
                                Text(yeniEftCari?.unvan ?? "Müşteri / Cari Seçiniz *")
                                    .foregroundColor(yeniEftCari == nil ? Color(hex: "8E8E93") : .white)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(12)
                            .background(Color(hex: "121216"))
                            .cornerRadius(10)
                        }
                        Button {
                            showYonCariPickerForEft = true
                        } label: {
                            HStack {
                                Text(yeniEftYonlendirilenCari?.unvan ?? "Yönlendirilen Tedarikçi (Opsiyonel)")
                                    .foregroundColor(yeniEftYonlendirilenCari == nil ? Color(hex: "8E8E93") : Color(hex: "F59E0B"))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(12)
                            .background(Color(hex: "121216"))
                            .cornerRadius(10)
                        }
                        modalInput("Banka Adı", text: $yeniEftBanka, placeholder: "Banka")
                        modalInput("IBAN / Hesap No", text: $yeniEftHesapNo, placeholder: "TR...")
                        modalInput("Dekont No", text: $yeniEftDekontNo, placeholder: "DK-001")
                        modalInput("Tutar (₺) *", text: $yeniEftTutar, placeholder: "0.00")
                        modalInput("Açıklama", text: $yeniEftAciklama, placeholder: "Havale / EFT")
                        
                        Button {
                            guard let t = Double(yeniEftTutar.replacingOccurrences(of: ",", with: ".")), t > 0 else { return }
                            let todayIso = AppFormatters.isoDate.string(from: Date())
                            let eftEvrakNo = yeniEftDekontNo.isEmpty ? "MB-EFT-\(Int.random(in: 1000...9999))" : yeniEftDekontNo
                            let item = EftIslem(
                                id: "",
                                musteriId: Int(yeniEftCari?.id ?? ""),
                                banka: yeniEftBanka,
                                hesapNo: yeniEftHesapNo,
                                dekontNo: yeniEftDekontNo,
                                aliciIban: yeniEftHesapNo,
                                aliciUnvan: yeniEftCari?.unvan ?? "Müşteri",
                                yonlendirilenCariId: Int(yeniEftYonlendirilenCari?.id ?? ""),
                                yonlendirilenCariUnvan: yeniEftYonlendirilenCari?.unvan,
                                tutar: t,
                                tarih: todayIso,
                                aciklama: yeniEftAciklama,
                                durum: yeniEftYonlendirilenCari != nil ? "Yönlendirildi" : "Tamamlandı"
                            )
                            let selectedCari = yeniEftCari
                            let selectedYonCari = yeniEftYonlendirilenCari
                            let targetBanka = bankalar.first(where: { $0.bankaAdi.localizedCaseInsensitiveContains(yeniEftBanka) }) ?? bankalar.first
                            eftIslemler.insert(item, at: 0)
                            Task {
                                let activeYearInt = Int(SupabaseService.shared.activeFiscalYear) ?? Calendar.current.component(.year, from: Date())
                                try? await SupabaseService.shared.insert(into: "eft_islemler", item: item)
                                if let c = selectedCari {
                                    let newSigned = c.signedBakiye - t
                                    var chPayload: [String: Any] = [
                                        "uuid": UUID().uuidString.lowercased(),
                                        "tenant_id": SupabaseService.shared.tenantId,
                                        "mali_yil": activeYearInt,
                                        "cari_unvan": c.unvan,
                                        "evrak_no": eftEvrakNo,
                                        "belge_no": eftEvrakNo,
                                        "islem_turu": "Tahsilat (Havale / EFT)",
                                        "hareket_turu": "Tahsilat",
                                        "odeme_sekli": "Havale / EFT",
                                        "borc": 0.0,
                                        "alacak": t,
                                        "bakiye": newSigned,
                                        "tarih": todayIso,
                                        "aciklama": yeniEftAciklama.isEmpty ? "Havale / EFT Tahsilatı" : yeniEftAciklama,
                                        "is_deleted": false
                                    ]
                                    if let cIdInt = Int(c.id) { chPayload["cari_id"] = cIdInt }
                                    if let cUuid = c.syncGuid { chPayload["cari_uuid"] = cUuid }
                                    if let chData = try? JSONSerialization.data(withJSONObject: chPayload) {
                                        try? await SupabaseService.shared.insertRaw(into: "cari_hareketler", data: chData)
                                    }
                                    try? await SupabaseService.shared.update(
                                        table: "cariler",
                                        id: c.id,
                                        item: CariBakiyeUpdate(bakiye: newSigned, bakiyeTuru: newSigned >= 0 ? "B" : "A")
                                    )
                                }
                                if selectedYonCari == nil, let b = targetBanka {
                                    var bhPayload: [String: Any] = [
                                        "uuid": UUID().uuidString.lowercased(),
                                        "tenant_id": SupabaseService.shared.tenantId,
                                        "mali_yil": activeYearInt,
                                        "banka_id": b.id ?? 1,
                                        "cari_unvan": selectedCari?.unvan ?? "Müşteri",
                                        "evrak_no": eftEvrakNo,
                                        "belge_no": eftEvrakNo,
                                        "islem_turu": "TAHSILAT",
                                        "hareket_turu": "Tahsilat",
                                        "giren": t,
                                        "cikan": 0.0,
                                        "yatan": t,
                                        "ceken": 0.0,
                                        "tutar": t,
                                        "tarih": todayIso,
                                        "aciklama": yeniEftAciklama.isEmpty ? "Havale / EFT Tahsilatı" : yeniEftAciklama,
                                        "is_deleted": false
                                    ]
                                    if let cIdStr = selectedCari?.id, let cIdInt = Int(cIdStr) { bhPayload["cari_id"] = cIdInt }
                                    if let bhData = try? JSONSerialization.data(withJSONObject: bhPayload) {
                                        try? await SupabaseService.shared.insertRaw(into: "banka_hareketler", data: bhData)
                                    }
                                }
                                await loadFinansData()
                            }
                            yeniEftTutar = ""
                            yeniEftYonlendirilenCari = nil
                            showYeniEftSheet = false
                        } label: {
                            Text("Havale / EFT İşlemini Kaydet")
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
            .navigationTitle("Yeni Havale / EFT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { showYeniEftSheet = false }
                }
            }
            .sheet(isPresented: $showCariPickerForEft) {
                CariPickerSheet { c in yeniEftCari = c }
            }
            .sheet(isPresented: $showYonCariPickerForEft) {
                CariPickerSheet { c in yeniEftYonlendirilenCari = c }
            }
        }
    }
    
    // MARK: - Helpers
    private func kpiCard(title: String, value: String, sub: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "8E8E93"))
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.system(size: 10))
                .foregroundColor(color)
        }
        .padding(12)
        .background(Color(hex: "121216"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.25), lineWidth: 1))
    }
    
    private func miniMetric(label: String, val: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "8E8E93"))
            Text(val)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
    
    private func flowCompareRow(label: String, kendi: Double, yon: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 90, alignment: .leading)
            Spacer()
            Text("Kasa: \(AppFormatters.money(kendi))")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "10B981"))
            Spacer()
            Text("Yönl: \(AppFormatters.money(yon))")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "F59E0B"))
        }
    }
    
    private func emptyStateBox(text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "8E8E93"))
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(hex: "121216"))
            .cornerRadius(14)
    }
    
    private func modalInput(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "8E8E93"))
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(12)
                .background(Color(hex: "121216"))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }
    
    private func openMakbuzPDF(hareket: KasaHareket) {
        #if canImport(UIKit)
        Task { @MainActor in
            isGeneratingPDF = true
            let data = await PDFService.shared.fetchOrGenerateMakbuzPDF(
                makbuzTipi: hareket.islemTuru,
                cariUnvan: hareket.cariUnvan ?? "Peşin İşlem",
                tarih: hareket.tarih,
                tutar: hareket.tutar,
                aciklama: hareket.aciklama
            )
            isGeneratingPDF = false
            if let d = data {
                pdfPreviewItem = PDFPreviewItem(
                    title: "\(hareket.islemTuru) Makbuzu",
                    data: d,
                    fileName: "Makbuz_\(hareket.id ?? 1).pdf"
                )
            }
        }
        #endif
    }
    
    private func exportFinansPDF() {
        #if canImport(UIKit)
        Task { @MainActor in
            isGeneratingPDF = true
            let reportTitle: String
            switch activeTab {
            case "nakit": reportTitle = "Nakit İşlem Detay Raporu"
            case "cekler": reportTitle = "Çek Detay Raporu"
            case "kredikarti": reportTitle = "Kredi Kartı Detay Raporu"
            case "havale": reportTitle = "Havale / EFT Detay Raporu"
            default: reportTitle = "Aylık Tahsilat ve Ödeme Analizi"
            }
            let data = await ReportCalculationService.shared.generateDesktopReportPDF(for: reportTitle, filter: "All")
            isGeneratingPDF = false
            pdfPreviewItem = PDFPreviewItem(
                title: reportTitle,
                data: data,
                fileName: "\(reportTitle).pdf"
            )
        }
        #endif
    }
    
    private func loadFinansData() async {
        await MainActor.run { isLoading = true }
        async let kFetch: [KasaBanka]? = try? SupabaseService.shared.fetch(from: "kasalar")
        async let bFetch: [BankaKart]? = try? SupabaseService.shared.fetch(from: "bankalar")
        async let khFetch: [KasaHareket]? = try? SupabaseService.shared.fetch(from: "kasa_hareketler")
        async let bhFetch: [BankaHareket]? = try? SupabaseService.shared.fetch(from: "banka_hareketler")
        async let cFetch: [Cek]? = try? SupabaseService.shared.fetch(from: "cekler")
        async let sFetch: [Senet]? = try? SupabaseService.shared.fetch(from: "senetler")
        async let kkFetch: [KrediKartiIslem]? = try? SupabaseService.shared.fetch(from: "kredi_karti_islemler")
        async let eftFetch: [EftIslem]? = try? SupabaseService.shared.fetch(from: "eft_islemler")
        async let fFetch: [Fatura]? = try? SupabaseService.shared.fetch(from: "faturalar")
        
        let (kRes, bRes, khRes, bhRes, cRes, sRes, kkRes, eftRes, fRes) = await (kFetch, bFetch, khFetch, bhFetch, cFetch, sFetch, kkFetch, eftFetch, fFetch)
        
        await MainActor.run {
            self.kasalar = kRes ?? []
            self.bankalar = bRes ?? []
            self.kasaHareketler = khRes ?? []
            self.bankaHareketler = bhRes ?? []
            self.cekler = cRes ?? []
            self.senetler = sRes ?? []
            self.kkIslemler = kkRes ?? []
            self.eftIslemler = eftRes ?? []
            self.faturalar = fRes ?? DataStore.shared.faturalar
            self.isLoading = false
        }
    }
}
