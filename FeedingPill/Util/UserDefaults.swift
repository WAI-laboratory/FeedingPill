import UIKit

@propertyWrapper
struct UserDefault<T> {
    private let key: String
    private let defaultValue: T

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            // Read value from UserDefaults
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            // Set value to UserDefaults
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

struct UserDefaultsData {
    
    @UserDefault(key: "appNotiStatus", defaultValue: "unknown")
    static var appNotiStatus: String
}

// Publisher 를 쓸경우

extension UserDefaults {
//    @objc var appName: String {
//        get {
//            return string(forKey: "appName") ?? ""
//        }
//        
//        set {
//            set(newValue, forKey: "appName")
//        }
//    }
//    
//    @objc var isLockAvailable: Bool {
//        get {
//            return bool(forKey: "isLockAvailable")
//        }
//        
//        set {
//            set(newValue, forKey: "isLockAvailable")
//        }
//    }
}
