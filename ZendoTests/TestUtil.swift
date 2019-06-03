import Foundation
import HealthKit

@testable import Zendo

class TestUtil {
    class func createStr(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = kUTCSubscriptionDateFormat
        return formatter.string(from: date)
    }
}
