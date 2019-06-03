import Foundation
import HealthKit

class WorkoutSessionReporter {
    var workoutFetcher = WorkoutFetcher()
    var metadataExtractor = MetadataExtractor()

    let urlString = URL(string: "https://s3.amazonaws.com/zenbf.org/opt-in.json")
    var values : [String: Any]?
    var task: URLSessionDataTask?

    func doesOptInCandidateHaveAnySessionsToUpload(_ handler: @escaping (Bool) -> ()) {
        if (didActiveUserOptIn()) {
            var since: Date!
            if Settings.lastUploadDate == nil {
                since = Date.createFrom(year: 2000, month: 1, day: 1)
            } else {
                since = Settings.lastUploadDate!.addingTimeInterval(1)
            }
            workoutFetcher.getWorkouts(since: since) { samples in
                guard let nextUploadSample = samples.first else {
                    handler(false)
                    return
                }
                guard nextUploadSample is HKWorkout else {
                    handler(false)
                    return
                }

                handler(true)
            }
        }
    }

    func generateMeditationSessionCSVForUpload(_ onCSVFileWritten: @escaping (HKWorkout, URL) -> ()) {
        if (didActiveUserOptIn()) {
            var since: Date!
            if Settings.lastUploadDate == nil {
                since = Date.createFrom(year: 2000, month: 1, day: 1)
            } else {
                since = Settings.lastUploadDate!.addingTimeInterval(1)
            }

            workoutFetcher.getWorkouts(since: since) { samples in
                guard let nextUploadSample = samples.first else {
                    return
                }
                guard let workout = nextUploadSample as? HKWorkout else {
                    return
                }

                let fileName = "workout-\(nextUploadSample.startDate.toUTCString).csv"
                let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

                var csvText = "start, end, now, hr, sdnn, motion\n"

                let samples = self.metadataExtractor.extract(fromWorkout: workout)

                for sample in samples {
                    let now = sample["now"] ?? ""
                    let heart = sample["heart"] ?? ""
                    let sdnn = sample["sdnn"] ?? ""
                    let motion = sample["motion"] ?? ""

                    let line : String =
                        "\(workout.startDate),"  +
                        "\(workout.endDate)," +
                        "\(now)," +
                        "\(heart)," +
                        "\(sdnn)," +
                        "\(motion)"

                    csvText += line + "\n"
                }
                do {
                    try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    print("Failed to create file")
                    print("\(error)")
                }

                onCSVFileWritten(workout, path!)
            }
        } else {
            print("not match")
        }
    }

    func loadOptInCandidates() {
        if let url = urlString {
            self.task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error as Any)
                } else {
                    if let usableData = data {
                        self.values = try! JSONSerialization.jsonObject(with: usableData, options: []) as! [String : Any]
                    }
                }
            }
            task!.resume()
        }
    }

    func didActiveUserOptIn() -> Bool {
        var value = false

        if let emailList = values {

            if let email = Settings.email {
                if let optInFlag = emailList[email] {
                    value = optInFlag as! Bool
                }
            }
        }
        return value;
    }
}
