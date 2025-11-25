//
//  PostMapper+Meet.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Post Mapper (Meet)

extension PostDTO {

    /// DTO → Domain Model 변환 (Meet)
    ///
    /// value 필드 매핑:
    /// - value1: 모집인원 (capacity)
    /// - value2: 성별제한 (0: 누구나, 1: 남성만, 2: 여성만)
    /// - value3: 예약 정보 ISO 형식 (yyyyMMddHHmm,totalHours)
    /// - value4: 공간정보 (spaceId|spaceName|address|imageURL)
    /// - value5: 모집 시작일 (ISO8601)
    /// - value6: 모집 종료일 (ISO8601)
    func toMeet() -> Meet {

        // 모집 인원
        let capacity = Int(value1 ?? "1") ?? 1
        // 참여인원
        let participants = buyers.count

        // 성별 제한
        let genderValue = Int(value2 ?? "0") ?? 0
        let gender = Gender(rawValue: genderValue)

        // 예약 정보 ISO 형식 (value3: "yyyyMMddHHmm,totalHours")
        let reservationInfo = parseReservationInfo(from: value3)

        // 공간 정보 (value4: "spaceId|spaceName|address" 형식)
        let spaceInfo = parseSpaceInfo(from: value4)

        // 모집 기간 (value5: 시작일, value6: 종료일)
        let recruitmentStartDate = value5?.toDate() ?? Date()
        let recruitmentEndDate = value6?.toDate() ?? Date()

        // 참가비 계산 (이미 계산된 price 사용 또는 계산)
        let pricePerPerson = price ?? 0

        return Meet(
            id: postId,
            title: title,
            content: content,
            imageURLs: files,
            creator: creator.toDomain(),
            createdAt: createdAt.toDate() ?? Date(),
            capacity: capacity,
            participants: participants,
            gender: gender,
            recruitmentStartDate: recruitmentStartDate,
            recruitmentEndDate: recruitmentEndDate,
            reservationInfo: reservationInfo,
            spaceId: spaceInfo.id,
            spaceName: spaceInfo.name,
            address: spaceInfo.address,
            spaceImageURL: spaceInfo.imageURL,
            latitude: geolocation.latitude,
            longitude: geolocation.longitude,
            pricePerPerson: pricePerPerson,
            likeCount: likes.count,
            distance: distance
        )
    }

    // MARK: - Private Parsing Helpers

    /// 예약 정보 파싱 (ISO 형식: yyyyMMddHHmm,totalHours)
    /// - Parameter value: ISO 형식 문자열 (예: "202511211400,3")
    /// - Returns: ISO 형식 문자열 (# 제거)
    private func parseReservationInfo(from value: String?) -> String {
        guard let value = value, !value.isEmpty else {
            // 기본값: 현재 날짜/시간, 1시간
            let now = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: now)
            return ReservationFormatter.createReservationISO(date: now, startHour: hour, totalHours: 1)
                .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        }

        // 이미 ISO 형식인 경우 (yyyyMMddHHmm,totalHours)
        // # 제거하고 반환
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    }

    /// 공간 정보 파싱
    /// - Parameter value: "spaceId|spaceName|address|imageURL" 형식의 문자열
    private func parseSpaceInfo(from value: String?) -> (id: String?, name: String, address: String, imageURL: String?) {
        guard let value = value else {
            return (nil, "", "", nil)
        }

        let components = value.components(separatedBy: "|")

        let id = components.first
        let name = components.count > 1 ? components[1] : ""
        let address = components.count > 2 ? components[2] : ""
        let imageURL = components.count > 3 ? components[3] : nil

        return (id, name, address, imageURL)
    }
}
