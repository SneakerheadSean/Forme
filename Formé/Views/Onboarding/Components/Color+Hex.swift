import SwiftUI

// Single, canonical Color(hex:) used app-wide.
extension Color {
    init(hex: String, opacity: Double = 1.0) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()

        // Expand 3/4-digit shorthand to 6/8 digits if needed
        if hexString.count == 3 || hexString.count == 4 {
            hexString = hexString.map { [$0, $0] }.flatMap { $0 }.map(String.init).joined()
        }

        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0, a: UInt64 = 255

        if hexString.count == 6,
           Scanner(string: String(hexString.prefix(2))).scanHexInt64(&r),
           Scanner(string: String(hexString.dropFirst(2).prefix(2))).scanHexInt64(&g),
           Scanner(string: String(hexString.dropFirst(4).prefix(2))).scanHexInt64(&b) {
            // RGB
        } else if hexString.count == 8,
                  Scanner(string: String(hexString.prefix(2))).scanHexInt64(&r),
                  Scanner(string: String(hexString.dropFirst(2).prefix(2))).scanHexInt64(&g),
                  Scanner(string: String(hexString.dropFirst(4).prefix(2))).scanHexInt64(&b),
                  Scanner(string: String(hexString.dropFirst(6).prefix(2))).scanHexInt64(&a) {
            // RGBA
        } else {
            self = .pink
            return
        }

        self = Color(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: min(max(opacity * Double(a) / 255.0, 0), 1)
        )
    }
}
