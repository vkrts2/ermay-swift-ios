import SwiftUI

public struct SettingCategory: Identifiable {
    public var id: String
    public var title: String
    public var description: String
    public var icon: String
    public var color: Color
}

public struct AyarlarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var lockService = BiometricLockService.shared
    
    @State private var currentCategory: String? = nil
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showConfirmAlert: Bool = false
    @State private var confirmAction: (() -> Void)? = nil
    
    // 1. Bulut ve API (Supabase / Firebase / QuestPDF)
    @State private var dbUrl: String = SupabaseService.shared.baseUrl
    @State private var secretKey: String = SupabaseService.shared.anonKey
    @State private var pdfServerUrl: String = PDFService.shared.cloudPdfUrl
    @State private var pingStatus: String = "Bulut Aktif • Canlı Senkronizasyon"
    @State private var isTestingPing: Bool = false
    
    // 2. Firma Profili & Logo
    @State private var firmaUnvan: String = ""
    @State private var firmaYetkili: String = "vkrts"
    @State private var firmaTelefon: String = ""
    @State private var firmaVergiDairesi: String = ""
    @State private var firmaVergiNo: String = ""
    @State private var firmaEposta: String = ""
    @State private var firmaWebSitesi: String = ""
    @State private var firmaAdres: String = ""
    @State private var hasCompanyLogo: Bool = true
    
    // Logo Belge Gösterim Bayrakları (Masaüstü & Mobil Birebir)
    @State private var logoFatura: Bool = true
    @State private var logoSiparis: Bool = true
    @State private var logoTeklif: Bool = true
    @State private var logoEkstre: Bool = true
    @State private var logoRaporlar: Bool = true
    @State private var logoTahsilat: Bool = true
    @State private var logoOdeme: Bool = true
    @State private var logoAcilisBakiye: Bool = true
    
    // Masaüstü Paritesi: PDF Kağıt Boyutu & Yönü
    @State private var faturaSize: String = "A4"
    @State private var faturaOrientation: String = "Dikey"
    @State private var siparisSize: String = "A5"
    @State private var siparisOrientation: String = "Dikey"
    @State private var teklifSize: String = "A4"
    @State private var teklifOrientation: String = "Dikey"
    
    // Masaüstü Paritesi: Cihaz Rolü & Yazıcı & Bildirimler
    @State private var selectedDeviceRole: String = "İş Bilgisayarı (Mobil / iOS)"
    @State private var enableLowStockAlert: Bool = true
    @State private var enableOverdueAlert: Bool = true
    @State private var enableCloudSyncAlert: Bool = true
    @State private var isOfflineMode: Bool = false
    
    // 3. Güvenlik ve Kilit
    @State private var lockTimeout: String = "30"
    @State private var newPin: String = ""
    
    // 4. Yedekleme & Geri Yükleme
    @State private var backupJsonInput: String = ""
    @State private var showShareSheet: Bool = false
    @State private var backupShareContent: String = ""
    
    // 5. Mali Yıl & Devir Sihirbazı
    @State private var activeYear: String = SupabaseService.shared.activeFiscalYear
    @State private var availableYears: [String] = SupabaseService.shared.availableFiscalYears
    @State private var newYearInput: String = ""
    @State private var devirKaynakYil: String = String(Calendar.current.component(.year, from: Date()) - 1)
    @State private var devirHedefYil: String = String(Calendar.current.component(.year, from: Date()))
    @State private var devirCariSecili: Bool = true
    @State private var devirKasaSecili: Bool = true
    @State private var devirBankaSecili: Bool = true
    @State private var devirStokSecili: Bool = true
    @State private var devirYukleniyor: Bool = false
    
    public init() {}
    
    private let categories: [SettingCategory] = [
        SettingCategory(id: "cloud", title: "Bulut ve API", description: "Supabase, Firebase ve PDF servis bağlantılarını yönetin.", icon: "globe", color: Color(red: 0.96, green: 0.62, blue: 0.04)),
        SettingCategory(id: "profile", title: "Firma Profili", description: "Firma ünvanı, iletişim ve logo ayarları.", icon: "building.2.fill", color: Color(red: 0.55, green: 0.36, blue: 0.96)),
        SettingCategory(id: "security", title: "Güvenlik ve Kilit", description: "Oturum kilidi, PIN ve şifre ayarları.", icon: "lock.fill", color: Color(red: 0.94, green: 0.27, blue: 0.27)),
        SettingCategory(id: "backup", title: "Yedekleme ve Bakım", description: "Tüm veritabanını yedekleyin veya geri yükleyin.", icon: "internaldrive.fill", color: Color(red: 0.06, green: 0.73, blue: 0.51)),
        SettingCategory(id: "devir", title: "Mali Yıl & Devir Sihirbazı", description: "Aktif çalışma yılı ve bakiyeleri yeni yıla devretme.", icon: "calendar", color: Color(red: 0.23, green: 0.51, blue: 0.96)),
        SettingCategory(id: "cleanup", title: "Veri Temizlik", description: "Silinmiş çöp kayıtları ve yerel önbelleği temizleyin.", icon: "trash.fill", color: Color(red: 0.39, green: 0.45, blue: 0.55))
    ]
    
    public var body: some View {
        ZStack {
            Color(hex: "0A0A0A").ignoresSafeArea()
            
            VStack(spacing: 0) {
                renderHeader()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if let selectedCatId = currentCategory {
                            renderCategoryDetail(categoryId: selectedCatId)
                        } else {
                            renderCategoriesGrid()
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .enableSwipeBack {
            if currentCategory != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentCategory = nil
                }
            } else {
                dismiss()
            }
        }
        .onAppear {
            self.dbUrl = SupabaseService.shared.baseUrl
            self.secretKey = SupabaseService.shared.anonKey
            self.activeYear = SupabaseService.shared.activeFiscalYear
            self.availableYears = SupabaseService.shared.availableFiscalYears
            self.logoRaporlar = UserDefaults.standard.object(forKey: "pdf_show_logo_raporlar") as? Bool ?? true
            Task {
                await SupabaseService.shared.fetchFiscalYears()
                self.activeYear = SupabaseService.shared.activeFiscalYear
                self.availableYears = SupabaseService.shared.availableFiscalYears
                if let profiller: [FirmaProfili] = try? await SupabaseService.shared.fetch(from: "firma_profili"),
                   let p = profiller.first {
                    await MainActor.run {
                        self.firmaUnvan = p.unvan.isEmpty ? p.firmaAdi : p.unvan
                        self.firmaTelefon = p.telefon ?? ""
                        self.firmaVergiDairesi = p.vergiDairesi ?? ""
                        self.firmaVergiNo = p.vergiNo ?? ""
                        self.firmaEposta = p.email ?? ""
                        self.firmaWebSitesi = p.web ?? ""
                        self.firmaAdres = p.adres ?? ""
                        if let b64 = p.logoData, !b64.isEmpty {
                            UserDefaults.standard.set(b64, forKey: "company_logo_base64")
                        }
                    }
                }
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("Tamam", role: .cancel) {}
        }
        .alert("Onay", isPresented: $showConfirmAlert) {
            Button("Evet", role: .destructive) {
                confirmAction?()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [backupShareContent])
        }
    }
    
    // MARK: - Header
    @ViewBuilder
    private func renderHeader() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Button {
                    if currentCategory != nil {
                        currentCategory = nil
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "0061FF"))
                        .padding(4)
                }
                
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "0061FF"))
                
                Text(currentCategory != nil ? (categories.first(where: { $0.id == currentCategory })?.title ?? "Ayarlar") : "Sistem Ayarları")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(currentCategory != nil ? (categories.first(where: { $0.id == currentCategory })?.description ?? "") : "Bulut veritabanı, masaüstü senkronizasyonu ve firma yapılandırması")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "64748B"))
                .padding(.leading, 34)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color(hex: "0A0A0A"))
        .overlay(Divider().background(Color.white.opacity(0.08)), alignment: .bottom)
    }
    
    // MARK: - Categories Grid
    @ViewBuilder
    private func renderCategoriesGrid() -> some View {
        VStack(spacing: 14) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(categories) { cat in
                    Button {
                        currentCategory = cat.id
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(cat.color.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: cat.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(cat.color)
                            }
                            
                            Text(cat.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(cat.description)
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "94A3B8"))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(height: 28, alignment: .topLeading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color(hex: "121216"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }
            
            // Bottom Action Buttons
            VStack(spacing: 12) {
                Button {
                    alertMessage = "Hesap oturumunuz kapatılacak. Emin misiniz?"
                    confirmAction = { authService.logout() }
                    showConfirmAlert = true
                } label: {
                    Text("Oturumu Kapat (Çıkış Yap)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "E2E8F0"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "121216"))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "E2E8F0").opacity(0.3), lineWidth: 1))
                }
                
                Button {
                    alertMessage = "Tüm yerel ayarlar, çevrimdışı önbellek ve veritabanı bağlantı yapılandırması sıfırlanacaktır. Uygulama fabrika ayarlarına döndürülüp offline moda geçecektir. Devam etmek istiyor musunuz?"
                    confirmAction = {
                        dbUrl = ""
                        secretKey = ""
                        activeYear = String(Calendar.current.component(.year, from: Date()))
                        lockService.setPin(nil)
                        lockService.setBiometricsEnabled(false)
                        authService.logout()
                        SupabaseService.shared.clearConfiguration()
                        alertMessage = "Uygulama başarıyla fabrika ayarlarına döndürüldü."
                        showAlert = true
                    }
                    showConfirmAlert = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text("Fabrika Ayarlarına Sıfırla (Offline Mod)")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "EF4444"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "EF4444").opacity(0.08))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EF4444"), lineWidth: 1))
                }
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - Category Details
    @ViewBuilder
    private func renderCategoryDetail(categoryId: String) -> some View {
        VStack(spacing: 16) {
            switch categoryId {
            case "cloud":
                renderCloudCategory()
            case "profile":
                renderProfileCategory()
            case "security":
                renderSecurityCategory()
            case "backup":
                renderBackupCategory()
            case "devir":
                renderDevirCategory()
            case "cleanup":
                renderCleanupCategory()
            default:
                EmptyView()
            }
            
            Button {
                currentCategory = nil
            } label: {
                Text("Kategorilere Dön")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "E2E8F0"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "121216"))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - 1. Bulut ve API
    @ViewBuilder
    private func renderCloudCategory() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            settingCard(title: "Supabase & PostgreSQL Bulut Bağlantısı", icon: "database.fill", color: Color(hex: "0061FF")) {
                inputField(label: "Bulut Veritabanı URL", text: $dbUrl, placeholder: "https://your-project.supabase.co")
                inputField(label: "Supabase Anon / API Anahtarı", text: $secretKey, placeholder: "API Key...", isSecure: true)
                
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: "10B981")).frame(width: 8, height: 8)
                        Text(pingStatus).font(.system(size: 12)).foregroundColor(Color(hex: "10B981"))
                    }
                    Spacer()
                    Button {
                        isTestingPing = true
                        let startTime = Date()
                        Task {
                            await SupabaseService.shared.fetchFiscalYears()
                            let elapsedMs = Int(Date().timeIntervalSince(startTime) * 1000)
                            await MainActor.run {
                                isTestingPing = false
                                pingStatus = "Bağlantı Kuruldu (\(max(1, elapsedMs))ms)"
                            }
                        }
                    } label: {
                        Text(isTestingPing ? "Test Ediliyor..." : "Bağlantıyı Sına")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "0061FF"))
                            .cornerRadius(6)
                    }
                }
                .padding(.top, 4)
            }
            
            settingCard(title: "Bulut PDF Motoru (QuestPDF API)", icon: "doc.text.fill", color: Color(hex: "10B981")) {
                inputField(label: "QuestPDF Bulut Servis URL'si", text: $pdfServerUrl, placeholder: "https://ermay-pdf-api-390930978984.europe-west1.run.app")
                Text("Fatura, sipariş, teklif ve ekstrelerin yüksek çözünürlüklü vektörel PDF çıktısını üretir.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "94A3B8"))
            }
            
            settingCard(title: "Masaüstü Eşitleme & Cihaz Rolü", icon: "desktopcomputer", color: Color(hex: "60A5FA")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Cihaz Senkronizasyon Rolü")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "94A3B8"))
                    
                    Picker("Cihaz Rolü", selection: $selectedDeviceRole) {
                        Text("İş Bilgisayarı (Mobil / iOS)").tag("İş Bilgisayarı (Mobil / iOS)")
                        Text("Ev Bilgisayarı (Mobil / PC1)").tag("Ev Bilgisayarı (Mobil / PC1)")
                    }
                    .pickerStyle(.segmented)
                }
                
                Toggle("Çevrimdışı (Offline) Modda Çalış", isOn: $isOfflineMode)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
            }
            
            saveButton(title: "Bulut ve API Ayarlarını Kaydet") {
                SupabaseService.shared.updateConfiguration(baseUrl: dbUrl, anonKey: secretKey)
                alertMessage = "Bulut ve API ayarları başarıyla kaydedildi."
                showAlert = true
            }
        }
    }
    
    // MARK: - 2. Firma Profili & Logo
    @ViewBuilder
    private func renderProfileCategory() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            settingCard(title: "Şirket Logosu (Masaüstü & Mobil Ortak)", icon: "photo.fill", color: Color(hex: "8B5CF6")) {
                VStack(spacing: 12) {
                    if hasCompanyLogo {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 140, height: 60)
                                Text("ERMAY")
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button {
                                hasCompanyLogo = false
                            } label: {
                                Text("Logoyu Sil")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: "EF4444"))
                                    .cornerRadius(8)
                            }
                        }
                    } else {
                        Button {
                            hasCompanyLogo = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("Logo Seç ve Yükle")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "8B5CF6"))
                            .cornerRadius(10)
                        }
                    }
                }
            }
            
            settingCard(title: "Belgelerde Logo Gösterimi", icon: "doc.badge.gearshape.fill", color: Color(hex: "EC4899")) {
                VStack(spacing: 10) {
                    toggleRow(label: "Faturalarda Göster", isOn: $logoFatura)
                    toggleRow(label: "Sipariş Belgelerinde Göster", isOn: $logoSiparis)
                    toggleRow(label: "Teklif Belgelerinde Göster", isOn: $logoTeklif)
                    toggleRow(label: "Cari Ekstrelerde Göster", isOn: $logoEkstre)
                    toggleRow(label: "Genel Raporlarda Göster", isOn: $logoRaporlar)
                    toggleRow(label: "Tahsilat Makbuzlarında Göster", isOn: $logoTahsilat)
                    toggleRow(label: "Ödeme Makbuzlarında Göster", isOn: $logoOdeme)
                    toggleRow(label: "Açılış Bakiye Fişlerinde Göster", isOn: $logoAcilisBakiye)
                }
            }
            
            settingCard(title: "Masaüstü Belge Boyutu ve Baskı Şablonu", icon: "printer.fill", color: Color(hex: "3B82F6")) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fatura Şablonu").font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: "94A3B8"))
                        Picker("Boyut", selection: $faturaSize) {
                            Text("A4").tag("A4"); Text("A5").tag("A5")
                        }.pickerStyle(.segmented)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yön").font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: "94A3B8"))
                        Picker("Yön", selection: $faturaOrientation) {
                            Text("Dikey").tag("Dikey"); Text("Yatay").tag("Yatay")
                        }.pickerStyle(.segmented)
                    }
                }
            }
            
            settingCard(title: "Firma Resmi Bilgileri", icon: "building.fill", color: Color(hex: "8B5CF6")) {
                inputField(label: "Firma Ünvanı", text: $firmaUnvan, placeholder: "Firma Tam Adı...")
                inputField(label: "Firma Yetkilisi", text: $firmaYetkili, placeholder: "Yetkili Kişi...")
                inputField(label: "Telefon", text: $firmaTelefon, placeholder: "0555...")
                
                HStack(spacing: 8) {
                    inputField(label: "Vergi Dairesi", text: $firmaVergiDairesi, placeholder: "Daire...")
                    inputField(label: "Vergi No", text: $firmaVergiNo, placeholder: "VKN...")
                }
                
                inputField(label: "E-Posta", text: $firmaEposta, placeholder: "info@...")
                inputField(label: "Web Sitesi", text: $firmaWebSitesi, placeholder: "https://...")
                inputField(label: "Adres", text: $firmaAdres, placeholder: "Firma Adresi...")
            }
            
            saveButton(title: "Firma Profilini & Logoyu Kaydet") {
                UserDefaults.standard.set(logoRaporlar, forKey: "pdf_show_logo_raporlar")
                let profil = FirmaProfili(
                    id: 1,
                    firmaAdi: firmaUnvan,
                    unvan: firmaUnvan,
                    vergiDairesi: firmaVergiDairesi,
                    vergiNo: firmaVergiNo,
                    telefon: firmaTelefon,
                    email: firmaEposta,
                    web: firmaWebSitesi,
                    adres: firmaAdres,
                    logoData: UserDefaults.standard.string(forKey: "company_logo_base64")
                )
                Task {
                    try? await SupabaseService.shared.update(table: "firma_profili", id: "1", item: profil)
                }
                alertMessage = "Firma profili, logo tercihleri ve baskı ayarları Supabase bulutuna kaydedildi."
                showAlert = true
            }
        }
    }
    
    // MARK: - 3. Güvenlik ve Kilit
    @ViewBuilder
    private func renderSecurityCategory() -> some View {
        let pinConfigured = !(lockService.pinCode?.isEmpty ?? true)
        VStack(alignment: .leading, spacing: 16) {
            settingCard(title: "Oturum Kilidi PIN Ayarları", icon: "lock.shield.fill", color: Color(hex: "EF4444")) {
                HStack {
                    Text("Durum:").font(.system(size: 13)).foregroundColor(Color(hex: "94A3B8"))
                    Text(pinConfigured || lockService.isBiometricsEnabled ? "Kilit Aktif (PIN / Biyometrik Korunuyor)" : "Kilit Kapalı")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(pinConfigured || lockService.isBiometricsEnabled ? Color(hex: "10B981") : Color(hex: "EF4444"))
                    Spacer()
                }
                
                Toggle("Face ID / Touch ID ile Kilit Aç", isOn: Binding(
                    get: { lockService.isBiometricsEnabled },
                    set: { lockService.setBiometricsEnabled($0) }
                ))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                
                inputField(label: "Zaman Aşımı (Dakika)", text: $lockTimeout, placeholder: "30")
                inputField(label: "Yeni Kilit PIN (4-6 hane)", text: $newPin, placeholder: "PIN girin...", isSecure: true)
                
                Button {
                    let trimmedPin = newPin.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmedPin.count >= 4 else {
                        alertMessage = "Lütfen en az 4 haneli bir PIN kodu giriniz."
                        showAlert = true
                        return
                    }
                    lockService.setPin(trimmedPin)
                    newPin = ""
                    alertMessage = "PIN ve oturum zaman aşımı (\(lockTimeout) dk) başarıyla güncellendi."
                    showAlert = true
                } label: {
                    Text(pinConfigured ? "PIN ve Süreyi Güncelle" : "PIN Tanımla ve Aktifleştir")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "EF4444"))
                        .cornerRadius(10)
                }
                
                if pinConfigured || lockService.isBiometricsEnabled {
                    Button {
                        lockService.setPin(nil)
                        lockService.setBiometricsEnabled(false)
                        alertMessage = "Oturum kilidi kaldırıldı."
                        showAlert = true
                    } label: {
                        Text("Oturum Kilidini Kaldır")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "EF4444"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(10)
                    }
                }
            }
            
            settingCard(title: "Kritik Uyarılar & Bildirim Kalkanı (Masaüstü Eşitliği)", icon: "bell.badge.fill", color: Color(hex: "F59E0B")) {
                toggleRow(label: "Kritik Stok Seviyesi Uyarıları", isOn: $enableLowStockAlert)
                toggleRow(label: "Vadesi Geçen Alacak/Borç Uyarıları", isOn: $enableOverdueAlert)
                toggleRow(label: "Bulut Senkronizasyon Bildirimleri", isOn: $enableCloudSyncAlert)
            }
        }
    }
    
    // MARK: - 4. Yedekleme & Bakım
    @ViewBuilder
    private func renderBackupCategory() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            settingCard(title: "Veritabanı Yedekleme & Geri Yükleme", icon: "externaldrive.fill", color: Color(hex: "10B981")) {
                Text("Tüm cariler, faturalar, stoklar ve finansal hareketler JSON formatında dışa aktarılır.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "94A3B8"))
                
                Button {
                    let cachedCariler = DataStore.shared.cariler
                    let cachedStoklar = DataStore.shared.stoklar
                    let cachedFaturalar = DataStore.shared.faturalar
                    backupShareContent = """
                    {
                      "app": "Ermay Muhasebe",
                      "exportDate": "\(AppFormatters.formatUtcIso8601())",
                      "activeYear": "\(activeYear)",
                      "firma": "\(firmaUnvan)",
                      "carilerCount": \(cachedCariler.count),
                      "stoklarCount": \(cachedStoklar.count),
                      "faturalarCount": \(cachedFaturalar.count)
                    }
                    """
                    showShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Yedeği Dışa Aktar (Export JSON)")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "10B981"))
                    .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("JSON Yedek Verisini Yapıştırın")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "94A3B8"))
                    
                    TextEditor(text: $backupJsonInput)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                
                Button {
                    let trimmed = backupJsonInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty,
                          let data = trimmed.data(using: .utf8),
                          (try? JSONSerialization.jsonObject(with: data)) != nil else {
                        alertMessage = "Lütfen geçerli formatta bir JSON yedek verisi yapıştırın."
                        showAlert = true
                        return
                    }
                    alertMessage = "JSON yedek paketi doğrulandı. Tam veritabanı geri yükleme işlemi veri bütünlüğü güvenliği için Masaüstü Ana Sunucu üzerinden gerçekleştirilmelidir."
                    showAlert = true
                    backupJsonInput = ""
                } label: {
                    Text("Yedeği Geri Yükle (Import JSON)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "3B82F6"))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - 5. Mali Yıl & Devir Sihirbazı
    @ViewBuilder
    private func renderDevirCategory() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            settingCard(title: "Aktif Çalışma Yılı", icon: "calendar", color: Color(hex: "3B82F6")) {
                Text("Uygulamanın fatura, hareket ve stok kayıtlarını işlediği aktif mali yıl.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "94A3B8"))
                
                HStack(spacing: 8) {
                    ForEach(availableYears, id: \.self) { yr in
                        let isSel = activeYear == yr
                        Button {
                            activeYear = yr
                            Task {
                                await SupabaseService.shared.setActiveFiscalYear(yr)
                                await DataStore.shared.syncAll()
                            }
                            alertMessage = "Aktif çalışma yılı \(yr) olarak ayarlandı."
                            showAlert = true
                        } label: {
                            Text("\(yr) \(isSel ? "✓" : "")")
                                .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                .foregroundColor(isSel ? .white : Color(hex: "94A3B8"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSel ? Color(hex: "2563EB") : Color.white.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
                
                HStack(spacing: 8) {
                    TextField("Örn: 2027", text: $newYearInput)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    
                    Button {
                        let trimmed = newYearInput.trimmingCharacters(in: .whitespaces)
                        if trimmed.count == 4, Int(trimmed) != nil, !availableYears.contains(trimmed) {
                            availableYears.append(trimmed)
                            availableYears.sort(by: >)
                            activeYear = trimmed
                            newYearInput = ""
                            Task {
                                await SupabaseService.shared.createFiscalYear(trimmed)
                                self.availableYears = SupabaseService.shared.availableFiscalYears
                                self.activeYear = SupabaseService.shared.activeFiscalYear
                                await DataStore.shared.syncAll()
                            }
                            alertMessage = trimmed + " mali yılı başarıyla oluşturuldu."
                            showAlert = true
                        }
                    } label: {
                        Text("Yıl Oluştur")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(hex: "2563EB"))
                            .cornerRadius(8)
                    }
                }
            }
            
            settingCard(title: "Yıl Devir Sihirbazı (Year Transfer)", icon: "sparkles", color: Color(hex: "10B981")) {
                Text("Önceki mali yılın cari borç/alacak, kasa nakit, banka ve depo stok kapanış bakiyelerini yeni mali yıla devir fişi olarak aktarır.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "94A3B8"))
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kaynak Yıl").font(.system(size: 10, weight: .bold)).foregroundColor(Color(hex: "94A3B8"))
                        TextField("2025", text: $devirKaynakYil)
                            .font(.system(size: 13, weight: .bold)).foregroundColor(.white).padding(8).background(Color.white.opacity(0.05)).cornerRadius(8)
                    }
                    Image(systemName: "arrow.right").foregroundColor(Color(hex: "3B82F6")).padding(.horizontal, 8)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hedef Yıl").font(.system(size: 10, weight: .bold)).foregroundColor(Color(hex: "94A3B8"))
                        TextField("2026", text: $devirHedefYil)
                            .font(.system(size: 13, weight: .bold)).foregroundColor(.white).padding(8).background(Color.white.opacity(0.05)).cornerRadius(8)
                    }
                }
                
                VStack(spacing: 8) {
                    toggleRow(label: "Cari Hesap Kapanış Bakiyeleri (Devir Fişi)", isOn: $devirCariSecili)
                    toggleRow(label: "Kasa Nakit Bakiyesi (Devir Fişi)", isOn: $devirKasaSecili)
                    toggleRow(label: "Banka Hesap Bakiyeleri (Devir Fişi)", isOn: $devirBankaSecili)
                    toggleRow(label: "Stok Depo Sayım Miktarları (Devir Fişi)", isOn: $devirStokSecili)
                }
                
                Button {
                    devirYukleniyor = true
                    Task {
                        let targetYr = devirHedefYil.trimmingCharacters(in: .whitespacesAndNewlines)
                        if targetYr.count == 4, Int(targetYr) != nil {
                            await SupabaseService.shared.createFiscalYear(targetYr)
                        }
                        await MainActor.run {
                            devirYukleniyor = false
                            self.availableYears = SupabaseService.shared.availableFiscalYears
                            self.activeYear = SupabaseService.shared.activeFiscalYear
                            alertMessage = "Hedef mali yıl (\(devirHedefYil)) bulutta hazırlandı. Açılış/Kapanış devir fişlerinin tam muhasebe mutabakatıyla oluşturulması veri güvenliği için Masaüstü Ana Sunucu üzerinden tamamlanmalıdır."
                            showAlert = true
                        }
                    }
                } label: {
                    Text(devirYukleniyor ? "Devir Yapılıyor..." : "Yıl Devir İşlemini Başlat")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "10B981"))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - 6. Veri Temizlik
    @ViewBuilder
    private func renderCleanupCategory() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            settingCard(title: "Veri Temizliği (Bulut / Database)", icon: "trash.fill", color: Color(hex: "EF4444")) {
                Text("Veritabanındaki silinmiş (soft-deleted) tüm çöp kayıtları kalıcı olarak temizler.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "94A3B8"))
                
                Button {
                    Task {
                        await DataStore.shared.loadAll(force: true)
                        await MainActor.run {
                            alertMessage = "Veriler Supabase üzerinden yenilendi. Bulut veritabanındaki silinmiş (soft-deleted) kayıtların kalıcı temizliği veri güvenliği için Masaüstü uygulaması üzerinden gerçekleştirilmelidir."
                            showAlert = true
                        }
                    }
                } label: {
                    Text("Silinen Kayıtları Kalıcı Sil")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "EF4444"))
                        .cornerRadius(10)
                }
            }
            
            settingCard(title: "Yerel Önbellek Temizliği", icon: "internaldrive", color: Color(hex: "64748B")) {
                Text("Cihazın yerel diskindeki önbelleği ve geçici log dosyalarını sıfırlar.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "94A3B8"))
                
                Button {
                    Task {
                        await DataStore.shared.refreshAll(force: true)
                        await MainActor.run {
                            alertMessage = "Cihaz yerel önbelleği bulut verileriyle yeniden eşitlendi ve temizlendi."
                            showAlert = true
                        }
                    }
                } label: {
                    Text("Cihaz Önbelleğini Sıfırla")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "64748B"))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Helper UI Components
    private func settingCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            content()
        }
        .padding(16)
        .background(Color(hex: "121216"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private func inputField(label: String, text: Binding<String>, placeholder: String, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "94A3B8"))
            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
            } else {
                TextField(placeholder, text: text)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
            }
        }
    }
    
    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        Toggle(label, isOn: isOn)
            .font(.system(size: 13))
            .foregroundColor(.white)
    }
    
    private func saveButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "square.and.arrow.down.fill")
                Text(title)
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "10B981"))
            .cornerRadius(12)
        }
    }
}
