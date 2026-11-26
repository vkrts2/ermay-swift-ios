import SwiftUI

public struct FaturaFormView: View {
    @Environment(\.dismiss) private var dismiss
    public var onSave: ((Fatura) -> Void)?
    
    // Fatura Başlık Bilgileri
    @State private var faturaNo: String = "MB-FTR-\(SupabaseService.shared.activeFiscalYear)-\(Int.random(in: 10000...99999))"
    @State private var tur: String = "Satış" // "Satış" | "Alış"
    @State private var durum: String = "Açık" // "Açık" | "Kapalı"
    @State private var odemeSekli: String = "Açık Hesap" // "Açık Hesap" | "Nakit" | "Kredi Kartı" | "Havale / EFT"
    @State private var tarih: Date = Date()
    @State private var vadeTarihi: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var aciklama: String = ""
    
    // Cari & Hesap Seçimleri
    @State private var selectedCari: CariKart? = nil
    @State private var showCariPicker: Bool = false
    @State private var kasaId: String = "1"
    @State private var bankaId: String = "1"
    @State private var kasalar: [DialogAccountItem] = []
    @State private var bankalar: [DialogAccountItem] = []
    
    // Kalemler
    @State private var items: [FaturaKalem] = []
    @State private var showStokPicker: Bool = false
    @State private var selectedItemIndexForBirim: Int? = nil
    
    // Form İşlem Durumu
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert: Bool = false
    
    private let birimListesi = ["Adet", "Kg", "Mt", "M2", "Paket", "Koli"]
    private let kdvOranlari: [Double] = [0.0, 1.0, 10.0, 20.0]
    
    public init(initialTur: String = "SATIS", initialCari: CariKart? = nil, onSave: ((Fatura) -> Void)? = nil) {
        let isAlis = initialTur.localizedCaseInsensitiveContains("alış") || initialTur.localizedCaseInsensitiveContains("alis")
        self._tur = State(initialValue: isAlis ? "Alış" : "Satış")
        self._selectedCari = State(initialValue: initialCari)
        self.onSave = onSave
    }
    
    public var araToplam: Double {
        items.reduce(0.0) { $0 + ($1.miktar * $1.birimFiyat) }
    }
    
    public var iskontoToplami: Double {
        items.reduce(0.0) { $0 + $1.iskontoTutari }
    }
    
    public var kdvToplami: Double {
        items.reduce(0.0) { sum, k in
            let matrah = (k.miktar * k.birimFiyat) - k.iskontoTutari
            return sum + (matrah * (k.kdvOrani / 100.0))
        }
    }
    
    public var genelToplam: Double {
        araToplam - iskontoToplami + kdvToplami
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // Fatura Türü Toggle (Satış Faturası / Alış Faturası)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FATURA TÜRÜ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "94A3B8"))
                            
                            HStack(spacing: 8) {
                                Button {
                                    tur = "Satış"
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.up.right.circle.fill")
                                        Text("Satış Faturası")
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(tur == "Satış" ? Color(hex: "10B981") : Color(hex: "1F2937"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                
                                Button {
                                    tur = "Alış"
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.down.left.circle.fill")
                                        Text("Alış Faturası")
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(tur == "Alış" ? Color(hex: "D97706") : Color(hex: "1F2937"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        
                        // Müşteri / Tedarikçi Seçici Kartı
                        Button {
                            showCariPicker = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "0061FF"))
                                
                                Text(selectedCari?.unvan ?? "Müşteri / Tedarikçi Seçin *")
                                    .font(.system(size: 14, weight: selectedCari == nil ? .medium : .bold))
                                    .foregroundColor(selectedCari == nil ? Color(hex: "94A3B8") : .white)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "64748B"))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(hex: "161616"))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        
                        // Fatura No & Ödeme Şekli Satırı
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("FATURA NUMARASI")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "94A3B8"))
                                
                                TextField("FTR-...", text: $faturaNo)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(10)
                                    .background(Color(hex: "1E1E1E"))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ÖDEME ŞEKLİ")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "94A3B8"))
                                
                                Menu {
                                    Button("Açık Hesap") { odemeSekli = "Açık Hesap"; durum = "Açık" }
                                    Button("Nakit") { odemeSekli = "Nakit"; durum = "Kapalı" }
                                    Button("Kredi Kartı") { odemeSekli = "Kredi Kartı"; durum = "Kapalı" }
                                    Button("Havale / EFT") { odemeSekli = "Havale / EFT"; durum = "Kapalı" }
                                } label: {
                                    HStack {
                                        Text(odemeSekli)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: "94A3B8"))
                                    }
                                    .padding(10)
                                    .background(Color(hex: "1E1E1E"))
                                    .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Kasa / Banka Hesap Seçici (Kapalı Fatura / Nakit / Kredi Kartı / Havale / EFT)
                        if odemeSekli != "Açık Hesap" {
                            let isBankPayment = odemeSekli == "Kredi Kartı" || odemeSekli == "Havale / EFT" || odemeSekli == "Banka"
                            let accounts = isBankPayment ? bankalar : kasalar
                            VStack(alignment: .leading, spacing: 6) {
                                Text(isBankPayment ? "BANKA / POS HESABI SEÇİN" : "KASA HESABI SEÇİN")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "94A3B8"))
                                
                                Menu {
                                    ForEach(accounts) { acc in
                                        Button("\(acc.name) (\(AppFormatters.money(acc.bakiye)))") {
                                            if isBankPayment {
                                                bankaId = acc.id
                                            } else {
                                                kasaId = acc.id
                                            }
                                        }
                                    }
                                } label: {
                                    let currentId = isBankPayment ? bankaId : kasaId
                                    let selectedAcc = accounts.first(where: { $0.id == currentId }) ?? accounts.first
                                    HStack {
                                        Image(systemName: isBankPayment ? "building.columns.fill" : "banknote.fill")
                                            .foregroundColor(Color(hex: "00FF87"))
                                        Text(selectedAcc != nil ? "\(selectedAcc!.name) (\(AppFormatters.money(selectedAcc!.bakiye)))" : "Hesap Seçiniz")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: "94A3B8"))
                                    }
                                    .padding(10)
                                    .background(Color(hex: "1E1E1E"))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Tarih & Vade Tarihi
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("FATURA TARİHİ")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "94A3B8"))
                                
                                DatePicker("", selection: $tarih, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("VADE TARİHİ")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "94A3B8"))
                                
                                DatePicker("", selection: $vadeTarihi, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Fatura Detay Kalemleri Bölümü
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Fatura Kalemleri (\(items.count))")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button {
                                    showStokPicker = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 13, weight: .bold))
                                        Text("Kalem Ekle")
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .foregroundColor(Color(hex: "00FF87"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "00FF87").opacity(0.12))
                                    .cornerRadius(8)
                                }
                            }
                            
                            if items.isEmpty {
                                Text("Henüz kalem eklenmedi.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "64748B"))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                                    .background(Color(hex: "141414"))
                                    .cornerRadius(12)
                            } else {
                                ForEach(items.indices, id: \.self) { index in
                                    faturaKalemCard(index: index)
                                }
                            }
                        }
                        
                        // Açıklama
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AÇIKLAMA")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "94A3B8"))
                            
                            TextField("Fatura hakkında not...", text: $aciklama, axis: .vertical)
                                .lineLimit(3...5)
                                .font(.system(size: 13))
                                .padding(10)
                                .background(Color(hex: "1E1E1E"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        // Toplam Bilgi Kartı
                        VStack(spacing: 8) {
                            HStack {
                                Text("Ara Toplam")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "94A3B8"))
                                Spacer()
                                Text(AppFormatters.money(araToplam))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            if iskontoToplami > 0 {
                                HStack {
                                    Text("İskonto Toplamı")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "94A3B8"))
                                    Spacer()
                                    Text("-\(AppFormatters.money(iskontoToplami))")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "EF4444"))
                                }
                            }
                            
                            HStack {
                                Text("KDV Toplamı")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "94A3B8"))
                                Spacer()
                                Text(AppFormatters.money(kdvToplami))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("GENEL TOPLAM")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(AppFormatters.money(genelToplam))
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(Color(hex: "10B981"))
                            }
                        }
                        .padding(14)
                        .background(Color(hex: "161616"))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        
                        // Kaydet Butonu
                        Button {
                            saveFatura()
                        } label: {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(isSaving ? "Kaydediliyor..." : "Faturayı Onayla & Kaydet")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isFormValid ? Color(hex: "00FF87") : Color.gray.opacity(0.4))
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || isSaving)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "EF4444"))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(tur == "Satış" ? "Satış Faturası Oluştur" : "Alış Faturası Oluştur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(Color(hex: "94A3B8"))
                }
            }
            .sheet(isPresented: $showCariPicker) {
                CariPickerSheet { cari in
                    self.selectedCari = cari
                    HardwareService.shared.hapticSuccess()
                }
            }
            .sheet(isPresented: $showStokPicker) {
                StokPickerSheet { stok in
                    let bf = tur == "Satış" ? stok.satisFiyati : stok.alisFiyati
                    let newItem = FaturaKalem(
                        stokId: stok.id,
                        stokUuid: stok.syncGuid,
                        stokKodu: stok.stokKodu,
                        stokAdi: stok.stokAdi,
                        birim: stok.birim ?? "Adet",
                        miktar: 1.0,
                        birimFiyat: bf,
                        kdvOrani: stok.kdvOrani,
                        iskontoOrani: 0.0,
                        aciklama: "",
                        syncGuid: stok.syncGuid ?? UUID().uuidString
                    )
                    items.append(newItem)
                    HardwareService.shared.hapticSuccess()
                }
            }
            .task {
                await loadAccounts()
            }
        }
    }
    
    private func loadAccounts() async {
        let fetchedKasalar: [DialogAccountItem] = (try? await SupabaseService.shared.fetch(from: "kasalar", orderBy: "id.asc")) ?? []
        let fetchedBankalar: [DialogAccountItem] = (try? await SupabaseService.shared.fetch(from: "bankalar", orderBy: "id.asc")) ?? []
        await MainActor.run {
            if !fetchedKasalar.isEmpty {
                self.kasalar = fetchedKasalar
                if let first = fetchedKasalar.first {
                    self.kasaId = first.id
                }
            } else {
                self.kasalar = [DialogAccountItem(id: "1", name: "Merkez TL Kasası", bakiye: 0.0)]
            }
            if !fetchedBankalar.isEmpty {
                self.bankalar = fetchedBankalar
                if let first = fetchedBankalar.first {
                    self.bankaId = first.id
                }
            } else {
                self.bankalar = [DialogAccountItem(id: "1", name: "Garanti BBVA Ticari", bakiye: 0.0)]
            }
        }
    }
    
    // MARK: - Kalem Kartı (Orijinal React Native 1:1 Paritesi)
    @ViewBuilder
    private func faturaKalemCard(index: Int) -> some View {
        let item = items[index]
        VStack(alignment: .leading, spacing: 10) {
            
            // Header: Stok Adı + Çöp Kutusu
            HStack {
                Text(item.stokAdi)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
                
                Button {
                    items.remove(at: index)
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
            
            // Body: Miktar + Birim, Birim Fiyatı, KDV
            HStack(alignment: .top, spacing: 10) {
                
                // Miktar + Birim Seçici
                VStack(alignment: .leading, spacing: 4) {
                    Text("MİKTAR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "94A3B8"))
                    
                    HStack(spacing: 2) {
                        TextField("Miktar", value: Binding(
                            get: { items[index].miktar },
                            set: { items[index].miktar = $0 }
                        ), formatter: itemNumberFormatter)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 7)
                        .foregroundColor(.white)
                        
                        Menu {
                            ForEach(birimListesi, id: \.self) { b in
                                Button(b) {
                                    items[index].birim = b
                                }
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
                
                // Birim Fiyatı
                VStack(alignment: .leading, spacing: 4) {
                    Text("BİRİM FİYATI")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "94A3B8"))
                    
                    TextField("Fiyat", value: Binding(
                        get: { items[index].birimFiyat },
                        set: { items[index].birimFiyat = $0 }
                    ), formatter: itemNumberFormatter)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(Color(hex: "2A2A2A"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                
                // KDV Seçici / Gösterici
                VStack(alignment: .leading, spacing: 4) {
                    Text("KDV")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "94A3B8"))
                    
                    Menu {
                        ForEach(kdvOranlari, id: \.self) { rate in
                            Button("%\(Int(rate))") {
                                items[index].kdvOrani = rate
                            }
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
            
            // Kalem Açıklaması (Opsiyonel)
            VStack(alignment: .leading, spacing: 4) {
                Text("KALEM AÇIKLAMASI (OPSİYONEL)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "94A3B8"))
                
                TextField("Açıklama girin...", text: Binding(
                    get: { items[index].aciklama ?? "" },
                    set: { items[index].aciklama = $0 }
                ))
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(hex: "2A2A2A"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Canlı Satır Tutarı
            HStack {
                Spacer()
                let rowTotal = items[index].miktar * items[index].birimFiyat
                Text("Satır Tutarı: \(AppFormatters.money(rowTotal))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "00FF87"))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private var isFormValid: Bool {
        selectedCari != nil && !faturaNo.trimmingCharacters(in: .whitespaces).isEmpty && !items.isEmpty
    }
    
    private var itemNumberFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }
    
    // MARK: - Kayıt İşlemi
    private func saveFatura() {
        guard let cari = selectedCari else { return }
        isSaving = true
        errorMessage = nil
        
        let req = InvoiceTransactionRequest(
            faturaNo: faturaNo,
            tarih: AppFormatters.isoDate.string(from: tarih),
            vadeTarihi: AppFormatters.isoDate.string(from: vadeTarihi),
            cari: cari,
            tur: tur,
            durum: durum,
            odemeSekli: odemeSekli,
            kasaId: kasaId,
            bankaId: bankaId,
            dovizTuru: "TL",
            dovizKuru: 1.0,
            aciklama: aciklama,
            items: items
        )
        
        Task {
            do {
                let savedFatura = try await TransactionService.shared.saveInvoiceTransaction(req: req)
                await MainActor.run {
                    HardwareService.shared.hapticSuccess()
                    onSave?(savedFatura)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    NotificationCenter.default.post(
                        name: .userToastNotification,
                        object: nil,
                        userInfo: ["message": "Fatura kaydedilemedi: \(error.localizedDescription)"]
                    )
                    self.isSaving = false
                }
            }
        }
    }
}
