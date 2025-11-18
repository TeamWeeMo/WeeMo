//
//  AnyModifier+Extension.swift
//  WeeMo
//
//  Created by Reimos on 11/15/25
//

import Foundation
import Kingfisher

extension AnyModifier {
    /// WeeMo API 요청을 위한 헤더를 추가하는 Modifier
    static var weeMoRequestModifier: AnyModifier {
        return AnyModifier { request in
            var modifiedRequest = request

            // 1. SeSACKey 추가
            if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
                modifiedRequest.setValue(sesacKey, forHTTPHeaderField: "SeSACKey")
            }

            // 2. ProductId 추가
            modifiedRequest.setValue("WeeMo", forHTTPHeaderField: "ProductId")

            // 3. Authorization (AccessToken) 추가
            if let token = UserDefaults.standard.string(forKey: "accessToken") {
                modifiedRequest.setValue(token, forHTTPHeaderField: "Authorization")
            }

            return modifiedRequest
        }
    }
}
