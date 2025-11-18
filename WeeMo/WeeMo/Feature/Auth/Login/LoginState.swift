//
//  LoginState.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation

struct LoginState {
    var id: String = ""
    var idError: String = ""
    var pw: String = ""
    var pwError: String = ""

    var isLoading: Bool = false    //로그인 요청 중인지 확인하는 trigger
    var loginErrorMessage: String? = nil
    var isLoginSucceeded: Bool = false
}
