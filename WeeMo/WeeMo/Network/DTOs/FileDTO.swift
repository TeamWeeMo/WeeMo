//
//  FileDTO.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - File DTOs

/// 파일 업로드 응답
struct FileDTO: Decodable {
    let files: [String]
}
