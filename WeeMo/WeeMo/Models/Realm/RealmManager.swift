//
//  RealmManager.swift
//  WeeMo
//
//  Created by 차지용 on 11/20/25.
//

import Foundation
import RealmSwift

// MARK: - Realm Manager

/// Realm 데이터베이스 관리자
class RealmManager {
    static let shared = RealmManager()

    private init() {}

    private var realm: Realm {
        do {
            return try Realm()
        } catch {
            fatalError("Realm initialization error: \(error)")
        }
    }

    // MARK: - Generic CRUD Operations

    /// 객체 저장
    func save<T: Object>(_ object: T) throws {
        try realm.write {
            realm.add(object, update: .modified)
        }
    }

    /// 객체 배열 저장
    func save<T: Object>(_ objects: [T]) throws {
        try realm.write {
            realm.add(objects, update: .modified)
        }
    }

    /// 객체 조회
    func fetch<T: Object>(_ type: T.Type) -> Results<T> {
        return realm.objects(type)
    }

    /// 특정 키로 객체 조회
    func fetch<T: Object>(_ type: T.Type, primaryKey: Any) -> T? {
        return realm.object(ofType: type, forPrimaryKey: primaryKey)
    }

    /// 객체 삭제
    func delete<T: Object>(_ object: T) throws {
        try realm.write {
            realm.delete(object)
        }
    }

    /// 객체 배열 삭제
    func delete<T: Object>(_ objects: Results<T>) throws {
        try realm.write {
            realm.delete(objects)
        }
    }

    /// 모든 데이터 삭제
    func deleteAll() throws {
        try realm.write {
            realm.deleteAll()
        }
    }

    /// Realm write 블록 실행
    func write(_ block: () throws -> Void) throws {
        try realm.write {
            try block()
        }
    }
}
