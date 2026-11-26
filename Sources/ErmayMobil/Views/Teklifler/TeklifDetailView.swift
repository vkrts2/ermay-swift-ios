import SwiftUI

public struct TeklifDetailView: View {
    @State public var teklif: Teklif
    @State private var showConvertAlert: Bool = false
    @State private var convertedNotice: String? = nil
    @State private var pdfPreviewItem: PDFPreviewItem? = nil
    @State private var liveKalemler: [TeklifKalem] = []
    @State private var isLoadingKalemler: Bool = false
    
    public init(teklif: Teklif) {
        self._teklif = State(initialValue: teklif)
    }
    
    public var displayedKalemler: [TeklifKalem] {
        !liveKalemler.isEmpty ? liveKalemler : (teklif.kalemler ?? [])
    }
    
    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    if let notice = convertedNotice {
                        Text(notice)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.success)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.success.opacity(0.15))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    GlassCard(cornerRadius: 18, padding: 18) {
                        VStack(spacing: 12) {
                            HStack {
                                Text(teklif.teklifNo)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                StatusBadge(title: teklif.durum, color: teklif.durum == "ONAYLANDI" ? AppTheme.success : AppTheme.primary)
                            }
                            
                            Divider().background(AppTheme.border)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("MÜŞTERİ / MUHATAP")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)
                                Text(teklif.cariUnvan ?? "-")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DetailInfoRow(label: "Teklif Tarihi", value: teklif.tarih)
                            DetailInfoRow(label: "Son Geçerlilik", value: teklif.gecerlilikTarihi ?? "-")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Kalemler
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Teklif Kalemleri")
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
                            DetailSummaryRow(label: "Ara Toplam", value: AppFormatters.money(teklif.araToplam))
                            DetailSummaryRow(label: "KDV Toplamı", value: AppFormatters.money(teklif.kdvToplami))
                            Divider().background(AppTheme.border)
                            HStack {
                                Text("GENEL TOPLAM")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Text(AppFormatters.money(teklif.genelToplam))
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Aksiyon Butonları
                    VStack(spacing: 10) {
                        ActionButton(
                            title: "QuestPDF Resmi Teklif Aç",
                            icon: "doc.text.fill",
                            color: AppTheme.primary
                        ) {
                            #if canImport(UIKit)
                            Task { @MainActor in
                                if let data = await PDFService.shared.fetchOrGenerateTeklifPDF(
                                    teklif: teklif,
                                    kalemler: displayedKalemler,
                                    firma: .varsayilan
                                ) {
                                    self.pdfPreviewItem = PDFPreviewItem(
                                        title: "Teklif - \(teklif.teklifNo)",
                                        data: data,
                                        fileName: "Teklif_\(teklif.teklifNo).pdf"
                                    )
                                }
                            }
                            #endif
                        }
                        
                        if teklif.durum != "ONAYLANDI" {
                            ActionButton(
                                title: "Teklifi Onayla",
                                icon: "checkmark.seal.fill",
                                color: AppTheme.success
                            ) {
                                updateDurum("ONAYLANDI")
                            }
                        }
                        
                        ActionButton(
                            title: "Siparişe Dönüştür",
                            icon: "cart.badge.plus.fill",
                            color: Color(hex: "00FF87")
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
        .navigationTitle("Teklif Detayı")
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
        .alert("Siparişe Dönüştür", isPresented: $showConvertAlert) {
            Button("Evet, Sipariş Oluştur") {
                convertToSiparis()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Bu teklifin kalemleri otomatik olarak yeni bir siparişe aktarılacaktır. Onaylıyor musunuz?")
        }
    }
    
    private func updateDurum(_ yeniDurum: String) {
        Task {
            try? await SupabaseService.shared.update(table: "teklifler", id: teklif.id, item: ["durum": yeniDurum])
            await MainActor.run {
                teklif.durum = yeniDurum
            }
        }
    }
    
    private func convertToSiparis() {
        let siparisNo = "MB-SIP-\(Int.random(in: 100000...999999))"
        let sipUuid = UUID().uuidString.lowercased()
        let tenantId = SupabaseService.shared.tenantId
        let activeYearInt = Int(SupabaseService.shared.activeFiscalYear) ?? Calendar.current.component(.year, from: Date())
        let cIdInt = teklif.cariId.flatMap { Int($0) }
        let todayStr = AppFormatters.isoDate.string(from: Date())
        let deliveryStr = AppFormatters.isoDate.string(from: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())

        var rpcPayload: [String: Any] = [
            "uuid": sipUuid,
            "tenant_id": tenantId,
            "siparis_no": siparisNo,
            "siparis_turu": "ALINAN",
            "tur": "Satış Siparişi",
            "cari_unvan": teklif.cariUnvan ?? "",
            "tarih": todayStr,
            "teslim_tarihi": deliveryStr,
            "baglanti_evrak_no": teklif.teklifNo,
            "ara_toplam": teklif.araToplam,
            "kdv_toplam": teklif.kdvToplami,
            "genel_toplam": teklif.genelToplam,
            "durum": "Bekliyor",
            "aciklama": teklif.aciklama ?? "Tekliften dönüştürüldü (\(teklif.teklifNo))",
            "mali_yil": activeYearInt,
            "detaylar": displayedKalemler.map { k -> [String: Any] in
                var d: [String: Any] = [
                    "uuid": UUID().uuidString.lowercased(),
                    "stok_adi": k.stokAdi,
                    "miktar": k.miktar,
                    "birim": k.birim ?? "Adet",
                    "birim_fiyat": k.birimFiyat,
                    "kdv_orani": k.kdvOrani,
                    "toplam_tutar": k.tutar
                ]
                if let intStok = k.stokId.flatMap({ Int($0) }) { d["stok_id"] = intStok }
                if let sKod = k.stokKodu, !sKod.isEmpty { d["stok_kodu"] = sKod }
                return d
            }
        ]
        if let cid = cIdInt { rpcPayload["cari_id"] = cid }

        Task {
            do {
                if let tIdInt = Int(teklif.id),
                   let res = try? await SupabaseService.shared.rpcRaw(
                       function: "convert_teklif_to_siparis_atomic",
                       params: [
                           "p_teklif_id": tIdInt,
                           "p_siparis_no": siparisNo,
                           "p_tenant_id": tenantId
                       ]
                   ),
                   (res["success"] as? Bool) == true {
                    await MainActor.run {
                        teklif.durum = "ONAYLANDI"
                        convertedNotice = "Teklif başarıyla '\(siparisNo)' nolu siparişe dönüştürüldü."
                    }
                    return
                }

                let res = try await SupabaseService.shared.rpcRaw(
                    function: "save_siparis_atomic",
                    params: ["p_payload": rpcPayload]
                )
                if let ok = res["success"] as? Bool, !ok {
                    throw NSError(domain: "TeklifDetail", code: 500, userInfo: [NSLocalizedDescriptionKey: (res["message"] as? String) ?? "Siparişe dönüştürülemedi."])
                }
                try? await SupabaseService.shared.update(table: "teklifler", id: teklif.id, item: ["durum": "ONAYLANDI"])
                await MainActor.run {
                    teklif.durum = "ONAYLANDI"
                    convertedNotice = "Teklif başarıyla '\(siparisNo)' nolu siparişe dönüştürüldü."
                }
            } catch {
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .userToastNotification,
                        object: nil,
                        userInfo: ["message": "Siparişe dönüştürme hatası: \(error.localizedDescription)"]
                    )
                }
            }
        }
    }
    
    private func loadKalemler() async {
        isLoadingKalemler = true
        do {
            let items: [TeklifKalem] = try await SupabaseService.shared.fetch(
                from: "teklif_detaylar",
                filters: ["teklif_id": "eq.\(teklif.id)"],
                applyTenantFilter: false
            )
            await MainActor.run {
                self.liveKalemler = items
            }
        } catch {
            print("Teklif Kalemler load error: \(error)")
        }
        isLoadingKalemler = false
    }
}
