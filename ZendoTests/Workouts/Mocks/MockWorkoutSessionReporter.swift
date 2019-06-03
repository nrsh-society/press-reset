@testable import Zendo

class MockWorkoutSessionReporter: WorkoutSessionReporter {
    var doesOptInCandidateHaveAnySessionsToUploadCallCount = 0
    var doesOptInCandidateHaveAnySessionsToUploadCapturedHandler: ((Bool) -> ())?

    override func doesOptInCandidateHaveAnySessionsToUpload(_ handler: @escaping (Bool) -> ()) {
        doesOptInCandidateHaveAnySessionsToUploadCallCount += 1
        doesOptInCandidateHaveAnySessionsToUploadCapturedHandler = handler
    }
}
