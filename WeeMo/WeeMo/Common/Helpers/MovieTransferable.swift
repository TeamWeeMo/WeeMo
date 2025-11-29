//
//  MovieTransferable.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Movie Transferable

/// PhotosPicker에서 동영상을 로드하기 위한 Transferable 타입
struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.temporaryDirectory.appending(path: "movie_\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Movie(url: copy)
        }
    }
}
