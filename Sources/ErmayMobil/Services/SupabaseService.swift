import Foundation
import Combine
import KeychainAccess

public final class SupabaseService: ObservableObject, @unchecked Sendable {
    public static let shared = SupabaseService()
    
    public static let defaultBaseUrl = ""
    public static let defaultAnonKey = ""
    private let unsupportedColsLock = NSLock()
    private var unsupportedColumnsByTable: [String: Set<String>] = [:]
    
    @Published public var baseUrl: String = SupabaseService.defaultBaseUrl
    @Published public var anonKey: String = SupabaseService.defaultAnonKey
    @Published public var tenantId: String = "tenant_ermay_master"
    @Published public var isConfigured: Bool = false
    @Published public var activeFiscalYear: String = String(Calendar.current.component(.year, from: Date()))
    @Published public var availableFiscalYears: [String] = [String(Calendar.current.component(.year, from: Date()))]
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
        let defaultYear = String(Calendar.current.component(.year, from: Date()))
        if let savedActiveYear = UserDefaults.standard.string(forKey: "supabase_active_fiscal_year"), !savedActiveYear.isEmpty {
            self.activeFiscalYear = savedActiveYear
        } else {
            self.activeFiscalYear = defaultYear
        }
        if let savedYears = UserDefaults.standard.stringArray(forKey: "supabase_available_fiscal_years"), !savedYears.isEmpty {
            self.availableFiscalYears = savedYears
        } else {
            self.availableFiscalYears = [self.activeFiscalYear]
        }
        self.isConfigured = !self.baseUrl.isEmpty && !self.anonKey.isEmpty
    }

    public func fetchFiscalYears() async {
        let defaultYear = String(Calendar.current.component(.year, from: Date()))
        guard !baseUrl.isEmpty, !anonKey.isEmpty else {
            await MainActor.run {
                if self.availableFiscalYears.isEmpty {
                    self.availableFiscalYears = [defaultYear]
                }
            }
            return
        }

        var yearsSet = Set<Int>()
        var cloudActiveYear: Int? = nil

        // 1. public.mali_yillar tablosundan mevcut yılları çek
        if let url = URL(string: "\(baseUrl)/rest/v1/mali_yillar?select=yil,is_active,is_deleted,tenant_id") {
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            defaultHeaders().forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
            if let (data, response) = try? await session.data(for: req),
               let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
               let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                for row in arr {
                    let isDel = (row["is_deleted"] as? Bool) ?? false
                    if isDel { continue }
                    let rowTenant = (row["tenant_id"] as? String) ?? ""
                    if !rowTenant.isEmpty && rowTenant != "default" && rowTenant != tenantId {
                        continue
                    }
                    var yVal: Int? = nil
                    if let num = row["yil"] as? NSNumber {
                        yVal = num.intValue
                    } else if let str = row["yil"] as? String, let parsed = Int(str) {
                        yVal = parsed
                    }
                    if let y = yVal, y >= 2000 && y <= 2100 {
                        yearsSet.insert(y)
                        if (row["is_active"] as? Bool) == true {
                            cloudActiveYear = y
                        }
                    }
                }
            }
        }

        // 2. Yedek olarak public.notlar (__MALI_YILLAR_...__) kontrolü
        if yearsSet.isEmpty {
            let noteTitle = tenantId == "default" ? "__MALI_YILLAR__" : "__MALI_YILLAR_\(tenantId)__"
            if let encoded = noteTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "\(baseUrl)/rest/v1/notlar?baslik=eq.\(encoded)&select=icerik,is_deleted") {
                var req = URLRequest(url: url)
                req.httpMethod = "GET"
                defaultHeaders().forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
                if let (data, response) = try? await session.data(for: req),
                   let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                   let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let first = arr.first,
                   ((first["is_deleted"] as? Bool) ?? false) == false,
                   let icerik = first["icerik"] as? String,
                   let icerikData = icerik.data(using: .utf8),
                   let parsedYears = try? JSONSerialization.jsonObject(with: icerikData) as? [Int] {
                    for y in parsedYears where y >= 2000 && y <= 2100 {
                        yearsSet.insert(y)
                    }
                }
            }
        }

        let sortedStrings: [String]
        if yearsSet.isEmpty {
            sortedStrings = [defaultYear]
        } else {
            sortedStrings = yearsSet.sorted(by: >).map { String($0) }
        }

        let resolvedActive: String
        if let active = cloudActiveYear, sortedStrings.contains(String(active)) {
            resolvedActive = String(active)
        } else if sortedStrings.contains(self.activeFiscalYear) {
            resolvedActive = self.activeFiscalYear
        } else {
            resolvedActive = sortedStrings.first ?? defaultYear
        }

        UserDefaults.standard.set(sortedStrings, forKey: "supabase_available_fiscal_years")
        UserDefaults.standard.set(resolvedActive, forKey: "supabase_active_fiscal_year")

        await MainActor.run {
            self.availableFiscalYears = sortedStrings
            self.activeFiscalYear = resolvedActive
        }
    }

    public func setActiveFiscalYear(_ yearStr: String) async {
        let trimmed = yearStr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(trimmed, forKey: "supabase_active_fiscal_year")
        await MainActor.run {
            self.activeFiscalYear = trimmed
            if !self.availableFiscalYears.contains(trimmed) {
                var updated = self.availableFiscalYears
                updated.append(trimmed)
                updated.sort(by: >)
                self.availableFiscalYears = updated
                UserDefaults.standard.set(updated, forKey: "supabase_available_fiscal_years")
            }
        }
    }

    public func createFiscalYear(_ yearStr: String) async {
        let trimmed = yearStr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let yInt = Int(trimmed), yInt >= 2000 && yInt <= 2100 else { return }

        if !baseUrl.isEmpty && !anonKey.isEmpty {
            let nowStr = ISO8601DateFormatter().string(from: Date())
            let payload: [String: Any] = [
                "yil": yInt,
                "mali_yil": yInt,
                "uuid": "mali_yil_\(yInt)",
                "tenant_id": tenantId,
                "is_active": true,
                "is_deleted": false,
                "aciklama": "\(yInt) Mali Yılı",
                "olusturma_tarihi": nowStr,
                "updated_at": nowStr
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload) {
                try? await insertRaw(into: "mali_yillar", data: data)
            }
        }

        await setActiveFiscalYear(trimmed)
        await fetchFiscalYears()
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
            "Content-Type": "application/json",
            "X-Tenant-Id": tenantId.isEmpty ? "tenant_ermay_master" : tenantId
        ]
        if let prefer = prefer {
            headers["Prefer"] = prefer
        }
        return headers
    }
    
    // MARK: - PostgREST GET / Paginated Fetch
    public func fetch<T: Decodable>(
        from table: String,
        select: String = "*",
        filters: [String: String] = [:],
        orderBy: String? = nil,
        limit: Int? = nil,
        applyTenantFilter: Bool = true
    ) async throws -> [T] {
        let maxPageSize = 1000
        let targetLimit = limit ?? Int.max
        
        // 1000 ve altı tek sayfa için tek istek yeterlidir
        if targetLimit <= maxPageSize {
            return try await fetchSinglePage(
                from: table,
                select: select,
                filters: filters,
                orderBy: orderBy,
                limit: targetLimit,
                offset: 0,
                applyTenantFilter: applyTenantFilter
            )
        }
        
        // 1000'den büyük veya limitsiz sorgular için Range / offset chunking (PostgREST 1.000 limitini aşmak için)
        var allItems: [T] = []
        var currentOffset = 0
        let safetyMax = min(targetLimit, 50_000)
        
        while allItems.count < safetyMax {
            let chunkSize = min(maxPageSize, safetyMax - allItems.count)
            let page: [T] = try await fetchSinglePage(
                from: table,
                select: select,
                filters: filters,
                orderBy: orderBy,
                limit: chunkSize,
                offset: currentOffset,
                applyTenantFilter: applyTenantFilter
            )
            
            allItems.append(contentsOf: page)
            if page.count < chunkSize {
                break // Tablodaki tüm veriler çekildi
            }
            currentOffset += page.count
        }
        
        return allItems
    }
    
    private func fetchSinglePage<T: Decodable>(
        from table: String,
        select: String = "*",
        filters: [String: String] = [:],
        orderBy: String? = nil,
        limit: Int,
        offset: Int = 0,
        applyTenantFilter: Bool = true
    ) async throws -> [T] {
        var components = URLComponents(string: "\(baseUrl)/rest/v1/\(table)")
        var queryItems = [
            URLQueryItem(name: "select", value: select)
        ]
        
        // Mali yıl izolasyonu: Mali yıla tabi operasyonel tablolarda aktif mali yılı filtrele
        let fiscalYearTables = ["faturalar", "cari_hareketler", "kasa_hareketler", "banka_hareketler", "stok_hareketler"]
        let applyFiscalYear = fiscalYearTables.contains(table) && !filters.keys.contains("mali_yil")
        
        if applyTenantFilter && applyFiscalYear {
            // PostgREST birden fazla or= parametresini ezeceğinden tek bir and=(or(...),or(...)) içinde birleştirilir
            queryItems.append(URLQueryItem(
                name: "and",
                value: "(or(tenant_id.eq.\(tenantId),tenant_id.eq.default,tenant_id.is.null),or(mali_yil.eq.\(activeFiscalYear),mali_yil.is.null))"
            ))
        } else if applyTenantFilter {
            // Canlı veritabanındaki tenant_id çeşitliliğini kapsayan filtre
            queryItems.append(URLQueryItem(name: "or", value: "(tenant_id.eq.\(tenantId),tenant_id.eq.default,tenant_id.is.null)"))
        } else if applyFiscalYear {
            queryItems.append(URLQueryItem(name: "or", value: "(mali_yil.eq.\(activeFiscalYear),mali_yil.is.null)"))
        }

        // Soft-delete filtresi: Silinmiş kayıtları getirme (not.is.true PostgreSQL'de FALSE ve NULL satırlarını güvenli kapsar)
        if !filters.keys.contains("deleted_at") && !filters.keys.contains("is_deleted") {
            queryItems.append(URLQueryItem(name: "is_deleted", value: "not.is.true"))
        }
        
        for (key, val) in filters {
            queryItems.append(URLQueryItem(name: key, value: val))
        }
        
        if let orderBy = orderBy {
            queryItems.append(URLQueryItem(name: "order", value: orderBy))
        }
        
        queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        if offset > 0 {
            queryItems.append(URLQueryItem(name: "offset", value: "\(offset)"))
        }
        
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        defaultHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // PostgREST Range header desteği
        request.setValue("\(offset)-\(offset + limit - 1)", forHTTPHeaderField: "Range")
        request.setValue("items", forHTTPHeaderField: "Range-Unit")
        
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
    
    // MARK: - Schema-Resilient Column Stripping Helpers
    private func recordUnsupportedColumn(table: String, column: String) {
        let baseTable = table.components(separatedBy: "?").first?.lowercased() ?? table.lowercased()
        unsupportedColsLock.lock()
        defer { unsupportedColsLock.unlock() }
        var set = unsupportedColumnsByTable[baseTable] ?? Set<String>()
        set.insert(column)
        unsupportedColumnsByTable[baseTable] = set
    }

    private func stripUnsupportedColumns(table: String, data: Data) -> Data {
        let baseTable = table.components(separatedBy: "?").first?.lowercased() ?? table.lowercased()
        unsupportedColsLock.lock()
        let cols = unsupportedColumnsByTable[baseTable] ?? Set<String>()
        unsupportedColsLock.unlock()
        guard !cols.isEmpty else { return data }
        if var dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            for col in cols { dict.removeValue(forKey: col) }
            if let stripped = try? JSONSerialization.data(withJSONObject: dict) { return stripped }
        }
        return data
    }

    private func extractMissingColumn(from errorMsg: String) -> String? {
        guard errorMsg.contains("PGRST204") || errorMsg.contains("42703") || errorMsg.contains("does not exist") else {
            return nil
        }
        let patterns = [
            "Could not find the '([^']+)' column",
            "column \"([^\"]+)\" of relation"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: errorMsg, range: NSRange(errorMsg.startIndex..., in: errorMsg)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: errorMsg) {
                return String(errorMsg[range])
            }
        }
        return nil
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
        var currentData = stripUnsupportedColumns(table: table, data: try encoder.encode(item))
        var retries = 25
        while retries > 0 {
            retries -= 1
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            defaultHeaders(prefer: "return=representation").forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            request.httpBody = currentData
            
            let (data, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                let results = try decoder.decode([R].self, from: data)
                guard let first = results.first else {
                    throw NSError(domain: "SupabaseError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sonuç bulunamadı"])
                }
                return first
            }
            let errorMsg = String(data: data, encoding: .utf8) ?? "Kayıt Eklenemedi"
            if let missingCol = extractMissingColumn(from: errorMsg),
               var dict = (try? JSONSerialization.jsonObject(with: currentData)) as? [String: Any],
               dict.keys.contains(missingCol) {
                recordUnsupportedColumn(table: table, column: missingCol)
                dict.removeValue(forKey: missingCol)
                if let nextData = try? JSONSerialization.data(withJSONObject: dict) {
                    currentData = nextData
                    continue
                }
            }
            throw NSError(domain: "SupabaseError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        throw NSError(domain: "SupabaseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Kayıt Eklenemedi"])
    }
    
    // MARK: - PostgREST Raw Insert & Idempotent Upsert
    public func upsertRaw(into table: String, data: Data, onConflict: String = "uuid") async throws {
        guard let url = URL(string: "\(baseUrl)/rest/v1/\(table)?on_conflict=\(onConflict)") else {
            throw URLError(.badURL)
        }
        var currentData = stripUnsupportedColumns(table: table, data: data)
        var retries = 25
        var lastStatus = 500
        var lastError = "Upsert başarısız"
        while retries > 0 {
            retries -= 1
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            defaultHeaders(prefer: "resolution=merge-duplicates,return=representation").forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            request.httpBody = currentData
            let (resData, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return
            }
            lastStatus = (response as? HTTPURLResponse)?.statusCode ?? 500
            lastError = String(data: resData, encoding: .utf8) ?? "Upsert başarısız"
            if let missingCol = extractMissingColumn(from: lastError),
               var dict = (try? JSONSerialization.jsonObject(with: currentData)) as? [String: Any],
               dict.keys.contains(missingCol) {
                recordUnsupportedColumn(table: table, column: missingCol)
                dict.removeValue(forKey: missingCol)
                if let nextData = try? JSONSerialization.data(withJSONObject: dict) {
                    currentData = nextData
                    continue
                }
            }
            throw NSError(domain: "SupabaseError", code: lastStatus, userInfo: [NSLocalizedDescriptionKey: lastError])
        }
        throw NSError(domain: "SupabaseError", code: lastStatus, userInfo: [NSLocalizedDescriptionKey: lastError])
    }

    public func insertRaw(into table: String, data: Data) async throws {
        guard let url = URL(string: "\(baseUrl)/rest/v1/\(table)") else {
            throw URLError(.badURL)
        }
        var currentData = stripUnsupportedColumns(table: table, data: data)
        var retries = 25
        while retries > 0 {
            retries -= 1
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            defaultHeaders(prefer: "return=representation").forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            request.httpBody = currentData
            let (resData, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            let errorMsg = String(data: resData, encoding: .utf8) ?? "Ham Kayıt Eklenemedi"

            if let missingCol = extractMissingColumn(from: errorMsg),
               var dict = (try? JSONSerialization.jsonObject(with: currentData)) as? [String: Any],
               dict.keys.contains(missingCol) {
                recordUnsupportedColumn(table: table, column: missingCol)
                dict.removeValue(forKey: missingCol)
                if let nextData = try? JSONSerialization.data(withJSONObject: dict) {
                    currentData = nextData
                    continue
                }
            }

            // Propagate 409/23505 conflicts and all database errors directly to caller
            throw NSError(domain: "SupabaseError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    // MARK: - PostgREST Raw Update
    public func updateRaw(table: String, id: String, data: Data) async throws {
        let filter = Int(id) != nil ? "id=eq.\(id)" : "uuid=eq.\(id)"
        guard let url = URL(string: "\(baseUrl)/rest/v1/\(table)?\(filter)") else {
            throw URLError(.badURL)
        }
        var currentData = stripUnsupportedColumns(table: table, data: data)
        var retries = 25
        while retries > 0 {
            retries -= 1
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            defaultHeaders(prefer: "return=representation").forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            request.httpBody = currentData
            let (resData, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                if let arr = try? JSONSerialization.jsonObject(with: resData) as? [[String: Any]], arr.isEmpty {
                    throw NSError(domain: "SupabaseError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Kayıt sunucuda bulunamadı veya başka bir cihaz tarafından silinmiş (\(table): \(id))."])
                }
                return
            }
            let errorMsg = String(data: resData, encoding: .utf8) ?? "Ham Güncelleme Başarısız"
            if let missingCol = extractMissingColumn(from: errorMsg),
               var dict = (try? JSONSerialization.jsonObject(with: currentData)) as? [String: Any],
               dict.keys.contains(missingCol) {
                recordUnsupportedColumn(table: table, column: missingCol)
                dict.removeValue(forKey: missingCol)
                if let nextData = try? JSONSerialization.data(withJSONObject: dict) {
                    currentData = nextData
                    continue
                }
            }
            throw NSError(domain: "SupabaseError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    // MARK: - PostgREST Update With Custom Filter
    public func updateWhere(table: String, filter: String, data: Data) async throws {
        guard let url = URL(string: "\(baseUrl)/rest/v1/\(table)?\(filter)") else {
            throw URLError(.badURL)
        }
        var currentData = stripUnsupportedColumns(table: table, data: data)
        var retries = 5
        while retries > 0 {
            retries -= 1
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            defaultHeaders(prefer: "return=representation").forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            request.httpBody = currentData
            let (resData, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                return
            }
            let errorMsg = String(data: resData, encoding: .utf8) ?? "Güncelleme Başarısız"
            if let missingCol = extractMissingColumn(from: errorMsg),
               var dict = (try? JSONSerialization.jsonObject(with: currentData)) as? [String: Any],
               dict.keys.contains(missingCol) {
                recordUnsupportedColumn(table: table, column: missingCol)
                dict.removeValue(forKey: missingCol)
                if let nextData = try? JSONSerialization.data(withJSONObject: dict) {
                    currentData = nextData
                    continue
                }
            }
            throw NSError(domain: "SupabaseError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
    
    // MARK: - PostgREST Update
    public func update<T: Encodable>(table: String, id: String, item: T) async throws {
        let data = try encoder.encode(item)
        try await updateRaw(table: table, id: id, data: data)
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
    
    // MARK: - PostgREST Soft Delete With Custom Filter
    public func deleteWhere(table: String, filter: String) async throws {
        let nowStr = ISO8601DateFormatter().string(from: Date())
        let softDeletePayload: [String: Any] = [
            "deleted_at": nowStr,
            "is_deleted": true,
            "updated_at": nowStr,
            "device_id": "iPhone-App"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: softDeletePayload)
        try await updateWhere(table: table, filter: filter, data: jsonData)
    }
    
    // MARK: - RPC Calls
    public func rpcRaw(function: String, params: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseUrl)/rest/v1/rpc/\(function)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        defaultHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "RPC Çağrısı Başarısız"
            throw NSError(domain: "SupabaseError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return dict
        }
        return ["success": true]
    }

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
    
    // MARK: - Supabase Realtime WebSocket Listener (Phoenix Channel + Heartbeat + Debounce)
    private var webSocketTask: URLSessionWebSocketTask? = nil
    private var isRealtimeActive: Bool = false
    private var heartbeatTimer: Timer? = nil
    private var heartbeatRefCounter: Int = 100
    private var reconnectAttempt: Int = 0
    private var realtimeDebounceWorkItem: DispatchWorkItem? = nil
    
    public func startRealtimeListener() {
        guard !isRealtimeActive, !baseUrl.isEmpty, !anonKey.isEmpty else { return }
        isRealtimeActive = true
        
        let wsHost = baseUrl.replacingOccurrences(of: "https://", with: "wss://").replacingOccurrences(of: "http://", with: "ws://")
        guard let wsUrl = URL(string: "\(wsHost)/realtime/v1/websocket?apikey=\(anonKey)&vsn=1.0.0") else {
            isRealtimeActive = false
            return
        }
        
        webSocketTask = session.webSocketTask(with: wsUrl)
        webSocketTask?.resume()
        
        // Join public channel
        let joinMessage = """
        {"topic":"realtime:public","event":"phx_join","payload":{"config":{"postgres_changes":[{"event":"*","schema":"public"}]}},"ref":"1"}
        """
        webSocketTask?.send(.string(joinMessage)) { [weak self] error in
            if error == nil {
                self?.reconnectAttempt = 0
            }
        }
        
        startPhoenixHeartbeatTimer()
        listenWebSocketMessages()
    }
    
    private func startPhoenixHeartbeatTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.heartbeatTimer?.invalidate()
            self?.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
                guard let self = self, self.isRealtimeActive, let task = self.webSocketTask else { return }
                self.heartbeatRefCounter += 1
                let hbMsg = "{\"topic\":\"phoenix\",\"event\":\"heartbeat\",\"payload\":{},\"ref\":\"\(self.heartbeatRefCounter)\"}"
                task.send(.string(hbMsg)) { _ in }
            }
        }
    }
    
    public func stopRealtimeListener() {
        isRealtimeActive = false
        reconnectAttempt = 0
        DispatchQueue.main.async { [weak self] in
            self?.heartbeatTimer?.invalidate()
            self?.heartbeatTimer = nil
            self?.realtimeDebounceWorkItem?.cancel()
            self?.realtimeDebounceWorkItem = nil
        }
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }
    
    private func extractRealtimeTable(from jsonText: String) -> String? {
        guard let data = jsonText.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payload = root["payload"] as? [String: Any] else {
            return nil
        }
        if let innerData = payload["data"] as? [String: Any],
           let table = innerData["table"] as? String, !table.isEmpty {
            return table.lowercased()
        }
        if let table = payload["table"] as? String, !table.isEmpty {
            return table.lowercased()
        }
        return nil
    }

    private func scheduleDebouncedRealtimeBroadcast(table: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.realtimeDebounceWorkItem?.cancel()
            let item = DispatchWorkItem {
                var info: [AnyHashable: Any] = [:]
                if let t = table, !t.isEmpty {
                    info["table"] = t
                }
                NotificationCenter.default.post(name: .supabaseRealtimeDataChanged, object: nil, userInfo: info)
            }
            self.realtimeDebounceWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
        }
    }

    private func listenWebSocketMessages() {
        guard isRealtimeActive, let task = webSocketTask else { return }

        task.receive { [weak self] result in
            guard let self = self, self.isRealtimeActive else { return }

            switch result {
            case .success(let message):
                self.reconnectAttempt = 0
                if case .string(let text) = message {
                    if text.contains("postgres_changes") || text.contains("INSERT") || text.contains("UPDATE") || text.contains("DELETE") {
                        let changedTable = self.extractRealtimeTable(from: text)
                        self.scheduleDebouncedRealtimeBroadcast(table: changedTable)
                    }
                }
                self.listenWebSocketMessages()
            case .failure:
                // Exponential backoff reconnection (5s, 10s, 20s, up to 60s max) to prevent battery/socket storm
                self.reconnectAttempt = min(self.reconnectAttempt + 1, 5)
                let delay = min(60.0, 5.0 * pow(2.0, Double(self.reconnectAttempt - 1)))
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
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
