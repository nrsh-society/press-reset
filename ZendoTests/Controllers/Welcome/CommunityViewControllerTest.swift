import XCTest
import Quick
import Nimble
import Fleet
@testable import Zendo

class CommunityViewControllerTest: QuickSpec {
    override func spec() {
        describe("CommunityViewController") {
            var subject: CommunityViewController!
            var healthKitViewController: HealthKitViewController!

            beforeEach {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                healthKitViewController = try! storyboard.mockIdentifier(
                    "HealthKitViewController",
                    usingMockFor: HealthKitViewController.self)
                subject = (storyboard.instantiateViewController(
                    withIdentifier: "CommunityViewController") as! CommunityViewController)

                let navigationController = UINavigationController(rootViewController: subject)
                Fleet.setAsAppWindowRoot(navigationController)
            }

            describe("When hitting the 'Skip' button") {
                beforeEach {
                    subject.skipButton.tap()
                }

                it("presents the HealthKitViewController") {
                    expect(Fleet.getApplicationScreen()?.topmostViewController).toEventually(beIdenticalTo(healthKitViewController))
                }

                it("registers in settings that the user skipped community setup") {
                    expect(Settings.didFinishCommunitySignup).toEventually(beFalse())
                    expect(Settings.skippedCommunitySignup).toEventually(beTrue())
                }
            }
        }
    }
}
