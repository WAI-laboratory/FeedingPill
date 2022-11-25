import Foundation
import Realm
import RealmSwift

protocol SoftDeletable {
    var id: String { get set }
    var isActive: Bool { get set }
}

typealias SoftDeletableObject = SoftDeletable & Object
