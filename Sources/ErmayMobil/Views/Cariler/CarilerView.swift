import SwiftUI

public struct CarilerView: View {
    @State private var cariler: [CariKart] = []
    @State private var isLoading: Bool = false
    @State private var searchQuery: String = ""
    
    // Sıralama & Filtreleme Durumları (Desktop & CarilerScreen.tsx Exact Parity)
    @State private var sortByBakiye: Bool = false
    @State private var bakiyeSortDesc: Bool = true
    @State private var grupSortState: Int = 0 // 0: None, 1: Müşteri first, 2: Tedarikçi first
    @State private var selectedGrupFilter: String = "Tümü" // "Tümü" | "Müşteri" | "Tedarikçi"
    
    // Sheet Formu (Yeni Cari & Düzenle)
    @State private var showFormSheet: Bool = false
    @State private var editingCari: CariKart? = nil
    
    // Rotating Apple icon colors
    private let iconColors: [Color] = [
        Color(hex: "FF9500"),
        Color(hex: "AF52DE"),
        Color(hex: "007AFF"),
        Color(hex: "34C759"),
        Color(hex: "FF2D55")
    ]
    
    public init() {}
    
    // Filtrelenmiş ve Sıralanmış Liste
    public var filteredCariler: [CariKart] {
        var list = cariler.filter { c in
            let composite = "\(c.unvan) \(c.cariKodu ?? "") \(c.yetkili ?? "") \(c.telefon ?? "") \(c.gsm ?? "") \(c.vergiNo ?? "")"
            let matchSearch = searchQuery.isEmpty || composite.localizedCaseInsensitiveContains(searchQuery)
            if !matchSearch { return false }
            
            if selectedGrupFilter == "Müşteri" {
                return (c.cariTuru ?? "").localizedCaseInsensitiveContains("müşteri") || (c.cariTuru ?? "").localizedCaseInsensitiveContains("musteri")
            }
            if selectedGrupFilter == "Tedarikçi" {
                return (c.cariTuru ?? "").localizedCaseInsensitiveContains("tedarik")
            }
            return true
        }
        
        if sortByBakiye {
            list.sort { a, b in
                let netA = a.bakiyeTuru == "B" ? -a.bakiye : a.bakiye
                let netB = b.bakiyeTuru == "B" ? -b.bakiye : b.bakiye
                return bakiyeSortDesc ? (netB < netA) : (netA < netB)
            }
        } else if grupSortState == 1 {
            list.sort { a, b in
                let aIsM = (a.cariTuru ?? "").localizedCaseInsensitiveContains("müşteri") ? 0 : 1
                let bIsM = (b.cariTuru ?? "").localizedCaseInsensitiveContains("müşteri") ? 0 : 1
                if aIsM != bIsM { return aIsM < bIsM }
                return a.unvan.localizedCompare(b.unvan) == .orderedAscending
            }
        } else if grupSortState == 2 {
            list.sort { a, b in
                let aIsT = (a.cariTuru ?? "").localizedCaseInsensitiveContains("tedarik") ? 0 : 1
                let bIsT = (b.cariTuru ?? "").localizedCaseInsensitiveContains("tedarik") ? 0 : 1
                if aIsT != bIsT { return aIsT < bIsT }
                return a.unvan.localizedCompare(b.unvan) == .orderedAscending
            }
        } else {
            list.sort { a, b in a.unvan.localizedCompare(b.unvan) == .orderedAscending }
        }
        
        return list
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // 1. Header (Standard Exact to CarilerScreen.tsx)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cariler")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(.white)
                                .tracking(-0.5)
                            Text("Müşteri ve Tedarikçi Listesi")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "94A3B8"))
                        }
                        
                        Spacer()
                        
                        Button {
                            editingCari = nil
                            showFormSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Yeni Cari")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: "2563EB"))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    
                    // 2. Search Box
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "94A3B8"))
                        
                        TextField("Cari unvanı, kodu veya yetkili ara...", text: $searchQuery)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(hex: "94A3B8"))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(hex: "121216"))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .padding(.horizontal, 16)
                    
                    // 3. Kolon Başlıkları & Grup / Bakiye Sıralama Butonları
                    HStack {
                        Button {
                            sortByBakiye = false
                            grupSortState = 0
                            selectedGrupFilter = "Tümü"
                        } label: {
                            HStack(spacing: 4) {
                                Text("Ünvan / Cari")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "8E8E93"))
                                if !sortByBakiye && grupSortState == 0 && selectedGrupFilter == "Tümü" {
                                    Text("(A-Z)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color(hex: "3B82F6"))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            // Grup Sıralama / Filtreleme Butonu
                            Button {
                                if sortByBakiye { sortByBakiye = false }
                                grupSortState = (grupSortState + 1) % 3
                            } label: {
                                HStack(spacing: 3) {
                                    Text(selectedGrupFilter != "Tümü" ? selectedGrupFilter : (grupSortState == 1 ? "Müşteri" : (grupSortState == 2 ? "Tedarikçi" : "Grup")))
                                        .font(.system(size: 11, weight: .bold))
                                    if grupSortState == 1 {
                                        Text("▼").font(.system(size: 9))
                                    } else if grupSortState == 2 {
                                        Text("▲").font(.system(size: 9))
                                    } else {
                                        Text("⇅").font(.system(size: 10))
                                    }
                                }
                                .foregroundColor((grupSortState != 0 || selectedGrupFilter != "Tümü") ? Color(hex: "3B82F6") : Color(hex: "94A3B8"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(6)
                            }
                            
                            // Bakiye Sıralama Butonu
                            Button {
                                if grupSortState != 0 { grupSortState = 0 }
                                if !sortByBakiye {
                                    sortByBakiye = true
                                    bakiyeSortDesc = true
                                } else {
                                    bakiyeSortDesc.toggle()
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Text("Bakiye")
                                        .font(.system(size: 11, weight: .bold))
                                    if sortByBakiye {
                                        Text(bakiyeSortDesc ? "▼ (+/-)" : "▲ (-/+)").font(.system(size: 9))
                                    } else {
                                        Text("⇅").font(.system(size: 10))
                                    }
                                }
                                .foregroundColor(sortByBakiye ? Color(hex: "3B82F6") : Color(hex: "94A3B8"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    
                    // 4. Liste
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            if isLoading && cariler.isEmpty {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.top, 40)
                            } else if filteredCariler.isEmpty {
                                Text("Hiç cari bulunamadı.")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "64748B"))
                                    .padding(.top, 40)
                            } else {
                                ForEach(Array(filteredCariler.enumerated()), id: \.element.id) { index, item in
                                    NavigationLink(destination: CariDetailView(
                                        cari: item,
                                        onUpdate: { updated in
                                            if let idx = cariler.firstIndex(where: { $0.id == updated.id }) {
                                                cariler[idx] = updated
                                            }
                                        },
                                        onDelete: { deleted in
                                            Task {
                                                try? await SupabaseService.shared.delete(table: "cariler", id: deleted.id)
                                            }
                                            cariler.removeAll { $0.id == deleted.id }
                                        }
                                    )) {
                                        renderAppleListRow(item: item, index: index)
                                    }
                                }
                            }
                            
                            Spacer().frame(height: 110)
                        }
                        .padding(.horizontal, 16)
                    }
                    .refreshable {
                        await loadLiveCariler()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showFormSheet) {
                CariFormView(cariToEdit: editingCari) { saved in
                    if let idx = cariler.firstIndex(where: { $0.id == saved.id }) {
                        cariler[idx] = saved
                    } else {
                        cariler.insert(saved, at: 0)
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        await loadLiveCariler()
                    }
                }
            }
            .onAppear {
                if cariler.isEmpty {
                    Task {
                        await loadLiveCariler()
                    }
                }
            }
        }
    }
    
    // MARK: - Live Supabase Sync
    private func loadLiveCariler() async {
        isLoading = true
        do {
            let fetched = try await SupabaseService.shared.fetchCariler()
            await MainActor.run {
                if !fetched.isEmpty {
                    self.cariler = fetched
                }
                self.isLoading = false
            }
        } catch {
            print("[CarilerView] Supabase cariler çekme hatası: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Apple List Row Component (Exact Parity with CarilerScreen.tsx renderItem)
    private func renderAppleListRow(item: CariKart, index: Int) -> some View {
        let isBorclu = item.bakiyeTuru == "B"
        let isAlacakli = item.bakiyeTuru == "A"
        let isZero = item.bakiye == 0
        let assignedColor = iconColors[index % iconColors.count]
        
        return HStack(spacing: 12) {
            // Colored Apple Rounded Box Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(assignedColor)
                    .frame(width: 40, height: 40)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            
            // Title & Subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(item.unvan)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text("\(item.cariKodu ?? "CARI-000") • \(item.yetkili ?? "Yetkili Yok")")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .lineLimit(1)
                    
                    // Tag Badge
                    Text(item.cariTuru ?? "Müşteri")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor((item.cariTuru ?? "").contains("Tedarik") ? Color(hex: "FF9F0A") : Color(hex: "0A84FF"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(((item.cariTuru ?? "").contains("Tedarik") ? Color(hex: "FF9F0A") : Color(hex: "0A84FF")).opacity(0.12))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Value & Sub-value
            VStack(alignment: .trailing, spacing: 2) {
                Text(AppFormatters.money(item.bakiye))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isZero ? Color(hex: "8E8E93") : (isAlacakli ? Color(hex: "30D158") : Color(hex: "FF453A")))
                
                Text(isZero ? "Sıfır" : (isAlacakli ? "Alacak" : "Borç"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isZero ? Color(hex: "8E8E93") : (isAlacakli ? Color(hex: "30D158") : Color(hex: "FF453A")))
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
