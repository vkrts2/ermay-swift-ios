import SwiftUI

public struct StokSayimView: View {
    public let stoklar: [StokKart]
    @Environment(\.dismiss) private var dismiss
    
    @State private var sayimListesi: [String: Double] = [:] // stokId: sayilanMiktar
    @State private var searchText: String = ""
    @State private var isFinalizing: Bool = false
    @State private var showScanner: Bool = false
    @State private var scannedNotice: String? = nil
    
    public init(stoklar: [StokKart] = []) {
        self.stoklar = stoklar
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        SearchBarView(text: $searchText, placeholder: "Ürün adı veya barkod ara...")
                        
                        Button {
                            showScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.primary)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if let notice = scannedNotice {
                        Text(notice)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.success)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(AppTheme.success.opacity(0.15))
                            .cornerRadius(8)
                    }
                    
                    List {
                        ForEach(stoklar.filter { s in
                            searchText.isEmpty ||
                            s.stokAdi.localizedCaseInsensitiveContains(searchText) ||
                            (s.barkod?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                            (s.stokKodu?.localizedCaseInsensitiveContains(searchText) ?? false)
                        }) { s in
                            let sayilan = sayimListesi[s.id] ?? s.mevcutMiktar
                            let fark = sayilan - s.mevcutMiktar
                            
                            GlassCard(cornerRadius: 12, padding: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(s.stokAdi)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        HStack(spacing: 6) {
                                            Text("Sistem: \(String(format: "%.0f", s.mevcutMiktar)) \(s.birim ?? "")")
                                                .font(.system(size: 11))
                                                .foregroundColor(AppTheme.textMuted)
                                            if let b = s.barkod, !b.isEmpty {
                                                Text("• \(b)")
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundColor(AppTheme.textSecondary)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Button {
                                            let current = sayimListesi[s.id] ?? s.mevcutMiktar
                                            if current > 0 {
                                                sayimListesi[s.id] = current - 1
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                        
                                        Text("\(String(format: "%.0f", sayilan))")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                            .frame(minWidth: 32)
                                        
                                        Button {
                                            let current = sayimListesi[s.id] ?? s.mevcutMiktar
                                            sayimListesi[s.id] = current + 1
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppTheme.primary)
                                        }
                                    }
                                    
                                    if fark != 0 {
                                        Text(fark > 0 ? "+\(String(format: "%.0f", fark))" : "\(String(format: "%.0f", fark))")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(fark > 0 ? AppTheme.success : AppTheme.danger)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background((fark > 0 ? AppTheme.success : AppTheme.danger).opacity(0.15))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    
                    ActionButton(
                        title: isFinalizing ? "Eşitleniyor..." : "Sayımı Tamamla ve Güncelle",
                        icon: "checkmark.seal.fill",
                        color: AppTheme.success
                    ) {
                        finalizeSayim()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Hızlı Stok Sayımı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView { barcode in
                    handleScannedBarcode(barcode)
                }
            }
        }
    }
    
    private func handleScannedBarcode(_ barcode: String) {
        if let match = stoklar.first(where: { $0.barkod == barcode || $0.stokKodu == barcode }) {
            let current = sayimListesi[match.id] ?? match.mevcutMiktar
            sayimListesi[match.id] = current + 1
            scannedNotice = "Taranan: \(match.stokAdi) (+1 eklendi)"
            searchText = match.stokAdi
        } else {
            scannedNotice = "Barkod (\(barcode)) ile eşleşen ürün bulunamadı"
            searchText = barcode
        }
    }
    
    private func finalizeSayim() {
        isFinalizing = true
        Task {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let bugun = df.string(from: Date())
            
            for (stokId, sayilan) in sayimListesi {
                if let s = stoklar.first(where: { $0.id == stokId }) {
                    let fark = sayilan - s.mevcutMiktar
                    if fark != 0 {
                        // Stok hareketi fişi oluştur (Sayım Düzeltmesi)
                        var hareket: [String: Any] = [
                            "uuid": UUID().uuidString,
                            "tenant_id": SupabaseService.shared.tenantId,
                            "stok_adi": s.stokAdi,
                            "tarih": bugun,
                            "islem_turu": fark > 0 ? "SAYIM_FAZLASI" : "SAYIM_EKSIGI",
                            "hareket_turu": fark > 0 ? "Giriş" : "Çıkış",
                            "giren": fark > 0 ? abs(fark) : 0.0,
                            "cikan": fark < 0 ? abs(fark) : 0.0,
                            "miktar": abs(fark),
                            "aciklama": "Mobil Hızlı Stok Sayım Düzeltmesi",
                            "is_deleted": false
                        ]
                        if let intStokId = Int(stokId) {
                            hareket["stok_id"] = intStokId
                        }
                        if let hData = try? JSONSerialization.data(withJSONObject: hareket) {
                            try? await SupabaseService.shared.insertRaw(into: "stok_hareketler", data: hData)
                        }
                    }
                    // Stok kartı mevcut miktarını güncelle
                    if let updateData = try? JSONSerialization.data(withJSONObject: ["mevcut_miktar": sayilan]) {
                        try? await SupabaseService.shared.updateRaw(table: "stoklar", id: stokId, data: updateData)
                    }
                }
            }
            await MainActor.run {
                isFinalizing = false
                dismiss()
            }
        }
    }
}
