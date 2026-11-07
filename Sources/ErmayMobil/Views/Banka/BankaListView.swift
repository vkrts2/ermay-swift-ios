import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct BankaListView: View {
    @State private var bankalar: [BankaKart] = []
    @State private var hareketler: [BankaHareket] = []
    @State private var selectedTab: Int = 0 // 0: Hesaplar, 1: Hareketler
    @State private var isLoading: Bool = false
    @State private var showEftForm: Bool = false
    @State private var copiedIban: String? = nil
    
    public init() {}
    
    public var toplamBakiyeTL: Double {
        bankalar.filter { ($0.dovizTuru ?? "TL") == "TL" }.reduce(0.0) { $0 + $1.bakiye }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 14) {
                    // Header Bar
                    HStack {
                        Text("Banka Hesapları & EFT")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        Button {
                            showEftForm = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "paperplane.fill")
                                Text("EFT/Havale")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.primary)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Toplam Banka Bakiyesi Kartı
                    GlassCard(cornerRadius: 16, padding: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TOPLAM BANKA MEVCUDU (TL)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)
                                Text(AppFormatters.money(toplamBakiyeTL))
                                    .font(.system(size: 26, weight: .heavy))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            Spacer()
                            Image(systemName: "building.columns.circle.fill")
                                .font(.system(size: 34))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Segment: Hesaplar / Hareketler
                    Picker("", selection: $selectedTab) {
                        Text("Banka Hesapları").tag(0)
                        Text("Son Banka Hareketleri").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if selectedTab == 0 {
                        // Hesaplar Listesi
                        List {
                            ForEach(bankalar) { b in
                                BankaKartRow(banka: b) { iban in
                                    #if canImport(UIKit)
                                    UIPasteboard.general.string = iban
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    #endif
                                    copiedIban = iban
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                    } else {
                        // Hareketler Listesi
                        List {
                            ForEach(hareketler) { h in
                                BankaHareketRow(hareket: h)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                
                // Kopyalandı Bildirimi Toast
                if let iban = copiedIban {
                    VStack {
                        Spacer()
                        Text("IBAN Kopyalandı: \(iban)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(20)
                            .padding(.bottom, 80)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedIban = nil
                                }
                            }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEftForm) {
                EftGonderimView(bankalar: bankalar) { newHareket in
                    hareketler.insert(newHareket, at: 0)
                }
            }
            .task {
                await loadBankaData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .supabaseRealtimeDataChanged)) { _ in
                Task {
                    await loadBankaData()
                }
            }
        }
    }
    
    private func loadBankaData() async {
        isLoading = true
        do {
            let items: [BankaKart] = try await SupabaseService.shared.fetch(from: "bankalar")
            let hItems: [BankaHareket] = try await SupabaseService.shared.fetch(from: "banka_hareketler", orderBy: "tarih.desc", limit: 30)
            await MainActor.run {
                self.bankalar = items
                self.hareketler = hItems
            }
        } catch {
            print("Banka fetch error: \(error)")
        }
        isLoading = false
    }
}

struct BankaKartRow: View {
    let banka: BankaKart
    let onCopyIban: (String) -> Void
    
    var body: some View {
        GlassCard(cornerRadius: 16, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(banka.bankaAdi)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(banka.subeAdi ?? "-")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(banka.dovizTuru == "USD" ? "$\(String(format: "%.2f", banka.bakiye))" : AppFormatters.money(banka.bakiye))
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(banka.dovizTuru ?? "TL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                    }
                }
                
                if let iban = banka.iban, !iban.isEmpty {
                    Divider().background(AppTheme.border)
                    
                    HStack {
                        Text(iban)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(AppTheme.textMuted)
                        Spacer()
                        Button {
                            onCopyIban(iban)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                Text("Kopyala")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                        }
                    }
                }
            }
        }
    }
}

struct BankaHareketRow: View {
    let hareket: BankaHareket
    
    var isGiris: Bool { hareket.girisCikis == "GIRIS" }
    
    var body: some View {
        GlassCard(cornerRadius: 12, padding: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill((isGiris ? AppTheme.success : AppTheme.danger).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: isGiris ? "arrow.down.left" : "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isGiris ? AppTheme.success : AppTheme.danger)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(hareket.cariUnvan ?? hareket.bankaAdi ?? "Banka İşlemi")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("\(hareket.aciklama ?? "") • \(hareket.tarih)")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
                
                Spacer()
                
                Text((isGiris ? "+" : "-") + AppFormatters.money(hareket.tutar))
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(isGiris ? AppTheme.success : AppTheme.danger)
            }
        }
    }
}

struct EftGonderimView: View {
    let bankalar: [BankaKart]
    let onEftComplete: (BankaHareket) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var aliciUnvan: String = ""
    @State private var aliciIban: String = "TR"
    @State private var tutar: String = ""
    @State private var aciklama: String = ""
    @State private var seciliBankaId: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        GlassCard(cornerRadius: 16, padding: 18) {
                            VStack(spacing: 14) {
                                FormField(label: "Alıcı Ünvanı / Adı Soyadı *", text: $aliciUnvan, placeholder: "Firma veya şahıs adı")
                                FormField(label: "Alıcı IBAN *", text: $aliciIban, placeholder: "TR00 0000...")
                                FormField(label: "Gönderilecek Tutar (₺) *", text: $tutar, placeholder: "0.00")
                                FormField(label: "Açıklama / Fatura No", text: $aciklama, placeholder: "Ödeme detayı")
                            }
                        }
                        
                        ActionButton(
                            title: "EFT / Havaleyi Gerçekleştir",
                            icon: "paperplane.fill",
                            color: AppTheme.primary
                        ) {
                            let tutarNum = Double(tutar) ?? 0.0
                            let df = DateFormatter()
                            df.dateFormat = "dd.MM.yyyy"
                            let h = BankaHareket(
                                id: UUID().uuidString,
                                bankaAdi: bankalar.first?.bankaAdi ?? "Garanti BBVA",
                                iban: aliciIban,
                                tarih: df.string(from: Date()),
                                islemTuru: "GONDERILEN_EFT",
                                aciklama: aciklama,
                                cariUnvan: aliciUnvan,
                                tutar: tutarNum,
                                girisCikis: "CIKIS"
                            )
                            onEftComplete(h)
                            Task {
                                let payload: [String: Any] = [
                                    "uuid": UUID().uuidString,
                                    "tenant_id": SupabaseService.shared.tenantId,
                                    "tarih": AppFormatters.isoDate.string(from: Date()),
                                    "islem_turu": "EFT / Havale",
                                    "hareket_turu": "Ödeme",
                                    "giren": 0.0,
                                    "cikan": tutarNum,
                                    "ceken": tutarNum,
                                    "cari_unvan": aliciUnvan,
                                    "evrak_no": "EFT-\(Int.random(in: 100...999))",
                                    "tutar": tutarNum,
                                    "aciklama": aciklama.isEmpty ? "Mobil EFT/Havale Gönderimi: \(aliciIban)" : aciklama,
                                    "is_deleted": false
                                ]
                                if let bData = try? JSONSerialization.data(withJSONObject: payload) {
                                    try? await SupabaseService.shared.insertRaw(into: "banka_hareketler", data: bData)
                                }
                            }
                            dismiss()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Yeni Havale / EFT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
}

