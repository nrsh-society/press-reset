import XCTest
import Quick
import Nimble

@testable import Zendo

class TimeTest: QuickSpec {
    override func spec() {
        describe("Time-related utils") {
            describe("Creating a digital clock string") {
                it("") {
                    expect(Time.digitalClockString(fromSeconds: 0)).to(equal("00:00"))
                    expect(Time.digitalClockString(fromSeconds: 1)).to(equal("00:01"))
                    expect(Time.digitalClockString(fromSeconds: 30)).to(equal("00:30"))
                    expect(Time.digitalClockString(fromSeconds: 31)).to(equal("00:31"))
                    expect(Time.digitalClockString(fromSeconds: 60)).to(equal("01:00"))
                    expect(Time.digitalClockString(fromSeconds: 61)).to(equal("01:01"))
                    expect(Time.digitalClockString(fromSeconds: 599)).to(equal("09:59"))
                    expect(Time.digitalClockString(fromSeconds: 600)).to(equal("10:00"))
                    expect(Time.digitalClockString(fromSeconds: 601)).to(equal("10:01"))
                }
            }
        }
    }
}
