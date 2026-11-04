import SwiftUI

public struct DashboardView: View {
    @State private var activeTab: String = "recents" // "recents" | "receivables" | "payables"
    @State private var goalPeriod: String = "week" // "week" | "month"
    
    // Live calculated stats
    @State private var gunlukCiro: Double = 42850.0
    @State private var toplamAlacak: Double = 184500.0
    @State private var toplamBorc: Double = 72300.0
    
    // Satış Hedefleri (Haftalık & Aylık)
    @State private var haftalikHedef: Double = 62500.0
    @State private var haftalikGerceklesen: Double = 78400.0
    @State private var aylikHedef: Double = 250000.0
    @State private var aylikGerceklesen: Double = 312500.0
    
    // Weekly Chart Data (Son 5 Hafta)
    struct BarChartPoint: Identifiable {
        let id = UUID()
        let label: String
        let target: Double
        let actual: Double
    }
    
    @State private var weeklyData: [BarChartPoint] = [
        BarChartPoint(label: "41.H", target: 62500, actual: 54000),
        BarChartPoint(label: "42.H", target: 62500, actual: 68500),
        BarChartPoint(label: "43.H", target: 62500, actual: 61200),
        BarChartPoint(label: "44.H", target: 62500, actual: 74800),
        BarChartPoint(label: "45.H", target: 62500, actual: 78400)
    ]
    
    @State private var monthlyData: [BarChartPoint] = [
        BarChartPoint(label: "Oca", target: 200000, actual: 185000),
        BarChartPoint(label: "Şub", target: 200000, actual: 210000),
        BarChartPoint(label: "Mar", target: 220000, actual: 245000),
        BarChartPoint(label: "Nis", target: 220000, actual: 198000),
        BarChartPoint(label: "May", target: 250000, actual: 260000),
        BarChartPoint(label: "Haz", target: 250000, actual: 280000),
        BarChartPoint(label: "Tem", target: 250000, actual: 240000),
        BarChartPoint(label: "Ağu", target: 250000, actual: 275000),
        BarChartPoint(label: "Eyl", target: 280000, actual: 295000),
        BarChartPoint(label: "Eki", target: 280000, actual: 310000),
        BarChartPoint(label: "Kas", target: 250000, actual: 312500),
        BarChartPoint(label: "Ara", target: 300000, actual: 0)
    ]
    
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
    
    @State private var sonIslemler: [DashboardListItem] = [
        DashboardListItem(title: "ERMAY MAKİNE VE TEKSTİL SAN. TİC. LTD. ŞTİ.", description: "Satış Faturası", amount: 24500, date: "Bugün", vade: nil, type: "In"),
        DashboardListItem(title: "KAYA METAL SANAYİ VE TİCARET A.Ş.", description: "Kasa: Tahsilat", amount: 35000, date: "Dün", vade: nil, type: "In"),
        DashboardListItem(title: "AKINCILAR LOJİSTİK VE DEPOLAMA LTD.", description: "Banka: Ödeme", amount: 6200, date: "02.11.2026", vade: nil, type: "Out"),
        DashboardListItem(title: "TEKNO HAMMADDE VE KİMYA A.Ş.", description: "Alış Faturası", amount: 22800, date: "01.11.2026", vade: nil, type: "Out"),
        DashboardListItem(title: "ÖZDEMİR RULMAN SANAYİ", description: "Banka: Tahsilat", amount: 14200, date: "31.10.2026", vade: nil, type: "In")
    ]
    
    @State private var alacakTakibi: [DashboardListItem] = [
        DashboardListItem(title: "ERMAY BİLİŞİM VE DIŞ TİC. LTD. ŞTİ.", description: "Müşteri", amount: 38400, date: "Alacak", vade: 12, type: "In"),
        DashboardListItem(title: "MEGA PLASTİK AMBALAJ SAN. A.Ş.", description: "Müşteri", amount: 29500, date: "Alacak", vade: -4, type: "In"),
        DashboardListItem(title: "YILDIZ TEKNİK CIVATA MAKİNA", description: "Müşteri", amount: 21800, date: "Alacak", vade: 8, type: "In"),
        DashboardListItem(title: "BİRLİK OTOMOTİV YEDEK PARÇA", description: "Müşteri", amount: 18200, date: "Alacak", vade: 0, type: "In"),
        DashboardListItem(title: "GÜVEN KALIP VE PRES SANAYİ", description: "Müşteri", amount: 14600, date: "Alacak", vade: -15, type: "In")
    ]
    
    @State private var borcTakibi: [DashboardListItem] = [
        DashboardListItem(title: "AKINCILAR ÇELİK DÖKÜM VE SANAYİ A.Ş.", description: "Tedarikçi", amount: 32000, date: "Borç", vade: 5, type: "Out"),
        DashboardListItem(title: "DOĞUŞ HAMMADDE SANAYİ TİCARET", description: "Tedarikçi", amount: 19400, date: "Borç", vade: -2, type: "Out"),
        DashboardListItem(title: "ÖZKAN NAKLİYAT VE LOJİSTİK A.Ş.", description: "Tedarikçi", amount: 11200, date: "Borç", vade: 14, type: "Out"),
        DashboardListItem(title: "AS KİMYA SANAYİ VE TİC. LTD.", description: "Tedarikçi", amount: 9700, date: "Borç", vade: 20, type: "Out")
    ]
    
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
    
    // Long Cari Name Compact Formatter (Exact to DashboardScreen.tsx formatDashboardCariName)
    private func formatCariTitle(_ raw: String) -> String {
        var name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        name = name.replacingOccurrences(of: "SANAYİ VE TİCARET LİMİTED ŞİRKETİ", with: "LTD.", options: .caseInsensitive)
        name = name.replacingOccurrences(of: "SANAYI VE TICARET LIMITED SIRKETI", with: "LTD.", options: .caseInsensitive)
        name = name.replacingOccurrences(of: "SANAYİ VE TİCARET ANONİM ŞİRKETİ", with: "A.Ş.", options: .caseInsensitive)
        name = name.replacingOccurrences(of: "SANAYI VE TICARET ANONIM SIRKETI", with: "A.Ş.", options: .caseInsensitive)
        name = name.replacingOccurrences(of: "SAN. VE TİC. LTD. ŞTİ.", with: "LTD.", options: .caseInsensitive)
        name = name.replacingOccurrences(of: "SAN. VE TİC. A.Ş.", with: "A.Ş.", options: .caseInsensitive)
        name = name.replacingOccurrences(of: "LİMİTED ŞİRKETİ", with: "LTD.", options: .caseInsensitive)
        name = name.replacingOccurrences(of: "ANONİM ŞİRKETİ", with: "A.Ş.", options: .caseInsensitive)
        name = name.replacingOccurrences(of: "LTD. ŞTİ.", with: "LTD.", options: .caseInsensitive)
        name = name.replacingOccurrences(of: "ŞİRKETİ", with: "ŞTİ.", options: .caseInsensitive)
        return name
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Header (Exact text & style)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Gösterge Paneli")
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(.white)
                                    .tracking(-0.5)
                                Text("Masaüstü sürümü ile anlık senkronize")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(hex: "8E8E93"))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 6)
                        
                        // 2. 4'lü Dashboard Kartları (2x2 Grid)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            // GÜNLÜK CİRO
                            mainCard(
                                title: "GÜNLÜK CİRO",
                                value: AppFormatters.money(gunlukCiro),
                                subtitle: "Güncel Toplam",
                                iconName: "banknote.fill",
                                color: Color(hex: "FF9F0A"),
                                valueColor: .white
                            )
                            
                            // TOPLAM ALACAK
                            mainCard(
                                title: "TOPLAM ALACAK",
                                value: AppFormatters.money(toplamAlacak),
                                subtitle: "Güncel Toplam",
                                iconName: "arrow.up.right",
                                color: Color(hex: "30D158"),
                                valueColor: .white
                            )
                            
                            // TOPLAM BORÇ
                            mainCard(
                                title: "TOPLAM BORÇ",
                                value: AppFormatters.money(toplamBorc),
                                subtitle: "Güncel Toplam",
                                iconName: "arrow.down.right",
                                color: Color(hex: "FF453A"),
                                valueColor: .white
                            )
                            
                            // NET BAKİYE
                            mainCard(
                                title: "NET",
                                value: netFormatted,
                                subtitle: netSubtitle,
                                iconName: "wallet.pass.fill",
                                color: netColor,
                                valueColor: netColor,
                                isNet: true
                            )
                        }
                        
                        // 3. HIZLI İŞLEMLER
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HIZLI İŞLEMLER")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "8E8E93"))
                            
                            HStack(spacing: 8) {
                                // Alış Faturası
                                quickActionButton(title: "Alış Faturası", iconName: "doc.badge.plus", color: Color(hex: "FF9F0A")) {
                                    showAlisFatura = true
                                }
                                
                                // Satış Faturası
                                quickActionButton(title: "Satış Faturası", iconName: "tablecells.badge.ellipsis", color: Color(hex: "30D158")) {
                                    showSatisFatura = true
                                }
                                
                                // Yeni Sipariş
                                quickActionButton(title: "Yeni Sipariş", iconName: "bag.fill", color: Color(hex: "0A84FF")) {
                                    showSiparis = true
                                }
                                
                                // Yeni Teklif
                                quickActionButton(title: "Yeni Teklif", iconName: "plus.circle.fill", color: Color(hex: "BF5AF2")) {
                                    showTeklif = true
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "121216"))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        
                        // 4. HEDEF & GERÇEKLEŞME Kartı (Harman Model 2 Dual Chart)
                        renderGoalChartCard()
                        
                        // 5. Dynamic Lists Tabs & Content
                        renderListSection()
                        
                        Spacer().frame(height: 110)
                    }
                    .padding(.horizontal, 16)
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
        }
    }
    
    // MARK: - Main Stat Card Component
    private func mainCard(
        title: String,
        value: String,
        subtitle: String,
        iconName: String,
        color: Color,
        valueColor: Color,
        isNet: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isNet ? color : Color(hex: "8E8E93"))
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }
            }
            
            Spacer().frame(height: 14)
            
            Text(value)
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(valueColor)
                .tracking(-0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isNet ? color.opacity(0.85) : Color(hex: "636366"))
                .padding(.top, 4)
        }
        .padding(14)
        .frame(minHeight: 110, alignment: .topLeading)
        .background(isNet ? Color(hex: "131419") : Color(hex: "121216"))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isNet ? color.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Action Button Component
    private func quickActionButton(title: String, iconName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "E2E8F0"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Goal Chart Card (Radial Ring + Mini Stats + Dual Column Bars)
    private func renderGoalChartCard() -> some View {
        let isWeekly = goalPeriod == "week"
        let chartPoints = isWeekly ? weeklyData : monthlyData
        let totalTarget = chartPoints.reduce(0) { $0 + $1.target }
        let totalActual = chartPoints.reduce(0) { $0 + $1.actual }
        let completionRate = totalTarget > 0 ? min(100.0, (totalActual / totalTarget) * 100.0) : 0
        let diff = totalActual - totalTarget
        let isGoalAchieved = totalActual >= totalTarget
        let diffColor = isGoalAchieved ? Color(hex: "10B981") : Color(hex: "EF4444")
        let diffText = isGoalAchieved
            ? (diff == 0 ? "₺0" : "+\(AppFormatters.money(diff))")
            : "-\(AppFormatters.money(abs(diff)))"
        
        return VStack(alignment: .leading, spacing: 14) {
            // Header: Title & Hafta/Ay Toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HEDEF & GERÇEKLEŞME")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "8E8E93"))
                    Text(isWeekly ? "Son 5 Haftalık Performans" : "12 Aylık Performans")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "64748B"))
                }
                Spacer()
                
                // Toggle Buttons
                HStack(spacing: 2) {
                    Button {
                        withAnimation { goalPeriod = "week" }
                    } label: {
                        Text("Hafta")
                            .font(.system(size: 11, weight: isWeekly ? .bold : .medium))
                            .foregroundColor(isWeekly ? .white : Color(hex: "94A3B8"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isWeekly ? Color(hex: "3B82F6") : Color.clear)
                            .cornerRadius(6)
                    }
                    Button {
                        withAnimation { goalPeriod = "month" }
                    } label: {
                        Text("Ay")
                            .font(.system(size: 11, weight: !isWeekly ? .bold : .medium))
                            .foregroundColor(!isWeekly ? .white : Color(hex: "94A3B8"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(!isWeekly ? Color(hex: "3B82F6") : Color.clear)
                            .cornerRadius(6)
                    }
                }
                .padding(2)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
            }
            
            // Top Row: Radial Ring + 3 Mini Badges
            HStack(spacing: 16) {
                // Radial Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                        .frame(width: 82, height: 82)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(min(1.0, completionRate / 100.0)))
                        .stroke(
                            LinearGradient(
                                colors: isGoalAchieved ? [Color(hex: "10B981"), Color(hex: "00FF87")] : [Color(hex: "F87171"), Color(hex: "EF4444")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 82, height: 82)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 1) {
                        Text("%\(Int(completionRate))")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                        Text(isGoalAchieved ? "BAŞARILI" : "TAMAMLANDI")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(isGoalAchieved ? Color(hex: "00FF87") : Color(hex: "EF4444"))
                    }
                }
                .frame(width: 88, height: 88)
                
                // 3 Mini Badges Column
                VStack(spacing: 6) {
                    miniStatBadge(title: isWeekly ? "🎯 Haftalık Hedef" : "🎯 Toplam Hedef", value: AppFormatters.money(totalTarget), borderLeft: Color(hex: "6366F1"), valueColor: .white)
                    miniStatBadge(title: "🚀 Gerçekleşen", value: AppFormatters.money(totalActual), borderLeft: Color(hex: "00FF87"), valueColor: Color(hex: "00FF87"))
                    miniStatBadge(title: "⚖️ Fark", value: diffText, borderLeft: diffColor, valueColor: diffColor, isBold: true)
                }
            }
            
            // Legend Row
            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "6366F1")).frame(width: 8, height: 8)
                    Text("Hedef").font(.system(size: 11, weight: .medium)).foregroundColor(Color(hex: "94A3B8"))
                }
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "00FF87")).frame(width: 8, height: 8)
                    Text("Gerçekleşen").font(.system(size: 11, weight: .medium)).foregroundColor(Color(hex: "94A3B8"))
                }
            }
            .padding(.top, 2)
            
            // Dual Column Bar Chart
            let maxVal = max(chartPoints.map { max($0.target, $0.actual) }.max() ?? 100000, 100000)
            HStack(alignment: .bottom, spacing: isWeekly ? 16 : 6) {
                ForEach(chartPoints) { pt in
                    VStack(spacing: 6) {
                        HStack(alignment: .bottom, spacing: 3) {
                            // Hedef Bar (Mor)
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(LinearGradient(colors: [Color(hex: "818CF8"), Color(hex: "4F46E5")], startPoint: .top, endPoint: .bottom))
                                .frame(width: isWeekly ? 12 : 7, height: max(4, CGFloat(pt.target / maxVal) * 85))
                            
                            // Gerçekleşen Bar (Yeşil)
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(LinearGradient(colors: [Color(hex: "00FF87"), Color(hex: "06B6D4")], startPoint: .top, endPoint: .bottom))
                                .frame(width: isWeekly ? 12 : 7, height: max(4, CGFloat(pt.actual / maxVal) * 85))
                        }
                        
                        Text(pt.label)
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(Color(hex: "94A3B8"))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 115)
            .padding(.top, 6)
        }
        .padding(16)
        .background(Color(hex: "121216"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private func miniStatBadge(title: String, value: String, borderLeft: Color, valueColor: Color, isBold: Bool = false) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(hex: "94A3B8"))
                Text(value)
                    .font(.system(size: 11, weight: isBold ? .heavy : .bold))
                    .foregroundColor(valueColor)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
        .overlay(
            Rectangle()
                .fill(borderLeft)
                .frame(width: 3),
            alignment: .leading
        )
    }
    
    // MARK: - 3 Sekmeli Liste (Apple Native Inset-Grouped Mimarisi)
    private func renderListSection() -> some View {
        let currentList: [DashboardListItem] = {
            switch activeTab {
            case "receivables": return alacakTakibi
            case "payables": return borcTakibi
            default: return sonIslemler
            }
        }()
        
        return VStack(alignment: .leading, spacing: 10) {
            // Apple Inset Section Title
            Text(activeTab == "receivables" ? "MÜŞTERİ ALACAK TAKİBİ" : (activeTab == "payables" ? "TEDARİKÇİ BORÇ TAKİBİ" : "SON TİCARİ HAREKETLER"))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "8E8E93"))
                .padding(.horizontal, 4)
            
            // Apple Native Inset Segmented Picker
            HStack(spacing: 2) {
                tabButton(title: "Son İşlemler", key: "recents")
                tabButton(title: "Alacak Takibi", key: "receivables")
                tabButton(title: "Borç Takibi", key: "payables")
            }
            .padding(2)
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            
            // Apple Inset-Grouped Card Container
            VStack(spacing: 0) {
                if currentList.isEmpty {
                    Text("Kayıt bulunamadı.")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "64748B"))
                        .padding(24)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(currentList.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            // Apple Squircle Icon (G / Ç)
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill((item.type == "In" ? Color(hex: "30D158") : Color(hex: "FF453A")).opacity(0.16))
                                    .frame(width: 32, height: 32)
                                Image(systemName: item.type == "In" ? "arrow.down.left" : "arrow.up.right")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(item.type == "In" ? Color(hex: "30D158") : Color(hex: "FF453A"))
                            }
                            
                            // Title & Subtitle
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatCariTitle(item.title))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text("\(item.description) • \(item.date)\(item.vade != nil ? " • \(item.vade!) G" : "")")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "8E8E93"))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Amount (+ / -)
                            Text("\(item.type == "In" ? "+" : "-")\(AppFormatters.money(item.amount))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(item.type == "In" ? Color(hex: "30D158") : Color(hex: "FF453A"))
                                .lineLimit(1)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "636366"))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        
                        if index < currentList.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 56)
                        }
                    }
                }
            }
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }
    
    private func tabButton(title: String, key: String) -> some View {
        let isSelected = activeTab == key
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { activeTab = key }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "8E8E93"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(isSelected ? Color(hex: "3A3A3C") : Color.clear)
                .cornerRadius(8)
        }
    }
}
