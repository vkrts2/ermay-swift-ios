import Foundation

public struct DovizKuru: Identifiable, Codable, Sendable {
    public var id: String { kod }
    public var kod: String
    public var ad: String
    public var alis: Double
    public var satis: Double
    public var degisim: Double
    public var tarih: String
    
    public init(
        kod: String,
        ad: String,
        alis: Double,
        satis: Double,
        degisim: Double = 0.0,
        tarih: String = ""
    ) {
        self.kod = kod
        self.ad = ad
        self.alis = alis
        self.satis = satis
        self.degisim = degisim
        self.tarih = tarih
    }
}
