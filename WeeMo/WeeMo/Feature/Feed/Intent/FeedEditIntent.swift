//
//  FeedEditIntent.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation
import UIKit

// MARK: - Feed Edit Intent

enum FeedEditIntent {
    // 라이프사이클
    case onAppear

    // 입력
    case updateContent(String)
    case selectImages([UIImage])
    case selectVideo(URL?)
    case removeImage(at: Int)

    // 액션
    case submitPost
    case cancel

    // 내부 이벤트
    case uploadImagesSuccess([String])  // 이미지 업로드 성공 (파일 경로 리스트)
    case uploadImagesFailed(Error)
    case createPostSuccess(Feed)
    case createPostFailed(Error)
    case setError(String)
}
