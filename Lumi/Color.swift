import SwiftUI
import UIKit

extension Color {
    // color based on theme
    static func dynamicColor(light: String, dark: String) -> Color {
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(hex: dark)
            } else {
                return UIColor(hex: light)
            }
        })
    }
    
    static let appGreen = dynamicColor(light: "6FA38C", dark: "4A7B65")
    static let appTan = dynamicColor(light: "C9B58E", dark: "A8936A")
    
    static let appBackground = dynamicColor(light: "F7F1E7", dark: "1C1C1E")
    
    static let appDarkGreen = dynamicColor(light: "2F5B4A", dark: "F2F2F7")
    
    // Secondary
    static let appLightGray = dynamicColor(light: "D8D0C0", dark: "3A3A3C")

    // inactive tapbar icons
    static let appTabInactive = dynamicColor(light: "6F8A7C", dark: "8E8E93")
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
