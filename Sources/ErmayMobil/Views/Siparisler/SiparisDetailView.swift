import SwiftUI

public struct SiparisDetailView: View {
    @State public var siparis: Siparis
    @State private var showConvertAlert: Bool = false
    @State private var convertedSuccess: Bool = false
    @State private var pdfPreviewItem: PDFPreviewItem? = nil
    @State private var liveKalemler: [SiparisKalem] = []
    @State private var isLoadingKalemler: Bool = false
    
    public init(siparis: Siparis) {
        self._siparis = State(initialValue: siparis)
    }
    
    public var displayedKalemler: [SiparisKalem] {
        !liveKalemler.isEmpty ? liveKalemler : (siparis.kalemler ?? [])
    }
    
    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    GlassCard(cornerRadius: 18, padding: 18) {
                        VStack(spacing: 12) {
                            HStack {
                                Text(siparis.siparisNo)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                StatusBadge(title: siparis.durum, color: AppTheme.primary)
                            }
                            
                            Divider().background(AppTheme.border)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("MÜŞTERİ / TEDARİKÇİ")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)
                                Text(siparis.cariUnvan ?? "-")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DetailInfoRow(label: "Sipariş Tarihi", value: siparis.tarih)
                            DetailInfoRow(label: "Teslim Tarihi", value: siparis.teslimTarihi ?? "-")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Kalemler
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sipariş Kalemleri")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal)
                        
                        let kalemler = displayedKalemler
                        if !kalemler.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(kalemler) { k in
                                    GlassCard(cornerRadius: 12, padding: 12) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(k.stokAdi)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                Text("\(String(format: "%.2f", k.miktar)) x \(AppFormatters.money(k.birimFiyat))")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(AppTheme.textMuted)
                                            }
                                            Spacer()
                                            Text(AppFormatters.money(k.tutar))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else if isLoadingKalemler {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Kalem bulunamadı.")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textMuted)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Toplamlar
                    GlassCard(cornerRadius: 16, padding: 16) {
                        VStack(spacing: 8) {
                            DetailSummaryRow(label: "Ara Toplam", value: AppFormatters.money(siparis.araToplam))
                            DetailSummaryRow(label: "KDV Toplamı", value: AppFormatters.money(siparis.kdvToplami))
                            Divider().background(AppTheme.border)
                            HStack {
                                Text("GENEL TOPLAM")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Text(AppFormatters.money(siparis.genelToplam))
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Aksiyon Butonları
                    VStack(spacing: 10) {
                        ActionButton(
                            title: "QuestPDF Resmi Sipariş Aç",
                            icon: "doc.text.fill",
                            color: AppTheme.primary
                        ) {
                            #if canImport(UIKit)
                            Task { @MainActor in
                                if let data = await PDFService.shared.fetchOrGenerateSiparisPDF(
                                    siparis: siparis,
                                    kalemler: displayedKalemler,
                                    firma: .varsayilan
                                ) {
                                    self.pdfPreviewItem = PDFPreviewItem(
                                        title: "Sipariş - \(siparis.siparisNo)",
                                        data: data,
                                        fileName: "Siparis_\(siparis.siparisNo).pdf"
                                    )
                                }
                            }
                            #endif
                        }
                        
                        // Faturaya Dönüştür Butonu
                        ActionButton(
                            title: "Faturaya Dönüştür",
                            icon: "doc.badge.arrow.up.fill",
                            color: AppTheme.success
                        ) {
                            showConvertAlert = true
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer().frame(height: 20)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("Sipariş Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .enableSwipeBack()
        .task {
            await loadKalemler()
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
        .alert("Faturaya Dönüştür", isPresented: $showConvertAlert) {
            Button("Evet, Fatura Oluştur") {
                convertToFatura()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Bu sipariş kalemleri satış faturasına aktarılacak ve sipariş 'TAMAMLANDI' durumuna getirilecektir. Onaylıyor musunuz?")
        }
    }
    
    private func convertToFatura() {
        let faturaNo = "MB-FTR-\(SupabaseService.shared.activeFiscalYear)-\(Int.random(in: 1000...9999))"
        let cachedStoklar = DataStore.shared.stoklar
        let faturaKalemler: [FaturaKalem] = displayedKalemler.map { k in
            let matchedStok = cachedStoklar.first(where: { $0.id == k.stokId || ($0.stokKodu != nil && $0.stokKodu == k.stokKodu) })
            return FaturaKalem(
                stokId: k.stokId,
                stokUuid: matchedStok?.syncGuid,
                stokKodu: k.stokKodu ?? matchedStok?.stokKodu,
                stokAdi: k.stokAdi,
                birim: k.birim ?? "Adet",
                miktar: k.miktar,
                birimFiyat: k.birimFiyat,
                kdvOrani: k.kdvOrani,
                syncGuid: matchedStok?.syncGuid ?? UUID().uuidString.lowercased()
            )
        }

        let cachedCariler = DataStore.shared.cariler
        let matchedCari = cachedCariler.first(where: { $0.id == siparis.cariId || $0.unvan == siparis.cariUnvan })
        let targetCari = matchedCari ?? CariKart(
            id: siparis.cariId ?? "",
            unvan: siparis.cariUnvan ?? "Müşteri"
        )
        let isSatis = siparis.siparisTuru == "ALINAN" || !siparis.siparisTuru.localizedCaseInsensitiveContains("verilen")
        let todayStr = AppFormatters.isoDate.string(from: Date())

        let req = InvoiceTransactionRequest(
            id: nil,
            faturaNo: faturaNo,
            tarih: todayStr,
            vadeTarihi: siparis.teslimTarihi ?? todayStr,
            cari: targetCari,
            tur: isSatis ? "Satış" : "Alış",
            durum: "Açık",
            odemeSekli: "Açık Hesap",
            baglantiEvrakNo: siparis.siparisNo,
            aciklama: siparis.aciklama ?? "Siparişten Dönüştürüldü: \(siparis.siparisNo)",
            items: faturaKalemler
        )

        Task {
            do {
                _ = try await TransactionService.shared.saveInvoiceTransaction(req: req)
                try await SupabaseService.shared.update(table: "siparisler", id: siparis.id, item: ["durum": "TAMAMLANDI"])
                await DataStore.shared.loadFaturalarCacheFirst(forceCloudRefresh: true)
                await MainActor.run {
                    siparis.durum = "TAMAMLANDI"
                    convertedSuccess = true
                    HardwareService.shared.hapticSuccess()
                }
            } catch {
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .userToastNotification,
                        object: nil,
                        userInfo: ["message": "Sipariş faturaya dönüştürülemedi: \(error.localizedDescription)"]
                    )
                }
            }
        }
    }
    
    private func loadKalemler() async {
        isLoadingKalemler = true
        do {
            let items: [SiparisKalem] = try await SupabaseService.shared.fetch(
                from: "siparis_detaylar",
                filters: ["siparis_id": "eq.\(siparis.id)"],
                applyTenantFilter: false
            )
            await MainActor.run {
                self.liveKalemler = items
            }
        } catch {
            print("Siparis Kalemler load error: \(error)")
        }
        isLoadingKalemler = false
    }
}

