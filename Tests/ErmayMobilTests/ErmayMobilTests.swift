import XCTest
@testable import ErmayMobil

final class ErmayMobilTests: XCTestCase {
    func testCurrencyFormatting() {
        let formatted = AppFormatters.money(1500.50)
        XCTAssertTrue(formatted.contains("1.500,50") || formatted.contains("1500"))
    }
    
    func testFaturaCalculation() {
        var kalem = FaturaKalem(
            stokAdi: "Test Ürün",
            miktar: 2,
            birimFiyat: 100,
            kdvOrani: 20,
            iskontoOrani: 10
        )
        // Brüt: 200, İskonto: 20, Matrah: 180, KDV: 36, Net: 216
        XCTAssertEqual(kalem.iskontoTutari, 20.0)
        XCTAssertEqual(kalem.kdvTutari, 36.0)
        XCTAssertEqual(kalem.netTutar, 216.0)
        
        // Dynamic recalculation on quantity change
        kalem.miktar = 4
        XCTAssertEqual(kalem.iskontoTutari, 40.0)
        XCTAssertEqual(kalem.kdvTutari, 72.0)
        XCTAssertEqual(kalem.netTutar, 432.0)
    }
    
    func testCariModelSerialization() throws {
        let cari = CariKart(
            unvan: "Ermay Ltd.",
            bakiye: -5000.0,
            bakiyeTuru: "A",
            riskLimiti: 100000.0,
            vadeGunu: 45,
            odemePlani: "45 Gün",
            ticaretSicilNo: "123456",
            iban: "TR120006200012345678901234"
        )
        let data = try JSONEncoder().encode(cari)
        let decoded = try JSONDecoder().decode(CariKart.self, from: data)
        XCTAssertEqual(decoded.unvan, "Ermay Ltd.")
        XCTAssertEqual(decoded.bakiye, -5000.0)
        XCTAssertEqual(decoded.signedBakiye, -5000.0)
        XCTAssertTrue(decoded.isAlacakli)
        XCTAssertEqual(decoded.iban, "TR120006200012345678901234")
        XCTAssertEqual(decoded.ticaretSicilNo, "123456")
        XCTAssertEqual(decoded.odemePlani, "45 Gün")
    }
    
    func testCekSenetSerialization() throws {
        let cek = Cek(
            cekNo: "CK-101",
            cariUnvan: "Ermay Bilişim",
            vadeTarihi: "15.11.2026",
            tutar: 35000.0,
            banka: "Garanti BBVA",
            durum: "PORTFOYDE"
        )
        let data = try JSONEncoder().encode(cek)
        let decoded = try JSONDecoder().decode(Cek.self, from: data)
        XCTAssertEqual(decoded.cekNo, "CK-101")
        XCTAssertEqual(decoded.tutar, 35000.0)
        XCTAssertEqual(decoded.durum, "PORTFOYDE")
    }
    
    func testMusteriRiskCalculation() {
        let risk = MusteriRisk(
            unvan: "Kaya Metal A.Ş.",
            riskLimiti: 50000.0,
            guncelBakiye: 65000.0
        )
        XCTAssertEqual(risk.riskSeviyesi, "LİMİT AŞIMI")
        XCTAssertEqual(risk.kalanLimit, 0.0)
    }
    
    @MainActor
    func testNetworkMonitorDefaultState() {
        let monitor = NetworkMonitor.shared
        XCTAssertTrue(monitor.isOnline)
    }
    
    @MainActor
    func testBiometricPinSecurityRejectsEmptyPin() {
        let lockService = BiometricLockService.shared
        lockService.setPin(nil)
        XCTAssertFalse(lockService.verifyPin("1234"), "verifyPin must return false when pinCode is nil")
        
        lockService.setPin("4826")
        XCTAssertFalse(lockService.verifyPin("0000"))
        XCTAssertTrue(lockService.verifyPin("4826"))
        lockService.setPin(nil)
    }
    
    @MainActor
    func testAuthPasswordVerificationRejectsPlaintext() {
        let auth = AuthService.shared
        XCTAssertFalse(auth.verifyPassword(plain: "secret123", storedHash: "secret123", saltBase64: nil))
    }
    
    func testDocumentConversionPipeline() {
        let teklifKalem = TeklifKalem(
            stokAdi: "Endüstriyel Rulman",
            miktar: 5,
            birimFiyat: 200,
            kdvOrani: 20
        )
        let teklif = Teklif(
            teklifNo: "TEK-001",
            cariUnvan: "Ermay Ltd.",
            araToplam: 1000,
            kdvToplami: 200,
            genelToplam: 1200,
            kalemler: [teklifKalem]
        )
        
        // Teklif -> Sipariş dönüşümü doğrulaması
        let sKalemler: [SiparisKalem] = (teklif.kalemler ?? []).map { k in
            SiparisKalem(stokAdi: k.stokAdi, miktar: k.miktar, birimFiyat: k.birimFiyat, kdvOrani: k.kdvOrani)
        }
        let siparis = Siparis(
            siparisNo: "SIP-001",
            cariUnvan: teklif.cariUnvan,
            araToplam: teklif.araToplam,
            kdvToplami: teklif.kdvToplami,
            genelToplam: teklif.genelToplam,
            kalemler: sKalemler
        )
        XCTAssertEqual(siparis.genelToplam, 1200.0)
        XCTAssertEqual(siparis.kalemler?.count, 1)
        XCTAssertEqual(siparis.kalemler?.first?.stokAdi, "Endüstriyel Rulman")
    }
}
