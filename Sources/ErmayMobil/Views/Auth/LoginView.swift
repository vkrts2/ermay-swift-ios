import SwiftUI

public struct LoginView: View {
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var supabaseService = SupabaseService.shared
    
    @State private var username: String = ""
    @State private var pass: String = ""
    @State private var rememberMe: Bool = true
    @State private var tenantId: String = SupabaseService.shared.tenantId
    @State private var supabaseUrl: String = SupabaseService.shared.baseUrl
    @State private var supabaseKey: String = SupabaseService.shared.anonKey
    @State private var showAdvancedTenant: Bool = false
    @State private var showSupabaseSetupSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(hex: "080A0C").ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 50)
                    
                    // Main Container (MaxWidth 350 - Desktop LoginView Exact Match)
                    VStack(spacing: 18) {
                        
                        // 1. Logo (vk_logo / VK Monogram)
                        renderLogo()
                        
                        // 2. Titles
                        VStack(spacing: 4) {
                            Text("VK")
                                .font(.system(size: 32, weight: .black))
                                .tracking(3)
                                .foregroundColor(.white)
                            
                            Text("Ön Muhasebe & Finans Yönetimi")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "94A3B8"))
                        }
                        
                        // 3. Form Card
                        VStack(alignment: .leading, spacing: 14) {
                            // Kullanıcı Adı
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Kullanıcı Adı")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "E2E8F0"))
                                
                                HStack {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "64748B"))
                                    TextField("Kullanıcı adınızı girin", text: $username)
                                        .font(.system(size: 14))
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
                            
                            // Şifre
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Şifre")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "E2E8F0"))
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "64748B"))
                                    SecureField("••••••••", text: $pass)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                                .background(Color(hex: "12161F"))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            }
                            
                            // Beni Hatırla (Desktop Birebir)
                            HStack {
                                Button {
                                    rememberMe.toggle()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 16))
                                            .foregroundColor(rememberMe ? Color(hex: "2563EB") : Color(hex: "64748B"))
                                        Text("Beni Hatırla")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(hex: "E2E8F0"))
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            
                            // Hata Mesajı
                            if let error = authService.errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
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
                            
                            // Giriş Yap Butonu (Desktop Birebir #2563EB)
                            Button {
                                handleLogin()
                            } label: {
                                HStack(spacing: 6) {
                                    if authService.isLoading {
                                        ProgressView().tint(.white)
                                        Text("Giriş Yapılıyor...")
                                    } else {
                                        Text("Giriş Yap")
                                    }
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 45)
                                .background(Color(hex: "2563EB"))
                                .cornerRadius(8)
                            }
                            .disabled(authService.isLoading)
                            
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "60A5FA")))
                                    .frame(height: 2)
                                    .padding(.top, -6)
                            }
                        }
                        .padding(20)
                        .background(Color(hex: "0F131A"))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        
                        // 4. Bulut Senkronizasyon Durumu & Gelişmiş Ayar
                        renderSyncBadge()
                    }
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 50)
                }
            }
        }
        .onAppear {
            self.supabaseUrl = supabaseService.baseUrl
            self.supabaseKey = supabaseService.anonKey
            self.tenantId = supabaseService.tenantId
            if let saved = UserDefaults.standard.string(forKey: "saved_login_username"), !saved.isEmpty {
                self.username = saved
            }
        }
        .sheet(isPresented: $showSupabaseSetupSheet) {
            SupabaseSetupView(onComplete: {
                self.supabaseUrl = supabaseService.baseUrl
                self.supabaseKey = supabaseService.anonKey
                self.tenantId = supabaseService.tenantId
                self.showSupabaseSetupSheet = false
            })
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func renderLogo() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1E293B"), Color(hex: "0F172A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "2563EB").opacity(0.6), lineWidth: 1.5))
                .shadow(color: Color(hex: "2563EB").opacity(0.3), radius: 14, x: 0, y: 6)
            
            #if canImport(UIKit)
            if let imgPath = Bundle.main.path(forResource: "vk_logo", ofType: "png"),
               let uiImg = UIImage(contentsOfFile: imgPath) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
            } else {
                VStack(spacing: -2) {
                    Text("VK")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(Color(hex: "60A5FA"))
                }
            }
            #else
            Text("VK")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(Color(hex: "60A5FA"))
            #endif
        }
        .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private func renderSyncBadge() -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(Color(hex: "10B981")).frame(width: 8, height: 8)
                Text("Supabase Bulut Senkronizasyonu Aktif")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "10B981"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "10B981").opacity(0.1))
            .cornerRadius(20)
            
            Button {
                withAnimation {
                    showAdvancedTenant.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Şirket / Tenant: \(tenantId)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "64748B"))
                    Image(systemName: showAdvancedTenant ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "64748B"))
                }
            }
            
            if showAdvancedTenant {
                VStack(spacing: 8) {
                    TextField("Şirket Kodu (tenant_ermay_master)", text: $tenantId)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(8)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(6)
                    
                    TextField("Supabase Proje URL (https://...supabase.co)", text: $supabaseUrl)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(8)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(6)
                    
                    SecureField("Supabase Anon Key", text: $supabaseKey)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(6)
                }
                .padding(.top, 4)
            }
            Button {
                showSupabaseSetupSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 11))
                    Text("Supabase Bağlantı Ayarlarını Değiştir")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(Color(hex: "60A5FA"))
                .padding(.top, 4)
            }
        }
        .padding(.top, 8)
    }
    
    private func handleLogin() {
        SupabaseService.shared.updateConfiguration(
            baseUrl: supabaseUrl,
            anonKey: supabaseKey,
            tenantId: tenantId
        )
        if rememberMe {
            UserDefaults.standard.set(username, forKey: "saved_login_username")
        } else {
            UserDefaults.standard.removeObject(forKey: "saved_login_username")
        }
        
        Task {
            _ = await authService.login(username: username, pass: pass, tenantId: tenantId)
        }
    }
}
