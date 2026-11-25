import SwiftUI

public struct FaturalarView: View {
    @ObservedObject private var dataStore = DataStore.shared
    @ObservedObject private var supabaseService = SupabaseService.shared
    @State private var faturalar: [Fatura] = []
    @State private var searchText: String = ""
    @State private var startDateStr: String = "01.01.\(SupabaseService.shared.activeFiscalYear)"
    @State private var endDateStr: String = "31.12.\(SupabaseService.shared.activeFiscalYear)"
    @State private var isLoading: Bool = false
    
    // Sheets
    @State private var activeFaturaSheet: String? = nil // "SATIS", "ALIS"
    @State private var selectedFaturaForDetail: Fatura? = nil
    @State private var pdfPreviewItem: PDFPreviewItem? = nil
    @State private var isGeneratingPDF: Bool = false
    
    public init() {}
    
    public var filteredFaturalar: [Fatura] {
        let sourceList = !dataStore.faturalar.isEmpty ? dataStore.faturalar : faturalar
        let startD = AppFormatters.parseDate(startDateStr)
        let endD = AppFormatters.parseDate(endDateStr)
        return sourceList.filter { f in
            let textMatch = searchText.isEmpty ||
                f.faturaNo.localizedCaseInsensitiveContains(searchText) ||
                (f.cariUnvan?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                f.faturaTuru.localizedCaseInsensitiveContains(searchText)
            if !textMatch { return false }
            if let sd = startD, let ed = endD, let fd = AppFormatters.parseDate(String(f.tarih.prefix(10))) ?? AppFormatters.parseDate(f.tarih) {
                let fDay = Calendar.current.startOfDay(for: fd)
                if fDay < Calendar.current.startOfDay(for: sd) || fDay > Calendar.current.startOfDay(for: ed) {
                    return false
                }
            }
            return true
        }
    }
    
    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 12) {
                    // Header Bar (Exact match to FaturalarScreen.tsx)
                    HStack {
                        Text("Faturalar")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Search + Date Filter Row (Exact to FaturalarScreen.tsx)
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color(hex: "94A3B8"))
                            TextField("Fatura / Cari Ara...", text: $searchText)
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(hex: "94A3B8"))
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(hex: "121216"))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        
                        // Date Range Row
                        HStack(spacing: 6) {
                            HStack {
                                TextField("01.01.\(supabaseService.activeFiscalYear)", text: $startDateStr)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color(hex: "121216"))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            
                            Text("—")
                                .foregroundColor(Color(hex: "64748B"))
                            
                            HStack {
                                TextField("31.12.\(supabaseService.activeFiscalYear)", text: $endDateStr)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color(hex: "121216"))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            
                            Button {
                                Task { await loadFaturalar() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(9)
                                    .background(Color(hex: "0061FF"))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons Row (Yeni Satış, Yeni Alış, Excel, PDF)
                    HStack(spacing: 8) {
                        Button {
                            activeFaturaSheet = "SATIS"
                        } label: {
                            HStack(spacing: 4) {
                                Text("+")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Yeni Satış")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color(hex: "10B981"))
                            .cornerRadius(8)
                        }
                        
                        Button {
                            activeFaturaSheet = "ALIS"
                        } label: {
                            HStack(spacing: 4) {
                                Text("+")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Yeni Alış")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color(hex: "F97316"))
                            .cornerRadius(8)
                        }
                        
                        Button {
                            #if canImport(UIKit)
                            Task { @MainActor in
                                isGeneratingPDF = true
                                let sDate = AppFormatters.parseDate(startDateStr) ?? Date()
                                let eDate = AppFormatters.parseDate(endDateStr) ?? Date()
                                let data = await PDFService.shared.fetchOrGenerateFaturaListPDF(
                                    faturalar: filteredFaturalar,
                                    startDate: sDate,
                                    endDate: eDate
                                )
                                isGeneratingPDF = false
                                pdfPreviewItem = PDFPreviewItem(
                                    title: "Fatura Listesi",
                                    data: data,
                                    fileName: "Fatura_Listesi.pdf"
                                )
                            }
                            #endif
                        } label: {
                            HStack(spacing: 4) {
                                if isGeneratingPDF {
                                    ProgressView().tint(.white).scaleEffect(0.7)
                                } else {
                                    Image(systemName: "arrow.down.doc.fill")
                                }
                                Text("PDF")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(Color(hex: "0061FF"))
                            .cornerRadius(8)
                        }
                        .disabled(isGeneratingPDF)
                    }
                    .padding(.horizontal)
                    
                    // Fatura Listesi
                    if isLoading && faturalar.isEmpty {
                        Spacer()
                        ProgressView().tint(AppTheme.primary)
                        Spacer()
                    } else if filteredFaturalar.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.textMuted)
                            Text("Herhangi bir fatura bulunamadı")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredFaturalar) { fatura in
                                Button {
                                    selectedFaturaForDetail = fatura
                                } label: {
                                    AppleFaturaRow(fatura: fatura)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await loadFaturalar()
                        }
                    }
                    
                    Spacer().frame(height: 70)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: Binding(
                get: { activeFaturaSheet != nil },
                set: { if !$0 { activeFaturaSheet = nil } }
            )) {
                FaturaFormView(initialTur: activeFaturaSheet ?? "SATIS") { newFatura in
                    faturalar.insert(newFatura, at: 0)
                }
                .enableSwipeBack()
            }
            .sheet(item: $selectedFaturaForDetail) { f in
                FaturaDetailView(fatura: f)
                    .enableSwipeBack()
            }
            .sheet(item: $pdfPreviewItem) { item in
                #if canImport(UIKit)
                PDFViewerModal(title: item.title, pdfData: item.data, fileName: item.fileName)
                #endif
            }
            .task {
                startDateStr = "01.01.\(supabaseService.activeFiscalYear)"
                endDateStr = "31.12.\(supabaseService.activeFiscalYear)"
                await loadFaturalar()
            }
            .onChange(of: supabaseService.activeFiscalYear) { newYear in
                startDateStr = "01.01.\(newYear)"
                endDateStr = "31.12.\(newYear)"
                Task {
                    await loadFaturalar()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .supabaseRealtimeDataChanged)) { _ in
                Task {
                    await loadFaturalar()
                }
            }
    }
    
    private func loadFaturalar() async {
        isLoading = dataStore.faturalar.isEmpty
        await dataStore.loadFaturalarCacheFirst(forceCloudRefresh: true)
        self.faturalar = dataStore.faturalar
        isLoading = false
    }
}

// MARK: - AppleFaturaRow (Exact match to FaturalarScreen.tsx)
public struct AppleFaturaRow: View {
    public let fatura: Fatura
    
    public init(fatura: Fatura) {
        self.fatura = fatura
    }
    
    private var isSatis: Bool {
        fatura.faturaTuru.uppercased().contains("SATIS") || fatura.faturaTuru.uppercased().contains("SATIŞ")
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill((isSatis ? Color(hex: "007AFF") : Color(hex: "FF9500")).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: isSatis ? "doc.text.fill" : "doc.badge.plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSatis ? Color(hex: "007AFF") : Color(hex: "FF9500"))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(fatura.cariUnvan ?? "Cari Belirtilmedi")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text("\(isSatis ? "Satış" : "Alış") Faturası")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSatis ? Color(hex: "007AFF") : Color(hex: "FF9500"))
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "64748B"))
                    
                    Text(fatura.faturaNo)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "94A3B8"))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text(AppFormatters.money(fatura.genelToplam))
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(.white)
                
                Text(fatura.durum)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(fatura.durum.uppercased().contains("KAPALI") ? Color(hex: "10B981") : Color(hex: "F59E0B"))
            }
        }
        .padding(14)
        .background(Color(hex: "121216"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
