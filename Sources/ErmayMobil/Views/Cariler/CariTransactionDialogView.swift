import SwiftUI

public struct CariTransactionDialogView: View {
    @Environment(\.dismiss) private var dismiss
    public let initialCari: CariKart
    public let transactionType: String // "Tahsilat" | "Ödeme" | "Alacak Dekontu" | "Borç Dekontu"
    public var onSave: ((CariHareket, CariKart) -> Void)?
    
    // Form States
    @State private var method: String = "Nakit"
    @State private var amountStr: String = ""
    @State private var transactionDate: Date = Date()
    @State private var selectedKasaBanka: String = "Merkez TL Kasası"
    @State private var dekontOnayNo: String = ""
    @State private var yonlendirilenTedarikci: String = ""
    @State private var isAcilisFisi: Bool = false
    @State private var aciklama: String = ""
    
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    
    private var isDekont: Bool {
        transactionType.localizedCaseInsensitiveContains("dekont") ||
        transactionType.localizedCaseInsensitiveContains("alacak") ||
        transactionType.localizedCaseInsensitiveContains("borç") ||
        transactionType.localizedCaseInsensitiveContains("borc")
    }
    
    private let availableKasalar = [
        "Merkez TL Kasası (₺42.500,00)",
        "Şube Kasası (₺18.250,00)",
        "Döviz Kasası ($5.400,00)"
    ]
    
    private let availableBankalar = [
        "Garanti BBVA Ticari (₺145.000,00)",
        "İş Bankası Şirket (₺98.500,00)",
        "Akbank Ticari POS (₺62.400,00)",
        "Yapı Kredi Ana Hesap (₺85.200,00)"
    ]
    
    public init(
        initialCari: CariKart,
        transactionType: String = "Tahsilat",
        onSave: ((CariHareket, CariKart) -> Void)? = nil
    ) {
        self.initialCari = initialCari
        self.transactionType = transactionType
        self.onSave = onSave
        
        let dekont = transactionType.localizedCaseInsensitiveContains("dekont") ||
                     transactionType.localizedCaseInsensitiveContains("alacak") ||
                     transactionType.localizedCaseInsensitiveContains("borç") ||
                     transactionType.localizedCaseInsensitiveContains("borc")
        _method = State(initialValue: dekont ? "Dekont" : "Nakit")
        _selectedKasaBanka = State(initialValue: dekont ? "Merkez TL Kasası" : "Merkez TL Kasası")
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "080A0C").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    renderHeader()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            if let err = errorMessage {
                                renderErrorBanner(err)
                            }
                            
                            renderCariInfoCard()
                            
                            // Method Selection (Masaüstü Birebir: Nakit, Havale/EFT, Kredi Kartı, Çek, Dekont)
                            if !isDekont {
                                renderMethodSelector()
                            }
                            
                            // Amount & Date
                            renderAmountAndDateCard()
                            
                            // Account Selection (Kasa / Banka)
                            renderAccountSelectionCard()
                            
                            // Reference No (Dekont No / Onay Kodu)
                            if method == "Havale / EFT" || method == "Kredi Kartı" {
                                renderReferenceNoCard()
                            }
                            
                            // Forwarded Supplier (Opsiyonel Yönlendirilen Tedarikçi)
                            renderSupplierCard()
                            
                            // Açıklama & Açılış Fişi
                            renderDescriptionCard()
                            
                            Spacer().frame(height: 30)
                        }
                        .padding(16)
                    }
                    
                    renderFooter()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header
    @ViewBuilder
    private func renderHeader() -> some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(typeAccentColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: typeIconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(typeAccentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(transactionType) İşlemi")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(initialCari.unvan)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "121216"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.08)), alignment: .bottom)
    }
    
    // MARK: - Cari Info Card
    @ViewBuilder
    private func renderCariInfoCard() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Seçili Cari")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "8E8E93"))
                Text(initialCari.unvan)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("Kod: \(initialCari.cariKodu ?? "-") • Bakiye: \(AppFormatters.money(initialCari.bakiye)) \(initialCari.bakiyeTuru == "A" ? "(Alacaklı)" : "(Borçlu)")")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "60A5FA"))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    // MARK: - Method Selector
    @ViewBuilder
    private func renderMethodSelector() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("İŞLEM YÖNTEMİ")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "8E8E93"))
            
            let methods = ["Nakit", "Havale / EFT", "Kredi Kartı", "Çek", "Dekont"]
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(methods, id: \.self) { m in
                    Button {
                        method = m
                        if m == "Nakit" {
                            selectedKasaBanka = availableKasalar.first ?? "Merkez TL Kasası"
                        } else if m == "Havale / EFT" || m == "Kredi Kartı" {
                            selectedKasaBanka = availableBankalar.first ?? "Garanti BBVA Ticari"
                        }
                    } label: {
                        Text(m)
                            .font(.system(size: 12, weight: method == m ? .bold : .medium))
                            .foregroundColor(method == m ? .white : Color(hex: "94A3B8"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(method == m ? Color(hex: "2563EB") : Color.white.opacity(0.04))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(method == m ? Color.white.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1))
                    }
                }
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(14)
    }
    
    // MARK: - Amount & Date
    @ViewBuilder
    private func renderAmountAndDateCard() -> some View {
        VStack(spacing: 12) {
            // Tutar
            VStack(alignment: .leading, spacing: 6) {
                Text("İşlem Tutarı (₺) *")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "8E8E93"))
                
                HStack {
                    Text("₺")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(typeAccentColor)
                    
                    TextField("0,00", text: $amountStr)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(typeAccentColor.opacity(0.4), lineWidth: 1))
            }
            
            // Tarih
            VStack(alignment: .leading, spacing: 6) {
                Text("İşlem Tarihi")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "8E8E93"))
                
                DatePicker("", selection: $transactionDate, displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(14)
    }
    
    // MARK: - Account Selection (Kasa / Banka)
    @ViewBuilder
    private func renderAccountSelectionCard() -> some View {
        let isBank = method == "Havale / EFT" || method == "Kredi Kartı"
        let isCash = method == "Nakit"
        
        if isCash || isBank {
            VStack(alignment: .leading, spacing: 8) {
                Text(isBank ? "BANKA HESABI / POS" : "KASA HESABI")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "8E8E93"))
                
                let list = isBank ? availableBankalar : availableKasalar
                ForEach(list, id: \.self) { item in
                    Button {
                        selectedKasaBanka = item
                    } label: {
                        HStack {
                            Image(systemName: isBank ? "building.columns.fill" : "banknote.fill")
                                .foregroundColor(selectedKasaBanka == item ? Color(hex: "60A5FA") : Color(hex: "64748B"))
                            Text(item)
                                .font(.system(size: 12, weight: selectedKasaBanka == item ? .bold : .regular))
                                .foregroundColor(selectedKasaBanka == item ? .white : Color(hex: "94A3B8"))
                            Spacer()
                            if selectedKasaBanka == item {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "10B981"))
                            }
                        }
                        .padding(10)
                        .background(selectedKasaBanka == item ? Color.white.opacity(0.07) : Color.white.opacity(0.02))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(14)
            .background(Color(hex: "121216"))
            .cornerRadius(14)
        }
    }
    
    // MARK: - Reference No Card
    @ViewBuilder
    private func renderReferenceNoCard() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(method == "Kredi Kartı" ? "Onay Kodu / POS Slip No" : "Banka Dekont / Evrak No")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "8E8E93"))
            
            TextField(method == "Kredi Kartı" ? "örn. ONY-84920" : "örn. DKT-2026-0045", text: $dekontOnayNo)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(14)
    }
    
    // MARK: - Supplier Card
    @ViewBuilder
    private func renderSupplierCard() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Yönlendirilen Tedarikçi (Opsiyonel)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "8E8E93"))
            
            TextField("Tedarikçi adı veya firma...", text: $yonlendirilenTedarikci)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(14)
    }
    
    // MARK: - Description Card
    @ViewBuilder
    private func renderDescriptionCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AÇIKLAMA")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "8E8E93"))
                Spacer()
                Toggle("Açılış Fişi (Devir)", isOn: $isAcilisFisi)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "60A5FA"))
                    .labelsHidden()
                Text("Açılış Fişi (Devir)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "60A5FA"))
            }
            
            TextField("İşlem hakkında detaylı açıklama giriniz...", text: $aciklama)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(14)
    }
    
    // MARK: - Footer
    @ViewBuilder
    private func renderFooter() -> some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Text("Vazgeç")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
            }
            
            Button {
                handleSave()
            } label: {
                HStack(spacing: 6) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("İşlemi Kaydet")
                    }
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(typeAccentColor)
                .cornerRadius(12)
            }
            .disabled(isSaving)
        }
        .padding(16)
        .background(Color(hex: "121216"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.08)), alignment: .top)
    }
    
    @ViewBuilder
    private func renderErrorBanner(_ msg: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(msg)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red)
            Spacer()
        }
        .padding(10)
        .background(Color.red.opacity(0.12))
        .cornerRadius(8)
    }
    
    private var typeAccentColor: Color {
        if transactionType.localizedCaseInsensitiveContains("tahsilat") {
            return Color(hex: "10B981")
        } else if transactionType.localizedCaseInsensitiveContains("ödeme") || transactionType.localizedCaseInsensitiveContains("odeme") {
            return Color(hex: "EF4444")
        } else if transactionType.localizedCaseInsensitiveContains("alacak") {
            return Color(hex: "8B5CF6")
        } else {
            return Color(hex: "EC4899")
        }
    }
    
    private var typeIconName: String {
        if transactionType.localizedCaseInsensitiveContains("tahsilat") {
            return "arrow.down.left"
        } else if transactionType.localizedCaseInsensitiveContains("ödeme") || transactionType.localizedCaseInsensitiveContains("odeme") {
            return "arrow.up.right"
        } else if transactionType.localizedCaseInsensitiveContains("alacak") {
            return "plus.circle.fill"
        } else {
            return "minus.circle.fill"
        }
    }
    
    private func handleSave() {
        let clean = amountStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(clean), amount > 0 else {
            errorMessage = "Lütfen 0'dan büyük geçerli bir tutar giriniz."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        let dateStr = AppFormatters.isoDate.string(from: transactionDate)
        let isTahsilat = transactionType.localizedCaseInsensitiveContains("tahsilat")
        let isOdeme = transactionType.localizedCaseInsensitiveContains("ödeme") || transactionType.localizedCaseInsensitiveContains("odeme")
        let isAlacak = transactionType.localizedCaseInsensitiveContains("alacak")
        
        // Alacak hareketi carinin alacağını artırır; borç hareketi borcunu artırır
        let borcTutar: Double = (isOdeme || !isAlacak && !isTahsilat) ? amount : 0.0
        let alacakTutar: Double = (isTahsilat || isAlacak) ? amount : 0.0
        
        var prefix = "DKT"
        if isTahsilat { prefix = "THS" }
        else if isOdeme { prefix = "TED" }
        
        let docNo = dekontOnayNo.isEmpty ? "\(prefix)-\(Int.random(in: 1000...9999))" : dekontOnayNo
        let desc = aciklama.isEmpty ? "\(transactionType) (\(method)) - \(selectedKasaBanka)" : "\(aciklama) (\(method))"
        
        let hareket = CariHareket(
            id: UUID().uuidString,
            cariId: initialCari.id,
            tarih: dateStr,
            belgeNo: docNo,
            islemTuru: isAcilisFisi ? "Açılış Fişi (\(transactionType))" : "\(transactionType) (\(method))",
            aciklama: desc,
            borc: borcTutar,
            alacak: alacakTutar,
            bakiye: 0.0
        )
        
        // Cari bakiyesini güncelle
        var updated = initialCari
        let oldNet = initialCari.bakiyeTuru == "B" ? -initialCari.bakiye : initialCari.bakiye
        // Borç artışı alacağı azaltır; Alacak artışı net bakiyeyi artırır
        let newNet = oldNet + (alacakTutar - borcTutar)
        updated.bakiye = abs(newNet)
        updated.bakiyeTuru = newNet >= 0 ? "A" : "B"
        
        Task {
            do {
                // 1. Cari Hareketi Supabase'e ekle
                var hareketPayload: [String: Any] = [
                    "uuid": UUID().uuidString,
                    "tenant_id": SupabaseService.shared.tenantId,
                    "cari_unvan": initialCari.unvan,
                    "evrak_no": docNo,
                    "islem_turu": isTahsilat ? "Tahsilat" : (isOdeme ? "Ödeme" : "Dekont"),
                    "hareket_turu": isTahsilat ? "Tahsilat" : (isOdeme ? "Ödeme" : "Dekont"),
                    "odeme_sekli": method,
                    "aciklama": desc,
                    "borc": borcTutar,
                    "alacak": alacakTutar,
                    "bakiye": updated.bakiye,
                    "tarih": dateStr,
                    "is_deleted": false
                ]
                if let intCariId = Int(initialCari.id) {
                    hareketPayload["cari_id"] = intCariId
                }
                if let cUuid = initialCari.syncGuid, !cUuid.isEmpty {
                    hareketPayload["cari_uuid"] = cUuid
                }
                let hData = try JSONSerialization.data(withJSONObject: hareketPayload)
                try await SupabaseService.shared.insertRaw(into: "cari_hareketler", data: hData)
                
                // 2. Carinin yeni bakiyesini Supabase'de güncelle
                if let intCariId = Int(initialCari.id) {
                    let bakiyePayload: [String: Any] = [
                        "bakiye": updated.bakiye,
                        "bakiye_turu": updated.bakiyeTuru ?? "A"
                    ]
                    let bData = try JSONSerialization.data(withJSONObject: bakiyePayload)
                    try? await SupabaseService.shared.updateRaw(table: "cariler", id: "\(intCariId)", data: bData)
                }
                
                // 3. Kasa veya Banka hareketini kaydet
                if method.localizedCaseInsensitiveContains("banka") || method.localizedCaseInsensitiveContains("havale") || method.localizedCaseInsensitiveContains("eft") {
                    let bankaPayload: [String: Any] = [
                        "uuid": UUID().uuidString,
                        "tenant_id": SupabaseService.shared.tenantId,
                        "cari_unvan": initialCari.unvan,
                        "evrak_no": docNo,
                        "islem_turu": isTahsilat ? "Tahsilat" : "Ödeme",
                        "hareket_turu": isTahsilat ? "Tahsilat" : "Ödeme",
                        "giren": isTahsilat ? amount : 0.0,
                        "cikan": isOdeme ? amount : 0.0,
                        "yatan": isTahsilat ? amount : 0.0,
                        "ceken": isOdeme ? amount : 0.0,
                        "tutar": amount,
                        "aciklama": desc,
                        "tarih": dateStr,
                        "is_deleted": false
                    ]
                    if let intCariId = Int(initialCari.id) {
                        var bp = bankaPayload
                        bp["cari_id"] = intCariId
                        let bpData = try JSONSerialization.data(withJSONObject: bp)
                        try? await SupabaseService.shared.insertRaw(into: "banka_hareketler", data: bpData)
                    }
                } else {
                    var kasaPayload: [String: Any] = [
                        "uuid": UUID().uuidString,
                        "tenant_id": SupabaseService.shared.tenantId,
                        "cari_unvan": initialCari.unvan,
                        "evrak_no": docNo,
                        "islem_turu": isTahsilat ? "Tahsilat" : "Ödeme",
                        "hareket_turu": isTahsilat ? "Tahsilat" : "Ödeme",
                        "giren": isTahsilat ? amount : 0.0,
                        "cikan": isOdeme ? amount : 0.0,
                        "gelir": isTahsilat ? amount : 0.0,
                        "gider": isOdeme ? amount : 0.0,
                        "tutar": amount,
                        "aciklama": desc,
                        "tarih": dateStr,
                        "is_deleted": false
                    ]
                    if let intCariId = Int(initialCari.id) {
                        kasaPayload["cari_id"] = intCariId
                    }
                    let kpData = try JSONSerialization.data(withJSONObject: kasaPayload)
                    try? await SupabaseService.shared.insertRaw(into: "kasa_hareketler", data: kpData)
                }
                
                await MainActor.run {
                    HardwareService.shared.hapticSuccess()
                    onSave?(hareket, updated)
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    HardwareService.shared.hapticSuccess()
                    onSave?(hareket, updated)
                    isSaving = false
                    dismiss()
                }
            }
        }
    }
}

