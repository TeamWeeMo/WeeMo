//
//  Font+Extension.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/7/25.
//

import SwiftUI

enum WeeMoFont {
    static let light = "S-CoreDream-3Light"
    static let regular = "S-CoreDream-4Regular"
    static let medium = "S-CoreDream-5Medium"
    static let bold = "S-CoreDream-6Bold"
}

enum AppFontSize: CGFloat, CaseIterable {
    case s10 = 10
    case s12 = 12
    case s14 = 14
    case s16 = 16
    case s18 = 18
    case s20 = 20
    case s22 = 22
    case s24 = 24
}

//MARK: - 폰트스타일

enum AppTextStyle {
    case headline1 // Bold, 24
    case headline2  // Bold, 20
    case headline3  // Medium, 20
    case headline4  // Bold 18
    case subHeadline1 // Medium, 18
    case subHeadline2 // Medium, 16
    case content1 // Regular, 16
    case content2 // Regular, 14
    case content3 // Light, 16
    case content4 // Light, 14
    case subContent1 // Regular, 12
    case subContent2 // Light, 12
    case subContent3 // Regular, 10
    case subContent4 // Light, 10
}

struct AppTypography {
    let name: String
    let size: CGFloat

    static func style(_ s: AppTextStyle) -> AppTypography {
        switch s {
        case .headline1:
            return .init(name: WeeMoFont.bold,
                         size: AppFontSize.s24.rawValue)
        case .headline2:
            return .init(name: WeeMoFont.bold,
                         size: AppFontSize.s20.rawValue)
        case .headline3:
            return .init(name: WeeMoFont.medium,
                         size: AppFontSize.s20.rawValue)
        case .subHeadline1:
            return .init(name: WeeMoFont.medium,
                         size: AppFontSize.s18.rawValue)
        case .subHeadline2:
            return .init(name: WeeMoFont.medium,
                         size: AppFontSize.s16.rawValue)
        case .content1:
            return .init(name: WeeMoFont.regular,
                         size: AppFontSize.s16.rawValue)
        case .content2:
            return .init(name: WeeMoFont.regular,
                         size: AppFontSize.s14.rawValue)
        case .content3:
            return .init(name: WeeMoFont.light,
                         size: AppFontSize.s16.rawValue)
        case .content4:
            return .init(name: WeeMoFont.light,
                         size: AppFontSize.s14.rawValue)
        case .subContent1:
            return .init(name: WeeMoFont.regular,
                         size: AppFontSize.s12.rawValue)
        case .subContent2:
            return .init(name: WeeMoFont.light,
                         size: AppFontSize.s12.rawValue)
        case .subContent3:
            return .init(name: WeeMoFont.regular,
                         size: AppFontSize.s10.rawValue)
        case .subContent4:
            return .init(name: WeeMoFont.light,
                         size: AppFontSize.s10.rawValue)
        case .headline4:
            return .init(name: WeeMoFont.bold,
                         size: AppFontSize.s18.rawValue)
        }
    }
}

extension Font {
    static func app(_ style: AppTextStyle) -> Font {
        let typo = AppTypography.style(style)
        return .custom(typo.name, size: typo.size)
    }
}
