import Foundation
import RealmSwift

protocol AlarmProtocol {
    var id: String { get set }
    var type: String { get set }
    var title: String { get set }
    var content: String { get set }
    var createdAt: Date { get set }
    var modifiedAt: Date { get set }
}


class SingleAlarm: SoftDeletableObject, AlarmProtocol {
    @Persisted(primaryKey: true) var id = UUID().uuidString
    @Persisted var targetDate = Date()
    @Persisted var type: String = ""
    @Persisted var title = ""
    @Persisted var content = ""
    @Persisted var isActive: Bool = true
    @Persisted var isEnable: Bool = true
    @Persisted var createdAt = Date()
    @Persisted var modifiedAt = Date()
}

class RepeatableAlarm: SoftDeletableObject, AlarmProtocol {
    @Persisted(primaryKey: true) var id = UUID().uuidString
    @Persisted var dates = List<Date>()
    @Persisted var repeatDays = List<Int>()
    @Persisted var type: String = ""
    @Persisted var title = ""
    @Persisted var content = ""
    @Persisted var pillType = PillType.nutrients.rawValue
    @Persisted var isActive: Bool = true
    @Persisted var isEnable: Bool = true
    @Persisted var createdAt = Date()
    @Persisted var modifiedAt = Date()
    @Persisted var onSnooze: Bool = false
    @Persisted var imageUrl: String? = nil
    
    var thumbnailImageUrl: String? {
        guard let imageUrl else { return nil }
        return imageUrl + "_thumbnail"
    }
}

enum PillType: String {
    case nutrients
    case medicine
}

extension Date {
    var formattedTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: self)
    }
}

enum AlarmType: String {
    case normal
}
