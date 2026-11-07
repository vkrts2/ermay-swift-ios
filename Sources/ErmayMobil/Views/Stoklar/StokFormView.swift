import SwiftUI

public struct StokFormView: View {
    @Environment(\.dismiss) private var dismiss
    public var onSave: ((StokKart) -> Void)?
    
    @State private var stokAdi: String = ""
    @State private var stokKodu: String = ""
    @State private var barkod: String = ""
    @State private var grupAdi: String = "Genel"
    @State private var birim: String = "Adet"
    @State private var alisFiyati: String = ""
    @State private var satisFiyati: String = ""
    @State private var kdvOrani: Double = 20.0
    @State private var baslangicMiktar: String = "0"
    @State private var kritikMiktar: String = "5"
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showScanner: Bool = false
    
    public init(onSave: ((StokKart) -> Void)? = nil) {
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.danger)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.dangerMuted.opacity(0.4))
                                .cornerRadius(10)
                        }
                        
                        GlassCard(cornerRadius: 16, padding: 18) {
                            VStack(spacing: 14) {
                                FormField(label: "Ürün / Stok Adı *", text: $stokAdi, placeholder: "Örn: Bilyalı Rulman")
                                FormField(label: "Stok Kodu", text: $stokKodu, placeholder: "Örn: STK-105")
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Barkod No")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(AppTheme.textSecondary)
                                        Spacer()
                                        Button {
                                            showScanner = true
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "barcode.viewfinder")
                                                Text("Kamera ile Tara")
                                            }
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(AppTheme.primary)
                                        }
                                    }
                                    
                                    TextField("8690001002005", text: $barkod)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(AppTheme.cardBackground)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(AppTheme.border, lineWidth: 1)
                                        )
                                }
                                
                                FormField(label: "Grup Adı", text: $grupAdi, placeholder: "Genel, Hırdavat, Yağ...")
                                FormField(label: "Birim", text: $birim, placeholder: "Adet, Kg, Metre, Koli...")
                            }
                        }
                        
                        GlassCard(cornerRadius: 16, padding: 18) {
                            VStack(spacing: 14) {
                                FormField(label: "Alış Fiyatı (₺)", text: $alisFiyati, placeholder: "0.00")
                                FormField(label: "Satış Fiyatı (₺)", text: $satisFiyati, placeholder: "0.00")
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("KDV Oranı: %\(Int(kdvOrani))")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Picker("KDV", selection: $kdvOrani) {
                                        Text("%0").tag(0.0)
                                        Text("%1").tag(1.0)
                                        Text("%10").tag(10.0)
                                        Text("%20").tag(20.0)
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                        }
                        
                        GlassCard(cornerRadius: 16, padding: 18) {
                            VStack(spacing: 14) {
                                FormField(label: "Açılış / Başlangıç Miktarı", text: $baslangicMiktar, placeholder: "0")
                                FormField(label: "Kritik Stok Uyarısı Eşiği", text: $kritikMiktar, placeholder: "5")
                            }
                        }
                        
                        ActionButton(
                            title: isSaving ? "Kaydediliyor..." : "Stok Kartını Kaydet",
                            icon: "checkmark.circle.fill",
                            color: AppTheme.primary
                        ) {
                            saveStok()
                        }
                        .disabled(isSaving)
                        
                        Spacer().frame(height: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Yeni Stok Kartı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView { code in
                    self.barkod = code
                }
            }
        }
    }
    
    private func saveStok() {
        guard !stokAdi.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Lütfen ürün adını giriniz."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        let newStok = StokKart(
            id: UUID().uuidString,
            stokKodu: stokKodu.isEmpty ? "STK-\(Int.random(in: 100...999))" : stokKodu,
            stokAdi: stokAdi,
            barkod: barkod.isEmpty ? nil : barkod,
            grupAdi: grupAdi.isEmpty ? "Genel" : grupAdi,
            birim: birim.isEmpty ? "Adet" : birim,
            alisFiyati: Double(alisFiyati) ?? 0.0,
            satisFiyati: Double(satisFiyati) ?? 0.0,
            kdvOrani: kdvOrani,
            mevcutMiktar: Double(baslangicMiktar) ?? 0.0,
            kritikMiktar: Double(kritikMiktar) ?? 5.0
        )
        
        Task {
            do {
                var itemToSave = newStok
                if itemToSave.id.isEmpty || Int(itemToSave.id) == nil || Int(itemToSave.id)! <= 0 {
                    let nextId = await SupabaseService.shared.getNextId(for: "stoklar")
                    itemToSave.id = String(nextId)
                }
                try await SupabaseService.shared.insert(into: "stoklar", item: itemToSave)
                await MainActor.run {
                    onSave?(itemToSave)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    OfflineQueueService.shared.enqueue(action: "INSERT", table: "stoklar", recordId: newStok.id, payload: try? JSONEncoder().encode(newStok))
                    onSave?(newStok)
                    dismiss()
                }
            }
        }
    }
}

