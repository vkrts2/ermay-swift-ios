import SwiftUI

public struct TahsilatKasaItem: Identifiable, Decodable, Hashable {
    public let id: String
    public let name: String
    public let bakiye: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case kasaAdi = "kasa_adi"
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
        } else if let ha = try? c.decode(String.self, forKey: .hesapAdi), !ha.isEmpty {
            self.name = ha
        } else {
            self.name = "Kasa"
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

public struct TahsilatFormView: View {
    public let isTahsilat: Bool
    public var onSave: ((KasaHareket) -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    @State private var tutarStr: String = ""
    @State private var cariUnvan: String = ""
    @State private var cariId: String? = nil
    @State private var aciklama: String = ""
    @State private var hesapId: String = "1"
    @State private var tarih: Date = Date()
    @State private var showCariPicker: Bool = false
    @State private var isSaving: Bool = false
    @State private var kasalar: [TahsilatKasaItem] = []
    @State private var errorMessage: String? = nil
    
    public init(isTahsilat: Bool = true, initialCari: CariKart? = nil, onSave: ((KasaHareket) -> Void)? = nil) {
        self.isTahsilat = isTahsilat
        self.onSave = onSave
        if let cari = initialCari {
            _cariId = State(initialValue: cari.id)
            _cariUnvan = State(initialValue: cari.unvan)
        }
    }
    
    public init(initialCari: CariKart?, isTahsilat: Bool = true, onSave: ((KasaHareket) -> Void)? = nil) {
        self.init(isTahsilat: isTahsilat, initialCari: initialCari, onSave: onSave)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if let err = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(err)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(10)
                            .background(Color.red.opacity(0.18))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        
                        HStack {
                            Text(isTahsilat ? "Hızlı Tahsilat Ekle" : "Hızlı Ödeme Ekle")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        GlassCard(cornerRadius: 16, padding: 16) {
                            VStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("İşlem Tutarı (₺) *")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    TextField("0.00", text: $tutarStr)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 20, weight: .heavy))
                                        .foregroundColor(isTahsilat ? Color(hex: "10B981") : Color(hex: "EF4444"))
                                        .padding(12)
                                        .background(Color(hex: "121216"))
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                }
                                
                                Button {
                                    showCariPicker = true
                                } label: {
                                    HStack {
                                        Image(systemName: "person.crop.circle.fill")
                                            .foregroundColor(AppTheme.primary)
                                        Text(cariUnvan.isEmpty ? "Cari Seçiniz *" : cariUnvan)
                                            .font(.system(size: 13, weight: cariUnvan.isEmpty ? .regular : .bold))
                                            .foregroundColor(cariUnvan.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                    .padding(12)
                                    .background(Color(hex: "121216"))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                }
                                
                                // Kasa Hesabı Seçimi
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Kasa Hesabı *")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(kasalar) { k in
                                                Button {
                                                    hesapId = k.id
                                                } label: {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: "banknote.fill")
                                                            .font(.system(size: 12))
                                                        Text(k.name)
                                                            .font(.system(size: 12, weight: hesapId == k.id ? .bold : .regular))
                                                    }
                                                    .foregroundColor(hesapId == k.id ? .white : AppTheme.textMuted)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 8)
                                                    .background(hesapId == k.id ? AppTheme.primary : Color.white.opacity(0.05))
                                                    .cornerRadius(8)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("İşlem Tarihi")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    DatePicker("", selection: $tarih, displayedComponents: .date)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(6)
                                        .background(Color(hex: "121216"))
                                        .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Açıklama")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    TextField("İşlem açıklaması...", text: $aciklama)
                                        .font(.system(size: 13))
                                        .padding(12)
                                        .background(Color(hex: "121216"))
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Button {
                            handleSave()
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(isTahsilat ? "Tahsilatı Kaydet" : "Ödemeyi Kaydet")
                                }
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isTahsilat ? Color(hex: "10B981") : Color(hex: "EF4444"))
                            .cornerRadius(12)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await loadKasalar()
            }
            .sheet(isPresented: $showCariPicker) {
                CariPickerSheet { c in
                    self.cariId = c.id
                    self.cariUnvan = c.unvan
                }
            }
        }
    }
    
    private func handleSave() {
        let clean = tutarStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        guard let tutar = Double(clean) ?? Double(tutarStr.replacingOccurrences(of: ",", with: ".")), tutar > 0 else {
            errorMessage = "Lütfen 0'dan büyük geçerli bir tutar giriniz."
            return
        }
        isSaving = true
        errorMessage = nil
        let docNo = isTahsilat ? "MB-THS-\(Int.random(in: 1000...9999))" : "MB-TED-\(Int.random(in: 1000...9999))"
        let desc = aciklama.isEmpty ? (isTahsilat ? "Tahsilat İşlemi" : "Ödeme İşlemi") : aciklama
        let dateStr = AppFormatters.isoDate.string(from: tarih)
        
        let h = KasaHareket(
            id: UUID().uuidString,
            hesapId: hesapId,
            tarih: dateStr,
            islemTuru: isTahsilat ? "Tahsilat" : "Ödeme",
            cariId: cariId,
            cariUnvan: cariUnvan.isEmpty ? nil : cariUnvan,
            belgeNo: docNo,
            tutar: tutar,
            aciklama: desc
        )
        
        let kasaName = kasalar.first(where: { $0.id == hesapId })?.name ?? "Merkez Kasa"
        let selectedKasaObj = KasaBanka(id: hesapId, hesapAdi: kasaName, hesapTuru: "KASA")
        let targetCari = DataStore.shared.cariler.first(where: { $0.id == cariId }) ?? CariKart(id: cariId ?? "", unvan: cariUnvan.isEmpty ? "Peşin İşlem" : cariUnvan)
        
        let finReq = FinancialTransactionRequest(
            cari: targetCari,
            transactionType: isTahsilat ? "Tahsilat" : "Ödeme",
            method: "Nakit",
            amount: tutar,
            date: dateStr,
            description: desc,
            selectedHesap: selectedKasaObj,
            isAcilisFisi: false,
            documentNo: docNo
        )
        
        Task {
            do {
                _ = try await TransactionService.shared.saveFinancialTransaction(req: finReq)
                await MainActor.run {
                    HardwareService.shared.hapticSuccess()
                    onSave?(h)
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    NotificationCenter.default.post(
                        name: .userToastNotification,
                        object: nil,
                        userInfo: ["message": "İşlem kaydedilemedi: \(error.localizedDescription)"]
                    )
                    isSaving = false
                }
            }
        }
    }
    
    // MARK: - Load Real Kasalar
    private func loadKasalar() async {
        let fetched: [TahsilatKasaItem] = (try? await SupabaseService.shared.fetch(from: "kasalar", orderBy: "id.asc")) ?? []
        await MainActor.run {
            if !fetched.isEmpty {
                self.kasalar = fetched
                if self.hesapId == "1" || self.hesapId.isEmpty {
                    self.hesapId = fetched.first?.id ?? "1"
                }
            } else {
                let defaultKasa = TahsilatKasaItem(id: "1", name: "Merkez Kasa", bakiye: 0.0)
                self.kasalar = [defaultKasa]
                self.hesapId = defaultKasa.id
            }
        }
    }
}

