import HealthKit

class MetadataExtractor {
    func extract(fromWorkout workout: HKWorkout) -> [[String: Any]] {
        guard let metadata = workout.metadata else {
            return [[String: Any]]()
        }
        var samples = [[String: Any]]()

        let timeArray = (metadata[MetadataType.time.rawValue] as! String).components(separatedBy: "/")
        let nowArray = (metadata[MetadataType.now.rawValue] as! String).components(separatedBy: "/")
        let motionArray = (metadata[MetadataType.motion.rawValue] as! String).components(separatedBy: "/")
        let sdnnArray = (metadata[MetadataType.sdnn.rawValue] as! String).components(separatedBy: "/")
        let heartArray = (metadata[MetadataType.heart.rawValue] as! String).components(separatedBy: "/")
        let pitchArray = (metadata[MetadataType.pitch.rawValue] as! String).components(separatedBy: "/")
        let rollArray = (metadata[MetadataType.roll.rawValue] as! String).components(separatedBy: "/")
        let yawArray = (metadata[MetadataType.yaw.rawValue] as! String).components(separatedBy: "/")

        for (index, _) in timeArray.enumerated() {
            samples.append([
                MetadataType.time.rawValue: timeArray[index],
                MetadataType.now.rawValue: nowArray[index],
                MetadataType.motion.rawValue: motionArray[index],
                MetadataType.sdnn.rawValue: sdnnArray[index],
                MetadataType.heart.rawValue: heartArray[index],
                MetadataType.pitch.rawValue: pitchArray[index],
                MetadataType.roll.rawValue: rollArray[index],
                MetadataType.yaw.rawValue: yawArray[index]
                ])
        }

        return samples
    }
}
