import UIKit
import Combine
import UserNotifications

class PushNotificationManager: NSObject {
    typealias ErrorFactory = PushNotificationManagerErrorFactory
    static let shared = PushNotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    let onNotificationStatusDidChange = PassthroughSubject<Void, Never>()
    
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func requestAuthorization(completion: ((Bool, Error?) -> Void)? = nil) {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        notificationCenter.requestAuthorization(options: options) { [weak self] (isOn, error) in
            self?.setNotificationSettingsOnUserData()
            self?.onNotificationStatusDidChange.send(())
            
            if let error = error {
                ErrorReporter.report(ErrorFactory.requestAuthorization(error))
            }
            completion?(isOn, error)
        }
    }
    
    func setNotificationSettingsOnUserData()  {
        notificationCenter.getNotificationSettings { (setting) in
            switch setting.authorizationStatus {
            case .notDetermined:
                UserDefaultsData.appNotiStatus = "undecided"
            case .denied:
                UserDefaultsData.appNotiStatus = "disagree"
            case .authorized, .ephemeral, .provisional:
                UserDefaultsData.appNotiStatus = "agree"
            @unknown default:
                UserDefaultsData.appNotiStatus = "unknown"
            }
        }
    }
    
    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        notificationCenter.getNotificationSettings { (setting) in
            completion(setting)
        }
    }
    
    func onTest() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Staff Meeting"
        content.body = "Every Tuesday at 2pm"
//        content.sound = .defaultRingtone
//        content.sound = .defaultCritical
        content.sound = .default
        content.badge = 3
        // Configure the recurring date.
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current

        dateComponents.hour = 1    // 14:00 hours
        dateComponents.minute = 37
           
        // Create the trigger as a repeating event.
        let trigger = UNCalendarNotificationTrigger(
                 dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                    content: content, trigger: trigger)

        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
           if error != nil {
              // Handle any errors.
           }
        }
    }
    
    func scheduleNotification(reminder: any AlarmProtocol) {
        unscheduleNotification(reminderIdentifier: reminder.id)
        if var reminder = reminder as? SingleAlarm {
            var dateCompoenet = DateComponents()
            dateCompoenet.year = reminder.targetDate.year
            dateCompoenet.month = reminder.targetDate.month
            dateCompoenet.day = reminder.targetDate.day
            dateCompoenet.hour = reminder.targetDate.hour
            dateCompoenet.minute = reminder.targetDate.minute
            dateCompoenet.second = reminder.targetDate.second
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateCompoenet, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.content
            content.sound = .default
            content.categoryIdentifier = reminder.type
            // TODO: - userinfo 바꾸기
            content.userInfo = ["url" : "/" + reminder.type]
            let identifier = reminder.id // reminder.id
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) {(error) in
                if let error = error {
                    ErrorReporter.report(ErrorFactory.scheduleNotification(error, reminder))
                }
            }
        } else if var reminder = reminder as? RepeatableAlarm {
            var weekdaysSorted:[Int] = [Int]()
            
            weekdaysSorted = reminder.repeatDays.sorted(by: <)
            
            for day in weekdaysSorted {
                if reminder.isEnable {
                    
                    for date in reminder.dates {
                        var weekly = DateComponents()
                        weekly.calendar = Calendar(identifier: .gregorian)
                        weekly.hour = date.hour
                        weekly.minute = date.minute
                        weekly.weekday = day
                        
                        let trigger = UNCalendarNotificationTrigger(dateMatching: weekly, repeats: true)
                        
                        let content = UNMutableNotificationContent()
                        content.title = reminder.title
                        content.body = "Take a Pill!"
                        content.sound = .default
                        content.categoryIdentifier = reminder.type
                        let identifier = reminder.id + "-\(day)" // reminder.id + 요일 숫자
                        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                        UNUserNotificationCenter.current().add(request) {(error) in
                            if let error = error {
                                ErrorReporter.report(ErrorFactory.scheduleNotification(error, reminder))
                            }
                        }
                        
                    }
                }
            }
            
        }
    }
    func unscheduleNotification(reminderIdentifier: String) {
        var identifiers = [Int](0...6).map { "\(reminderIdentifier)-\($0)"}
        identifiers.append(reminderIdentifier)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func showNotificationImmediately(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) {(error) in
            if let error = error {
                ErrorReporter.report(ErrorFactory.showNotificationImmediately(error, title, body))
            }
        }
    }
    
    enum NotiStatus: String {
        case agree
        case disagree
        case undecided
        case unknown
        
        var name: String {
            return self.rawValue
        }
    }
}

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .list, .badge, .sound])
    }
}



extension Dictionary {
    public func getStringOrNil(_ key: Key) -> String? {
        switch self[key] {
        case let value as String:
            return value
        default:
            return nil
        }
    }
}

enum PushNotificationManagerErrorFactory: ErrorFactory {
    enum Code: Int {
        case scheduleNotification = 0
        case scheduleInduceNotification = 1
        case scheduleThreeDayChallengeNotification = 2
        case showNotificationImmediately = 3
        case requestAuthorization = 4
    }
    
    static func scheduleNotification(_ underlying: Error, _ reminder: AlarmProtocol) -> NSError {
        return NSError(
            domain: domain,
            code: Code.scheduleNotification.rawValue,
            userInfo:
                [
                    NSUnderlyingErrorKey: underlying,
                    "reminder": reminder
                ]
        )
    }
    
    static func scheduleInduceNotificationDayRequest(_ underlying: Error, _ days: Int) -> NSError {
        return NSError(
            domain: domain,
            code: Code.scheduleInduceNotification.rawValue,
            userInfo:
                [
                    NSUnderlyingErrorKey: underlying,
                    "days": days,
                    "request": "dayRequest"
                ]
        )
    }
    
    static func scheduleInduceNotificationNightRequest(_ underlying: Error, _ days: Int) -> NSError {
        return NSError(
            domain: domain,
            code: Code.scheduleInduceNotification.rawValue,
            userInfo:
                [
                    NSUnderlyingErrorKey: underlying,
                    "days": days,
                    "request": "nightRequest"
                ]
        )
    }
    
    static func scheduleThreeDayChallengeNotification(_ underlying: Error) -> NSError {
        return NSError(
            domain: domain,
            code: Code.scheduleThreeDayChallengeNotification.rawValue,
            userInfo:
                [
                    NSUnderlyingErrorKey: underlying,
                ]
        )
        
    }
    
    static func showNotificationImmediately(_ underlying: Error, _ title: String, _ body: String) -> NSError {
        return NSError(
            domain: domain,
            code: Code.showNotificationImmediately.rawValue,
            userInfo:
                [
                    NSUnderlyingErrorKey: underlying,
                    "title": title,
                    "body": body
                ]
        )
    }
    
    static func requestAuthorization(_ underlying: Error) -> NSError {
        return NSError(
            domain: domain,
            code: Code.requestAuthorization.rawValue,
            userInfo:
                [
                    NSUnderlyingErrorKey: underlying,
                ]
        )
    }
}

