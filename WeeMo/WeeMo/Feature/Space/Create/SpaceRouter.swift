//
//  SpaceRouter.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import Foundation
import Alamofire

// MARK: - Space Router (Space 전용)

enum SpaceRouter: APIRouter {
    case createSpace(title: String, price: Int, content: String, files: [String], value1: String, value2: String, value3: String, /*value4: String, value5: String,*/ longitude: Double, latitude: Double)

    var method: HTTPMethod {
        .post
    }

    var path: String {
        let version = NetworkConstants.apiVersion
        return "\(version)/posts"
    }

    var parameters: Parameters? {
        switch self {
        case .createSpace(let title, let price, let content, let files, let value1, let value2, let value3, /*let value4, let value5,*/ let longitude, let latitude):
            return [
                "title": title,
                "price": price,
                "content": content,
                "category": "space",
                "files": files,
                "value1": value1,
                "value2": value2,
                "value3": value3,
                //"value4": value4,
                //"value5": value5,
                "longitude": longitude,  // Number 타입
                "latitude": latitude  // Number 타입
            ]
        }
    }

    var encoding: ParameterEncoding {
        JSONEncoding.default
    }
}
