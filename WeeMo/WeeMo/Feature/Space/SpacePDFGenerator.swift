//
//  SpacePDFGenerator.swift
//  WeeMo
//
//  Created by Reimos on 2025/11/30.
//

import UIKit
import PDFKit

// MARK: - Space PDF Generator

/// 공간 상세 정보를 PDF로 생성하는 유틸리티
struct SpacePDFGenerator {

    // MARK: - PDF 생성

    /// 공간 정보와 예약 정보를 포함한 PDF 생성
    static func generatePDF(
        space: Space,
        reservationInfos: [ReservationInfo],
        spaceImage: UIImage? = nil
    ) -> URL? {
        // PDF 메타데이터 설정
        let pdfMetaData = [
            kCGPDFContextCreator: "WeeMo",
            kCGPDFContextAuthor: "WeeMo",
            kCGPDFContextTitle: space.title
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        // A4 사이즈 (595 x 842)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var currentY: CGFloat = 40

            // 1. 제목
            currentY = drawTitle(space.title, at: currentY, in: pageRect)
            currentY += 20

            // 2. 공간 이미지
            if let image = spaceImage {
                currentY = drawImage(image, at: currentY, in: pageRect)
                currentY += 20
            }

            // 3. 카테고리
            currentY = drawCategory(space.category, at: currentY, in: pageRect)
            currentY += 10

            // 4. 해시태그
            if !space.hashTags.isEmpty {
                currentY = drawHashTags(space.hashTags, at: currentY, in: pageRect)
                currentY += 10
            }

            // 구분선 (상단)
            currentY = drawDivider(at: currentY, in: pageRect)
            currentY += 20

            // 5. 기본 정보
            currentY = drawBasicInfo(space, at: currentY, in: pageRect)
            currentY += 20

            // 구분선 (중단)
            currentY = drawDivider(at: currentY, in: pageRect)
            currentY += 20

            // 6. 편의시설
            currentY = drawFacilities(space, at: currentY, in: pageRect)
            
            // [수정됨] 편의시설과 구분선 사이 여백 줄임 (30 -> 20)
            currentY += 20
            
            // 구분선 그리기
            currentY = drawDivider(at: currentY, in: pageRect)
            
            // [수정됨] 구분선과 공간 소개 사이 여백 줄임 (30 -> 20)
            currentY += 20

            // 7. 공간 소개 (바닥 여백 로직 적용됨)
            currentY = drawDescription(space.description, at: currentY, in: pageRect)
            
            // 공간 소개가 끝난 후 다음 요소와의 간격
            currentY += 25

            // 예약 정보 섹션 - 페이지 체크 후 필요시 새 페이지 추가
            let reservationSectionHeight: CGFloat = reservationInfos.isEmpty ? 150 : CGFloat(reservationInfos.count * 180 + 60)

            if currentY + reservationSectionHeight > pageRect.height {
                context.beginPage()
                currentY = 40
            }

            // 8. 예약 정보
            if !reservationInfos.isEmpty {
                currentY = drawReservationCards(reservationInfos, at: currentY, in: pageRect)
            } else {
                currentY = drawNoReservationMessage(at: currentY, in: pageRect)
            }
        }

        // 임시 파일로 저장
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("space_\(space.id).pdf")

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("PDF 저장 실패: \(error)")
            return nil
        }
    }

    // MARK: - Drawing Helpers

    private static func drawImage(_ image: UIImage, at y: CGFloat, in rect: CGRect) -> CGFloat {
        let imageWidth = rect.width - 80
        let imageHeight: CGFloat = 200

        let aspectRatio = image.size.width / image.size.height
        var drawWidth = imageWidth
        var drawHeight = imageHeight

        if aspectRatio > (imageWidth / imageHeight) {
            drawHeight = imageWidth / aspectRatio
        } else {
            drawWidth = imageHeight * aspectRatio
        }

        let xOffset = 40 + (imageWidth - drawWidth) / 2
        let imageRect = CGRect(x: xOffset, y: y, width: drawWidth, height: drawHeight)
        image.draw(in: imageRect)

        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.systemGray4.cgColor)
        context?.setLineWidth(1)
        context?.stroke(imageRect)

        return y + imageHeight
    }

    private static func drawTitle(_ title: String, at y: CGFloat, in rect: CGRect) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 28),
            .foregroundColor: UIColor.label
        ]

        let attributedString = NSAttributedString(string: title, attributes: attributes)
        let textRect = CGRect(x: 40, y: y, width: rect.width - 80, height: 50)
        attributedString.draw(in: textRect)

        return y + 30
    }

    private static func drawCategory(_ category: SpaceCategory, at y: CGFloat, in rect: CGRect) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20),
            .foregroundColor: UIColor.systemBlue
        ]

        let categoryText = "[\(category.rawValue)]"
        let attributedString = NSAttributedString(string: categoryText, attributes: attributes)
        let textRect = CGRect(x: 40, y: y, width: rect.width - 80, height: 25)
        attributedString.draw(in: textRect)

        return y + 25
    }

    private static func drawHashTags(_ tags: [String], at y: CGFloat, in rect: CGRect) -> CGFloat {
        let tagsText = tags.map { "#\($0)" }.joined(separator: " ")

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.secondaryLabel
        ]

        let attributedString = NSAttributedString(string: tagsText, attributes: attributes)
        let textRect = CGRect(x: 40, y: y, width: rect.width - 80, height: 40)
        attributedString.draw(in: textRect)

        return y + 30
    }

    private static func drawDivider(at y: CGFloat, in rect: CGRect) -> CGFloat {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.systemGray4.cgColor)
        context?.setLineWidth(1)
        context?.move(to: CGPoint(x: 40, y: y))
        context?.addLine(to: CGPoint(x: rect.width - 40, y: y))
        context?.strokePath()

        return y + 1
    }

    private static func drawBasicInfo(_ space: Space, at y: CGFloat, in rect: CGRect) -> CGFloat {
        var currentY = y

        let fullAddress: String
        if let roadAddress = space.roadAddress, !roadAddress.isEmpty {
            fullAddress = "\(space.address), \(roadAddress)"
        } else {
            fullAddress = space.address
        }
        
        currentY = drawInfoRow(icon: "📍", label: "주소", value: fullAddress, at: currentY, in: rect)
        currentY += 28

        currentY = drawInfoRow(icon: "💰", label: "가격", value: space.formattedPrice, at: currentY, in: rect)
        currentY += 28

        currentY = drawInfoRow(icon: "⭐️", label: "평점", value: space.formattedDetailRating, at: currentY, in: rect)
        
        return currentY + 28
    }

    private static func drawFacilities(_ space: Space, at y: CGFloat, in rect: CGRect) -> CGFloat {
        var currentY = y

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.label
        ]

        let title = NSAttributedString(string: "편의시설", attributes: titleAttributes)
        title.draw(at: CGPoint(x: 40, y: currentY))
        
        currentY += 40

        let contentFontSize: CGFloat = 16
        let rowSpacing: CGFloat = 22

        // 주차
        let parkingIcon = space.hasParking ? "🅿️" : "🚫"
        let parkingText = space.hasParking ? "주차 가능" : "주차 불가"
        currentY = drawInfoRow(icon: parkingIcon, label: "", value: parkingText, at: currentY, in: rect, fontSize: contentFontSize)
        currentY += rowSpacing

        // 화장실
        let bathroomIcon = space.hasBathRoom ? "🚻" : "🚫"
        let bathroomText = space.hasBathRoom ? "화장실 있음" : "화장실 없음"
        currentY = drawInfoRow(icon: bathroomIcon, label: "", value: bathroomText, at: currentY, in: rect, fontSize: contentFontSize)
        currentY += rowSpacing

        // 최대인원
        currentY = drawInfoRow(icon: "👥", label: "", value: "\(space.maxPeople)명까지", at: currentY, in: rect, fontSize: contentFontSize)

        return currentY + rowSpacing
    }

    private static func drawDescription(_ description: String, at y: CGFloat, in rect: CGRect) -> CGFloat {
        var currentY = y

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.label
        ]

        let title = NSAttributedString(string: "공간 소개", attributes: titleAttributes)
        title.draw(at: CGPoint(x: 40, y: currentY))
        
        currentY += 40

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6

        let fullAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: paragraphStyle
        ]

        let content = NSAttributedString(string: description, attributes: fullAttributes)
        
        // [수정됨] 바닥 여백 확보를 위한 동적 높이 계산
        let bottomPadding: CGFloat = 40 // 바닥에서 띄울 최소 안전 여백
        // 현재 위치에서 바닥 안전 여백 전까지 남은 높이 계산
        let availableHeight = rect.height - currentY - bottomPadding
        // 사용 가능한 높이가 음수가 되지 않도록 처리 (최소 0)
        let actualTextHeight = max(0, availableHeight)

        // 기존의 고정 높이(180) 대신 계산된 가용 높이를 사용하여 그리기 영역 설정
        let textRect = CGRect(x: 40, y: currentY, width: rect.width - 80, height: actualTextHeight)
        
        // 텍스트가 영역을 넘치면 자동으로 잘림(clipping)
        content.draw(in: textRect)

        // 실제로 텍스트 영역으로 잡은 높이만큼 Y축 증가
        return currentY + actualTextHeight
    }

    private static func drawReservationCards(_ infos: [ReservationInfo], at y: CGFloat, in rect: CGRect) -> CGFloat {
        var currentY = y

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.label
        ]

        let title = NSAttributedString(string: "예약 정보", attributes: titleAttributes)
        title.draw(at: CGPoint(x: 40, y: currentY))
        
        currentY += 40

        for (index, info) in infos.enumerated() {
            currentY = drawReservationCard(info, at: currentY, in: rect, showTitle: false)

            if index < infos.count - 1 {
                currentY += 15
            }
        }

        return currentY
    }

    private static func drawReservationCard(_ info: ReservationInfo, at y: CGFloat, in rect: CGRect, showTitle: Bool = true) -> CGFloat {
        var currentY = y

        if showTitle {
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor.label
            ]
            let title = NSAttributedString(string: "예약 정보", attributes: titleAttributes)
            title.draw(at: CGPoint(x: 40, y: currentY))
            currentY += 40
        }

        let cardHeight: CGFloat = 150
        let cardRect = CGRect(x: 40, y: currentY, width: rect.width - 80, height: cardHeight)

        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemGray6.cgColor)
        let roundedPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 12)
        roundedPath.fill()

        context?.setStrokeColor(UIColor.systemGray4.cgColor)
        context?.setLineWidth(1)
        roundedPath.stroke()

        let padding: CGFloat = 20
        var cardContentY = currentY + padding
        let rowSpacing: CGFloat = 28

        cardContentY = drawCardRow(icon: "👤", label: "예약자", value: info.userName, at: cardContentY, startX: 40 + padding)
        cardContentY += rowSpacing

        cardContentY = drawCardRow(icon: "📅", label: "예약 날짜", value: info.date, at: cardContentY, startX: 40 + padding)
        cardContentY += rowSpacing

        cardContentY = drawCardRow(icon: "⏰", label: "예약 시간", value: info.timeSlot, at: cardContentY, startX: 40 + padding)
        cardContentY += rowSpacing

        let priceAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.systemBlue
        ]
        let priceIcon = NSAttributedString(string: "💳 ", attributes: [.font: UIFont.systemFont(ofSize: 20)])
        let priceLabel = NSAttributedString(string: "총 금액: ", attributes: [.font: UIFont.systemFont(ofSize: 18), .foregroundColor: UIColor.secondaryLabel])
        let priceValue = NSAttributedString(string: info.totalPrice, attributes: priceAttributes)

        priceIcon.draw(at: CGPoint(x: 40 + padding, y: cardContentY))
        priceLabel.draw(at: CGPoint(x: 40 + padding + 35, y: cardContentY))
        priceValue.draw(at: CGPoint(x: 40 + padding + 120, y: cardContentY))

        return currentY + cardHeight + 10
    }

    private static func drawCardRow(icon: String, label: String, value: String, at y: CGFloat, startX: CGFloat) -> CGFloat {
        var xOffset = startX

        let iconAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18)
        ]
        let iconString = NSAttributedString(string: icon, attributes: iconAttributes)
        iconString.draw(at: CGPoint(x: xOffset, y: y))
        xOffset += 35

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let labelString = NSAttributedString(string: label + ":", attributes: labelAttributes)
        labelString.draw(at: CGPoint(x: xOffset, y: y))
        xOffset += 90

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.label
        ]
        let valueString = NSAttributedString(string: value, attributes: valueAttributes)
        valueString.draw(at: CGPoint(x: xOffset, y: y))

        return y
    }

    private static func drawInfoRow(
        icon: String,
        label: String,
        value: String,
        at y: CGFloat,
        in rect: CGRect,
        isSecondary: Bool = false,
        fontSize: CGFloat? = nil
    ) -> CGFloat {
        let defaultSize: CGFloat = isSecondary ? 16 : 18
        let currentFontSize: CGFloat = fontSize ?? defaultSize
        let color = isSecondary ? UIColor.tertiaryLabel : UIColor.secondaryLabel

        var xOffset: CGFloat = 40

        if !icon.isEmpty {
            let iconAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: currentFontSize)
            ]
            let iconString = NSAttributedString(string: icon, attributes: iconAttributes)
            iconString.draw(at: CGPoint(x: xOffset, y: y))
            xOffset += 35
        } else if isSecondary {
            xOffset += 35
        }

        if !label.isEmpty {
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: currentFontSize),
                .foregroundColor: color
            ]
            let labelString = NSAttributedString(string: label, attributes: labelAttributes)
            labelString.draw(at: CGPoint(x: xOffset, y: y))
            xOffset += 90
        }

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: currentFontSize),
            .foregroundColor: UIColor.label
        ]
        let valueString = NSAttributedString(string: value, attributes: valueAttributes)
        valueString.draw(at: CGPoint(x: xOffset, y: y))

        return y
    }

    private static func drawNoReservationMessage(at y: CGFloat, in rect: CGRect) -> CGFloat {
        var currentY = y

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.label
        ]

        let title = NSAttributedString(string: "예약 정보", attributes: titleAttributes)
        title.draw(at: CGPoint(x: 40, y: currentY))
        currentY += 40

        let messageRect = CGRect(x: 40, y: currentY, width: rect.width - 80, height: 90)

        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemGray6.cgColor)
        let roundedPath = UIBezierPath(roundedRect: messageRect, cornerRadius: 12)
        roundedPath.fill()

        context?.setStrokeColor(UIColor.systemGray4.cgColor)
        context?.setLineWidth(1)
        roundedPath.stroke()

        let iconAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 42)
        ]
        let icon = NSAttributedString(string: "📋", attributes: iconAttributes)

        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let message = NSAttributedString(string: "예약 정보가 없습니다", attributes: messageAttributes)

        let iconSize = icon.size()
        let messageSize = message.size()
        let totalWidth = iconSize.width + 10 + messageSize.width
        let startX = 40 + (messageRect.width - totalWidth) / 2
        let centerY = currentY + (messageRect.height - iconSize.height) / 2

        icon.draw(at: CGPoint(x: startX, y: centerY))
        message.draw(at: CGPoint(x: startX + iconSize.width + 10, y: centerY + (iconSize.height - messageSize.height) / 2))

        return currentY + 90 + 10
    }
}

// MARK: - Reservation Info Model

struct ReservationInfo {
    let userName: String
    let date: String
    let timeSlot: String
    let totalPrice: String
}
