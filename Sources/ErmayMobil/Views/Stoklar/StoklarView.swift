import SwiftUI

public struct StokHareketItem: Identifiable, Hashable {
    public let id: String
    public let tarih: String
    public let islemTuru: String
    public let aciklama: String
    public let miktar: Double
    public let kalanMiktar: Double
    public let isGiris: Bool
    
    public init(id: String = UUID().uuidString, tarih: String, islemTuru: String, aciklama: String, miktar: Double, kalanMiktar: Double, isGiris: Bool) {
        self.id = id
        self.tarih = tarih
        self.islemTuru = islemTuru
        self.aciklama = aciklama
        self.miktar = miktar
        self.kalanMiktar = kalanMiktar
        self.isGiris = isGiris
    }
}

public struct StoklarView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var dataStore = DataStore.shared
    
    // Stok Listesi State
    @State private var stoklar: [StokKart] = []
    @State private var dbSearchResults: [StokKart]? = nil
    
    // Filters & Paging State
    @State private var filterKod: String = ""
    @State private var onlyWithBalance: Bool = false
    @State private var selectedStokIds: [String] = []
    @State private var selectedStok: StokKart? = nil
    
    // Form State (Exact to StoklarScreen.tsx)
    @State private var editStokKodu: String = ""
    @State private var editStokAdi: String = ""
    @State private var editKategori: String = "Rulman"
    @State private var editBirim: String = "Adet"
    @State private var editOrtalamaAlisFiyati: String = "0"
    @State private var editAlisFiyati: String = "0"
    @State private var editOrtalamaSatisFiyati: String = "0"
    @State private var editSatisFiyati: String = "0"
    @State private var editKdv: String = "20"
    @State private var editAcilisBakiye: String = "0"
    
    // Movements for Selected Stock
    @State private var hareketler: [StokHareketItem] = []
    @State private var selectedHareket: StokHareketItem? = nil
    
    // Modals
    @State private var showCalendar: Bool = false
    @State private var showGroupModal: Bool = false
    @State private var newGroupName: String = ""
    @State private var showManualIslemModal: Bool = false
    @State private var manualIslemTur: String = "GİRİŞ"
    @State private var manualMiktar: String = "1"
    @State private var manualFiyat: String = "0"
    @State private var manualAciklama: String = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareContent: String = ""
    @State private var pdfPreviewItem: PDFPreviewItem? = nil
    @State private var isGeneratingPDF: Bool = false
    
    // Groups & Units
    @State private var gruplar: [String] = ["Genel", "Rulman", "Sızdırmazlık", "Madeni Yağ", "Bağlantı"]
    private let birimler = ["Adet", "Kg", "Mt", "M2"]
    
    public init() {}
    
    public var filteredStoklar: [StokKart] {
        let baseList: [StokKart]
        if !filterKod.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let pushedDown = dbSearchResults {
            baseList = pushedDown
        } else {
            baseList = !dataStore.stoklar.isEmpty ? dataStore.stoklar : stoklar
        }
        return baseList.filter { s in
            if dbSearchResults == nil && !filterKod.isEmpty {
                let matchText = s.stokAdi.localizedCaseInsensitiveContains(filterKod) ||
                    (s.stokKodu ?? "").localizedCaseInsensitiveContains(filterKod) ||
                    (s.barkod ?? "").localizedCaseInsensitiveContains(filterKod) ||
                    (s.grupAdi ?? "").localizedCaseInsensitiveContains(filterKod)
                if !matchText { return false }
            }
            if onlyWithBalance && s.mevcutMiktar <= 0 { return false }
            return true
        }
    }
    
    private var isEditMode: Bool {
        selectedStok != nil
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        
                        // =========================================================================
                        // 1. TOP LEFT: STOK LİSTESİ PANELİ (Exact Desktop Parity)
                        // =========================================================================
                        VStack(spacing: 12) {
                            // Panel Header
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "shippingbox.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "60A5FA"))
                                    Text("Stok Listesi")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text("Toplam:")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                    Text("\(filteredStoklar.count)")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundColor(Color(hex: "60A5FA"))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "60A5FA").opacity(0.12))
                                .cornerRadius(6)
                            }
                            
                            // Search Row & Bakiye Göster Checkbox
                            HStack(spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                    TextField("Stok Kodu / Adı / Barkodu...", text: $filterKod)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                    if !filterKod.isEmpty {
                                        Button { filterKod = "" } label: {
                                            Image(systemName: "xmark.circle.fill").foregroundColor(Color(hex: "8E8E93"))
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                                
                                // Bakiye Göster Butonu
                                Button {
                                    onlyWithBalance.toggle()
                                } label: {
                                    Text("Bakiye Göster")
                                        .font(.system(size: 11, weight: onlyWithBalance ? .bold : .medium))
                                        .foregroundColor(onlyWithBalance ? .white : Color(hex: "8E8E93"))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(onlyWithBalance ? Color(hex: "2563EB") : Color.white.opacity(0.05))
                                        .cornerRadius(10)
                                }
                            }
                            
                            // Pager & Select All Row
                            HStack {
                                Button {
                                    if selectedStokIds.count == filteredStoklar.count {
                                        selectedStokIds.removeAll()
                                    } else {
                                        selectedStokIds = filteredStoklar.map { $0.id }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: selectedStokIds.count == filteredStoklar.count && !filteredStoklar.isEmpty ? "checkmark.square.fill" : "square")
                                            .foregroundColor(Color(hex: "60A5FA"))
                                        Text("Tümünü Seç")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(hex: "94A3B8"))
                                    }
                                }
                                
                                Spacer()
                                
                                Text("1 / 1 (\(filteredStoklar.count))")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "94A3B8"))
                            }
                            
                            // Stock Items
                            VStack(spacing: 8) {
                                ForEach(filteredStoklar) { item in
                                    let isSelected = selectedStok?.id == item.id
                                    stokItemRow(item: item, isSelected: isSelected)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "121216"))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        
                        // =========================================================================
                        // 2. MIDDLE: STOK HAREKETLERİ PANELİ (Exact Desktop Parity)
                        // =========================================================================
                        VStack(spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "60A5FA"))
                                    Text("Stok Hareket İşlemleri")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                Button {
                                    showCalendar = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                        Text("Takvim")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(hex: "60A5FA"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(hex: "60A5FA").opacity(0.12))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Table Header Row
                            HStack {
                                Text("Tarih").font(.system(size: 10, weight: .bold)).foregroundColor(Color(hex: "8E8E93")).frame(width: 70, alignment: .leading)
                                Text("İşlem Türü").font(.system(size: 10, weight: .bold)).foregroundColor(Color(hex: "8E8E93")).frame(width: 75, alignment: .leading)
                                Text("Açıklama").font(.system(size: 10, weight: .bold)).foregroundColor(Color(hex: "8E8E93")).frame(maxWidth: .infinity, alignment: .leading)
                                Text("Miktar").font(.system(size: 10, weight: .bold)).foregroundColor(Color(hex: "8E8E93")).frame(width: 50, alignment: .trailing)
                                Text("Kalan").font(.system(size: 10, weight: .bold)).foregroundColor(Color(hex: "8E8E93")).frame(width: 50, alignment: .trailing)
                            }
                            .padding(.horizontal, 4)
                            
                            Divider().background(Color.white.opacity(0.08))
                            
                            if selectedStok == nil {
                                Text("Hareketleri görmek için lütfen bir stok kartı seçin.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "64748B"))
                                    .padding(.vertical, 20)
                            } else if hareketler.isEmpty {
                                Text("Bu stok kartına ait hareket bulunamadı.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "64748B"))
                                    .padding(.vertical, 20)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(hareketler) { h in
                                        let isSelH = selectedHareket?.id == h.id
                                        Button {
                                            selectedHareket = isSelH ? nil : h
                                        } label: {
                                            HStack {
                                                Text(h.tarih).font(.system(size: 11)).foregroundColor(.white).frame(width: 70, alignment: .leading)
                                                Text(h.islemTuru).font(.system(size: 11, weight: .bold)).foregroundColor(h.isGiris ? Color(hex: "10B981") : Color(hex: "F59E0B")).frame(width: 75, alignment: .leading)
                                                Text(h.aciklama).font(.system(size: 11)).foregroundColor(Color(hex: "E2E8F0")).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
                                                Text(String(format: "%.1f", h.miktar)).font(.system(size: 11, weight: .semibold)).foregroundColor(.white).frame(width: 50, alignment: .trailing)
                                                Text(String(format: "%.1f", h.kalanMiktar)).font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: "60A5FA")).frame(width: 50, alignment: .trailing)
                                            }
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 4)
                                            .background(isSelH ? Color(hex: "3B82F6").opacity(0.15) : Color.clear)
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "121216"))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        
                        // =========================================================================
                        // 3. BOTTOM: STOK KARTI FORM & ACTIONS (Exact Desktop Parity)
                        // =========================================================================
                        VStack(alignment: .leading, spacing: 14) {
                            Text(isEditMode ? "Stok Kartını Düzenle: \(editStokAdi)" : "Yeni Stok Kartı Ekle")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(isEditMode ? Color(hex: "F59E0B") : Color(hex: "60A5FA"))
                            
                            // Form Input Grid
                            VStack(spacing: 10) {
                                // Kodu
                                fieldRow(label: "Kodu", text: $editStokKodu, placeholder: "Stok Kodu")
                                
                                // Stok Adı
                                fieldRow(label: "Stok Adı", text: $editStokAdi, placeholder: "Stok Adı")
                                
                                // Grup & Birim
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Grup").font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
                                            Spacer()
                                            Button { showGroupModal = true } label: {
                                                Image(systemName: "plus.circle.fill").font(.system(size: 12)).foregroundColor(Color(hex: "60A5FA"))
                                            }
                                        }
                                        Picker("Grup", selection: $editKategori) {
                                            ForEach(gruplar, id: \.self) { g in Text(g).tag(g) }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Birim").font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
                                        Picker("Birim", selection: $editBirim) {
                                            ForEach(birimler, id: \.self) { b in Text(b).tag(b) }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                // Fiyatlar
                                HStack(spacing: 10) {
                                    fieldRow(label: "Ort. Alış F.", text: $editOrtalamaAlisFiyati, placeholder: "0.00", disabled: true)
                                    fieldRow(label: "Alış F.", text: $editAlisFiyati, placeholder: "0.00")
                                }
                                HStack(spacing: 10) {
                                    fieldRow(label: "Ort. Satış F.", text: $editOrtalamaSatisFiyati, placeholder: "0.00", disabled: true)
                                    fieldRow(label: "Satış F.", text: $editSatisFiyati, placeholder: "0.00")
                                }
                                HStack(spacing: 10) {
                                    fieldRow(label: "KDV (%)", text: $editKdv, placeholder: "20")
                                    fieldRow(label: "Açılış Bakiye", text: $editAcilisBakiye, placeholder: "0", disabled: isEditMode)
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.08)).padding(.vertical, 4)
                            
                            // Action Buttons (Desktop Parity 5 Rows)
                            VStack(spacing: 8) {
                                // Row 1: Yeni, Kaydet, Düzen, Sil
                                HStack(spacing: 8) {
                                    desktopActionBtn(title: "Yeni", icon: "plus", color: Color(hex: "00C2FF")) {
                                        handleCreateNew()
                                    }
                                    desktopActionBtn(title: "Kaydet", icon: "checkmark", color: Color(hex: "10B981")) {
                                        handleSaveStok()
                                    }
                                    desktopActionBtn(title: "Düzen", icon: "square.and.pencil", color: Color(hex: "60A5FA"), enabled: isEditMode) {}
                                    desktopActionBtn(title: "Sil", icon: "trash.fill", color: Color(hex: "EF4444"), enabled: isEditMode) {
                                        showDeleteConfirm = true
                                    }
                                }
                                
                                // Row 2: Stok Girişi (F1), Stok Çıkışı (F2)
                                HStack(spacing: 8) {
                                    desktopFullActionBtn(title: "Stok Girişi (F1)", icon: "plus.square.fill", color: Color(hex: "10B981"), enabled: isEditMode) {
                                        manualIslemTur = "GİRİŞ"
                                        manualFiyat = editAlisFiyati
                                        showManualIslemModal = true
                                    }
                                    desktopFullActionBtn(title: "Stok Çıkışı (F2)", icon: "minus.square.fill", color: Color(hex: "F59E0B"), enabled: isEditMode) {
                                        manualIslemTur = "ÇIKIŞ"
                                        manualFiyat = editSatisFiyati
                                        showManualIslemModal = true
                                    }
                                }
                                
                                // Row 3: Düzenle (F3), İşlemi Sil
                                HStack(spacing: 8) {
                                    desktopFullActionBtn(title: "Düzenle (F3)", icon: "pencil", color: Color(hex: "06B6D4"), enabled: isEditMode && selectedHareket != nil) {
                                        if let h = selectedHareket {
                                            manualIslemTur = h.islemTuru
                                            manualMiktar = String(h.miktar)
                                            manualAciklama = h.aciklama
                                            showManualIslemModal = true
                                        }
                                    }
                                    desktopFullActionBtn(title: "İşlemi Sil", icon: "trash.fill", color: Color(hex: "EF4444"), enabled: isEditMode && selectedHareket != nil) {
                                        if let h = selectedHareket {
                                            hareketler.removeAll { $0.id == h.id }
                                            selectedHareket = nil
                                        }
                                    }
                                }
                                
                                // Row 4: Raporlar, Yazdır
                                HStack(spacing: 8) {
                                    desktopFullActionBtn(title: "Raporlar", icon: "doc.text.fill", color: Color(hex: "6366F1")) {
                                        exportReport()
                                    }
                                    desktopFullActionBtn(title: "Yazdır", icon: "printer.fill", color: Color(hex: "8B5CF6")) {
                                        exportReport()
                                    }
                                }
                                
                                // Row 5: Excel
                                desktopFullActionBtn(title: "Excel (Dışa Aktar)", icon: "tablecells.fill", color: Color(hex: "10B981")) {
                                    exportExcel()
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "121216"))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        
                        Spacer().frame(height: 110)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showManualIslemModal) {
                manualIslemSheet()
            }
            .sheet(isPresented: $showCalendar) {
                VStack(spacing: 20) {
                    Text("Tarih Filtresi").font(.system(size: 18, weight: .bold)).foregroundColor(.white).padding(.top, 20)
                    DatePicker("Tarih", selection: .constant(Date()), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                    Button("Uygula") { showCalendar = false }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color(hex: "2563EB"))
                        .cornerRadius(10)
                    Spacer()
                }
                .presentationDetents([.medium])
            }
            .alert("Stok Kartını Sil", isPresented: $showDeleteConfirm) {
                Button("Sil", role: .destructive) {
                    if let sel = selectedStok {
                        let stokUuid = sel.syncGuid ?? sel.id
                        let stokId = sel.id
                        stoklar.removeAll { $0.id == sel.id || $0.syncGuid == stokUuid }
                        handleCreateNew()

                        Task {
                            do {
                                try await SupabaseService.shared.delete(table: "stoklar", id: stokId)
                                await loadLiveStoklar()
                            } catch {
                                await MainActor.run {
                                    NotificationCenter.default.post(
                                        name: .userToastNotification,
                                        object: nil,
                                        userInfo: ["message": "Stok silinemedi: \(error.localizedDescription)"]
                                    )
                                }
                            }
                        }
                    }
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("\(selectedStok?.stokAdi ?? "") adlı stoğu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.")
            }
            .onAppear {
                Task {
                    await loadLiveStoklar()
                }
            }
            .onChange(of: filterKod) { _ in
                dbSearchResults = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: .supabaseRealtimeDataChanged)) { _ in
                Task {
                    await loadLiveStoklar()
                }
            }
            .sheet(item: $pdfPreviewItem) { item in
                #if canImport(UIKit)
                PDFViewerModal(title: item.title, pdfData: item.data, fileName: item.fileName)
                #endif
            }
    }
    
    private func loadLiveStoklar() async {
        await dataStore.loadStoklarCacheFirst(forceCloudRefresh: true)
        self.stoklar = dataStore.stoklar
    }
    
    private func loadStokHareketler(for stok: StokKart) async {
        let fetched: [StokHareket] = (try? await SupabaseService.shared.fetch(from: "stok_hareketler")) ?? []
        let filtered = fetched.filter { $0.stokId == stok.id || $0.stokAdi == stok.stokAdi || ($0.stokKodu != nil && $0.stokKodu == stok.stokKodu) }
            .sorted { ($0.tarih ?? "") < ($1.tarih ?? "") }
        var running = 0.0
        var items: [StokHareketItem] = []
        for h in filtered {
            let isG = h.giren > 0 || (h.cikan == 0 && !(h.islemTuru ?? "").localizedCaseInsensitiveContains("çıkış") && !(h.islemTuru ?? "").localizedCaseInsensitiveContains("satış"))
            let m = max(h.miktar, max(h.giren, h.cikan))
            running += isG ? m : -m
            items.append(StokHareketItem(
                id: h.id,
                tarih: String((h.tarih ?? "-").prefix(10)),
                islemTuru: h.islemTuru ?? (isG ? "GİRİŞ" : "ÇIKIŞ"),
                aciklama: h.aciklama ?? h.cariUnvan ?? "-",
                miktar: m,
                kalanMiktar: running,
                isGiris: isG
            ))
        }
        await MainActor.run {
            self.hareketler = items.reversed()
        }
    }
    
    // MARK: - Helper Views
    private func fieldRow(label: String, text: Binding<String>, placeholder: String, disabled: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
            TextField(placeholder, text: text)
                .font(.system(size: 13))
                .foregroundColor(disabled ? Color(hex: "8E8E93") : .white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(disabled ? Color.white.opacity(0.02) : Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .disabled(disabled)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func desktopActionBtn(title: String, icon: String, color: Color, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 11, weight: .bold))
                Text(title).font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.12))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 1))
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
    
    private func desktopFullActionBtn(title: String, icon: String, color: Color, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .bold))
                Text(title).font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(color.opacity(0.12))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 1))
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
    
    private func handleSelectStok(_ item: StokKart) {
        if selectedStok?.id == item.id {
            handleCreateNew()
            return
        }
        selectedStok = item
        editStokKodu = item.stokKodu ?? ""
        editStokAdi = item.stokAdi
        editKategori = item.grupAdi ?? "Genel"
        editBirim = item.birim ?? "Adet"
        editAlisFiyati = String(item.alisFiyati)
        editOrtalamaAlisFiyati = String(item.alisFiyati)
        editSatisFiyati = String(item.satisFiyati)
        editOrtalamaSatisFiyati = String(item.satisFiyati)
        editKdv = String(Int(item.kdvOrani))
        editAcilisBakiye = String(item.mevcutMiktar)
        
        hareketler = []
        Task {
            await loadStokHareketler(for: item)
        }
    }
    
    private func handleCreateNew() {
        selectedStok = nil
        selectedHareket = nil
        editStokKodu = "STK-\(Int.random(in: 100...999))"
        editStokAdi = ""
        editKategori = "Genel"
        editBirim = "Adet"
        editAlisFiyati = "0"
        editOrtalamaAlisFiyati = "0"
        editSatisFiyati = "0"
        editOrtalamaSatisFiyati = "0"
        editKdv = "20"
        editAcilisBakiye = "0"
        hareketler = []
    }
    
    private func handleSaveStok() {
        guard !editStokAdi.isEmpty else { return }
        if var sel = selectedStok {
            sel.stokAdi = editStokAdi
            sel.stokKodu = editStokKodu
            sel.grupAdi = editKategori
            sel.birim = editBirim
            sel.alisFiyati = Double(editAlisFiyati.replacingOccurrences(of: ",", with: ".")) ?? 0
            sel.satisFiyati = Double(editSatisFiyati.replacingOccurrences(of: ",", with: ".")) ?? 0
            sel.kdvOrani = Double(editKdv.replacingOccurrences(of: ",", with: ".")) ?? 20
            if let idx = stoklar.firstIndex(where: { $0.id == sel.id }) {
                stoklar[idx] = sel
            }
            selectedStok = sel
            Task {
                do {
                    try await DataStore.shared.saveStok(sel, isUpdate: true)
                    await loadLiveStoklar()
                } catch {
                    await MainActor.run {
                        NotificationCenter.default.post(name: .userToastNotification, object: nil, userInfo: ["message": "Stok güncellenemedi: \(error.localizedDescription)"])
                    }
                }
            }
        } else {
            let newItem = StokKart(
                id: "",
                stokKodu: editStokKodu.isEmpty ? "STK-\(Int.random(in: 100...999))" : editStokKodu,
                stokAdi: editStokAdi,
                grupAdi: editKategori,
                birim: editBirim,
                alisFiyati: Double(editAlisFiyati.replacingOccurrences(of: ",", with: ".")) ?? 0,
                satisFiyati: Double(editSatisFiyati.replacingOccurrences(of: ",", with: ".")) ?? 0,
                kdvOrani: Double(editKdv.replacingOccurrences(of: ",", with: ".")) ?? 20,
                mevcutMiktar: Double(editAcilisBakiye.replacingOccurrences(of: ",", with: ".")) ?? 0
            )
            stoklar.insert(newItem, at: 0)
            selectedStok = newItem
            Task {
                do {
                    try await DataStore.shared.saveStok(newItem, isUpdate: false)
                    await loadLiveStoklar()
                } catch {
                    await MainActor.run {
                        NotificationCenter.default.post(name: .userToastNotification, object: nil, userInfo: ["message": "Stok kaydedilemedi: \(error.localizedDescription)"])
                    }
                }
            }
        }
    }
    
    private func manualIslemSheet() -> some View {
        VStack(spacing: 16) {
            Text("Stok \(manualIslemTur) İşlemi")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            VStack(spacing: 12) {
                fieldRow(label: "Miktar", text: $manualMiktar, placeholder: "1")
                fieldRow(label: "Fiyat", text: $manualFiyat, placeholder: "0.00")
                fieldRow(label: "Açıklama", text: $manualAciklama, placeholder: "Manuel Stok Hareketi")
            }
            .padding(.horizontal, 20)
            
            Button {
                let m = Double(manualMiktar.replacingOccurrences(of: ",", with: ".")) ?? 1.0
                let f = Double(manualFiyat.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                let isG = manualIslemTur == "GİRİŞ"
                let currentBal = selectedStok?.mevcutMiktar ?? 0.0
                let newBal = isG ? (currentBal + m) : (currentBal - m)
                let todayStr = AppFormatters.isoDate.string(from: Date())
                let desc = manualAciklama.isEmpty ? "Manuel \(manualIslemTur)" : manualAciklama
                
                let newHareket = StokHareketItem(
                    tarih: AppFormatters.shortDate.string(from: Date()),
                    islemTuru: manualIslemTur,
                    aciklama: desc,
                    miktar: m,
                    kalanMiktar: newBal,
                    isGiris: isG
                )
                hareketler.insert(newHareket, at: 0)
                if var sel = selectedStok {
                    sel.mevcutMiktar = newBal
                    selectedStok = sel
                    if let idx = stoklar.firstIndex(where: { $0.id == sel.id }) {
                        stoklar[idx] = sel
                    }
                    Task {
                        var hPayload: [String: Any] = [
                            "uuid": UUID().uuidString.lowercased(),
                            "tenant_id": SupabaseService.shared.tenantId,
                            "stok_adi": sel.stokAdi,
                            "stok_kodu": sel.stokKodu ?? "",
                            "islem_turu": manualIslemTur,
                            "hareket_turu": manualIslemTur,
                            "miktar": m,
                            "giren": isG ? m : 0.0,
                            "cikan": !isG ? m : 0.0,
                            "birim": sel.birim ?? "Adet",
                            "birim_fiyat": f,
                            "fiyat": f,
                            "toplam_tutar": m * f,
                            "aciklama": desc,
                            "tarih": todayStr,
                            "is_deleted": false
                        ]
                        if let sIdInt = Int(sel.id) {
                            hPayload["stok_id"] = sIdInt
                        }
                        if let hData = try? JSONSerialization.data(withJSONObject: hPayload) {
                            try? await SupabaseService.shared.insertRaw(into: "stok_hareketler", data: hData)
                        }
                        try? await DataStore.shared.saveStok(sel, isUpdate: true)
                    }
                }
                showManualIslemModal = false
            } label: {
                Text("Hareketi Kaydet")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "2563EB"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
        }
        .presentationDetents([.medium])
    }
    
    private func exportReport() {
        #if canImport(UIKit)
        Task { @MainActor in
            isGeneratingPDF = true
            let listToExport = selectedStok != nil ? [selectedStok!] : filteredStoklar
            let data = await PDFService.shared.fetchOrGenerateStokListPDF(stoklar: listToExport)
            isGeneratingPDF = false
            pdfPreviewItem = PDFPreviewItem(
                title: "Stok Envanter Raporu",
                data: data,
                fileName: "Toplu_Stok_Raporu.pdf"
            )
        }
        #endif
    }
    
    private func exportExcel() {
        #if canImport(UIKit)
        let csv = "StokKodu,StokAdi,Grup,Birim,Miktar,AlisFiyati,SatisFiyati\n" +
            stoklar.map { "\($0.stokKodu ?? ""),\"\($0.stokAdi)\",\($0.grupAdi ?? ""),\($0.birim ?? ""),\(String(format: "%.2f", $0.mevcutMiktar)),\($0.alisFiyati),\($0.satisFiyati)" }.joined(separator: "\n")
        let av = UIActivityViewController(activityItems: [csv], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
        #endif
    }

    @ViewBuilder
    private func stokItemRow(item: StokKart, isSelected: Bool) -> some View {
        Button {
            handleSelectStok(item)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "0A84FF").opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "0A84FF"))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.stokAdi)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text("\(item.stokKodu ?? "KODSUZ") • \(item.grupAdi ?? "Genel")")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "8E8E93"))
                        
                        Text(String(format: "%.2f %@", item.mevcutMiktar, item.birim ?? "Adet"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(item.mevcutMiktar <= 0 ? Color(hex: "EF4444") : Color(hex: "30D158"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((item.mevcutMiktar <= 0 ? Color(hex: "EF4444") : Color(hex: "30D158")).opacity(0.12))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(AppFormatters.money(item.satisFiyati))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("Satış")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            }
            .padding(12)
            .background(isSelected ? Color(hex: "0A84FF").opacity(0.12) : Color.white.opacity(0.03))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color(hex: "0A84FF") : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}
