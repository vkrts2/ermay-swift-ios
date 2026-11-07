import SwiftUI

public struct BanknotItem: Identifiable {
    public let id: Int
    public let deger: Double
    public var adet: Int
    
    public var toplam: Double {
        deger * Double(adet)
    }
}

public struct KasaSayimView: View {
    @State private var banknotlar: [BanknotItem] = [
        BanknotItem(id: 200, deger: 200, adet: 0),
        BanknotItem(id: 100, deger: 100, adet: 0),
        BanknotItem(id: 50, deger: 50, adet: 0),
        BanknotItem(id: 20, deger: 20, adet: 0),
        BanknotItem(id: 10, deger: 10, adet: 0),
        BanknotItem(id: 5, deger: 5, adet: 0)
    ]
    @State private var madeniToplam: String = "0"
    @State private var sistemKasaBakiyesi: Double = 45850.50
    @State private var isFinalizing: Bool = false
    @State private var showSavedAlert: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    public init(sistemBakiye: Double = 45850.50) {
        _sistemKasaBakiyesi = State(initialValue: sistemBakiye)
    }
    
    public var fizikiToplam: Double {
        let banknotToplam = banknotlar.reduce(0.0) { $0 + $1.toplam }
        let madeni = Double(madeniToplam) ?? 0.0
        return banknotToplam + madeni
    }
    
    public var kasaFarki: Double {
        fizikiToplam - sistemKasaBakiyesi
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Günlük Kasa Sayımı")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Özet Karşılaştırma Kartı
                        GlassCard(cornerRadius: 18, padding: 18) {
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sistem Kasa Bakiyesi")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppTheme.textMuted)
                                        Text(AppFormatters.money(sistemKasaBakiyesi))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Fiziki Sayılan")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppTheme.textMuted)
                                        Text(AppFormatters.money(fizikiToplam))
                                            .font(.system(size: 16, weight: .heavy))
                                            .foregroundColor(AppTheme.primary)
                                    }
                                }
                                
                                Divider().background(AppTheme.border)
                                
                                HStack {
                                    Text(kasaFarki == 0 ? "KASA MUTABIK" : (kasaFarki > 0 ? "KASA FAZLASI" : "KASA NOKSANI"))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(kasaFarki == 0 ? AppTheme.success : (kasaFarki > 0 ? Color(hex: "00FF87") : AppTheme.danger))
                                    Spacer()
                                    Text((kasaFarki > 0 ? "+" : "") + AppFormatters.money(kasaFarki))
                                        .font(.system(size: 18, weight: .heavy))
                                        .foregroundColor(kasaFarki == 0 ? AppTheme.success : (kasaFarki > 0 ? Color(hex: "00FF87") : AppTheme.danger))
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Banknot Küpleri
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Banknot Adetleri")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                ForEach(banknotlar.indices, id: \.self) { idx in
                                    let b = banknotlar[idx]
                                    GlassCard(cornerRadius: 12, padding: 12) {
                                        HStack {
                                            Text("₺\(Int(b.deger))")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                                .frame(width: 50, alignment: .leading)
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 8) {
                                                Button {
                                                    if banknotlar[idx].adet > 0 {
                                                        banknotlar[idx].adet -= 1
                                                    }
                                                } label: {
                                                    Image(systemName: "minus.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(AppTheme.textSecondary)
                                                }
                                                
                                                Text("\(banknotlar[idx].adet)")
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                    .frame(minWidth: 32)
                                                
                                                Button {
                                                    banknotlar[idx].adet += 1
                                                } label: {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(AppTheme.primary)
                                                }
                                            }
                                            
                                            Text(AppFormatters.money(b.toplam))
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                                .frame(width: 80, alignment: .trailing)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        GlassCard(cornerRadius: 14, padding: 14) {
                            FormField(label: "Bozuk / Madeni Para Toplamı (₺)", text: $madeniToplam, placeholder: "0.00")
                        }
                        .padding(.horizontal)
                        
                        ActionButton(
                            title: isFinalizing ? "Kaydediliyor..." : "Kasa Sayımını Tamamla",
                            icon: "checkmark.seal.fill",
                            color: AppTheme.success
                        ) {
                            finalizeKasaSayim()
                        }
                        .padding(.horizontal)
                        
                        Spacer().frame(height: 70)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Kasa Sayımı Başarılı", isPresented: $showSavedAlert) {
                Button("Tamam") { dismiss() }
            } message: {
                Text("Günlük kasa sayım fişi kaydedildi ve mutabakat sağlandı.")
            }
        }
    }
    
    private func finalizeKasaSayim() {
        isFinalizing = true
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let bugun = df.string(from: Date())
        
        let fis = KasaHareket(
            id: UUID().uuidString,
            tarih: bugun,
            islemTuru: kasaFarki >= 0 ? "KASA_FAZLASI" : "KASA_NOKSANI",
            cariUnvan: "KASA MUTABAKATI",
            belgeNo: "SYM-\(Int.random(in: 100...999))",
            tutar: abs(kasaFarki),
            aciklama: "Günlük Kasa Sayım Fişi - Fiziki: \(AppFormatters.money(fizikiToplam))"
        )
        
        Task {
            let payload: [String: Any] = [
                "uuid": UUID().uuidString,
                "tenant_id": SupabaseService.shared.tenantId,
                "tarih": bugun,
                "islem_turu": kasaFarki >= 0 ? "KASA_FAZLASI" : "KASA_NOKSANI",
                "hareket_turu": kasaFarki >= 0 ? "Tahsilat" : "Ödeme",
                "giren": kasaFarki >= 0 ? abs(kasaFarki) : 0.0,
                "cikan": kasaFarki < 0 ? abs(kasaFarki) : 0.0,
                "gelir": kasaFarki >= 0 ? abs(kasaFarki) : 0.0,
                "gider": kasaFarki < 0 ? abs(kasaFarki) : 0.0,
                "cari_unvan": "KASA MUTABAKATI",
                "evrak_no": "SYM-\(Int.random(in: 100...999))",
                "tutar": abs(kasaFarki),
                "aciklama": "Günlük Kasa Sayım Fişi - Fiziki: \(AppFormatters.money(fizikiToplam))",
                "is_deleted": false
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload) {
                try? await SupabaseService.shared.insertRaw(into: "kasa_hareketler", data: data)
            }
            await MainActor.run {
                isFinalizing = false
                showSavedAlert = true
            }
        }
    }
}

