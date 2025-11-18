//
//  SignState.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation

struct SignState {
    var email: String = ""
    var password: String = ""
    var nickname: String = ""

    var emailError: String = ""
    var passwordError: String = ""
    var nicknameError: String = ""

    var isLoading: Bool = false
    var isEmailValidated: Bool = false

    var signUpErrorMessage: String? = nil
    var isSignUpSucceeded: Bool = false
}
