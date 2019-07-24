class WorkoutFetcher {
    func getWorkouts(since date: Date, handler: @escaping ZBFHealthKit.GetSamplesHandler) {
        ZBFHealthKit.getWorkouts(since: date, handler: handler)
    }
}
