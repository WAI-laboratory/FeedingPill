//
//  DBService.swift
//  Edison
//
//  Created by 이용준 on 2022/06/01.
//

import Foundation
import RealmSwift
import Combine
import CloudKit

class DBService: ObservableObject {
    typealias ErrorFactory = DBServiceErrorFactory
    static let shared: DBService = .init()
    var realm: Realm = try! Realm()
    init() {
    }

    func update<Element>(_ object: Element) where Element : Object {
        update([object])
    }
    
    func update<Element>(_ objects: [Element]) where Element : Object {
        guard !objects.isEmpty else { return }
        
        do {
            try realm.write {
                realm.add(objects, update: .all)
            }
        } catch {
            Log.error("\(#file) \(#function) \(#line)", error)
        }
    }

    
    func delete<Element>(objects: Results<Element>) where Element : Object & SoftDeletable  {
        try! realm.write {
            for _object in objects {
                var object = _object
                object.isActive = false
            }
        }
    }
}



enum DBServiceErrorFactory: ErrorFactory {
    enum Code: Int {
        case realmInitFailed = 0
        case pullFailed = 1
    }
    
    static func realmInitFailed(_ error: Error) -> NSError {
        return NSError(domain: domain, code: Code.realmInitFailed.rawValue, userInfo: [NSUnderlyingErrorKey : error])
    }
    
    static func pullFailed(_ error: Error) -> NSError {
        return NSError(domain: domain, code: Code.pullFailed.rawValue, userInfo: [NSUnderlyingErrorKey : error])
    }
}
