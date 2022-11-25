class AlarmService {
    static let shared = AlarmService()
    
    private let pushNotificationManager = PushNotificationManager.shared
    private let dbService = DBService.shared
//    private let userDefaults = UserDefaultsData.shared
    
    func set(repeatable alarm: RepeatableAlarm?, isUpdate: Bool) {
        guard let alarm = alarm else { return }
        
        dbService.update(alarm)
        pushNotificationManager.scheduleNotification(reminder: alarm)
    }
    
    func set(single alarm: SingleAlarm?, isUpdate: Bool) {
        guard let alarm = alarm else { return }
        
        dbService.update(alarm)
        pushNotificationManager.scheduleNotification(reminder: alarm)
    }
}
