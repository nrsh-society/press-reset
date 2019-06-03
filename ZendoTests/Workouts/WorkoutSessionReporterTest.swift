import HealthKit
import XCTest
import Quick
import Nimble

@testable import Zendo

class WorkoutSessionReporterTest: QuickSpec {
    override func spec() {
        describe("WorkoutSessionReporter") {
            var subject: WorkoutSessionReporter!
            var mockWorkoutFetcher: MockWorkoutFetcher!

            beforeEach {
                subject = WorkoutSessionReporter()
                mockWorkoutFetcher = MockWorkoutFetcher()
                subject.workoutFetcher = mockWorkoutFetcher
            }

            afterEach {
                Settings.lastUploadDateStr = nil
            }

            describe("findOptInCandidateSessionsForUpload") {
                describe("when the active user has opted in") {
                    beforeEach {
                        subject.values = ["email@example.com": true]
                        Settings.email = "email@example.com"
                    }
                    
                    describe("before the user has ever uploaded anything") {
                        beforeEach {
                            subject.doesOptInCandidateHaveAnySessionsToUpload() {result in}
                        }

                        it("fetches all sessions since before the beginning of this app's life") {
                            let expectedArg = Date.createFrom(year: 2000, month: 1, day: 1)

                            expect(mockWorkoutFetcher.getWorkoutsSinceCallCount).to(equal(1))
                            expect(mockWorkoutFetcher.getWorkoutsSinceDateArgForCall[0]).to(equal(expectedArg))
                        }
                    }

                    describe("when user has uploaded stuff previously") {
                        var callbackResult: Bool?

                        beforeEach {
                            Settings.lastUploadDateStr = TestUtil.createStr(from: Date.createFrom(year: 2019, month: 1, day: 15)!)
                            subject.doesOptInCandidateHaveAnySessionsToUpload() { result in
                                callbackResult = result
                            }
                        }

                        afterEach {
                            Settings.lastUploadDateStr = nil
                        }

                        it("fetches all sessions since the last recorded upload date") {
                            let expectedArg = Date.createFrom(year: 2019, month: 1, day: 15)!.addingTimeInterval(1)
                            expect(mockWorkoutFetcher.getWorkoutsSinceCallCount).to(equal(1))
                            expect(mockWorkoutFetcher.getWorkoutsSinceDateArgForCall[0]).to(equal(expectedArg))
                        }

                        describe("when there are no samples") {
                            beforeEach {
                                mockWorkoutFetcher.getWorkoutsSinceHandlerArgForCall[0]!([])
                            }

                            it("calls back with false") {
                                expect(callbackResult).toEventually(beFalse())
                            }
                        }
                    }
                }
            }
        }
    }
}
