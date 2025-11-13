//
//  Feed.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/12/25.
//

import Foundation

// MARK: - Feed 데이터 모델 (임시)

struct Feed: Identifiable, Hashable {
    let id: String            // post_id
    let imageURL: String
    let content: String
    let creator: User  // 피드게시글 작성 유저
    let createdAt: Date
    let likes: [String]       // 좋아요 배열 - 좋아요한 사람들 [String]
                              // 숫자 카운트만 쓰면 Int
    let commentCount: Int
    
    //TODO: - 삭제 예정
    // Pinterest Layout을 위한 계산된 높이 비율
    var aspectRatio: CGFloat {
        // Mock에서는 랜덤하게, 실제로는 이미지 메타데이터에서 가져올 수 있음
        return .random(in: 1.0...1.8)
    }

}
