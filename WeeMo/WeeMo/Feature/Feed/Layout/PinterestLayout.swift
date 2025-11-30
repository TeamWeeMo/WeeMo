//
//  PinterestLayout.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/8/25.
//

import SwiftUI

// MARK: - Pinterest Style Waterfall Layout

/// Pinterest 스타일의 2단 그리드 레이아웃
/// 각 아이템의 높이가 다를 수 있으며, 더 짧은 컬럼에 다음 아이템을 배치
///
/// **SwiftUI Layout 프로토콜 (iOS 16+)**
/// - `sizeThatFits`: 레이아웃이 차지할 전체 크기 계산
/// - `placeSubviews`: 각 서브뷰를 실제로 배치
/// - `makeCache`: 성능 최적화를 위한 캐시 생성
struct PinterestLayout: Layout {
    var numberOfColumns: Int = 2
    var spacing: CGFloat = 8

    // 캐시 구조체: 각 아이템의 프레임 정보 저장
    // 매번 재계산하지 않고 캐시에 저장하여 성능 향상
    struct Cache {
        var frames: [CGRect] = []
        var totalHeight: CGFloat = 0
    }

    /// 캐시 초기화
    /// - Parameter subviews: 레이아웃에 포함될 서브뷰들
    /// - Returns: 빈 캐시 구조체
    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }

    /// 레이아웃이 차지할 전체 크기를 계산
    /// - Parameters:
    ///   - proposal: 부모 뷰가 제안하는 크기
    ///   - subviews: 배치할 서브뷰들
    ///   - cache: 계산 결과를 저장할 캐시
    /// - Returns: 레이아웃의 전체 크기 (width, height)
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let width = proposal.width ?? 0

        // 각 아이템의 프레임 계산 (핵심 로직)
        cache.frames = calculateFrames(
            width: width,
            subviews: subviews
        )

        // 가장 긴 컬럼의 높이를 전체 높이로 설정
        cache.totalHeight = cache.frames.map { $0.maxY }.max() ?? 0

        return CGSize(width: width, height: cache.totalHeight)
    }

    /// 각 서브뷰를 실제로 화면에 배치
    /// - Parameters:
    ///   - bounds: 레이아웃이 그려질 영역
    ///   - proposal: 부모 뷰가 제안하는 크기
    ///   - subviews: 배치할 서브뷰들
    ///   - cache: 미리 계산된 프레임 정보
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        for (index, subview) in subviews.enumerated() {
            guard index < cache.frames.count else { continue }

            let frame = cache.frames[index]

            // 절대 좌표로 변환 (bounds 기준)
            let position = CGPoint(
                x: bounds.minX + frame.minX,
                y: bounds.minY + frame.minY
            )

            // 서브뷰에게 크기를 "제안"하고 배치
            // ProposedViewSize로 크기를 제안하면, 서브뷰는 자신의 sizeThatFits를 통해 실제 크기 결정
            subview.place(
                at: position,
                proposal: ProposedViewSize(
                    width: frame.width,
                    height: frame.height
                )
            )
        }
    }

    // MARK: - Private Methods

    /// Waterfall 알고리즘: 각 아이템을 가장 짧은 컬럼에 배치
    /// - Parameters:
    ///   - width: 전체 레이아웃 너비
    ///   - subviews: 배치할 서브뷰들
    /// - Returns: 각 아이템의 CGRect 배열
    private func calculateFrames(
        width: CGFloat,
        subviews: Subviews
    ) -> [CGRect] {
        guard !subviews.isEmpty else { return [] }

        // 1. 컬럼 너비 계산
        // 전체 너비에서 spacing을 제외한 나머지를 컬럼 수로 나눔
        let totalSpacing = spacing * CGFloat(numberOfColumns - 1)
        let columnWidth = (width - totalSpacing) / CGFloat(numberOfColumns)

        // 2. 각 컬럼의 현재 높이 추적 (처음엔 모두 0)
        var columnHeights = Array(repeating: CGFloat.zero, count: numberOfColumns)
        var frames: [CGRect] = []

        for subview in subviews {
            // 3. 가장 짧은 컬럼 찾기 (Waterfall 핵심 알고리즘)
            let shortestColumnIndex = columnHeights.enumerated()
                .min(by: { $0.element < $1.element })?
                .offset ?? 0

            // 4. 서브뷰에게 컬럼 너비를 제안하고, 실제 높이를 받아옴
            // 여기서 FeedCardView의 sizeThatFits가 호출됨
            let itemHeight = subview.sizeThatFits(
                ProposedViewSize(
                    width: columnWidth,
                    height: nil  // 높이는 nil로 제안 -> 서브뷰가 자유롭게 결정
                )
            ).height

            // 5. 프레임 계산 (x: 컬럼 위치, y: 해당 컬럼의 현재 높이)
            let x = CGFloat(shortestColumnIndex) * (columnWidth + spacing)
            let y = columnHeights[shortestColumnIndex]

            let frame = CGRect(
                x: x,
                y: y,
                width: columnWidth,
                height: itemHeight
            )

            frames.append(frame)

            // 6. 해당 컬럼의 높이 업데이트 (아이템 높이 + spacing)
            columnHeights[shortestColumnIndex] += itemHeight + spacing
        }

        return frames
    }
}
