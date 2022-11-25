import Foundation
import OSLog

public protocol ErrorFactory {
  static var domain: String { get }
  associatedtype Code: RawRepresentable where Code.RawValue == Int
}

extension ErrorFactory {
  public static var domain: String { "\(Self.self)" }
}


public enum ErrorReporter {
    private static let log = OSLog(subsystem: "com.WAI.FeedingPill", category: "ErrorReporter")
    
    public static func report(_ error: Error) {
        guard !canIgnore(error) else { return }
        
        log(error)
    }
    
    public static func log(_ error: Error) {
        os_log("⚠️⚠️ Error ⚠️⚠️ %@", log: log, type: .error, error as NSError)
    }
    
    public static func log(_ message: String) {
        os_log("⚠️⚠️ Error ⚠️⚠️ %@", log: log, type: .error, message)
    }
    
    
    private static func canIgnore(_ error: Error) -> Bool {
        let nsError = error as NSError

        switch (nsError.domain, nsError.code) {
        case (URLError.errorDomain, URLError.networkConnectionLost.rawValue),
            (URLError.errorDomain, URLError.cancelled.rawValue),
            (URLError.errorDomain, URLError.cannotConnectToHost.rawValue),
            (URLError.errorDomain, URLError.cannotFindHost.rawValue),
            (URLError.errorDomain, URLError.cannotLoadFromNetwork.rawValue),
            (URLError.errorDomain, URLError.dnsLookupFailed.rawValue),
            (URLError.errorDomain, URLError.networkConnectionLost.rawValue),
            (URLError.errorDomain, URLError.notConnectedToInternet.rawValue),
            (URLError.errorDomain, URLError.timedOut.rawValue):
            return true
        default:
            break
        }
        return false
    }
}
