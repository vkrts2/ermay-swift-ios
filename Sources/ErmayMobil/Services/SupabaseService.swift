import Foundation
import Combine
import KeychainAccess

public final class SupabaseService: ObservableObject, @unchecked Sendable {
    public static let shared = SupabaseService()
    
    public static let defaultBaseUrl = ""
    public static let defaultAnonKey = ""
    
    @Published public var baseUrl: String = SupabaseService.defaultBaseUrl
    @Published public var anonKey: String = SupabaseService.defaultAnonKey
    @Published public var tenantId: String = "tenant_ermay_master"
    @Published public var isConfigured: Bool = false
    public var authToken: String? = nil
    
    private let keychain = Keychain(service: "com.ermay.muhasebe").accessibility(.afterFirstUnlock)
    private let keychainAnonKey = "supabase_secure_anon_key"
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        
        if let savedUrl = UserDefaults.standard.string(forKey: "supabase_base_url")?.trimmingCharacters(in: .whitespacesAndNewlines),
           !savedUrl.isEmpty {
            self.baseUrl = savedUrl.hasSuffix("/") ? String(savedUrl.dropLast()) : savedUrl
        }
        if let secureKey = try? keychain.getString(keychainAnonKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !secureKey.isEmpty {
            self.anonKey = secureKey
        } else if let legacyKey = UserDefaults.standard.string(forKey: "supabase_anon_key")?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !legacyKey.isEmpty {
            self.anonKey = legacyKey
            try? keychain.set(legacyKey, key: keychainAnonKey)
            UserDefaults.standard.removeObject(forKey: "supabase_anon_key")
        }
        if let savedTenant = UserDefaults.standard.string(forKey: "supabase_tenant_id")?.trimmingCharacters(in: .whitespacesAndNewlines),
           !savedTenant.isEmpty {
            self.tenantId = savedTenant
        }
        self.isConfigured = !self.baseUrl.isEmpty && !self.anonKey.isEmpty
    }
    
    public func updateConfiguration(baseUrl: String, anonKey: String, tenantId: String? = nil) {
        let cleanUrl = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanKey = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanUrl.isEmpty {
            self.baseUrl = cleanUrl.hasSuffix("/") ? String(cleanUrl.dropLast()) : cleanUrl
            UserDefaults.standard.set(self.baseUrl, forKey: "supabase_base_url")
        }
        if !cleanKey.isEmpty {
            self.anonKey = cleanKey
            try? keychain.set(self.anonKey, key: keychainAnonKey)
            UserDefaults.standard.removeObject(forKey: "supabase_anon_key")
        }
        if let t = tenantId?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
            self.tenantId = t
            UserDefaults.standard.set(self.tenantId, forKey: "supabase_tenant_id")
        }
        let configured = !self.baseUrl.isEmpty && !self.anonKey.isEmpty
        DispatchQueue.main.async {
            self.isConfigured = configured
        }
    }

    public func clearConfiguration() {
        UserDefaults.standard.removeObject(forKey: "supabase_base_url")
        UserDefaults.standard.removeObject(forKey: "supabase_anon_key")
        try? keychain.remove(keychainAnonKey)
        DispatchQueue.main.async {
            self.baseUrl = ""
            self.anonKey = ""
            self.isConfigured = false
        }
    }

    public func testConnection(testUrl: String, testKey: String) async -> (Bool, String) {
        let cleanUrl = testUrl.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
        let cleanKey = testKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUrl.isEmpty, !cleanKey.isEmpty, let url = URL(string: "\(cleanUrl)/rest/v1/kullanicilar?select=id&limit=1") else {
            return (false, "Geçersiz Supabase URL formatı.")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue(cleanKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await session.data(for: req)
            if let http = response as? HTTPURLResponse {
                if (200...299).contains(http.statusCode) {
                    return (true, "Supabase bağlantısı doğrulandı.")
                } else if http.statusCode == 401 || http.statusCode == 403 {
                    return (false, "Supabase Anon Key geçersiz veya yetkisiz (HTTP \(http.statusCode)).")
                } else if http.statusCode == 404 {
                    return (true, "Supabase sunucusuna ulaşıldı.")
                }
                return (false, "Sunucu yanıt kodu: HTTP \(http.statusCode)")
            }
            return (false, "Sunucudan geçerli yanıt alınamadı.")
        } catch {
            return (false, "Bağlantı hatası: \(error.localizedDescription)")
        }
    }

    public func resolveFromAccessToken(accessToken: String) async throws -> (url: String, anonKey: String) {
        let cleanToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty, let projectsUrl = URL(string: "https://api.supabase.com/v1/projects") else {
            throw NSError(domain: "SupabaseSetup", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz Access Token."])
        }
        var projReq = URLRequest(url: projectsUrl)
        projReq.httpMethod = "GET"
        projReq.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
        let (projData, projResp) = try await session.data(for: projReq)
        guard let httpProj = projResp as? HTTPURLResponse, (200...299).contains(httpProj.statusCode),
              let projArray = try JSONSerialization.jsonObject(with: projData) as? [[String: Any]],
              let firstProj = projArray.first,
              let ref = firstProj["id"] as? String, !ref.isEmpty else {
            throw NSError(domain: "SupabaseSetup", code: 404, userInfo: [NSLocalizedDescriptionKey: "Supabase hesabınızda aktif proje bulunamadı veya Access Token geçersiz."])
        }
        guard let keysUrl = URL(string: "https://api.supabase.com/v1/projects/\(ref)/api-keys") else {
            throw NSError(domain: "SupabaseSetup", code: 400, userInfo: [NSLocalizedDescriptionKey: "API anahtarı adresi oluşturulamadı."])
        }
        var keysReq = URLRequest(url: keysUrl)
        keysReq.httpMethod = "GET"
        keysReq.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
        let (keysData, keysResp) = try await session.data(for: keysReq)
        guard let httpKeys = keysResp as? HTTPURLResponse, (200...299).contains(httpKeys.statusCode),
              let keysArray = try JSONSerialization.jsonObject(with: keysData) as? [[String: Any]] else {
            throw NSError(domain: "SupabaseSetup", code: 404, userInfo: [NSLocalizedDescriptionKey: "Proje API anahtarları alınamadı."])
        }
        var foundAnonKey = ""
        for item in keysArray {
            if let name = item["name"] as? String, name == "anon",
               let apiKey = item["api_key"] as? String, !apiKey.isEmpty {
                foundAnonKey = apiKey
                break
            }
        }
        guard !foundAnonKey.isEmpty else {
            throw NSError(domain: "SupabaseSetup", code: 404, userInfo: [NSLocalizedDescriptionKey: "Projede anon key bulunamadı."])
        }
        return (url: "https://\(ref).supabase.co", anonKey: foundAnonKey)
    }
    
    private func defaultHeaders(prefer: String? = nil) -> [String: String] {
        var headers: [String: String] = [
            "apikey": anonKey,
            "Authorization": "Bearer \(authToken ?? anonKey)",
            "Content-Type": "application/json"
        ]
        if let prefer = prefer {
            headers["Prefer"] = prefer
        }
        return headers
    }
    
    // MARK: - PostgREST GET / Fetch
    public func fetch<T: Decodable>(
        from table: String,
        select: String = "*",
        filters: [String: String] = [:],
        orderBy: String? = nil,
        limit: Int? = nil,
        applyTenantFilter: Bool = true
    ) async throws -> [T] {
        var components = URLComponents(string: "\(baseUrl)/rest/v1/\(table)")
        var queryItems = [
            URLQueryItem(name: "select", value: select)
        ]
        
        if applyTenantFilter {
            // Canlı veritabanındaki tenant_id çeşitliliğini kapsayan filtre
            queryItems.append(URLQueryItem(name: "or", value: "(tenant_id.eq.\(tenantId),tenant_id.eq.default,tenant_id.is.null)"))
        }

        // Soft-delete filtresi: Silinmiş kayıtları getirme
        if !filters.keys.contains("deleted_at") && !filters.keys.contains("is_deleted") {
            queryItems.append(URLQueryItem(name: "is_deleted", value: "is.false"))
        }
        
        for (key, val) in filters {
            queryItems.append(URLQueryItem(name: key, value: val))
        }
        
        if let orderBy = orderBy {
            queryItems.append(URLQueryItem(name: "order", value: orderBy))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        defaultHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Bilinmeyen Sunucu Hatası"
            throw NSError(domain: "SupabaseError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        return try decoder.decode([T].self, from: data)
    }
    
    // MARK: - Convenience Fetch Methods for Exact Desktop Parity
    public func fetchCariler() async throws -> [CariKart] {
        return try await fetch(from: "cariler", orderBy: "unvan.asc", limit: 5000)
    }
    
    public func fetchCariHareketler(cariId: String) async throws -> [CariHareket] {
        return try await fetch(
            from: "cari_hareketler",
            filters: ["cari_id": "eq.\(cariId)"],
            orderBy: "tarih.desc",
            limit: 2000,
            applyTenantFilter: false
        )
    }
    
    public func fetchStoklar() async throws -> [StokKart] {
        return try await fetch(from: "stoklar", orderBy: "stok_adi.asc", limit: 5000)
    }
    
    public func fetchFaturalar() async throws -> [Fatura] {
        return try await fetch(from: "faturalar", orderBy: "tarih.desc", limit: 5000)
    }
    
    public func fetchSiparisler() async throws -> [Siparis] {
        return try await fetch(from: "siparisler", orderBy: "tarih.desc", limit: 5000)
    }
    
    public func fetchTeklifler() async throws -> [Teklif] {
        return try await fetch(from: "teklifler", orderBy: "tarih.desc", limit: 5000)
    }
    
    // MARK: - PostgREST Insert
    public func insert<T: Encodable>(into table: String, item: T) async throws {
        let data = try encoder.encode(item)
        try await insertRaw(into: table, data: data)
    }
    
    public func insert<T: Encodable, R: Decodable>(into table: String, item: T) async throws -> R {
        guard let url = URL(string: "\(baseUrl)/rest/v1/\(table)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        defaultHeaders(prefer: "return=representation").forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        request.httpBody = try encoder.encode(item)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Kayıt Eklenemedi"
            throw NSError(domain: "SupabaseError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        let results = try decoder.decode([R].self, from: data)
        guard let first = results.first else {
            throw NSError(domain: "SupabaseError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sonuç bulunamadı"])
        }
        return first
    }
    
    // MARK: - PostgREST Raw Insert
    public func insertRaw(into table: String, data: Data) async throws {
        guard let url = URL(string: "\(baseUrl)/rest/v1/\(table)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        defaultHeaders(prefer: "return=minimal").forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = data
        let (resData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: resData, encoding: .utf8) ?? "Ham Kayıt Eklenemedi"
            throw NSError(domain: "SupabaseError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    // MARK: - PostgREST Raw Update
    public func updateRaw(table: String, id: String, data: Data) async throws {
        guard let url = URL(string: "\(baseUrl)/rest/v1/\(table)?id=eq.\(id)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        defaultHeaders(prefer: "return=minimal").forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = data
        let (resData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: resData, encoding: .utf8) ?? "Ham Güncelleme Başarısız"
            throw NSError(domain: "SupabaseError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    // MARK: - PostgREST Update
    public func update<T: Encodable>(table: String, id: String, item: T) async throws {
        guard let url = URL(string: "\(baseUrl)/rest/v1/\(table)?id=eq.\(id)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        defaultHeaders(prefer: "return=minimal").forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = try encoder.encode(item)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Güncelleme Başarısız"
            throw NSError(domain: "SupabaseError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    // MARK: - PostgREST Soft Delete (Silinen kayıtlar deleted_at ile işaretlenir, diğer cihazlara yayılır)
    public func delete(table: String, id: String) async throws {
        let nowStr = ISO8601DateFormatter().string(from: Date())
        let softDeletePayload: [String: Any] = [
            "deleted_at": nowStr,
            "is_deleted": true,
            "updated_at": nowStr,
            "device_id": "iPhone-App"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: softDeletePayload)
        try await updateRaw(table: table, id: id, data: jsonData)
    }
    
    // MARK: - RPC Calls
    public func rpc<T: Encodable, R: Decodable>(function: String, params: T) async throws -> R {
        guard let url = URL(string: "\(baseUrl)/rest/v1/rpc/\(function)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        defaultHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = try encoder.encode(params)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "RPC Çağrısı Başarısız"
            throw NSError(domain: "SupabaseError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        return try decoder.decode(R.self, from: data)
    }
    
    // MARK: - Supabase Realtime WebSocket Listener (Phoenix Channel)
    private var webSocketTask: URLSessionWebSocketTask? = nil
    private var isRealtimeActive: Bool = false
    
    public func startRealtimeListener() {
        guard !isRealtimeActive else { return }
        isRealtimeActive = true
        
        let wsHost = baseUrl.replacingOccurrences(of: "https://", with: "wss://").replacingOccurrences(of: "http://", with: "ws://")
        guard let wsUrl = URL(string: "\(wsHost)/realtime/v1/websocket?apikey=\(anonKey)&vsn=1.0.0") else { return }
        
        webSocketTask = session.webSocketTask(with: wsUrl)
        webSocketTask?.resume()
        
        // Join public channel
        let joinMessage = """
        {"topic":"realtime:public","event":"phx_join","payload":{"config":{"postgres_changes":[{"event":"*","schema":"public"}]}},"ref":"1"}
        """
        webSocketTask?.send(.string(joinMessage)) { _ in }
        
        listenWebSocketMessages()
    }
    
    public func stopRealtimeListener() {
        isRealtimeActive = false
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }
    
    private func listenWebSocketMessages() {
        guard isRealtimeActive, let task = webSocketTask else { return }
        
        task.receive { [weak self] result in
            guard let self = self, self.isRealtimeActive else { return }
            
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    if text.contains("postgres_changes") || text.contains("INSERT") || text.contains("UPDATE") || text.contains("DELETE") {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .supabaseRealtimeDataChanged, object: nil)
                        }
                    }
                }
                self.listenWebSocketMessages()
            case .failure:
                // Yeniden bağlanma (Reconnection with 5s delay)
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
                    if self?.isRealtimeActive == true {
                        self?.webSocketTask = nil
                        self?.isRealtimeActive = false
                        self?.startRealtimeListener()
                    }
                }
            }
        }
    }
}

public extension Notification.Name {
    static let supabaseRealtimeDataChanged = Notification.Name("supabaseRealtimeDataChanged")
}
