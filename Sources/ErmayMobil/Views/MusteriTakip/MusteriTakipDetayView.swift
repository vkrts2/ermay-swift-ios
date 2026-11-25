import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
import WebKit
#endif

public struct MusteriTakipDetayView: View {
    @Environment(\.presentationMode) var presentationMode
    public let klasor: MusteriTakipKlasor
    
    @State private var activeTab: String = "Gorusmeler" // "Gorusmeler" | "Fiyatlar" | "Gorseller" | "Notlar"
    @State private var klasorEtiket: String
    @State private var klasorRenk: String
    @State private var isEtiketModalOpen: Bool = false
    @State private var isPdfGenerating: Bool = false
    
    // Detay Listeleri
    @State private var gorusmeler: [MusteriTakipDetay] = []
    @State private var fiyatlar: [MusteriTakipDetay] = []
    @State private var gorseller: [MusteriTakipDetay] = []
    @State private var notlar: [MusteriTakipDetay] = []
    @State private var isLoading: Bool = false
    
    // Görüşme Formu State
    @State private var gorusmeBaslik: String = ""
    @State private var gorusmeIcerik: String = ""
    @State private var gorusmeTarih: Date = Date()
    
    // Fiyat Formu State
    @State private var fiyatBaslik: String = ""
    @State private var fiyatTutar: String = ""
    @State private var fiyatParaBirimi: String = "₺"
    @State private var fiyatAciklama: String = ""
    @State private var fiyatTarih: Date = Date()
    
    // Görsel & Evrak Formu State
    @State private var gorselBaslik: String = ""
    @State private var gorselTarih: Date = Date()
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var previewImage: UIImage? = nil
    @State private var showFullScreenImage: Bool = false
    
    // Not Formu State
    @State private var notBaslik: String = ""
    @State private var notIcerik: String = ""
    @State private var notTarih: Date = Date()
    
    private let etiketSecenekleri = ["Sıcak Müşteri", "Teklif Aşamasında", "Önemli", "Yeni İletişim", "Takipte"]
    private let renkSecenekleri = ["#0A84FF", "#30D158", "#BF5AF2", "#FF9F0A", "#FF453A", "#64D2FF", "#FF375F"]
    private let paraBirimleri = ["₺", "$", "€"]
    
    public init(klasor: MusteriTakipKlasor) {
        self.klasor = klasor
        _klasorEtiket = State(initialValue: klasor.etiket ?? "Yeni İletişim")
        _klasorRenk = State(initialValue: klasor.renk ?? "#0A84FF")
    }
    
    private func touchKlasorSonIslemTarihi() {
        let nowIso = ISO8601DateFormatter().string(from: Date())
        Task {
            let payload: [String: Any] = ["son_islem_tarihi": nowIso]
            if let data = try? JSONSerialization.data(withJSONObject: payload) {
                _ = try? await SupabaseService.shared.updateRaw(table: "musteri_takip_klasorler", id: String(klasor.id), data: data)
            }
        }
    }
    
    private func formatDisplayDate(_ str: String, includeTime: Bool = false) -> String {
        let clean = str.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.contains("-") {
            let parts = clean.replacingOccurrences(of: "T", with: " ").split(separator: " ")
            if let dPart = parts.first {
                let ymd = dPart.split(separator: "-")
                if ymd.count == 3 {
                    let formattedDate = "\(ymd[2]).\(ymd[1]).\(ymd[0])"
                    if includeTime && parts.count > 1 {
                        let timeStr = String(parts[1].prefix(5))
                        return "\(formattedDate) \(timeStr)"
                    }
                    return formattedDate
                }
            }
        }
        return clean
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Header Bar
                HStack(spacing: 10) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                    }
                    
                    // Folder Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: klasorRenk).opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: klasorRenk))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(klasor.cariUnvan)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("\(klasor.yetkili ?? "-") | \(klasor.telefon ?? "-")")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // PDF / Rapor Butonu
                    Button {
                        generateAndShareCRMReport()
                    } label: {
                        HStack(spacing: 4) {
                            if isPdfGenerating {
                                ProgressView().scaleEffect(0.7).tint(Color(hex: "FF453A"))
                            } else {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "FF453A"))
                            }
                            Text("PDF")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "FF453A"))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(hex: "FF453A").opacity(0.12))
                        .cornerRadius(8)
                    }
                    
                    // Etiket / Renk Değiştir Butonu
                    Button {
                        isEtiketModalOpen = true
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color(hex: klasorRenk))
                                .frame(width: 8, height: 8)
                            Text(klasorEtiket)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: klasorRenk).opacity(0.4), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                
                // 2. 4 Modern Sekme Çubuğu (Görüşmeler | Fiyatlar | Evrak | Notlar)
                HStack(spacing: 8) {
                    tabItem(title: "Görüşmeler", icon: "message.fill", count: gorusmeler.count, key: "Gorusmeler", color: Color(hex: "0A84FF"))
                    tabItem(title: "Fiyatlar", icon: "tag.fill", count: fiyatlar.count, key: "Fiyatlar", color: Color(hex: "30D158"))
                    tabItem(title: "Evrak", icon: "photo.fill", count: gorseller.count, key: "Gorseller", color: Color(hex: "BF5AF2"))
                    tabItem(title: "Notlar", icon: "doc.text.fill", count: notlar.count, key: "Notlar", color: Color(hex: "FF9F0A"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // 3. Sekme İçerikleri
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        switch activeTab {
                        case "Gorusmeler":
                            renderGorusmelerTab()
                        case "Fiyatlar":
                            renderFiyatlarTab()
                        case "Gorseller":
                            renderGorsellerTab()
                        case "Notlar":
                            renderNotlarTab()
                        default:
                            EmptyView()
                        }
                        
                        // Müşteri CRM Raporu Oluştur Butonu
                        Button {
                            generateAndShareCRMReport()
                        } label: {
                            HStack(spacing: 8) {
                                if isPdfGenerating {
                                    ProgressView().tint(.white)
                                    Text("Rapor Hazırlanıyor...")
                                        .font(.system(size: 14, weight: .bold))
                                } else {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Müşteri CRM Raporu Oluştur ve Paylaş")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "2563EB"), Color(hex: "1D4ED8")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(14)
                        }
                        .padding(.top, 10)
                        
                        Spacer().frame(height: 50)
                    }
                    .padding(16)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isEtiketModalOpen) {
            etiketSheet()
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let img = previewImage {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showFullScreenImage = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .padding(16)
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
        }
        .task {
            await loadDetaylar()
        }
        .onReceive(NotificationCenter.default.publisher(for: .supabaseRealtimeDataChanged)) { _ in
            Task {
                await loadDetaylar()
            }
        }
    }
    
    private func tabItem(title: String, icon: String, count: Int, key: String, color: Color) -> some View {
        let isSel = activeTab == key
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { activeTab = key }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11))
                Text(title).font(.system(size: 11, weight: isSel ? .bold : .medium))
                Text("\(count)")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(isSel ? color : Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            .foregroundColor(isSel ? color : Color(hex: "8E8E93"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSel ? color.opacity(0.15) : Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSel ? color.opacity(0.4) : Color.clear, lineWidth: 1))
        }
    }
    
    // MARK: - Görüşmeler Sekmesi
    private func renderGorusmelerTab() -> some View {
        VStack(spacing: 12) {
            // Ekleme Kartı
            formCard {
                Text("Yeni Görüşme / Toplantı Ekle").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                inputField(label: "Görüşme Başlığı", text: $gorusmeBaslik, placeholder: "Örn: Sözleşme Şartları...")
                inputField(label: "Görüşme Detayı & Alınan Kararlar", text: $gorusmeIcerik, placeholder: "Konuşulan konular ve anlaşılan şartlar...")
                
                // DatePicker (Tarih Seçici)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Görüşme Tarihi").font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
                    DatePicker("", selection: $gorusmeTarih, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                }
                
                Button {
                    guard !gorusmeBaslik.isEmpty || !gorusmeIcerik.isEmpty else { return }
                    let isoTarih = ISO8601DateFormatter().string(from: gorusmeTarih)
                    let payload: [String: Any] = [
                        "uuid": UUID().uuidString.lowercased(),
                        "tenant_id": SupabaseService.shared.tenantId,
                        "klasor_id": klasor.id,
                        "cari_id": klasor.cariId,
                        "baslik": gorusmeBaslik.isEmpty ? "Müşteri Görüşmesi" : gorusmeBaslik,
                        "icerik": gorusmeIcerik,
                        "tip": "Gorusme",
                        "tarih": isoTarih,
                        "is_deleted": false
                    ]
                    Task {
                        if let data = try? JSONSerialization.data(withJSONObject: payload) {
                            try? await SupabaseService.shared.insertRaw(into: "musteri_takip_detaylar", data: data)
                        }
                        touchKlasorSonIslemTarihi()
                        await loadDetaylar()
                    }
                    gorusmeBaslik = ""
                    gorusmeIcerik = ""
                    gorusmeTarih = Date()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Görüşmeyi Ekle")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "0A84FF"))
                    .cornerRadius(10)
                }
            }
            
            // Liste
            ForEach(gorusmeler) { g in
                itemCard(title: g.baslik, subtitle: g.icerik ?? "", date: formatDisplayDate(g.tarih, includeTime: true), color: Color(hex: "0A84FF")) {
                    gorusmeler.removeAll { $0.id == g.id }
                    Task {
                        _ = try? await SupabaseService.shared.delete(table: "musteri_takip_detaylar", id: String(g.id))
                    }
                }
            }
        }
    }
    
    // MARK: - Fiyatlar Sekmesi
    private func renderFiyatlarTab() -> some View {
        VStack(spacing: 12) {
            formCard {
                Text("Özel Fiyat Teklifi Ekle").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                inputField(label: "Ürün / Hizmet Başlığı (İsteğe Bağlı)", text: $fiyatBaslik, placeholder: "Örn: Rulman 6204 veya Fiyat Teklifi")
                HStack(spacing: 8) {
                    inputField(label: "Fiyat Tutarı", text: $fiyatTutar, placeholder: "0,00")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Birim").font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
                        Picker("Birim", selection: $fiyatParaBirimi) {
                            ForEach(paraBirimleri, id: \.self) { p in Text(p).tag(p) }
                        }
                        .pickerStyle(.menu)
                        .padding(7)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                
                // DatePicker (Tarih Seçici)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Teklif Tarihi").font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
                    DatePicker("", selection: $fiyatTarih, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                }
                
                inputField(label: "Teklif Açıklaması", text: $fiyatAciklama, placeholder: "Örn: 50 adet ve üzeri")
                
                Button {
                    let cleanTutarStr = fiyatTutar.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
                    let parsedFiyat = Double(cleanTutarStr) ?? 0.0
                    guard !fiyatBaslik.isEmpty || parsedFiyat > 0 else { return }
                    
                    let isoTarih = ISO8601DateFormatter().string(from: fiyatTarih)
                    let safeBaslik = fiyatBaslik.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Fiyat Teklifi" : fiyatBaslik
                    let payload: [String: Any] = [
                        "uuid": UUID().uuidString.lowercased(),
                        "tenant_id": SupabaseService.shared.tenantId,
                        "klasor_id": klasor.id,
                        "cari_id": klasor.cariId,
                        "baslik": safeBaslik,
                        "icerik": fiyatAciklama,
                        "tip": "Fiyat",
                        "fiyat_bilgisi": parsedFiyat,
                        "para_birimi": fiyatParaBirimi,
                        "tarih": isoTarih,
                        "is_deleted": false
                    ]
                    Task {
                        if let data = try? JSONSerialization.data(withJSONObject: payload) {
                            try? await SupabaseService.shared.insertRaw(into: "musteri_takip_detaylar", data: data)
                        }
                        touchKlasorSonIslemTarihi()
                        await loadDetaylar()
                    }
                    fiyatBaslik = ""
                    fiyatTutar = ""
                    fiyatAciklama = ""
                    fiyatTarih = Date()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Fiyatı Ekle")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "30D158"))
                    .cornerRadius(10)
                }
            }
            
            ForEach(fiyatlar) { f in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(f.baslik).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                        Spacer()
                        Text("\(String(format: "%.2f", f.fiyatBilgisi ?? 0)) \(f.paraBirimi ?? "₺")")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(Color(hex: "30D158"))
                    }
                    if let icerik = f.icerik, !icerik.isEmpty {
                        Text(icerik).font(.system(size: 12)).foregroundColor(Color(hex: "E2E8F0"))
                    }
                    HStack {
                        Text(formatDisplayDate(f.tarih)).font(.system(size: 10)).foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                        Button {
                            fiyatlar.removeAll { $0.id == f.id }
                            Task {
                                _ = try? await SupabaseService.shared.delete(table: "musteri_takip_detaylar", id: String(f.id))
                            }
                        } label: {
                            Image(systemName: "trash").font(.system(size: 11)).foregroundColor(Color(hex: "EF4444"))
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
    
    // MARK: - Evrak & Görseller Sekmesi (PhotosPicker & Küçük Resim Galerisi)
    private func renderGorsellerTab() -> some View {
        VStack(spacing: 12) {
            formCard {
                Text("Evrak / Fotoğraf Ekle").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                inputField(label: "Evrak Başlığı", text: $gorselBaslik, placeholder: "Örn: Numune, Sözleşme, Kartvizit")
                
                // DatePicker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Evrak Tarihi").font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
                    DatePicker("", selection: $gorselTarih, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                }
                
                // PhotosPicker Butonu
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Galeriden Fotoğraf / Belge Seç")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color(hex: "BF5AF2"))
                    .cornerRadius(10)
                }
                .onChange(of: selectedPhotoItem) { newItem in
                    guard let item = newItem else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImg = UIImage(data: data) {
                            let compressed = uiImg.jpegData(compressionQuality: 0.6) ?? data
                            let base64 = compressed.base64EncodedString()
                            let isoTarih = ISO8601DateFormatter().string(from: gorselTarih)
                            let safeBaslik = gorselBaslik.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Belge / Görsel" : gorselBaslik
                            
                            let payload: [String: Any] = [
                                "uuid": UUID().uuidString.lowercased(),
                                "tenant_id": SupabaseService.shared.tenantId,
                                "klasor_id": klasor.id,
                                "cari_id": klasor.cariId,
                                "baslik": safeBaslik,
                                "icerik": "Fotoğraf / Evrak Eklendi",
                                "tip": "Gorsel",
                                "gorsel_base64": base64,
                                "tarih": isoTarih,
                                "is_deleted": false
                            ]
                            await MainActor.run {
                                gorselBaslik = ""
                                selectedPhotoItem = nil
                            }
                            Task {
                                if let data = try? JSONSerialization.data(withJSONObject: payload) {
                                    try? await SupabaseService.shared.insertRaw(into: "musteri_takip_detaylar", data: data)
                                }
                                touchKlasorSonIslemTarihi()
                                await loadDetaylar()
                            }
                        }
                    }
                }
            }
            
            // Görseller Galerisi
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(gorseller) { g in
                    VStack(alignment: .leading, spacing: 6) {
                        // Görsel Önizleme
                        ZStack(alignment: .topTrailing) {
                            if let b64 = g.gorselBase64,
                               let d = Data(base64Encoded: b64),
                               let uiImg = UIImage(data: d) {
                                Image(uiImage: uiImg)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 110)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        previewImage = uiImg
                                        showFullScreenImage = true
                                    }
                            } else {
                                ZStack {
                                    Color.white.opacity(0.05)
                                    Image(systemName: "doc.richtext.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color(hex: "BF5AF2"))
                                }
                                .frame(height: 110)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(10)
                            }
                            
                            // Sil Butonu
                            Button {
                                gorseller.removeAll { $0.id == g.id }
                                Task {
                                    _ = try? await SupabaseService.shared.delete(table: "musteri_takip_detaylar", id: String(g.id))
                                }
                            } label: {
                                Image(systemName: "trash.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "EF4444"))
                                    .background(Color.black.clipShape(Circle()))
                                    .padding(4)
                            }
                        }
                        
                        Text(g.baslik)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(formatDisplayDate(g.tarih))
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(10)
                    .background(Color(hex: "121216"))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
            }
        }
    }
    
    // MARK: - Notlar Sekmesi
    private func renderNotlarTab() -> some View {
        VStack(spacing: 12) {
            formCard {
                Text("Özel Not Ekle").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                inputField(label: "Not Başlığı", text: $notBaslik, placeholder: "Örn: Tahsilat Tercihi")
                inputField(label: "Not İçeriği", text: $notIcerik, placeholder: "Müşteriye dair kritik hatırlatmalar...")
                
                // DatePicker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Not Tarihi").font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
                    DatePicker("", selection: $notTarih, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                }
                
                Button {
                    guard !notBaslik.isEmpty || !notIcerik.isEmpty else { return }
                    let isoTarih = ISO8601DateFormatter().string(from: notTarih)
                    let payload: [String: Any] = [
                        "uuid": UUID().uuidString.lowercased(),
                        "tenant_id": SupabaseService.shared.tenantId,
                        "klasor_id": klasor.id,
                        "cari_id": klasor.cariId,
                        "baslik": notBaslik.isEmpty ? "Genel Not" : notBaslik,
                        "icerik": notIcerik,
                        "tip": "Not",
                        "tarih": isoTarih,
                        "is_deleted": false
                    ]
                    Task {
                        if let data = try? JSONSerialization.data(withJSONObject: payload) {
                            try? await SupabaseService.shared.insertRaw(into: "musteri_takip_detaylar", data: data)
                        }
                        touchKlasorSonIslemTarihi()
                        await loadDetaylar()
                    }
                    notBaslik = ""
                    notIcerik = ""
                    notTarih = Date()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Notu Ekle")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "FF9F0A"))
                    .cornerRadius(10)
                }
            }
            
            ForEach(notlar) { n in
                itemCard(title: n.baslik, subtitle: n.icerik ?? "", date: formatDisplayDate(n.tarih), color: Color(hex: "FF9F0A")) {
                    notlar.removeAll { $0.id == n.id }
                    Task {
                        _ = try? await SupabaseService.shared.delete(table: "musteri_takip_detaylar", id: String(n.id))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper UI Builders
    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .padding(14)
            .background(Color(hex: "121216"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private func inputField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
            TextField(placeholder, text: text)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
        }
    }
    
    private func itemCard(title: String, subtitle: String, date: String, color: Color, onDelete: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(color).frame(width: 8, height: 8).padding(.top, 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.system(size: 12)).foregroundColor(Color(hex: "E2E8F0"))
                }
                Text(date).font(.system(size: 10)).foregroundColor(Color(hex: "8E8E93"))
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash").font(.system(size: 11)).foregroundColor(Color(hex: "EF4444"))
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    // MARK: - Etiket & Renk Sheet (Buluta Gerçekten Kaydeder)
    private func etiketSheet() -> some View {
        VStack(spacing: 16) {
            Text("Klasör Etiketi ve Rengi").font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Etiket Seçiniz").font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
                Picker("Etiket", selection: $klasorEtiket) {
                    ForEach(etiketSecenekleri, id: \.self) { e in Text(e).tag(e) }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Renk Seçiniz").font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "8E8E93"))
                HStack(spacing: 12) {
                    ForEach(renkSecenekleri, id: \.self) { hex in
                        Button {
                            klasorRenk = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.white, lineWidth: klasorRenk == hex ? 2 : 0))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Button("Kaydet & Kapat") {
                isEtiketModalOpen = false
                let nowIso = ISO8601DateFormatter().string(from: Date())
                Task {
                    let payload: [String: Any] = [
                        "etiket": klasorEtiket,
                        "renk": klasorRenk,
                        "son_islem_tarihi": nowIso
                    ]
                    if let data = try? JSONSerialization.data(withJSONObject: payload) {
                        _ = try? await SupabaseService.shared.updateRaw(table: "musteri_takip_klasorler", id: String(klasor.id), data: data)
                    }
                }
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(Color(hex: "2563EB"))
            .cornerRadius(10)
            .padding(.top, 10)
            
            Spacer()
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Müşteri CRM Raporu Oluştur ve Paylaş
    private func generateAndShareCRMReport() {
        isPdfGenerating = true
        
        let reportHTML = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>Müşteri Takip Raporu - \(klasor.cariUnvan)</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; margin: 30px; color: #1E293B; }
            .header { border-bottom: 2px solid #2563EB; padding-bottom: 12px; margin-bottom: 20px; }
            .title { font-size: 22px; font-weight: bold; color: #1E3A8A; margin: 0; }
            .unvan { font-size: 16px; font-weight: bold; color: #0F172A; margin-top: 6px; }
            .meta { font-size: 12px; color: #475569; margin-top: 4px; }
            .right-meta { float: right; text-align: right; font-size: 12px; color: #64748B; }
            .badge { display: inline-block; background: #DBEAFE; color: #1E40AF; padding: 3px 8px; border-radius: 6px; font-weight: bold; font-size: 12px; }
            .section-title { font-size: 14px; font-weight: bold; color: #1E40AF; margin-top: 25px; margin-bottom: 8px; border-bottom: 1px solid #E2E8F0; padding-bottom: 4px; text-transform: uppercase; }
            table { width: 100%; border-collapse: collapse; margin-top: 6px; font-size: 12px; }
            th { background: #F1F5F9; border-bottom: 1px solid #CBD5E1; padding: 8px; text-align: left; font-weight: 600; color: #334155; }
            td { padding: 8px; border-bottom: 1px solid #F1F5F9; vertical-align: top; }
            .empty { color: #94A3B8; font-style: italic; padding: 8px 0; font-size: 12px; }
            .price-tag { color: #059669; font-weight: bold; }
            .footer { margin-top: 40px; border-top: 1px solid #E2E8F0; padding-top: 10px; text-align: center; font-size: 10px; color: #94A3B8; }
          </style>
        </head>
        <body>
          <div class="header">
            <div class="right-meta">
              <div>Rapor Tarihi: \(AppFormatters.shortDate.string(from: Date()))</div>
              <div style="margin-top: 4px;">Durum: <span class="badge">\(klasorEtiket)</span></div>
            </div>
            <div class="title">MÜŞTERİ TAKİP &amp; CRM RAPORU</div>
            <div class="unvan">Müşteri / Ünvan: \(klasor.cariUnvan)</div>
            <div class="meta">
              Yetkili: \(klasor.yetkili ?? "-") &nbsp;|&nbsp;
              Telefon: \(klasor.telefon ?? "-") &nbsp;|&nbsp;
              Cari Kod: \(klasor.cariKod ?? "-")
            </div>
          </div>

          <!-- 1. GÖRÜŞME NOTLARI -->
          <div class="section-title">1. Görüşme ve Toplantı Notları</div>
          \(gorusmeler.isEmpty ? "<div class='empty'>Kayıtlı görüşme bulunmamaktadır.</div>" : """
          <table>
            <thead>
              <tr><th style='width: 140px;'>Tarih</th><th style='width: 200px;'>Görüşme Konusu</th><th>Detay ve Anlaşmalar</th></tr>
            </thead>
            <tbody>
              \(gorusmeler.map { "<tr><td>\(formatDisplayDate($0.tarih, includeTime: true))</td><td><strong>\($0.baslik)</strong></td><td>\($0.icerik ?? "-")</td></tr>" }.joined())
            </tbody>
          </table>
          """)

          <!-- 2. VERİLEN FİYAT TEKLİFLERİ -->
          <div class="section-title">2. Verilen Fiyat Teklifleri</div>
          \(fiyatlar.isEmpty ? "<div class='empty'>Kayıtlı fiyat teklifi bulunmamaktadır.</div>" : """
          <table>
            <thead>
              <tr><th style='width: 140px;'>Tarih</th><th style='width: 200px;'>Teklif / Ürün</th><th style='width: 120px;'>Verilen Fiyat</th><th>Açıklama</th></tr>
            </thead>
            <tbody>
              \(fiyatlar.map { "<tr><td>\(formatDisplayDate($0.tarih))</td><td><strong>\($0.baslik)</strong></td><td class='price-tag'>\(String(format: "%.2f", $0.fiyatBilgisi ?? 0)) \($0.paraBirimi ?? "₺")</td><td>\($0.icerik ?? "-")</td></tr>" }.joined())
            </tbody>
          </table>
          """)

          <!-- 3. YÜKLENEN GÖRSELLER & EVRAKLAR -->
          <div class="section-title">3. Yüklenen Görseller ve Evraklar</div>
          \(gorseller.isEmpty ? "<div class='empty'>Kayıtlı evrak bulunmamaktadır.</div>" : """
          <ul>
            \(gorseller.map { "<li><strong>\($0.baslik)</strong> - \(formatDisplayDate($0.tarih)) (\($0.icerik ?? ""))</li>" }.joined())
          </ul>
          """)

          <!-- 4. ÖZEL NOTLAR -->
          <div class="section-title">4. Özel Notlar</div>
          \(notlar.isEmpty ? "<div class='empty'>Kayıtlı not bulunmamaktadır.</div>" : """
          <table>
            <thead>
              <tr><th style='width: 140px;'>Tarih</th><th style='width: 200px;'>Not Başlığı</th><th>Not İçeriği</th></tr>
            </thead>
            <tbody>
              \(notlar.map { "<tr><td>\(formatDisplayDate($0.tarih))</td><td><strong>\($0.baslik)</strong></td><td>\($0.icerik ?? "-")</td></tr>" }.joined())
            </tbody>
          </table>
          """)

          <div class="footer">
            Ermay Muhasebe &copy; \(SupabaseService.shared.activeFiscalYear) - Müşteri Takip Sistemi tarafından otomatik oluşturulmuştur.
          </div>
        </body>
        </html>
        """
        
        #if canImport(UIKit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let printFormatter = UIMarkupTextPrintFormatter(markupText: reportHTML)
            let renderer = UIPrintPageRenderer()
            renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
            
            // Standard A4 Size
            let a4Rect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
            renderer.setValue(NSValue(cgRect: a4Rect), forKey: "paperRect")
            renderer.setValue(NSValue(cgRect: a4Rect.insetBy(dx: 20, dy: 20)), forKey: "printableRect")
            
            let pdfData = NSMutableData()
            UIGraphicsBeginPDFContextToData(pdfData, a4Rect, nil)
            for i in 0..<renderer.numberOfPages {
                UIGraphicsBeginPDFPage()
                renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
            }
            UIGraphicsEndPDFContext()
            
            isPdfGenerating = false
            PDFService.shared.sharePDF(
                data: pdfData as Data,
                fileName: "Musteri_CRM_Raporu_\(klasor.cariUnvan).pdf"
            )
        }
        #else
        isPdfGenerating = false
        #endif
    }
    
    private func loadDetaylar() async {
        isLoading = true
        do {
            let items: [MusteriTakipDetay] = try await SupabaseService.shared.fetch(from: "musteri_takip_detaylar", filters: ["klasor_id": "eq.\(klasor.id)"])
            await MainActor.run {
                self.gorusmeler = items.filter { $0.tip == "Gorusme" }
                self.fiyatlar = items.filter { $0.tip == "Fiyat" }
                self.gorseller = items.filter { $0.tip == "Gorsel" }
                self.notlar = items.filter { $0.tip == "Not" }
            }
        } catch {
            print("MusteriTakipDetay fetch error: \(error)")
        }
        isLoading = false
    }
}
