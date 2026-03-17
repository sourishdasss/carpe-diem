import SwiftUI

// MARK: - V2 Warm Palette

extension Color {
    // Backgrounds
    static let sonderBackground   = Color(red: 0.961, green: 0.941, blue: 0.922) // #F5F0EB
    static let sonderSurface      = Color.white
    static let sonderDivider      = Color(red: 0.878, green: 0.851, blue: 0.824) // #E0D9D2

    // Accents
    static let sonderAccent       = Color(red: 0.753, green: 0.384, blue: 0.184) // #C0622F terracotta
    static let sonderSage         = Color(red: 0.290, green: 0.486, blue: 0.435) // #4A7C6F sage green

    // Text
    static let sonderTextPrimary  = Color(red: 0.110, green: 0.110, blue: 0.118) // #1C1C1E
    static let sonderTextSecond   = Color(red: 0.420, green: 0.420, blue: 0.420) // #6B6B6B

    // Legacy aliases so old call-sites compile unchanged
    static let night900   = sonderBackground
    static let night800   = sonderSurface
    static let night700   = sonderDivider
    static let slate700   = sonderDivider
    static let slate500   = sonderTextSecond
    static let slate400   = sonderTextSecond
    static let slate300   = sonderTextSecond
    static let accentAmber = sonderAccent
}

// MARK: - Georgia Font Helpers

extension Font {
    static func georgia(_ size: CGFloat) -> Font {
        Font.custom("Georgia", size: size)
    }
    static func georgiaBold(_ size: CGFloat) -> Font {
        Font.custom("Georgia-Bold", size: size)
    }
    static func georgiaItalic(_ size: CGFloat) -> Font {
        Font.custom("Georgia-Italic", size: size)
    }
}
