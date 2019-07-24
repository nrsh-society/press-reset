import XCTest
import Quick
import Nimble
import Fleet

@testable import Zendo

class ForegrounderTest: QuickSpec {
    override func spec() {
        describe("Foregrounder") {
            var subject: Foregrounder!
            var workoutSessionReporter: MockWorkoutSessionReporter!

            var screen: FLTScreen!

            beforeEach {
                let window = UIApplication.shared.keyWindow!
                workoutSessionReporter = MockWorkoutSessionReporter()
                subject = Foregrounder(window: window,
                                       workoutSessionReporter: workoutSessionReporter)
                screen = Fleet.getScreen(forWindow: window)
            }

            describe("execute") {
                beforeEach {
                    subject.execute()
                }

                it("checks to see if any workout sessions require uploading") {
                    expect(workoutSessionReporter.doesOptInCandidateHaveAnySessionsToUploadCallCount).to(equal(1))
                }

                describe("when there are sessions to upload") {
                    beforeEach {
                        workoutSessionReporter.doesOptInCandidateHaveAnySessionsToUploadCapturedHandler!(true)
                    }

                    it("presents an alert informing the user") {
                        expect(screen.topmostViewController).toEventually(beAKindOf(UIAlertController.self))

                        let alertController = screen.topmostViewController as? UIAlertController
                        expect(alertController?.message).to(equal("Some meditation sessions are ready to upload via email. Would you like to upload them now?"))
                    }

                    describe("when the user taps 'Yes'") {
                        beforeEach {
                            let alertController = screen.topmostViewController as? UIAlertController
                            alertController?.tapAlertAction(withTitle: "Yes")
                        }
                    }
                }
            }
        }
    }
}
