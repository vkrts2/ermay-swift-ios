// Sources/ErmayMobil/Services/DataStore.swift
import Foundation
import Combine
import SwiftUI

@MainActor
public final class DataStore: ObservableObject {
    public static let shared = DataStore()

    // Published State for SwiftUI Direct Binding (Pure In-Memory, Backed by Direct PostgreSQL)
    @Published public var cariler: [CariKart] = []
    @Published public var stoklar: [StokKart] = []
    @Published public var faturalar: [Fatura] = []

    // Loading Indicators
    @Published public var isLoadingCariler: Bool = false
    @Published public var isLoadingStoklar: Bool = false
    @Published public var isLoadingFaturalar: Bool = false
    @Published public var isSyncingAll: Bool = false

    // Metadata
    @Published public var lastSyncDate: Date? = nil
    @Published public var syncErrorMessage: String? = nil
    private var cancellables = Set<AnyCancellable>()

    public var currentFiscalYear: String {
        let yr = SupabaseService.shared.activeFiscalYear.trimmingCharacters(in: .whitespacesAndNewlines)
        return yr.isEmpty ? String(Calendar.current.component(.year, from: Date())) : yr
    }

    private init() {
        SupabaseService.shared.$activeFiscalYear
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.loadAll(force: true)
                    NotificationCenter.default.post(name: .supabaseRealtimeDataChanged, object: nil, userInfo: ["table": "mali_yil"])
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .supabaseRealtimeDataChanged)
            .sink { [weak self] notification in
                let table = (notification.userInfo?["table"] as? String)?.lowercased()
                Task { @MainActor [weak self] in
                    await self?.handleRealtimeTableChange(table: table)
                }
            }
            .store(in: &cancellables)
    }

    public func clearMemoryCache() {
        self.cariler = []
        self.stoklar = []
        self.faturalar = []
        self.lastSyncDate = nil
        self.syncErrorMessage = nil
    }

    private func handleRealtimeTableChange(table: String?) async {
        guard SupabaseService.shared.isConfigured, AuthService.shared.isAuthenticated else { return }
        switch table {
        case "mali_yil":
            break
        case "cariler", "cari_hareketler":
            await loadCarilerCacheFirst(forceCloudRefresh: true)
        case "stoklar", "stok_hareketler", "stok_gruplar":
            await loadStoklarCacheFirst(forceCloudRefresh: true)
        case "faturalar", "fatura_detaylar":
            await loadFaturalarCacheFirst(forceCloudRefresh: true)
            await loadCarilerCacheFirst(forceCloudRefresh: true)
            await loadStoklarCacheFirst(forceCloudRefresh: true)
        case "kasalar", "bankalar", "kasa_hareketler", "banka_hareketler", "cekler", "senetler", "kredi_karti_islemler", "eft_islemler":
            await loadCarilerCacheFirst(forceCloudRefresh: true)
            await loadFaturalarCacheFirst(forceCloudRefresh: true)
        case "siparisler", "siparis_detaylar", "teklifler", "teklif_detaylar":
            await loadStoklarCacheFirst(forceCloudRefresh: true)
        case nil, "":
            await syncAll()
        default:
            break
        }
        NotificationManager.shared.refreshAccountingAlerts(stoklar: self.stoklar, faturalar: self.faturalar)
    }

    // MARK: - Direct PostgreSQL Cariler
    public func loadAll(force: Bool = true) async {
        let shouldForce = force || self.cariler.isEmpty || self.stoklar.isEmpty || self.faturalar.isEmpty
        await loadCarilerCacheFirst(forceCloudRefresh: shouldForce || true)
        await loadStoklarCacheFirst(forceCloudRefresh: shouldForce || true)
        await loadFaturalarCacheFirst(forceCloudRefresh: shouldForce || true)
        NotificationManager.shared.refreshAccountingAlerts(stoklar: self.stoklar, faturalar: self.faturalar)
    }

    public func loadCariler(force: Bool = true) async {
        await loadCarilerCacheFirst(forceCloudRefresh: force)
    }

    public func loadStoklar(force: Bool = true) async {
        await loadStoklarCacheFirst(forceCloudRefresh: force)
    }

    public func loadFaturalar(force: Bool = true) async {
        await loadFaturalarCacheFirst(forceCloudRefresh: force)
    }

    public func loadCarilerCacheFirst(forceCloudRefresh: Bool = true) async {
        guard forceCloudRefresh, SupabaseService.shared.isConfigured else { return }
        isLoadingCariler = self.cariler.isEmpty
        defer { isLoadingCariler = false }

        do {
            let cloudCariler = try await SupabaseService.shared.fetchCariler()
            self.cariler = cloudCariler
            self.lastSyncDate = Date()
            self.syncErrorMessage = nil
        } catch {
            self.syncErrorMessage = error.localizedDescription
            print("[DataStore] Supabase cariler fetch error: \(error)")
        }
    }

    // MARK: - Direct PostgreSQL Stoklar
    public func loadStoklarCacheFirst(forceCloudRefresh: Bool = true) async {
        guard forceCloudRefresh, SupabaseService.shared.isConfigured else { return }
        isLoadingStoklar = self.stoklar.isEmpty
        defer { isLoadingStoklar = false }

        do {
            let cloudStoklar = try await SupabaseService.shared.fetchStoklar()
            self.stoklar = cloudStoklar
            self.lastSyncDate = Date()
            self.syncErrorMessage = nil
        } catch {
            self.syncErrorMessage = error.localizedDescription
            print("[DataStore] Supabase stoklar fetch error: \(error)")
        }
    }

    // MARK: - Direct PostgreSQL Faturalar
    public func loadFaturalarCacheFirst(forceCloudRefresh: Bool = true) async {
        guard forceCloudRefresh, SupabaseService.shared.isConfigured else { return }
        isLoadingFaturalar = self.faturalar.isEmpty
        defer { isLoadingFaturalar = false }

        do {
            let cloudFaturalar: [Fatura] = try await SupabaseService.shared.fetch(from: "faturalar", orderBy: "tarih.desc", limit: 5000)
            self.faturalar = cloudFaturalar
            self.lastSyncDate = Date()
            self.syncErrorMessage = nil
        } catch {
            self.syncErrorMessage = error.localizedDescription
            print("[DataStore] Supabase faturalar fetch error: \(error)")
        }
    }

    // MARK: - Global Full Refresh
    public func refreshAll(force: Bool = true) async {
        await syncAll()
    }

    public func syncAll() async {
        guard !isSyncingAll else { return }
        isSyncingAll = true
        defer { isSyncingAll = false }

        await loadCarilerCacheFirst(forceCloudRefresh: true)
        await loadStoklarCacheFirst(forceCloudRefresh: true)
        await loadFaturalarCacheFirst(forceCloudRefresh: true)
        NotificationManager.shared.refreshAccountingAlerts(stoklar: self.stoklar, faturalar: self.faturalar)
    }

    // MARK: - Direct Save Helpers (No Offline Queue; Real Error Propagation)
    public func saveStok(_ item: StokKart, isUpdate: Bool = false) async throws {
        if isUpdate {
            try await SupabaseService.shared.update(table: "stoklar", id: item.id, item: item)
        } else {
            try await SupabaseService.shared.insert(into: "stoklar", item: item)
        }
        await loadStoklarCacheFirst(forceCloudRefresh: true)
        NotificationManager.shared.refreshAccountingAlerts(stoklar: self.stoklar, faturalar: self.faturalar)
    }

    public func saveCari(_ item: CariKart, isUpdate: Bool = false) async throws {
        if isUpdate {
            try await SupabaseService.shared.update(table: "cariler", id: item.id, item: item)
        } else {
            try await SupabaseService.shared.insert(into: "cariler", item: item)
        }
        await loadCarilerCacheFirst(forceCloudRefresh: true)
    }
}
