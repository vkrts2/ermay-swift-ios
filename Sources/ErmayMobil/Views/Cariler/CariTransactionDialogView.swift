import SwiftUI

public struct DialogAccountItem: Identifiable, Decodable, Hashable {
    public let id: String
    public let name: String
    public let bakiye: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case kasaAdi = "kasa_adi"
        case bankaAdi = "banka_adi"
        case hesapAdi = "hesap_adi"
        case bakiye
        case guncelBakiye = "guncel_bakiye"
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else if let strId = try? c.decode(String.self, forKey: .id) {
            self.id = strId
        } else {
            self.id = "1"
        }
        
        if let ka = try? c.decode(String.self, forKey: .kasaAdi), !ka.isEmpty {
            self.name = ka
        } else if let ba = try? c.decode(String.self, forKey: .bankaAdi), !ba.isEmpty {
            self.name = ba
        } else if let ha = try? c.decode(String.self, forKey: .hesapAdi), !ha.isEmpty {
            self.name = ha
        } else {
            self.name = "Hesap"
        }
        
        if let b = try? c.decode(Double.self, forKey: .bakiye) {
            self.bakiye = b
        } else if let gb = try? c.decode(Double.self, forKey: .guncelBakiye) {
            self.bakiye = gb
        } else {
            self.bakiye = 0.0
        }
    }
    
    public init(id: String, name: String, bakiye: Double) {
        self.id = id
        self.name = name
        self.bakiye = bakiye
    }
}

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
    
    @State private var kasalar: [DialogAccountItem] = []
    @State private var bankalar: [DialogAccountItem] = []
    @State private var selectedKasaId: String? = nil
    @State private var selectedBankaId: String? = nil
    @State private var isLoadingAccounts: Bool = false
    
    private var isDekont: Bool {
        transactionType.localizedCaseInsensitiveContains("dekont") ||
        transactionType.localizedCaseInsensitiveContains("alacak") ||
        transactionType.localizedCaseInsensitiveContains("borç") ||
        transactionType.localizedCaseInsensitiveContains("borc")
    }
    
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
            .task {
                await loadAccounts()
            }
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
                Text("Kod: \(initialCari.cariKodu ?? "-") • Bakiye: \(AppFormatters.money(abs(initialCari.signedBakiye))) \(initialCari.isAlacakli ? "(Alacaklı)" : "(Borçlu)")")
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
                            selectedKasaBanka = kasalar.first?.name ?? "Merkez TL Kasası"
                        } else if m == "Havale / EFT" || m == "Kredi Kartı" {
                            selectedKasaBanka = bankalar.first?.name ?? "Garanti BBVA Ticari"
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
                
                let list = isBank ? bankalar : kasalar
                ForEach(list) { acc in
                    let isSelected = isBank ? (selectedBankaId == acc.id) : (selectedKasaId == acc.id)
                    Button {
                        if isBank {
                            selectedBankaId = acc.id
                            selectedKasaBanka = "\(acc.name) (\(AppFormatters.money(acc.bakiye)))"
                        } else {
                            selectedKasaId = acc.id
                            selectedKasaBanka = "\(acc.name) (\(AppFormatters.money(acc.bakiye)))"
                        }
                    } label: {
                        HStack {
                            Image(systemName: isBank ? "building.columns.fill" : "banknote.fill")
                                .foregroundColor(isSelected ? Color(hex: "60A5FA") : Color(hex: "64748B"))
                            Text("\(acc.name) (\(AppFormatters.money(acc.bakiye)))")
                                .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? .white : Color(hex: "94A3B8"))
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "10B981"))
                            }
                        }
                        .padding(10)
                        .background(isSelected ? Color.white.opacity(0.07) : Color.white.opacity(0.02))
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
        
        var prefix = "MB-DKT"
        if method.localizedCaseInsensitiveContains("kredi") { prefix = "MB-KK" }
        else if method.localizedCaseInsensitiveContains("eft") || method.localizedCaseInsensitiveContains("havale") { prefix = "MB-EFT" }
        else if method.localizedCaseInsensitiveContains("çek") || method.localizedCaseInsensitiveContains("cek") { prefix = "MB-CK" }
        else if isTahsilat { prefix = "MB-THS" }
        else if isOdeme { prefix = "MB-TED" }
        
        let rawInputDoc = dekontOnayNo.trimmingCharacters(in: .whitespacesAndNewlines)
        let docNo = rawInputDoc.isEmpty ? "\(prefix)-\(Int.random(in: 1000...9999))" : (rawInputDoc.hasPrefix("MB-") ? rawInputDoc : "MB-\(rawInputDoc)")
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
        
        let isBank = method == "Havale / EFT" || method == "Kredi Kartı"
        let isCash = method == "Nakit"
        let selectedAccountObj: KasaBanka?
        if isBank, let bId = selectedBankaId {
            let bName = bankalar.first(where: { $0.id == bId })?.name ?? selectedKasaBanka
            selectedAccountObj = KasaBanka(id: bId, hesapAdi: bName, hesapTuru: "BANKA")
        } else if isCash, let kId = selectedKasaId {
            let kName = kasalar.first(where: { $0.id == kId })?.name ?? selectedKasaBanka
            selectedAccountObj = KasaBanka(id: kId, hesapAdi: kName, hesapTuru: "KASA")
        } else {
            selectedAccountObj = nil
        }
        
        let finReq = FinancialTransactionRequest(
            cari: initialCari,
            transactionType: transactionType,
            method: method,
            amount: amount,
            date: dateStr,
            description: desc,
            selectedHesap: selectedAccountObj,
            isAcilisFisi: isAcilisFisi,
            documentNo: docNo,
            forwardedSupplierName: yonlendirilenTedarikci
        )
        
        Task {
            do {
                _ = try await TransactionService.shared.saveFinancialTransaction(req: finReq)
                let refreshedCari = await MainActor.run {
                    DataStore.shared.cariler.first(where: { $0.id == initialCari.id })
                }
                var updated = refreshedCari ?? initialCari
                if refreshedCari == nil {
                    let newNet = initialCari.signedBakiye + (borcTutar - alacakTutar)
                    updated.bakiye = newNet
                    updated.bakiyeTuru = newNet >= 0 ? "B" : "A"
                }
                await MainActor.run {
                    HardwareService.shared.hapticSuccess()
                    onSave?(hareket, updated)
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    NotificationCenter.default.post(
                        name: .userToastNotification,
                        object: nil,
                        userInfo: ["message": "Cari işlem kaydedilemedi: \(error.localizedDescription)"]
                    )
                    isSaving = false
                }
            }
        }
    }
    
    // MARK: - Load Real Accounts from Supabase
    private func loadAccounts() async {
        isLoadingAccounts = true
        let fetchedKasalar: [DialogAccountItem] = (try? await SupabaseService.shared.fetch(from: "kasalar", orderBy: "id.asc")) ?? []
        let fetchedBankalar: [DialogAccountItem] = (try? await SupabaseService.shared.fetch(from: "bankalar", orderBy: "id.asc")) ?? []
        await MainActor.run {
            if !fetchedKasalar.isEmpty {
                self.kasalar = fetchedKasalar
                if self.selectedKasaId == nil, let first = fetchedKasalar.first {
                    self.selectedKasaId = first.id
                    self.selectedKasaBanka = "\(first.name) (\(AppFormatters.money(first.bakiye)))"
                }
            } else {
                let defaultKasa = DialogAccountItem(id: "1", name: "Merkez TL Kasası", bakiye: 0.0)
                self.kasalar = [defaultKasa]
                if self.selectedKasaId == nil {
                    self.selectedKasaId = defaultKasa.id
                    self.selectedKasaBanka = "\(defaultKasa.name) (₺0,00)"
                }
            }
            
            if !fetchedBankalar.isEmpty {
                self.bankalar = fetchedBankalar
                if self.selectedBankaId == nil, let first = fetchedBankalar.first {
                    self.selectedBankaId = first.id
                }
            } else {
                let defaultBanka = DialogAccountItem(id: "1", name: "Garanti BBVA Ticari", bakiye: 0.0)
                self.bankalar = [defaultBanka]
                if self.selectedBankaId == nil {
                    self.selectedBankaId = defaultBanka.id
                }
            }
            self.isLoadingAccounts = false
        }
    }
}

