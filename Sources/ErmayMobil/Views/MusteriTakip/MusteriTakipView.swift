import SwiftUI

public struct MusteriAdayItem: Identifiable, Hashable {
    public let id: String
    public let numericId: Int
    public let unvan: String
    public let cariKod: String?
    public let yetkili: String?
    public let telefon: String?
    public let kaynak: String // "Cari Hesap" | "Portföy"
    public var kaynakRenk: Color {
        kaynak == "Portföy" ? Color(hex: "10B981") : Color(hex: "3B82F6")
    }
}

public struct MusteriTakipView: View {
    @State private var klasorler: [MusteriTakipKlasor] = []
    @State private var detaylar: [MusteriTakipDetay] = []
    @State private var isLoading: Bool = false
    
    @State private var searchString: String = ""
    @State private var selectedEtiket: String = "Tümü"
    private let etiketler = ["Tümü", "Sıcak Müşteri", "Teklif Aşamasında", "Önemli", "Yeni İletişim", "Takipte"]
    
    // Modal to transfer/add customer (Masaüstü: Yeni Müşteri Aktar)
    @State private var showAdaySelectionModal: Bool = false
    @State private var adaylar: [MusteriAdayItem] = []
    @State private var adaySearchText: String = ""
    @State private var isLoadingAdaylar: Bool = false
    
    // Klasör Silme Onay Modalı
    @State private var klasorToDelete: MusteriTakipKlasor? = nil
    @State private var showDeleteConfirm: Bool = false
    
    public init() {}
    
    public var filteredKlasorler: [MusteriTakipKlasor] {
        klasorler.filter { k in
            let matchSearch = searchString.isEmpty ||
                k.cariUnvan.localizedCaseInsensitiveContains(searchString) ||
                (k.yetkili ?? "").localizedCaseInsensitiveContains(searchString) ||
                (k.etiket ?? "").localizedCaseInsensitiveContains(searchString) ||
                (k.cariKod ?? "").localizedCaseInsensitiveContains(searchString) ||
                (k.telefon ?? "").localizedCaseInsensitiveContains(searchString) ||
                (k.aciklama ?? "").localizedCaseInsensitiveContains(searchString)
            if !matchSearch { return false }
            if selectedEtiket != "Tümü" && k.etiket != selectedEtiket { return false }
            return true
        }
    }
    
    private var filteredAdaylar: [MusteriAdayItem] {
        if adaySearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return adaylar
        }
        let q = adaySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return adaylar.filter { a in
            a.unvan.lowercased().contains(q) ||
            (a.cariKod ?? "").lowercased().contains(q) ||
            (a.yetkili ?? "").lowercased().contains(q) ||
            (a.telefon ?? "").lowercased().contains(q) ||
            a.kaynak.lowercased().contains(q)
        }
    }
    
    private func getCounts(for klasorId: Int) -> (gorusme: Int, fiyat: Int, evrak: Int, not: Int) {
        let items = detaylar.filter { $0.klasorId == klasorId }
        let g = items.filter { $0.tip == "Gorusme" }.count
        let f = items.filter { $0.tip == "Fiyat" }.count
        let e = items.filter { $0.tip == "Gorsel" }.count
        let n = items.filter { $0.tip == "Not" }.count
        return (g, f, e, n)
    }
    
    private func formatDisplayDate(_ isoStr: String) -> String {
        let prefix = String(isoStr.prefix(19)).replacingOccurrences(of: "T", with: " ")
        let parts = prefix.split(separator: " ")
        if let dPart = parts.first {
            let ymd = dPart.split(separator: "-")
            if ymd.count == 3 {
                let timeStr = parts.count > 1 ? String(parts[1].prefix(5)) : ""
                return "\(ymd[2]).\(ymd[1]).\(ymd[0]) \(timeStr)".trimmingCharacters(in: .whitespaces)
            }
        }
        return isoStr
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Header Bar (Masaüstüyle %100 Birebir)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Müşteri Takip")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                            .tracking(-0.5)
                        Text("Müşteri bazlı görüşme, fiyat ve evrak arşivi")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "94A3B8"))
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await prepareAdaylarList()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 13, weight: .bold))
                            Text("Yeni Müşteri Aktar")
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
                
                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "94A3B8"))
                    
                    TextField("Müşteri unvanı, kod, yetkili, telefon veya not ara...", text: $searchString)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    if !searchString.isEmpty {
                        Button {
                            searchString = ""
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
                
                // Filter Chips (Tümü, Sıcak Müşteri, ...)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(etiketler, id: \.self) { etiket in
                            let isSelected = selectedEtiket == etiket
                            Button {
                                selectedEtiket = etiket
                            } label: {
                                Text(etiket)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : Color(hex: "8E8E93"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(isSelected ? Color(hex: "2563EB") : Color.white.opacity(0.05))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Folder List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if filteredKlasorler.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "folder.badge.questionmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(hex: "64748B"))
                                Text("Aramanıza uygun müşteri klasörü bulunamadı.")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "64748B"))
                            }
                            .padding(.top, 50)
                        } else {
                            ForEach(filteredKlasorler) { item in
                                NavigationLink(destination: MusteriTakipDetayView(klasor: item).enableSwipeBack()) {
                                    renderFolderCard(item: item)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 110)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAdaySelectionModal) {
            adaySelectionSheet()
        }
        .alert(isPresented: $showDeleteConfirm) {
            Alert(
                title: Text("Müşteri Takip Klasörünü Sil"),
                message: Text("'\(klasorToDelete?.cariUnvan ?? "")' müşterisine ait takip klasörünü ve tüm detaylarını silmek istediğinize emin misiniz?"),
                primaryButton: .destructive(Text("Evet, Sil")) {
                    if let target = klasorToDelete {
                        executeDeleteKlasor(target)
                    }
                },
                secondaryButton: .cancel(Text("Vazgeç"))
            )
        }
        .task {
            await loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .supabaseRealtimeDataChanged)) { _ in
            Task {
                await loadData()
            }
        }
    }
    
    // MARK: - Folder Card Component
    private func renderFolderCard(item: MusteriTakipKlasor) -> some View {
        let counts = getCounts(for: item.id)
        let folderColor = Color(hex: item.renk ?? "0A84FF")
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // Colored Folder Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(folderColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "folder.fill")
                        .font(.system(size: 20))
                        .foregroundColor(folderColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.cariUnvan)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let kod = item.cariKod, !kod.isEmpty {
                            Text(kod)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "94A3B8"))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("\(item.yetkili ?? "Yetkili Yok") • \(item.telefon ?? "-")")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .lineLimit(1)
                    
                    Text("Son İşlem: \(formatDisplayDate(item.sonIslemTarihi))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "64748B"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    // Etiket Badge
                    Text(item.etiket ?? "Takipte")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(folderColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(folderColor.opacity(0.12))
                        .cornerRadius(6)
                    
                    // Sil Butonu (Masaüstüyle Birebir)
                    Button {
                        klasorToDelete = item
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "EF4444"))
                            .padding(6)
                            .background(Color(hex: "EF4444").opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            Divider().background(Color.white.opacity(0.06))
            
            // 4 Mini Count Badges: Görüşme, Fiyat, Evrak, Not
            HStack(spacing: 8) {
                countBadge(title: "Görüşme", count: counts.gorusme, color: Color(hex: "0A84FF"))
                countBadge(title: "Fiyat", count: counts.fiyat, color: Color(hex: "30D158"))
                countBadge(title: "Evrak", count: counts.evrak, color: Color(hex: "BF5AF2"))
                countBadge(title: "Not", count: counts.not, color: Color(hex: "FF9F0A"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "64748B"))
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private func countBadge(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "94A3B8"))
            Text("(\(count))")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }
    
    // MARK: - Masaüstü Birebir: Yeni Müşteri Aktar Modal (Cari Hesaplar & Portföy Kartları)
    private func adaySelectionSheet() -> some View {
        NavigationStack {
            ZStack {
                Color(hex: "080A0C").ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Modal Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "94A3B8"))
                        
                        TextField("Cari veya Portföy ara...", text: $adaySearchText)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                        
                        if !adaySearchText.isEmpty {
                            Button { adaySearchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(hex: "94A3B8"))
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    
                    if isLoadingAdaylar {
                        Spacer()
                        ProgressView().tint(Color(hex: "2563EB"))
                        Spacer()
                    } else if filteredAdaylar.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: "64748B"))
                            Text("Aktarılacak yeni cari veya portföy kartı bulunamadı.")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "8E8E93"))
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredAdaylar) { aday in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(aday.unvan)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            
                                            Text(aday.kaynak)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(aday.kaynakRenk)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(aday.kaynakRenk.opacity(0.15))
                                                .cornerRadius(4)
                                        }
                                        
                                        HStack(spacing: 4) {
                                            if let kod = aday.cariKod, !kod.isEmpty {
                                                Text(kod)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(Color(hex: "94A3B8"))
                                                Text("•").foregroundColor(Color(hex: "64748B"))
                                            }
                                            Text(aday.yetkili ?? "Yetkili Yok")
                                                .font(.system(size: 11))
                                                .foregroundColor(Color(hex: "8E8E93"))
                                            if let tel = aday.telefon, !tel.isEmpty {
                                                Text("•").foregroundColor(Color(hex: "64748B"))
                                                Text(tel)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color(hex: "8E8E93"))
                                            }
                                        }
                                        .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        selectAdayAndCreateKlasor(aday)
                                    } label: {
                                        Text("Seç & Aktar")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(Color(hex: "2563EB"))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.vertical, 6)
                                .listRowBackground(Color(hex: "121216"))
                                .listRowSeparatorTint(Color.white.opacity(0.08))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .padding(.top, 12)
            }
            .navigationTitle("Yeni Müşteri Aktar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        showAdaySelectionModal = false
                    }
                    .foregroundColor(Color(hex: "94A3B8"))
                }
            }
        }
        .presentationDetents([.large, .medium])
    }
    
    // MARK: - Adayları Hazırla (Cari & Portföy)
    private func prepareAdaylarList() async {
        isLoadingAdaylar = true
        showAdaySelectionModal = true
        adaySearchText = ""
        
        let existingCariIds = Set(klasorler.filter { $0.cariId > 0 }.map { $0.cariId })
        let existingUnvanlar = Set(klasorler.map { $0.cariUnvan.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        
        var list: [MusteriAdayItem] = []
        
        // 1. Cari Hesaplar
        let cariler = DataStore.shared.cariler
        for c in cariler {
            let numId = Int(c.id) ?? 0
            let unvanClean = c.unvan.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if numId > 0 && existingCariIds.contains(numId) { continue }
            if existingUnvanlar.contains(unvanClean) { continue }
            
            list.append(MusteriAdayItem(
                id: "cari_\(c.id)",
                numericId: numId,
                unvan: c.unvan,
                cariKod: c.cariKodu,
                yetkili: c.yetkili,
                telefon: !(c.telefon ?? "").isEmpty ? (c.telefon ?? "") : (c.gsm ?? ""),
                kaynak: "Cari Hesap"
            ))
        }
        
        // 2. Portföy Kartları
        do {
            let portfoyler: [PortfoyKartKayit] = try await SupabaseService.shared.fetch(from: "portfoy_kartlar")
            for p in portfoyler where !p.isDeleted {
                let unvanClean = p.firmaIsmi.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if existingUnvanlar.contains(unvanClean) { continue }
                if list.contains(where: { $0.unvan.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == unvanClean }) { continue }
                
                list.append(MusteriAdayItem(
                    id: "portfoy_\(p.id)",
                    numericId: Int(p.id) ?? 0,
                    unvan: p.firmaIsmi,
                    cariKod: p.vkn.isEmpty ? "PORTFOY" : p.vkn,
                    yetkili: p.yetkiliKisi,
                    telefon: (!p.gsm.isEmpty ? p.gsm : p.telefon),
                    kaynak: "Portföy"
                ))
            }
        } catch {
            print("Portfoy fetch error: \(error)")
        }
        
        list.sort { $0.unvan.localizedCompare($1.unvan) == .orderedAscending }
        await MainActor.run {
            self.adaylar = list
            self.isLoadingAdaylar = false
        }
    }
    
    // MARK: - Aday Seç ve Takip Klasörü Oluştur
    private func selectAdayAndCreateKlasor(_ aday: MusteriAdayItem) {
        let nowIso = ISO8601DateFormatter().string(from: Date())
        let targetCariId = (aday.kaynak == "Cari Hesap") ? aday.numericId : 0
        let targetKod = aday.cariKod ?? (aday.kaynak == "Portföy" ? "PORTFOY" : nil)

        var payload: [String: Any] = [
            "uuid": UUID().uuidString.lowercased(),
            "tenant_id": SupabaseService.shared.tenantId,
            "cari_id": targetCariId,
            "cari_unvan": aday.unvan,
            "klasor_adi": aday.unvan,
            "etiket": "Yeni İletişim",
            "renk": "#3B82F6",
            "olusturma_tarihi": nowIso,
            "son_islem_tarihi": nowIso,
            "is_deleted": false
        ]
        if let kod = targetKod { payload["cari_kod"] = kod }
        if let tel = aday.telefon { payload["telefon"] = tel }
        if let yet = aday.yetkili { payload["yetkili"] = yet }

        showAdaySelectionModal = false

        Task {
            if let data = try? JSONSerialization.data(withJSONObject: payload) {
                try? await SupabaseService.shared.insertRaw(into: "musteri_takip_klasorler", data: data)
            }
            await loadData()
        }
    }
    
    // MARK: - Klasör Silme (Bulut + Yerel)
    private func executeDeleteKlasor(_ item: MusteriTakipKlasor) {
        klasorler.removeAll { $0.id == item.id }
        detaylar.removeAll { $0.klasorId == item.id }
        
        Task {
            // Önce alt detayları klasor_id filtresi ile soft-delete yap
            try? await SupabaseService.shared.deleteWhere(table: "musteri_takip_detaylar", filter: "klasor_id=eq.\(item.id)")
            // Ardından klasörü temizle
            try? await SupabaseService.shared.delete(table: "musteri_takip_klasorler", id: String(item.id))
        }
    }
    
    private func loadData() async {
        isLoading = true
        do {
            let kList: [MusteriTakipKlasor] = try await SupabaseService.shared.fetch(from: "musteri_takip_klasorler", orderBy: "id.desc")
            let dList: [MusteriTakipDetay] = try await SupabaseService.shared.fetch(from: "musteri_takip_detaylar", orderBy: "id.desc")
            await MainActor.run {
                self.klasorler = kList
                self.detaylar = dList
            }
        } catch {
            print("MusteriTakip fetch error: \(error)")
        }
        isLoading = false
    }
}
