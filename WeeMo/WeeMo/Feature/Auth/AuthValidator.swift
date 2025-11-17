//
//  AuthValidator.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation

enum AuthValidator {
    static func checkId(_ id: String) -> String {
        if id.isEmpty {
            return "이메일을 입력해주세요"
        } else if !id.contains("@") {
            return "이메일 형식이 잘못되었어요"
        } else if id.count >= 100 {
            return "이메일이 너무 길어요. 다시 확인해주세요"
        } else {
            return ""
        }
    }

    static func checkPw(_ pw: String) -> String {
        let pattern = "^(?!.*[.,?*\\-@+\\^${\\}()|\\[\\]\\\\])\\S+$"

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return "비밀번호 형식을 확인해주세요"
        }

        let range = NSRange(location: 0, length: pw.utf16.count)
        let isMatch = regex.firstMatch(in: pw, range: range) != nil

        if pw.isEmpty {
            return "비밀번호를 입력해주세요"
        }

        if !isMatch {
            return "공백 또는 특수문자는 사용할 수 없어요"
        } else {
            return ""
        }
    }

    static func checkNickname(_ nickname: String) -> String {
        if nickname.isEmpty {
            return "닉네임을 입력해주세요"
        } else if nickname.count < 2 {
            return "닉네임은 2자 이상이어야 해요"
        } else if nickname.count > 20 {
            return "닉네임이 너무 길어요. 다시 확인해주세요"
        } else {
            return ""
        }
    }
}
