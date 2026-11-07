import SwiftUI

public struct CariFormView: View {
    @Environment(\.dismiss) private var dismiss
    public var cariToEdit: CariKart?
    public var onSave: ((CariKart) -> Void)?
    
    @State private var unvan: String = ""
    @State private var yetkili: String = ""
    @State private var cariKod: String = ""
    @State private var tur: String = "Alici"
    @State private var grup: String = "Müşteri"
    @State private var tcNo: String = ""
    @State private var vergiDairesi: String = ""
    @State private var vergiNo: String = ""
    @State private var ticaretSicilNo: String = ""
    @State private var iban: String = ""
    @State private var telefon: String = ""
    @State private var cepTelefon: String = ""
    @State private var eposta: String = ""
    @State private var webAdresi: String = ""
    @State private var odemePlani: String = "Peşin"
    @State private var vadeGunu: String = "0"
    @State private var riskLimiti: String = "0"
    @State private var ulke: String = "Türkiye"
    @State private var il: String = "İstanbul"
    @State private var ilce: String = "Başakşehir"
    @State private var adres: String = ""
    @State private var sevkAdresi: String = ""
    @State private var aciklama: String = ""
    @State private var riskTakibiYapilsin: Bool = false
    @State private var vadeGecmisteEngelle: Bool = false
    @State private var faturadaRiskKontrolu: Bool = true
    @State private var aktifMi: Bool = true
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    
    private let odemePlanlari = ["Peşin", "7 Gün", "15 Gün", "30 Gün", "45 Gün", "60 Gün", "90 Gün", "Haftalık", "Aylık"]
    
    public init(cariToEdit: CariKart? = nil, onSave: ((CariKart) -> Void)? = nil) {
        self.cariToEdit = cariToEdit
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 14) {
                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(10)
                        }
                        
                        // Temel Bilgiler Kartı
                        formCard {
                            formInputField(label: "Cari Unvanı *", text: $unvan, placeholder: "örn. Ermay Tekstil Ltd. Şti.")
                            formInputField(label: "Yetkili Kişi", text: $yetkili, placeholder: "örn. Ahmet Yılmaz")
                            
                            HStack(spacing: 10) {
                                formInputField(label: "Cari Kodu (Opsiyonel)", text: $cariKod, placeholder: "örn. CARI-001")
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Cari Tipi")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                    
                                    HStack(spacing: 4) {
                                        Button {
                                            grup = "Müşteri"
                                            tur = "Alici"
                                        } label: {
                                            Text("Müşteri")
                                                .font(.system(size: 12, weight: grup == "Müşteri" ? .bold : .medium))
                                                .foregroundColor(grup == "Müşteri" ? .white : Color(hex: "8E8E93"))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(grup == "Müşteri" ? Color(hex: "2563EB") : Color.white.opacity(0.05))
                                                .cornerRadius(8)
                                        }
                                        
                                        Button {
                                            grup = "Tedarikçi"
                                            tur = "Satici"
                                        } label: {
                                            Text("Tedarikçi")
                                                .font(.system(size: 12, weight: grup == "Tedarikçi" ? .bold : .medium))
                                                .foregroundColor(grup == "Tedarikçi" ? .white : Color(hex: "8E8E93"))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(grup == "Tedarikçi" ? Color(hex: "D97706") : Color.white.opacity(0.05))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // Vergi & Sicil Bilgileri
                        formCard {
                            HStack(spacing: 10) {
                                formInputField(label: "Vergi Dairesi", text: $vergiDairesi, placeholder: "İkitelli VD")
                                formInputField(label: "Vergi No", text: $vergiNo, placeholder: "10 Haneli")
                            }
                            HStack(spacing: 10) {
                                formInputField(label: "T.C. Kimlik No", text: $tcNo, placeholder: "11 Haneli")
                                formInputField(label: "Ticaret Sicil No", text: $ticaretSicilNo, placeholder: "Sicil No")
                            }
                            formInputField(label: "IBAN", text: $iban, placeholder: "TR00 0000 0000 0000 0000 0000 00")
                        }
                        
                        // İletişim Bilgileri
                        formCard {
                            HStack(spacing: 10) {
                                formInputField(label: "Telefon", text: $telefon, placeholder: "0212...")
                                formInputField(label: "Cep Telefonu", text: $cepTelefon, placeholder: "0532...")
                            }
                            formInputField(label: "E-Posta", text: $eposta, placeholder: "bilgi@ermay.com")
                            formInputField(label: "Web Adresi", text: $webAdresi, placeholder: "www.ermay.com")
                        }
                        
                        // Ödeme & Risk Parametreleri
                        formCard {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Ödeme Planı")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                    
                                    Picker("Ödeme Planı", selection: $odemePlani) {
                                        ForEach(odemePlanlari, id: \.self) { p in
                                            Text(p).tag(p)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                }
                                
                                formInputField(label: "Vade Günü", text: $vadeGunu, placeholder: "0")
                            }
                            
                            HStack(spacing: 10) {
                                formInputField(label: "Risk Limiti (TL)", text: $riskLimiti, placeholder: "0.00")
                                formInputField(label: "Ülke", text: $ulke, placeholder: "Türkiye")
                            }
                        }
                        
                        // Adres Bilgileri
                        formCard {
                            HStack(spacing: 10) {
                                formInputField(label: "İl", text: $il, placeholder: "İstanbul")
                                formInputField(label: "İlçe", text: $ilce, placeholder: "Başakşehir")
                            }
                            formInputField(label: "Açık Adres", text: $adres, placeholder: "Detaylı adres bilgisi...")
                            formInputField(label: "Sevk Adresi", text: $sevkAdresi, placeholder: "Sevk adresi bilgisi...")
                            formInputField(label: "Açıklama", text: $aciklama, placeholder: "Cari hakkında özel notlar...")
                        }
                        
                        // Kaydet Butonu
                        Button {
                            handleSave()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(isSaving ? "Kaydediliyor..." : "Kaydet")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "2563EB"))
                            .cornerRadius(12)
                        }
                        .padding(.top, 4)
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(cariToEdit != nil ? "Cari Kartı Düzenle" : "Yeni Cari Kartı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
            .onAppear {
                if let c = cariToEdit {
                    unvan = c.unvan
                    cariKod = c.cariKodu ?? ""
                    yetkili = c.yetkili ?? ""
                    telefon = c.telefon ?? ""
                    cepTelefon = c.gsm ?? ""
                    eposta = c.email ?? ""
                    vergiDairesi = c.vergiDairesi ?? ""
                    vergiNo = c.vergiNo ?? ""
                    il = c.sehir ?? "İstanbul"
                    ilce = c.ilce ?? ""
                    adres = c.adres ?? ""
                    grup = (c.cariTuru ?? "").contains("Tedarik") ? "Tedarikçi" : "Müşteri"
                }
            }
        }
    }
    
    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12, content: content)
            .padding(14)
            .background(Color(hex: "121216"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private func formInputField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "8E8E93"))
            TextField(placeholder, text: text)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }
    
    private func handleSave() {
        guard !unvan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Lütfen cari unvanını giriniz."
            return
        }
        isSaving = true
        errorMessage = nil
        
        let saved = CariKart(
            id: cariToEdit?.id ?? UUID().uuidString,
            cariKodu: cariKod.isEmpty ? "CARI-\(Int.random(in: 100...999))" : cariKod,
            unvan: unvan,
            cariTuru: grup,
            yetkili: yetkili,
            vergiDairesi: vergiDairesi,
            vergiNo: vergiNo,
            tcKimlikNo: tcNo.isEmpty ? nil : tcNo,
            telefon: telefon,
            gsm: cepTelefon,
            email: eposta,
            webSitesi: webAdresi.isEmpty ? nil : webAdresi,
            adres: adres,
            sevkAdresi: sevkAdresi,
            sehir: il,
            ilce: ilce,
            bakiye: cariToEdit?.bakiye ?? 0.0,
            bakiyeTuru: cariToEdit?.bakiyeTuru ?? "A",
            riskLimiti: Double(riskLimiti) ?? 0.0,
            vadeGunu: Int(vadeGunu) ?? 0,
            odemePlani: odemePlani,
            ticaretSicilNo: ticaretSicilNo.isEmpty ? nil : ticaretSicilNo,
            iban: iban.isEmpty ? nil : iban,
            aktif: aktifMi,
            syncGuid: cariToEdit?.syncGuid ?? UUID().uuidString,
            tenantId: SupabaseService.shared.tenantId
        )
        
        Task {
            do {
                if let editItem = cariToEdit, let intId = Int(editItem.id) {
                    try await SupabaseService.shared.update(table: "cariler", id: "\(intId)", item: saved)
                } else {
                    var itemToSave = saved
                    if itemToSave.id.isEmpty || Int(itemToSave.id) == nil || Int(itemToSave.id)! <= 0 {
                        let nextId = await SupabaseService.shared.getNextId(for: "cariler")
                        itemToSave.id = String(nextId)
                    }
                    try await SupabaseService.shared.insert(into: "cariler", item: itemToSave)
                }
                await MainActor.run {
                    HardwareService.shared.hapticSuccess()
                    onSave?(saved)
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Kayıt Başarısız: \(error.localizedDescription)"
                    self.isSaving = false
                    // İnternet hatası durumunda yine de offline kuyruğa kaydet
                    OfflineQueueService.shared.enqueue(
                        action: cariToEdit == nil ? "INSERT" : "UPDATE",
                        table: "cariler",
                        recordId: saved.id,
                        payload: try? JSONEncoder().encode(saved)
                    )
                }
            }
        }
    }
}
