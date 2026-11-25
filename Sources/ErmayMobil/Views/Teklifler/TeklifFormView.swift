import SwiftUI

private struct TeklifStrictInsertPayload: Encodable {
    let id: Int
    let teklif_no: String
    let cari_id: Int?
    let cari_unvan: String?
    let tarih: String
    let gecerlilik_tarihi: String?
    let ara_toplam: Double
    let kdv_toplam: Double
    let genel_toplam: Double
    let durum: String
    let aciklama: String?
    let tenant_id: String
    let uuid: String
    let version: Int
}

private struct TeklifDetayStrictInsertPayload: Encodable {
    let id: Int
    let teklif_id: Int
    let stok_id: Int?
    let stok_adi: String?
    let miktar: Double
    let birim: String
    let birim_fiyat: Double
    let kdv_orani: Double
    let toplam_tutar: Double
    let tenant_id: String
    let uuid: String
    let version: Int
}

public struct TeklifFormView: View {
    @Environment(\.dismiss) private var dismiss
    public var onSave: ((Teklif) -> Void)?
    
    @State private var teklifNo: String = "TKF-\(Int.random(in: 100000...999999))"
    @State private var durum: String = "Bekliyor"
    @State private var odemeBilgisi: String = ""
    @State private var tarihStr: String = ""
    @State private var gecerlilikTarihiStr: String = ""
    @State private var aciklama: String = ""
    
    // Cari
    @State private var cariUnvan: String = ""
    @State private var cariId: String? = nil
    
    // Items
    @State private var kalemler: [TeklifKalem] = []
    
    // Pickers
    @State private var showCariPicker: Bool = false
    @State private var showStokPicker: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    
    private let birimler = ["Adet", "Kg", "Mt", "M2"]
    
    public init(onSave: ((Teklif) -> Void)? = nil) {
        self.onSave = onSave
    }
    
    public var araToplam: Double {
        kalemler.reduce(0.0) { $0 + ($1.miktar * $1.birimFiyat) }
    }
    
    public var kdvToplami: Double {
        kalemler.reduce(0.0) { $0 + ($1.miktar * $1.birimFiyat * ($1.kdvOrani / 100.0)) }
    }
    
    public var genelToplam: Double {
        araToplam + kdvToplami
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        
                        if let err = errorMessage {
                            errorBanner(err)
                        }
                        
                        cariCardSection
                        teklifNoAndDurumSection
                        datesSection
                        odemeSection
                        kalemlerSection
                        aciklamaSection
                        summarySection
                        saveButtonSection
                    }
                }
            }
            .navigationBarHidden(true)
            .scrollDismissesKeyboard(.interactively)
            .enableSwipeBack()
            .keyboardDismissToolbar(buttonTitle: "Bitti")
            .hideKeyboardOnTap()
            .onAppear {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                tarihStr = formatter.string(from: Date())
                let expiryDate = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
                gecerlilikTarihiStr = formatter.string(from: expiryDate)
            }
            .sheet(isPresented: $showCariPicker) {
                CariPickerSheet { c in
                    self.cariId = c.id
                    self.cariUnvan = c.unvan
                }
                .enableSwipeBack()
            }
            .sheet(isPresented: $showStokPicker) {
                StokPickerSheet { s in
                    let newKalem = TeklifKalem(
                        stokId: s.id,
                        stokAdi: s.stokAdi,
                        miktar: 1.0,
                        birim: s.birim,
                        birimFiyat: s.satisFiyati,
                        kdvOrani: s.kdvOrani
                    )
                    kalemler.append(newKalem)
                }
                .enableSwipeBack()
            }
        }
    }
    
    // MARK: - Modular Sections
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Text("Yeni Teklif Oluştur")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(8)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    @ViewBuilder
    private func errorBanner(_ err: String) -> some View {
        Text(err)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.red.opacity(0.15))
            .cornerRadius(8)
            .padding(.horizontal)
    }
    
    @ViewBuilder
    private var cariCardSection: some View {
        Button {
            showCariPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "0061FF"))
                Text(cariUnvan.isEmpty ? "Cari Kart Seçin *" : cariUnvan)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "64748B"))
            }
            .padding(14)
            .background(Color(hex: "121216"))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var teklifNoAndDurumSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TEKLİF NO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "94A3B8"))
                TextField("Teklif No", text: $teklifNo)
                    .padding(12)
                    .background(Color(hex: "121216"))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("DURUM")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "94A3B8"))
                HStack(spacing: 4) {
                    ForEach(["Bekliyor", "Reddedildi"], id: \.self) { st in
                        Button {
                            durum = st
                        } label: {
                            Text(st)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(durum == st ? .white : Color(hex: "94A3B8"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(durum == st ? Color(hex: "0061FF") : Color.white.opacity(0.04))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var datesSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TEKLİF TARİHİ")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "94A3B8"))
                TextField("YYYY-MM-DD", text: $tarihStr)
                    .padding(12)
                    .background(Color(hex: "121216"))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("GEÇERLİLİK TARİHİ")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "94A3B8"))
                TextField("YYYY-MM-DD", text: $gecerlilikTarihiStr)
                    .padding(12)
                    .background(Color(hex: "121216"))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var odemeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ÖDEME BİLGİSİ")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "94A3B8"))
            TextField("örn. 30 Gün Vade veya Peşin Ödeme...", text: $odemeBilgisi)
                .padding(12)
                .background(Color(hex: "121216"))
                .cornerRadius(10)
                .foregroundColor(.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var kalemlerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Teklif Kalemleri")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    showStokPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Kalem Ekle")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "00FF87"))
                }
            }
            
            if kalemler.isEmpty {
                Text("Henüz kalem eklenmedi.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "64748B"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(hex: "141414"))
                    .cornerRadius(12)
            } else {
                ForEach(kalemler.indices, id: \.self) { index in
                    teklifKalemCard(index: index)
                }
            }
        }
        .padding(14)
        .background(Color(hex: "161616"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func teklifKalemCard(index: Int) -> some View {
        let item = kalemler[index]
        VStack(alignment: .leading, spacing: 10) {
            teklifKalemTopBar(index: index, item: item)
            teklifKalemInputsRow(index: index, item: item)
            teklifKalemNoteRow(index: index)
            teklifKalemTotalRow(item: item)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    @ViewBuilder
    private func teklifKalemTopBar(index: Int, item: TeklifKalem) -> some View {
        HStack {
            Text(item.stokAdi)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
            Spacer()
            Button {
                kalemler.remove(at: index)
                HardwareService.shared.hapticWarning()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "EF4444"))
                    .padding(4)
            }
        }
        .padding(.bottom, 4)
        .overlay(Divider().background(Color.white.opacity(0.06)), alignment: .bottom)
    }
    
    @ViewBuilder
    private func teklifKalemInputsRow(index: Int, item: TeklifKalem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MİKTAR")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "94A3B8"))
                HStack(spacing: 2) {
                    TextField("Miktar", value: Binding(
                        get: { kalemler[index].miktar },
                        set: { kalemler[index].miktar = $0 }
                    ), formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 7)
                    .foregroundColor(.white)
                    
                    Menu {
                        ForEach(birimler, id: \.self) { b in
                            Button(b) { kalemler[index].birim = b }
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Text(item.birim ?? "Adet")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "94A3B8"))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(Color(hex: "94A3B8"))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                    }
                }
                .background(Color(hex: "2A2A2A"))
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("BİRİM FİYATI")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "94A3B8"))
                TextField("Fiyat", value: Binding(
                    get: { kalemler[index].birimFiyat },
                    set: { kalemler[index].birimFiyat = $0 }
                ), formatter: NumberFormatter())
                .keyboardType(.decimalPad)
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(Color(hex: "2A2A2A"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("KDV")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "94A3B8"))
                Menu {
                    ForEach([0.0, 1.0, 10.0, 20.0], id: \.self) { rate in
                        Button("%\(Int(rate))") { kalemler[index].kdvOrani = rate }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text("%\(Int(item.kdvOrani))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                }
            }
            .frame(width: 60)
        }
    }
    
    @ViewBuilder
    private func teklifKalemNoteRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("KALEM AÇIKLAMASI (OPSİYONEL)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "94A3B8"))
            TextField("Kalem hakkında not...", text: Binding(
                get: { kalemler[index].aciklama ?? "" },
                set: { kalemler[index].aciklama = $0 }
            ))
            .font(.system(size: 11))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(hex: "2A2A2A"))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private func teklifKalemTotalRow(item: TeklifKalem) -> some View {
        HStack {
            Spacer()
            let rowTotal = item.miktar * item.birimFiyat
            Text("Satır Tutarı: \(AppFormatters.money(rowTotal))")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "00FF87"))
        }
    }


    @ViewBuilder
    private var aciklamaSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AÇIKLAMA")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "94A3B8"))
            TextField("Teklif hakkında not...", text: $aciklama, axis: .vertical)
                .lineLimit(3...5)
                .padding(12)
                .background(Color(hex: "121216"))
                .cornerRadius(10)
                .foregroundColor(.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var summarySection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Ara Toplam:")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "94A3B8"))
                Spacer()
                Text(AppFormatters.money(araToplam))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            HStack {
                Text("KDV Toplamı:")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "94A3B8"))
                Spacer()
                Text(AppFormatters.money(kdvToplami))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            Divider().background(Color.white.opacity(0.1))
            HStack {
                Text("Genel Toplam:")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(AppFormatters.money(genelToplam))
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Color(hex: "00FF87"))
            }
        }
        .padding(16)
        .background(Color(hex: "121216"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var saveButtonSection: some View {
        Button {
            handleSave()
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Teklifi Kaydet")
                }
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(hex: "0061FF"))
            .cornerRadius(12)
        }
        .disabled(isSaving)
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
    
    private func handleSave() {
        if cariUnvan.isEmpty {
            errorMessage = "Lütfen bir cari kart seçiniz."
            return
        }
        if kalemler.isEmpty {
            errorMessage = "Lütfen en az bir kalem ekleyiniz."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        let teklifUuid = UUID().uuidString.lowercased()
        let tenantId = SupabaseService.shared.tenantId
        let cIdInt = cariId != nil ? Int(cariId!) : nil
        let activeYearInt = Int(SupabaseService.shared.activeFiscalYear) ?? Calendar.current.component(.year, from: Date())

        let newTeklif = Teklif(
            id: teklifUuid,
            teklifNo: teklifNo,
            cariId: cariId ?? "",
            cariUnvan: cariUnvan,
            tarih: tarihStr,
            gecerlilikTarihi: gecerlilikTarihiStr,
            araToplam: araToplam,
            kdvToplami: kdvToplami,
            genelToplam: genelToplam,
            durum: durum,
            aciklama: aciklama,
            kalemler: kalemler,
            syncGuid: teklifUuid,
            tenantId: tenantId
        )

        var rpcPayload: [String: Any] = [
            "uuid": teklifUuid,
            "tenant_id": tenantId,
            "teklif_no": teklifNo,
            "cari_unvan": cariUnvan,
            "tarih": tarihStr,
            "gecerlilik_tarihi": gecerlilikTarihiStr,
            "ara_toplam": araToplam,
            "kdv_toplam": kdvToplami,
            "genel_toplam": genelToplam,
            "durum": durum,
            "aciklama": aciklama,
            "mali_yil": activeYearInt,
            "detaylar": kalemler.map { it -> [String: Any] in
                var d: [String: Any] = [
                    "uuid": UUID().uuidString.lowercased(),
                    "stok_adi": it.stokAdi,
                    "miktar": it.miktar,
                    "birim": it.birim ?? "Adet",
                    "birim_fiyat": it.birimFiyat,
                    "kdv_orani": it.kdvOrani,
                    "toplam_tutar": it.tutar
                ]
                if let intStok = it.stokId.flatMap({ Int($0) }) { d["stok_id"] = intStok }
                return d
            }
        ]
        if let cid = cIdInt { rpcPayload["cari_id"] = cid }

        Task {
            do {
                let res = try await SupabaseService.shared.rpcRaw(
                    function: "save_teklif_atomic",
                    params: ["p_payload": rpcPayload]
                )
                if let ok = res["success"] as? Bool, !ok {
                    throw NSError(domain: "TeklifForm", code: 500, userInfo: [NSLocalizedDescriptionKey: (res["message"] as? String) ?? "Teklif kaydedilemedi."])
                }
                var savedTeklif = newTeklif
                if let tid = res["teklif_id"] { savedTeklif.id = String(describing: tid) }

                await MainActor.run {
                    HardwareService.shared.hapticSuccess()
                    onSave?(savedTeklif)
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Teklif kaydedilemedi: " + error.localizedDescription
                    self.isSaving = false
                }
            }
        }
    }
}