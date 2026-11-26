import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct FaturaDetailView: View {
    @Environment(\.dismiss) private var dismiss
    public let fatura: Fatura
    @State private var liveKalemler: [FaturaKalem] = []
    @State private var isLoadingKalemler: Bool = false
    @State private var pdfPreviewItem: PDFPreviewItem? = nil
    @State private var isGeneratingPDF: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var isDeleting: Bool = false
    
    public init(fatura: Fatura) {
        self.fatura = fatura
    }
    
    public var displayedKalemler: [FaturaKalem] {
        !liveKalemler.isEmpty ? liveKalemler : (fatura.kalemler ?? [])
    }
    
    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Üst Fatura Başlık Kartı
                    GlassCard(cornerRadius: 18, padding: 18) {
                        VStack(spacing: 12) {
                            HStack {
                                Text(fatura.faturaNo)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                StatusBadge(
                                    title: fatura.faturaTuru,
                                    color: fatura.faturaTuru.contains("SATIS") ? AppTheme.primary : AppTheme.purple
                                )
                            }
                            
                            Divider().background(AppTheme.border)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("MÜŞTERİ / CARİ")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Text(fatura.cariUnvan ?? "Perakende Müşteri")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Fatura Tarihi")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textMuted)
                                    Text(fatura.tarih)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Vade Tarihi")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textMuted)
                                    Text(fatura.vadeTarihi ?? "-")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Kalemler Tablosu
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Fatura Kalemleri (\(displayedKalemler.count))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            if isLoadingKalemler {
                                ProgressView().tint(AppTheme.primary)
                            }
                        }
                        .padding(.horizontal)
                        
                        if !displayedKalemler.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(displayedKalemler) { k in
                                    GlassCard(cornerRadius: 12, padding: 12) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(k.stokAdi)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                Text("\(String(format: "%.2f", k.miktar)) \(k.birim ?? "Adet") x \(AppFormatters.money(k.birimFiyat)) (KDV %\(Int(k.kdvOrani)))")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(AppTheme.textMuted)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(AppFormatters.money(k.toplamTutar > 0 ? k.toplamTutar : k.netTutar))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            GlassCard(cornerRadius: 12, padding: 16) {
                                Text("Kalem detayları kayıtlı değil veya genel toplam üzerinden kaydedildi.")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Toplamlar Özeti
                    GlassCard(cornerRadius: 16, padding: 16) {
                        VStack(spacing: 8) {
                            DetailSummaryRow(label: "Ara Toplam (Matrah)", value: AppFormatters.money(fatura.araToplam))
                            DetailSummaryRow(label: "İskonto", value: AppFormatters.money(fatura.iskontoToplami))
                            DetailSummaryRow(label: "KDV Toplamı", value: AppFormatters.money(fatura.kdvToplami))
                            
                            if let tev = fatura.tevkifatTutari, tev > 0 {
                                DetailSummaryRow(label: "Tevkifat Tutarı", value: "-\(AppFormatters.money(tev))")
                            }
                            
                            Divider().background(AppTheme.border)
                            
                            HStack {
                                Text("GENEL TOPLAM")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Text(AppFormatters.money(fatura.genelToplam))
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // PDF Oluştur ve Paylaş Butonu (QuestPDF Destekli)
                    ActionButton(
                        title: isGeneratingPDF ? "PDF Hazırlanıyor..." : "QuestPDF Resmi Fatura Aç",
                        icon: "doc.text.fill",
                        color: AppTheme.primary
                    ) {
                        #if canImport(UIKit)
                        Task { @MainActor in
                            self.isGeneratingPDF = true
                            let generated = await PDFService.shared.fetchOrGenerateFaturaPDF(
                                fatura: fatura,
                                kalemler: displayedKalemler,
                                firma: .varsayilan
                            )
                            self.isGeneratingPDF = false
                            if let data = generated {
                                self.pdfPreviewItem = PDFPreviewItem(
                                    title: "Fatura - \(fatura.faturaNo)",
                                    data: data,
                                    fileName: "Fatura_\(fatura.faturaNo).pdf"
                                )
                            }
                        }
                        #endif
                    }
                    .padding(.horizontal)
                    .disabled(isGeneratingPDF)
                    
                    ActionButton(
                        title: isDeleting ? "Fatura İptal Ediliyor..." : "Faturayı İptal Et / Sil",
                        icon: "trash.fill",
                        color: AppTheme.danger
                    ) {
                        showDeleteConfirm = true
                    }
                    .padding(.horizontal)
                    .disabled(isDeleting)
                    
                    Spacer().frame(height: 20)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("Fatura Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .enableSwipeBack()
        .alert("Faturayı İptal Et / Sil", isPresented: $showDeleteConfirm) {
            Button("Evet, Faturayı Sil", role: .destructive) {
                cancelAndDeleteFatura()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("\(fatura.faturaNo) numaralı faturayı ve bağlı cari/stok/kasa hareketlerini iptal etmek istediğinize emin misiniz?")
        }
        .task {
            await loadKalemler()
        }
        .onReceive(NotificationCenter.default.publisher(for: .supabaseRealtimeDataChanged)) { _ in
            Task {
                await loadKalemler()
            }
        }
        .sheet(item: $pdfPreviewItem) { item in
            #if canImport(UIKit)
            PDFViewerModal(
                title: item.title,
                pdfData: item.data,
                fileName: item.fileName
            )
            #endif
        }
    }
    
    private func loadKalemler() async {
        isLoadingKalemler = true
        do {
            let items: [FaturaKalem] = try await SupabaseService.shared.fetch(
                from: "fatura_detaylar",
                filters: ["fatura_id": "eq.\(fatura.id)"],
                applyTenantFilter: false
            )
            await MainActor.run {
                self.liveKalemler = items
            }
        } catch {
            print("Kalemler load error: \(error)")
        }
        isLoadingKalemler = false
    }
    
    private func cancelAndDeleteFatura() {
        isDeleting = true
        Task {
            do {
                try await TransactionService.shared.deleteInvoiceAtomic(fatura: fatura)
                await MainActor.run {
                    HardwareService.shared.hapticSuccess()
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    NotificationCenter.default.post(
                        name: .userToastNotification,
                        object: nil,
                        userInfo: ["message": "Fatura silinemedi: \(error.localizedDescription)"]
                    )
                }
            }
        }
    }
}

struct DetailSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

