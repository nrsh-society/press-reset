class Foregrounder {
    var window: UIWindow!
    var workoutSessionReporter: WorkoutSessionReporter!

    init(window: UIWindow, workoutSessionReporter: WorkoutSessionReporter) {
        self.window = window
        self.workoutSessionReporter = workoutSessionReporter
    }

    func execute() {
        workoutSessionReporter.doesOptInCandidateHaveAnySessionsToUpload() { shouldUpload in
            if !shouldUpload {
                return
            }

            let onUserWantsUpload: (UIAlertAction) -> () = { action in
                self.workoutSessionReporter.generateMeditationSessionCSVForUpload() { workout, csvPath in
                    let activityChooser =
                        UIActivityViewController(activityItems: [csvPath as Any],
                                                 applicationActivities: [])

                    activityChooser.excludedActivityTypes = [
                        UIActivityType.assignToContact,
                        UIActivityType.saveToCameraRoll,
                        UIActivityType.postToFlickr,
                        UIActivityType.postToVimeo,
                        UIActivityType.postToTencentWeibo,
                        UIActivityType.postToTwitter,
                        UIActivityType.postToFacebook,
                        UIActivityType.openInIBooks
                    ]

                    activityChooser.completionWithItemsHandler = { activityType, completed, items, error in
                        if completed {
                            Settings.lastUploadDateStr = workout.startDate.toUTCSubscriptionString
                            return
                        }

                        let errorMsg = error?.localizedDescription ?? ""
                        print("failed during activity view actions: \(errorMsg)")
                    }

                    DispatchQueue.main.async {
                        self.window.topViewController?.present(activityChooser, animated: true)
                    }
                }
            }

            let alert = UIAlertController(title: "Sessions ready for upload",
                                          message: "Some meditation sessions are ready to upload via email. Would you like to upload them now?",
                                          preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: onUserWantsUpload))
            alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: nil))
            DispatchQueue.main.async {
                self.window.topViewController?.present(alert, animated: true)
            }
        }
    }
}
