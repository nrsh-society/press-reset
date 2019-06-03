import XCTest
import Quick
import Nimble

@testable import Zendo

class DateInitializersTest: QuickSpec {
    override func spec() {
        describe("Custom date initializers") {
            it("") {
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                formatter.dateFormat = kUTCDateFormat

                let dateOne = Date.createFrom(year: 2019, month: 5, day: 15)
                expect(dateOne).toNot(beNil())
                expect(formatter.string(from: dateOne!)).to(equal("2019-05-15T12:00:00.000 +0000"))
            }
        }
    }
}
