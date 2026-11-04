import SwiftUI

public enum MainTab: Int, CaseIterable {
    case dashboard = 0
    case cariler = 1
    case siparisler = 2
    case teklifler = 3
    case dahaFazla = 4
    
    public var title: String {
        switch self {
        case .dashboard: return "Ana Sayfa"
        case .cariler: return "Cariler"
        case .siparisler: return "Siparişler"
        case .teklifler: return "Teklifler"
        case .dahaFazla: return "Daha Fazla"
        }
    }
    
    public var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .cariler: return "person.2.fill"
        case .siparisler: return "bag.fill"
        case .teklifler: return "doc.text.fill"
        case .dahaFazla: return "ellipsis.circle.fill"
        }
    }
    
    public var outlineIcon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .cariler: return "person.2"
        case .siparisler: return "bag"
        case .teklifler: return "doc.text"
        case .dahaFazla: return "ellipsis.circle"
        }
    }
}

public struct FloatingTabBar: View {
    @Binding public var selectedTab: MainTab
    @Namespace private var lensNamespace
    
    public init(selectedTab: Binding<MainTab>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                } label: {
                    ZStack {
                        // WhatsApp Aktif Oval Cam Mercek (Bulging Oval Lens with Chromatic Dispersion)
                        if isSelected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.22),
                                            Color.white.opacity(0.08)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 52) // Bar sınırlarının dışına hafifçe taşan oval büyüteç
                                .overlay(
                                    // Prizmatik Speküler Kenar Çizgisi
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.8),
                                                    Color.white.opacity(0.2),
                                                    Color.white.opacity(0.4)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.2
                                        )
                                )
                                .overlay(
                                    // Üst Prizma Renk Kırılması (Gökkuşağı Caustic: Camgöbeği -> Zümrüt -> Amber -> Kırmızı)
                                    VStack {
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.0, green: 0.95, blue: 1.0, opacity: 0.95),
                                                Color(red: 0.1, green: 1.0, blue: 0.5, opacity: 0.95),
                                                Color(red: 1.0, green: 0.9, blue: 0.1, opacity: 0.95),
                                                Color(red: 1.0, green: 0.25, blue: 0.35, opacity: 0.9)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .frame(height: 2.5)
                                        .cornerRadius(1.5)
                                        .padding(.horizontal, 8)
                                        .offset(y: -0.5)
                                        
                                        Spacer()
                                        
                                        // Alt Prizma Renk Kırılması
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1.0, green: 0.25, blue: 0.35, opacity: 0.85),
                                                Color(red: 1.0, green: 0.85, blue: 0.1, opacity: 0.9),
                                                Color(red: 0.1, green: 1.0, blue: 0.6, opacity: 0.9),
                                                Color(red: 0.0, green: 0.8, blue: 1.0, opacity: 0.85)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .frame(height: 2.0)
                                        .cornerRadius(1)
                                        .padding(.horizontal, 10)
                                        .offset(y: 0.5)
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
                                .shadow(color: Color.white.opacity(0.15), radius: 6, x: 0, y: 0)
                                .matchedGeometryEffect(id: "whatsappActiveTabLens", in: lensNamespace)
                        }
                        
                        VStack(spacing: 3) {
                            Image(systemName: isSelected ? tab.icon : tab.outlineIcon)
                                .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? .white : Color.white.opacity(0.65))
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                            
                            Text(tab.title)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : Color.white.opacity(0.65))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            // Ana WhatsApp Buzlu Cam Kapsülü (Frosted Glass Capsule)
            Capsule()
                .fill(Color(hex: "161A22").opacity(0.70))
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    // Üst Speküler Işık Yansıması
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.42),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.black.opacity(0.65), radius: 25, x: 0, y: 12)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}
