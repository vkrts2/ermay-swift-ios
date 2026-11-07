import SwiftUI

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
            .sheet(isPresented: $showCariPicker) {
                CariPickerSheet { c in
                    self.cariId = c.id
                    self.cariUnvan = c.unvan
                }
            }
        }
    }
    
    private func handleSave() {
        guard let tutar = Double(tutarStr.replacingOccurrences(of: ",", with: ".")), tutar > 0 else { return }
        isSaving = true
        let docNo = isTahsilat ? "THS-\(Int.random(in: 100...999))" : "TED-\(Int.random(in: 100...999))"
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
        
        Task {
            do {
                // 1. Kasa Hareketi Ekle
                var kasaPayload: [String: Any] = [
                    "uuid": UUID().uuidString,
                    "tenant_id": SupabaseService.shared.tenantId,
                    "tarih": dateStr,
                    "islem_turu": isTahsilat ? "Tahsilat" : "Ödeme",
                    "hareket_turu": isTahsilat ? "Tahsilat" : "Ödeme",
                    "giren": isTahsilat ? tutar : 0.0,
                    "cikan": isTahsilat ? 0.0 : tutar,
                    "gelir": isTahsilat ? tutar : 0.0,
                    "gider": isTahsilat ? 0.0 : tutar,
                    "evrak_no": docNo,
                    "tutar": tutar,
                    "aciklama": desc,
                    "is_deleted": false
                ]
                if let cid = cariId, let intCid = Int(cid) {
                    kasaPayload["cari_id"] = intCid
                }
                if !cariUnvan.isEmpty {
                    kasaPayload["cari_unvan"] = cariUnvan
                }
                let kData = try JSONSerialization.data(withJSONObject: kasaPayload)
                try await SupabaseService.shared.insertRaw(into: "kasa_hareketler", data: kData)
                
                // 2. Eğer Cari seçildiyse Cari Hareketi de ekle
                if let cid = cariId, !cid.isEmpty {
                    var cariPayload: [String: Any] = [
                        "uuid": UUID().uuidString,
                        "tenant_id": SupabaseService.shared.tenantId,
                        "cari_unvan": cariUnvan,
                        "evrak_no": docNo,
                        "islem_turu": isTahsilat ? "Tahsilat" : "Ödeme",
                        "hareket_turu": isTahsilat ? "Tahsilat" : "Ödeme",
                        "odeme_sekli": "Nakit",
                        "aciklama": desc,
                        "borc": isTahsilat ? 0.0 : tutar,
                        "alacak": isTahsilat ? tutar : 0.0,
                        "tarih": dateStr,
                        "is_deleted": false
                    ]
                    if let intCid = Int(cid) {
                        cariPayload["cari_id"] = intCid
                    }
                    let cData = try JSONSerialization.data(withJSONObject: cariPayload)
                    try await SupabaseService.shared.insertRaw(into: "cari_hareketler", data: cData)
                }
                
                await MainActor.run {
                    HardwareService.shared.hapticSuccess()
                    onSave?(h)
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    HardwareService.shared.hapticSuccess()
                    onSave?(h)
                    isSaving = false
                    dismiss()
                }
            }
        }
    }
}

