import SwiftUI

public struct DashboardView: View {
    @State private var activeTab: String = "recents" // "recents" | "receivables" | "payables"
    @State private var goalPeriod: String = "week" // "week" | "month"
    @ObservedObject private var supabaseService = SupabaseService.shared
    @State private var showYearPicker: Bool = false
    @State private var showNotifications: Bool = false
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var isSyncing: Bool = false
    @State private var lastSyncTime: String = "Şimdi"
    
    // Live calculated stats (Masaüstü Birebir Gerçek Veriler)
    @State private var gunlukCiro: Double = 0.0
    @State private var toplamAlacak: Double = 0.0
    @State private var toplamBorc: Double = 0.0
    @State private var kasaBankaMevcut: Double = 0.0
    
    // Satış Hedefleri (Haftalık & Aylık)
    @State private var haftalikHedef: Double = 0.0
    @State private var haftalikGerceklesen: Double = 0.0
    @State private var aylikHedef: Double = 0.0
    @State private var aylikGerceklesen: Double = 0.0
    
    // Weekly Chart Data
    struct BarChartPoint: Identifiable {
        let id = UUID()
        let label: String
        let target: Double
        let actual: Double
    }
    
    @State private var weeklyData: [BarChartPoint] = []
    @State private var monthlyData: [BarChartPoint] = []
    
    // Tab list data items
    struct DashboardListItem: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let amount: Double
        let date: String
        let vade: Int?
        let type: String // "In" | "Out"
    }
    
    @State private var sonIslemler: [DashboardListItem] = []
    @State private var alacakTakibi: [DashboardListItem] = []
    @State private var borcTakibi: [DashboardListItem] = []
    
    // Sheets
    @State private var showAlisFatura: Bool = false
    @State private var showSatisFatura: Bool = false
    @State private var showSiparis: Bool = false
    @State private var showTeklif: Bool = false
    
    public init() {}
    
    // Net Bakiye Durumu (ToplamAlacak - ToplamBorc)
    private var netBakiye: Double {
        toplamAlacak - toplamBorc
    }
    private var isNetPozitif: Bool {
        netBakiye >= 0
    }
    private var netColor: Color {
        isNetPozitif ? Color(hex: "30D158") : Color(hex: "FF453A")
    }
    private var netFormatted: String {
        let sign = isNetPozitif ? "+" : "-"
        return "\(sign)\(AppFormatters.money(abs(netBakiye)))"
    }
    private var netSubtitle: String {
        isNetPozitif ? "Alacak Fazlası" : "Borç Fazlası"
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "080A0C").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Masaüstü Birebir Üst Bar (VK Logo + Mali Yıl + Senkron + Bildirim)
                        renderDesktopHeaderBar()
                        
                        // 2. Masaüstü Birebir 4'lü Hızlı İşlem Butonları (ModernSaaS Gradientleri)
                        renderQuickActionGrid()
                        
                        // 3. Masaüstü Birebir 4'lü Finansal KPI Kartları
                        renderKPICards()
                        
                        // 4. Hedef & Gerçekleşme Grafiği
                        renderGoalChartCard()
                        
                        // 5. Hareket ve Takip Sekmeleri
                        renderListSection()
                        
                        Spacer().frame(height: 110)
                    }
                    .padding(.horizontal, 16)
                }
                .refreshable {
                    await syncWithCloud()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAlisFatura) {
                FaturaFormView(initialTur: "Alış")
            }
            .sheet(isPresented: $showSatisFatura) {
                FaturaFormView(initialTur: "Satış")
            }
            .sheet(isPresented: $showSiparis) {
                SiparisFormView()
            }
            .sheet(isPresented: $showTeklif) {
                TeklifFormView()
            }
            .sheet(isPresented: $showNotifications) {
                BildirimlerView()
            }
            .confirmationDialog("Mali Yıl Seçimi", isPresented: $showYearPicker, titleVisibility: .visible) {
                ForEach(supabaseService.availableFiscalYears, id: \.self) { year in
                    Button(supabaseService.activeFiscalYear == year ? "\(year) (Aktif Yıl)" : year) {
                        Task {
                            await supabaseService.setActiveFiscalYear(year)
                            await syncWithCloud()
                        }
                    }
                }
                Button("Vazgeç", role: .cancel) {}
            }
            .task {
                await syncWithCloud()
            }
            .onReceive(NotificationCenter.default.publisher(for: .supabaseRealtimeDataChanged)) { _ in
                Task {
                    await syncWithCloud()
                }
            }
        }
    }
    
    // MARK: - 1. Masaüstü Birebir Header Bar (MainView.axaml Exact Parity)
    @ViewBuilder
    private func renderDesktopHeaderBar() -> some View {
        HStack(spacing: 10) {
            // VK Logo & Title
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "1E293B"))
                        .frame(width: 34, height: 34)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "2563EB").opacity(0.5), lineWidth: 1))
                    
                    #if canImport(UIKit)
                    if let imgPath = Bundle.main.path(forResource: "vk_logo", ofType: "png"),
                       let uiImg = UIImage(contentsOfFile: imgPath) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    } else {
                        Text("VK")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(Color(hex: "60A5FA"))
                    }
                    #else
                    Text("VK")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color(hex: "60A5FA"))
                    #endif
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text("VK")
                            .font(.system(size: 17, weight: .black))
                            .tracking(2)
                            .foregroundColor(.white)
                        
                        // Canlı Senkronizasyon Rozeti
                        HStack(spacing: 3) {
                            Circle()
                                .fill(isSyncing ? Color(hex: "F59E0B") : Color(hex: "10B981"))
                                .frame(width: 6, height: 6)
                            Text(isSyncing ? "Eşitleniyor" : "Bulut Senkron")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(isSyncing ? Color(hex: "F59E0B") : Color(hex: "10B981"))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                    }
                    
                    Text("Ön Muhasebe & Finans")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            }
            
            Spacer()
            
            // Mali Yıl Butonu (Masaüstü SwitchFiscalYearCommand Birebir Menü - Sadece Oluşturulmuş Yıllar)
            Menu {
                ForEach(supabaseService.availableFiscalYears, id: \.self) { year in
                    Button {
                        Task {
                            await supabaseService.setActiveFiscalYear(year)
                            await syncWithCloud()
                        }
                    } label: {
                        HStack {
                            Text("Mali Yıl \(year)")
                            if supabaseService.activeFiscalYear == year {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "38BDF8"))
                    Text(supabaseService.activeFiscalYear)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "94A3B8"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            
            // Bildirim Butonu (Masaüstü Birebir Zil + Canlı Dinamik Rozet)
            Button {
                showNotifications = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                    
                    if notificationManager.unreadCount > 0 {
                        Circle()
                            .fill(Color(hex: "EF4444"))
                            .frame(width: 9, height: 9)
                            .offset(x: 2, y: -2)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }
    
    // MARK: - 2. Masaüstü Birebir 4'lü Hızlı İşlem Grid (ModernSaaS Exact Gradients)
    @ViewBuilder
    private func renderQuickActionGrid() -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            // 1. Alış (Fatura Girişi) - Kırmızı/Kızıl Gradient
            desktopActionCard(
                title: "Alış",
                subtitle: "Fatura Girişi",
                iconName: "cart.fill",
                gradient: [Color(hex: "EF4444"), Color(hex: "DC2626")]
            ) {
                showAlisFatura = true
            }
            
            // 2. Satış (Yeni Satış) - Neon Zümrüt Gradient
            desktopActionCard(
                title: "Satış",
                subtitle: "Yeni Satış",
                iconName: "tag.fill",
                gradient: [Color(hex: "10B981"), Color(hex: "059669")]
            ) {
                showSatisFatura = true
            }
            
            // 3. Sipariş (Sipariş Yaz) - Turuncu Gradient
            desktopActionCard(
                title: "Sipariş",
                subtitle: "Sipariş Yaz",
                iconName: "doc.text.fill",
                gradient: [Color(hex: "F97316"), Color(hex: "EA580C")]
            ) {
                showSiparis = true
            }
            
            // 4. Teklif (Teklif Hazırla) - Mavi Gradient
            desktopActionCard(
                title: "Teklif",
                subtitle: "Teklif Hazırla",
                iconName: "percent",
                gradient: [Color(hex: "007ACC"), Color(hex: "005A9E")]
            ) {
                showTeklif = true
            }
        }
    }
    
    private func desktopActionCard(
        title: String,
        subtitle: String,
        iconName: String,
        gradient: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.85))
                }
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(14)
            .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - 3. Masaüstü Birebir 4'lü KPI Kartları
    @ViewBuilder
    private func renderKPICards() -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            // GÜNLÜK SATIŞ (CİRO)
            desktopKpiCard(
                title: "GÜNLÜK SATIŞ",
                amount: AppFormatters.money(gunlukCiro),
                subtitle: "Günün Cirosu",
                iconName: "wallet.pass.fill",
                accentColor: Color(hex: "FACC15"),
                isBorderGlow: true
            )
            
            // TOPLAM ALACAK
            desktopKpiCard(
                title: "TOPLAM ALACAK",
                amount: AppFormatters.money(toplamAlacak),
                subtitle: "Tüm Müşteriler",
                iconName: "arrow.up.right",
                accentColor: Color(hex: "10B981")
            )
            
            // TOPLAM BORÇ
            desktopKpiCard(
                title: "TOPLAM BORÇ",
                amount: AppFormatters.money(toplamBorc),
                subtitle: "Tüm Tedarikçiler",
                iconName: "arrow.down.right",
                accentColor: Color(hex: "EF4444")
            )
            
            // NET KASA & BANKA
            desktopKpiCard(
                title: "NET BAKİYE",
                amount: netFormatted,
                subtitle: netSubtitle,
                iconName: "building.columns.fill",
                accentColor: netColor
            )
        }
    }
    
    private func desktopKpiCard(
        title: String,
        amount: String,
        subtitle: String,
        iconName: String,
        accentColor: Color,
        isBorderGlow: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "8E8E93"))
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }
            
            Spacer().frame(height: 10)
            
            Text(amount)
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "94A3B8"))
                .padding(.top, 4)
        }
        .padding(12)
        .frame(minHeight: 95, alignment: .topLeading)
        .background(Color(hex: "121216"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isBorderGlow ? accentColor.opacity(0.5) : Color.white.opacity(0.08), lineWidth: isBorderGlow ? 1.5 : 1)
        )
    }
    
    // MARK: - 4. Hedef & Gerçekleşme Kartı
    @ViewBuilder
    private func renderGoalChartCard() -> some View {
        let isWeekly = (goalPeriod == "week")
        let hedef = isWeekly ? haftalikHedef : aylikHedef
        let gercek = isWeekly ? haftalikGerceklesen : aylikGerceklesen
        let diff = gercek - hedef
        let completionRate = hedef > 0 ? (gercek / hedef) : 0.0
        let percentInt = Int(round(completionRate * 100))
        let isPositive = gercek >= hedef
        let ringColor = isPositive ? Color(hex: "10B981") : Color(hex: "EF4444")
        
        VStack(alignment: .leading, spacing: 16) {
            
            // Header: İkon + Başlık + Hafta/Ay Butonları
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "10B981").opacity(0.16))
                            .frame(width: 32, height: 32)
                        Image(systemName: "target")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    
                    Text("Hedef & Gerçekleşme")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Toggle Hafta / Ay (Masaüstü Exact Toggle)
                HStack(spacing: 2) {
                    Button {
                        goalPeriod = "week"
                        HardwareService.shared.hapticImpact()
                    } label: {
                        Text("Hafta")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(isWeekly ? .white : Color(hex: "8E8E93"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isWeekly ? Color(hex: "10B981") : Color.clear)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        goalPeriod = "month"
                        HardwareService.shared.hapticImpact()
                    } label: {
                        Text("Ay")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(!isWeekly ? .white : Color(hex: "8E8E93"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(!isWeekly ? Color(hex: "10B981") : Color.clear)
                            .cornerRadius(8)
                    }
                }
                .padding(3)
                .background(Color(hex: "222222"))
                .cornerRadius(10)
            }
            
            // HARMAN MODEL: Apple Radial Ring (Sol) + Çift Kolon Barları (Sağ)
            HStack(alignment: .center, spacing: 14) {
                
                // Sol Panel: Apple Radial Ring & Metrikler
                VStack(spacing: 10) {
                    
                    // Radial Progress Ring (110x110)
                    ZStack {
                        // Background Track
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 10)
                            .frame(width: 96, height: 96)
                        
                        // Progress Indicator
                        Circle()
                            .trim(from: 0, to: CGFloat(min(completionRate, 1.0)))
                            .stroke(
                                ringColor,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 96, height: 96)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: completionRate)
                        
                        // Center Info
                        VStack(spacing: 2) {
                            Text("%\(percentInt)")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(.white)
                            Text("Tamamlandı")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                    }
                    .frame(width: 100, height: 100)
                    
                    // Metrikler Alt Tablosu
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(Color(hex: "10B981")).frame(width: 6, height: 6)
                            Text("Hedef:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "94A3B8"))
                            Spacer()
                            Text(AppFormatters.money(hedef))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Circle().fill(Color(hex: "EF4444")).frame(width: 6, height: 6)
                            Text("Gerçekleşen:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "94A3B8"))
                            Spacer()
                            Text(AppFormatters.money(gercek))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "EF4444"))
                        }
                        
                        HStack {
                            Circle().fill(isPositive ? Color(hex: "10B981") : Color(hex: "EF4444")).frame(width: 6, height: 6)
                            Text("Fark:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "94A3B8"))
                            Spacer()
                            Text((diff >= 0 ? "+" : "") + AppFormatters.money(diff))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(isPositive ? Color(hex: "10B981") : Color(hex: "EF4444"))
                        }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(8)
                }
                .frame(width: 130)
                
                Divider()
                    .background(Color.white.opacity(0.08))
                    .frame(height: 180)
                
                // Sağ Panel: Çift Kolonlu Dikey Bar Grafiği (Türkiye Muhasebe Standardı)
                VStack(spacing: 8) {
                    
                    let chartPoints = isWeekly ? weeklyData : monthlyData
                    
                    let maxVal = max(chartPoints.map { max($0.target, $0.actual) }.max() ?? 100000, 1000)
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(chartPoints) { pt in
                            VStack(spacing: 6) {
                                HStack(alignment: .bottom, spacing: 3) {
                                    // 🟩 Hedef Kolonu
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(hex: "10B981"))
                                        .frame(width: 10, height: max(CGFloat(pt.target / maxVal) * 85, 4))
                                    
                                    // 🟥 Gerçekleşen Kolonu
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(hex: "EF4444"))
                                        .frame(width: 10, height: max(CGFloat(pt.actual / maxVal) * 85, 4))
                                }
                                .frame(height: 90, alignment: .bottom)
                                
                                Text(pt.label)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color(hex: "94A3B8"))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 110)
                    .padding(.top, 4)
                    
                    // Legend / Gösterge
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "10B981"))
                                .frame(width: 8, height: 8)
                            Text("Hedef")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(hex: "94A3B8"))
                        }
                        
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "EF4444"))
                                .frame(width: 8, height: 8)
                            Text("Gerçekleşen")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(hex: "94A3B8"))
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color(hex: "141416"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1.5))
    }

    // MARK: - 5. Dynamic Lists Tabs & Content
    @ViewBuilder
    private func renderListSection() -> some View {
        VStack(spacing: 12) {
            // Segmented Tabs
            HStack(spacing: 6) {
                tabButton(title: "Son İşlemler", tab: "recents")
                tabButton(title: "Alacak Takibi", tab: "receivables")
                tabButton(title: "Borç Takibi", tab: "payables")
            }
            
            // List Items
            let currentList = activeTab == "recents" ? sonIslemler : (activeTab == "receivables" ? alacakTakibi : borcTakibi)
            VStack(spacing: 6) {
                ForEach(currentList) { item in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill((item.type == "In" ? Color(hex: "10B981") : Color(hex: "EF4444")).opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: item.type == "In" ? "arrow.down.left" : "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(item.type == "In" ? Color(hex: "10B981") : Color(hex: "EF4444"))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("\(item.description) • \(item.date)")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        
                        Spacer()
                        
                        Text(AppFormatters.money(item.amount))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(item.type == "In" ? Color(hex: "10B981") : Color(hex: "EF4444"))
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(10)
                }
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private func tabButton(title: String, tab: String) -> some View {
        Button {
            activeTab = tab
        } label: {
            Text(title)
                .font(.system(size: 12, weight: activeTab == tab ? .bold : .medium))
                .foregroundColor(activeTab == tab ? .white : Color(hex: "8E8E93"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(activeTab == tab ? Color(hex: "2563EB") : Color.white.opacity(0.04))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Supabase Bulut Senkronizasyonu (Masaüstü ile Anlık Eşitleme)
    private func syncWithCloud() async {
        isSyncing = true
        await supabaseService.fetchFiscalYears()
        
        do {
            // 1. Cariler tablosundan canlı bakiye ve toplamları çek
            let cariler: [CariKart] = try await SupabaseService.shared.fetch(from: "cariler")
            if !cariler.isEmpty {
                var topAlacak: Double = 0
                var topBorc: Double = 0
                var alacakList: [DashboardListItem] = []
                var borcList: [DashboardListItem] = []
                var recentList: [DashboardListItem] = []
                
                for c in cariler {
                    // bakiyeTuru == "B" borçludur (Müşterinin firmaya borcu = Firmanın ALACAĞI)
                    // bakiyeTuru == "A" alacaklıdır (Firmanın tedarikçiye BORCU)
                    if c.bakiyeTuru == "B" || (c.bakiye > 0 && c.bakiyeTuru != "A") {
                        let amt = abs(c.bakiye)
                        topAlacak += amt
                        if amt > 0 {
                            alacakList.append(DashboardListItem(
                                title: c.unvan,
                                description: "Müşteri Alacağı",
                                amount: amt,
                                date: "Alacak",
                                vade: c.vadeGunu,
                                type: "In"
                            ))
                        }
                    } else {
                        let amt = abs(c.bakiye)
                        topBorc += amt
                        if amt > 0 {
                            borcList.append(DashboardListItem(
                                title: c.unvan,
                                description: "Tedarikçi Borcu",
                                amount: amt,
                                date: "Borç",
                                vade: c.vadeGunu,
                                type: "Out"
                            ))
                        }
                    }
                    
                    if recentList.count < 5 {
                        let isAlacak = (c.bakiyeTuru == "B" || (c.bakiye > 0 && c.bakiyeTuru != "A"))
                        recentList.append(DashboardListItem(
                            title: c.unvan,
                            description: isAlacak ? "Müşteri Alacağı" : "Tedarikçi Borcu",
                            amount: abs(c.bakiye),
                            date: "Güncel",
                            vade: c.vadeGunu,
                            type: isAlacak ? "In" : "Out"
                        ))
                    }
                }
                
                await MainActor.run {
                    self.toplamAlacak = topAlacak
                    self.toplamBorc = topBorc
                    self.alacakTakibi = alacakList
                    self.borcTakibi = borcList
                    if self.sonIslemler.isEmpty {
                        self.sonIslemler = recentList
                    }
                }
            }
            
            // 2. Kasa ve Banka Mevcutlarını Çek
            var recentKasaHareketler: [KasaHareket] = []
            do {
                let kasalar: [KasaBanka] = (try? await SupabaseService.shared.fetch(from: "kasalar")) ?? []
                let kasaTop = kasalar.reduce(0.0) { $0 + $1.bakiye }
                let bankalar: [BankaKart] = (try? await SupabaseService.shared.fetch(from: "bankalar")) ?? []
                let bankaTop = bankalar.reduce(0.0) { $0 + $1.bakiye }
                let totalNakit = kasaTop + bankaTop
                recentKasaHareketler = (try? await SupabaseService.shared.fetch(from: "kasa_hareketler", orderBy: "tarih.desc", limit: 15)) ?? []
                await MainActor.run {
                    self.kasaBankaMevcut = totalNakit
                }
            } catch { }
            
            // 3. Faturalar ve Satış Hedefleri tablosundan canlı ciroyu ve gerçekleşen satışları çek
            do {
                let faturalar: [Fatura] = (try? await SupabaseService.shared.fetch(from: "faturalar", orderBy: "tarih.desc")) ?? []
                var realRecentTransactions: [(sortDate: Date, item: DashboardListItem)] = []
                for f in faturalar.prefix(15) {
                    let isSatis = f.faturaTuru.localizedCaseInsensitiveContains("satış") || f.faturaTuru.localizedCaseInsensitiveContains("satis")
                    let d = AppFormatters.parseDate(String(f.tarih.prefix(10))) ?? AppFormatters.parseDate(f.tarih) ?? .distantPast
                    realRecentTransactions.append((
                        sortDate: d,
                        item: DashboardListItem(
                            title: f.cariUnvan ?? f.faturaNo,
                            description: "\(isSatis ? "Satış Faturası" : "Alış Faturası") (\(f.faturaNo))",
                            amount: f.genelToplam,
                            date: String(f.tarih.prefix(10)),
                            vade: nil,
                            type: isSatis ? "In" : "Out"
                        )
                    ))
                }
                for kh in recentKasaHareketler.prefix(15) {
                    let isGiris = kh.giren >= kh.cikan && kh.giren > 0
                    let d = AppFormatters.parseDate(String(kh.tarih.prefix(10))) ?? AppFormatters.parseDate(kh.tarih) ?? .distantPast
                    realRecentTransactions.append((
                        sortDate: d,
                        item: DashboardListItem(
                            title: kh.cariUnvan ?? kh.aciklama ?? kh.islemTuru,
                            description: "Kasa \(kh.islemTuru)",
                            amount: kh.tutar,
                            date: String(kh.tarih.prefix(10)),
                            vade: nil,
                            type: isGiris ? "In" : "Out"
                        )
                    ))
                }
                let sortedRecentItems = realRecentTransactions
                    .sorted { $0.sortDate > $1.sortDate }
                    .prefix(10)
                    .map { $0.item }
                if !sortedRecentItems.isEmpty {
                    await MainActor.run {
                        self.sonIslemler = Array(sortedRecentItems)
                    }
                }
                let aylikHedefler: [SatisHedefRow] = (try? await SupabaseService.shared.fetch(from: "satis_hedefleri")) ?? []
                let haftalikHedefler: [SatisHedefRow] = (try? await SupabaseService.shared.fetch(from: "haftalik_satis_hedefleri")) ?? []
                let today = AppFormatters.isoDate.string(from: Date())
                let cal = Calendar.current
                let curYear = cal.component(.year, from: Date())
                let curMonth = cal.component(.month, from: Date())
                let curWeek = Calendar(identifier: .iso8601).component(.weekOfYear, from: Date())
                
                let satisFaturalari = faturalar.filter {
                    $0.faturaTuru.localizedCaseInsensitiveContains("satış") || $0.faturaTuru.localizedCaseInsensitiveContains("satis")
                }
                
                let bugunSatis = satisFaturalari
                    .filter { $0.tarih.hasPrefix(today) || $0.tarih.hasPrefix(AppFormatters.shortDate.string(from: Date())) }
                    .reduce(0.0) { $0 + $1.genelToplam }
                
                let curMonthPrefix = String(format: "%04d-%02d", curYear, curMonth)
                let curMonthSuffix = String(format: ".%02d.%04d", curMonth, curYear)
                let buAySatis = satisFaturalari
                    .filter { $0.tarih.hasPrefix(curMonthPrefix) || $0.tarih.hasSuffix(curMonthSuffix) }
                    .reduce(0.0) { $0 + $1.genelToplam }
                
                let weekStart = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                let buHaftaSatis = satisFaturalari.filter { f in
                    guard let d = AppFormatters.parseDate(String(f.tarih.prefix(10))) ?? AppFormatters.parseDate(f.tarih) else { return false }
                    return d >= cal.startOfDay(for: weekStart)
                }.reduce(0.0) { $0 + $1.genelToplam }
                
                let curAyHedef = aylikHedefler.first(where: { ($0.yil ?? curYear) == curYear && $0.ay == curMonth })?.effectiveHedef ?? 0.0
                let curHaftaHedef = haftalikHedefler.first(where: { ($0.yil ?? curYear) == curYear && $0.effectiveHafta == curWeek })?.effectiveHedef ?? (curAyHedef / 4.0)
                
                let ayIsimleri = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"]
                var mPoints: [BarChartPoint] = []
                for i in (0..<5).reversed() {
                    if let d = cal.date(byAdding: .month, value: -i, to: Date()) {
                        let y = cal.component(.year, from: d)
                        let m = cal.component(.month, from: d)
                        let p1 = String(format: "%04d-%02d", y, m)
                        let p2 = String(format: ".%02d.%04d", m, y)
                        let act = satisFaturalari.filter { $0.tarih.hasPrefix(p1) || $0.tarih.hasSuffix(p2) }.reduce(0.0) { $0 + $1.genelToplam }
                        let tgt = aylikHedefler.first(where: { ($0.yil ?? y) == y && $0.ay == m })?.effectiveHedef ?? curAyHedef
                        mPoints.append(BarChartPoint(label: ayIsimleri[max(0, min(11, m - 1))], target: tgt, actual: act))
                    }
                }
                
                var wPoints: [BarChartPoint] = []
                for i in (0..<4).reversed() {
                    let wNo = max(1, curWeek - i)
                    let hStart = cal.date(byAdding: .day, value: -(i * 7 + 7), to: Date()) ?? Date()
                    let hEnd = cal.date(byAdding: .day, value: -(i * 7), to: Date()) ?? Date()
                    let act = satisFaturalari.filter { f in
                        guard let fd = AppFormatters.parseDate(String(f.tarih.prefix(10))) ?? AppFormatters.parseDate(f.tarih) else { return false }
                        return fd >= cal.startOfDay(for: hStart) && fd <= hEnd
                    }.reduce(0.0) { $0 + $1.genelToplam }
                    let tgt = haftalikHedefler.first(where: { ($0.yil ?? curYear) == curYear && $0.effectiveHafta == wNo })?.effectiveHedef ?? curHaftaHedef
                    wPoints.append(BarChartPoint(label: "H\(wNo)", target: tgt, actual: act))
                }
                
                await MainActor.run {
                    self.gunlukCiro = bugunSatis
                    self.haftalikHedef = curHaftaHedef
                    self.haftalikGerceklesen = buHaftaSatis
                    self.aylikHedef = curAyHedef
                    self.aylikGerceklesen = buAySatis
                    self.monthlyData = mPoints
                    self.weeklyData = wPoints
                }
            } catch { }
            
            await MainActor.run {
                self.lastSyncTime = "\(ISO8601DateFormatter().string(from: Date()).prefix(16))"
                self.isSyncing = false
            }
        } catch {
            print("Bulut senkronizasyon: \(error)")
            await MainActor.run {
                self.isSyncing = false
            }
        }
    }
}
