import SwiftUI

public struct SupabaseSetupView: View {
    @ObservedObject var supabaseService = SupabaseService.shared
    @Environment(\.openURL) private var openURL

    @State private var supabaseUrl: String = SupabaseService.shared.baseUrl
    @State private var supabaseKey: String = SupabaseService.shared.anonKey
    @State private var tenantId: String = SupabaseService.shared.tenantId.isEmpty ? "tenant_ermay_master" : SupabaseService.shared.tenantId
    @State private var accessToken: String = ""
    @State private var isTesting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var statusMessage: String? = nil

    public var onComplete: (() -> Void)? = nil

    public init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            Color(hex: "080A0C").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Spacer().frame(height: 30)

                    // Logo & Başlık
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "1E293B"), Color(hex: "0F172A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "10B981").opacity(0.6), lineWidth: 1.5))

                        Image(systemName: "externaldrive.connected.to.line.below.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                    }

                    VStack(spacing: 6) {
                        Text("Supabase Bulut Kurulumu")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text("Kullanıcı girişi yapmadan önce bağlanacağınız Supabase veritabanı bilgilerini yapılandırın.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "94A3B8"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }

                    // 1. Kart: Tarayıcıdan Supabase Girişi & Otomatik Kurulum
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.shield.fill")
                                .foregroundColor(Color(hex: "10B981"))
                            Text("Otomatik Kurulum (Supabase Hesabı İle)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text("Tarayıcıdan Supabase hesabınıza giriş yapıp Access Token (sbp_...) kodunuzu girerek Proje URL ve Anon Key bilgilerini otomatik çekebilirsiniz.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "94A3B8"))

                        Button {
                            if let url = URL(string: "https://supabase.com/dashboard/account/tokens") {
                                openURL(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "safari.fill")
                                Text("Tarayıcıda Supabase Giriş Ekranını Aç")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "60A5FA"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Color(hex: "2563EB").opacity(0.15))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "2563EB").opacity(0.4), lineWidth: 1))
                        }

                        HStack {
                            Image(systemName: "key.radiowaves.forward.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "64748B"))
                            SecureField("Supabase Access Token (sbp_...)", text: $accessToken)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(hex: "12161F"))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))

                        Button {
                            handleAutoResolve()
                        } label: {
                            HStack(spacing: 6) {
                                if isTesting {
                                    ProgressView().tint(.white)
                                }
                                Text("URL ve Anon Key'i Otomatik Al & Bağlan")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color(hex: "10B981"))
                            .cornerRadius(8)
                        }
                        .disabled(isTesting || accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(16)
                    .background(Color(hex: "0F131A"))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "10B981").opacity(0.25), lineWidth: 1))

                    // 2. Kart: Manuel Supabase URL ve Anon Key Girişi
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Manuel Supabase Bağlantı Bilgileri")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)

                        // Supabase Proje URL
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Supabase Proje URL")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "E2E8F0"))

                            HStack {
                                Image(systemName: "link")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "64748B"))
                                TextField("https://xxxx.supabase.co", text: $supabaseUrl)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(Color(hex: "12161F"))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }

                        // Supabase Anon Key
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Supabase Anon / Public Key")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "E2E8F0"))

                            HStack {
                                Image(systemName: "key.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "64748B"))
                                SecureField("eyJhbGciOiJIUzI1NiIs...", text: $supabaseKey)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(Color(hex: "12161F"))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }

                        // Şirket / Tenant Kodu
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Şirket Kodu (Tenant ID)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "E2E8F0"))

                            HStack {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "64748B"))
                                TextField("tenant_ermay_master", text: $tenantId)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(Color(hex: "12161F"))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }

                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color(hex: "EF4444"))
                                Text(error)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "EF4444"))
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "EF4444").opacity(0.12))
                            .cornerRadius(8)
                        }

                        if let status = statusMessage {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "10B981"))
                                Text(status)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "10B981"))
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "10B981").opacity(0.12))
                            .cornerRadius(8)
                        }

                        Button {
                            handleSaveAndContinue()
                        } label: {
                            HStack(spacing: 6) {
                                if isTesting {
                                    ProgressView().tint(.white)
                                    Text("Bağlantı Doğrulanıyor...")
                                } else {
                                    Text("Supabase Bilgilerini Kaydet ve Giriş Ekranına Geç")
                                }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(Color(hex: "2563EB"))
                            .cornerRadius(8)
                        }
                        .disabled(isTesting)
                    }
                    .padding(18)
                    .background(Color(hex: "0F131A"))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))

                    Spacer().frame(height: 30)
                }
                .frame(maxWidth: 360)
                .padding(.horizontal, 20)
            }
        }
    }

    private func handleAutoResolve() {
        errorMessage = nil
        statusMessage = nil
        isTesting = true

        Task {
            do {
                let resolved = try await supabaseService.resolveFromAccessToken(accessToken: accessToken)
                await MainActor.run {
                    self.supabaseUrl = resolved.url
                    self.supabaseKey = resolved.anonKey
                }
                let (ok, msg) = await supabaseService.testConnection(testUrl: resolved.url, testKey: resolved.anonKey)
                await MainActor.run {
                    isTesting = false
                    if ok {
                        statusMessage = "Proje URL ve Anon Key otomatik alındı! Giriş ekranına yönlendiriliyorsunuz..."
                        supabaseService.updateConfiguration(baseUrl: resolved.url, anonKey: resolved.anonKey, tenantId: tenantId)
                        onComplete?()
                    } else {
                        errorMessage = msg
                    }
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleSaveAndContinue() {
        errorMessage = nil
        statusMessage = nil
        let cleanUrl = supabaseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanKey = supabaseKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanUrl.isEmpty || cleanKey.isEmpty {
            errorMessage = "Lütfen Supabase Proje URL ve Anon Key bilgilerini girin veya yukarıdan Access Token ile otomatik çekin."
            return
        }

        isTesting = true
        Task {
            let (ok, msg) = await supabaseService.testConnection(testUrl: cleanUrl, testKey: cleanKey)
            await MainActor.run {
                isTesting = false
                if ok {
                    statusMessage = msg
                    supabaseService.updateConfiguration(baseUrl: cleanUrl, anonKey: cleanKey, tenantId: tenantId)
                    onComplete?()
                } else {
                    errorMessage = msg
                }
            }
        }
    }
}

