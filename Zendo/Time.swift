class Time {
    static func digitalClockString(fromSeconds seconds: Int) -> String {
        let minutesComponent = seconds / 60
        let secondsComponent = seconds % 60
        return String(format: "%02d:%02d", minutesComponent, secondsComponent)
    }
}
