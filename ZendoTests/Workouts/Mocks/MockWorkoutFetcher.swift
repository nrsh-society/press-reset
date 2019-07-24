@testable import Zendo

class MockWorkoutFetcher: WorkoutFetcher {
    var getWorkoutsSinceCallCount: Int = 0
    var getWorkoutsSinceDateArgForCall: [Int:Date] = [:]
    var getWorkoutsSinceHandlerArgForCall: [Int:ZBFHealthKit.GetSamplesHandler] = [:]

    override func getWorkouts(since date: Date, handler: @escaping ZBFHealthKit.GetSamplesHandler) {
        getWorkoutsSinceDateArgForCall[getWorkoutsSinceCallCount] = date
        getWorkoutsSinceHandlerArgForCall[getWorkoutsSinceCallCount] = handler
        getWorkoutsSinceCallCount += 1
    }
}
