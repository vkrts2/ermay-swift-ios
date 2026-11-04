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
    @State private var isDragging: Bool = false
    
    public init(selectedTab: Binding<MainTab>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let totalTabs = CGFloat(MainTab.allCases.count)
            let tabWidth = proxy.size.width / totalTabs
            
            HStack(spacing: 0) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        selectTab(tab)
                    } label: {
                        ZStack {
                            // WhatsApp Aktif Oval Cam Mercek (Saf Kristal Sıvı Cam - Çizgisiz)
                            if isSelected {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.24),
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
                                                        Color.white.opacity(0.85),
                                                        Color.white.opacity(0.25),
                                                        Color.white.opacity(0.4)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.2
                                            )
                                    )
                                    .shadow(color: Color.black.opacity(0.45), radius: 8, x: 0, y: 4)
                                    .shadow(color: Color.white.opacity(0.12), radius: 6, x: 0, y: 0)
                                    .scaleEffect(isDragging ? 1.08 : 1.0)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isDragging)
                                    .matchedGeometryEffect(id: "whatsappActiveTabLens", in: lensNamespace)
                            }
                            
                            VStack(spacing: 3) {
                                Image(systemName: isSelected ? tab.icon : tab.outlineIcon)
                                    .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.65))
                                    .scaleEffect(isSelected ? (isDragging ? 1.12 : 1.05) : 1.0)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.68), value: isSelected)
                                
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
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                        }
                        let clampedX = max(0, min(value.location.x, proxy.size.width - 1))
                        let idx = Int(clampedX / tabWidth)
                        let target = MainTab.allCases[max(0, min(idx, MainTab.allCases.count - 1))]
                        if selectedTab != target {
                            triggerHaptic()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                                selectedTab = target
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.70)) {
                            isDragging = false
                        }
                        triggerHaptic()
                    }
            )
        }
        .frame(height: 52)
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
    
    private func selectTab(_ tab: MainTab) {
        triggerHaptic()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
            selectedTab = tab
        }
    }
    
    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}
