//
//  Foregrounder.swift
//  Zendo
//
//  Copyright © 2019 zenbf. All rights reserved.
//

import MessageUI

class Foregrounder: NSObject, MFMailComposeViewControllerDelegate {
    //var description: String
    
    var window: UIWindow!
    var workoutSessionReporter: WorkoutSessionReporter!
    
    init(window: UIWindow, workoutSessionReporter: WorkoutSessionReporter) {
        self.window = window
        self.workoutSessionReporter = workoutSessionReporter
    }
    
    func showSendMailErrorAlert() {
        let alert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async {
            self.window.topViewController?.present(alert, animated: true)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func execute() {
        
        if !Settings.isUploadDate {
            return
        }
        
        workoutSessionReporter.doesOptInCandidateHaveAnySessionsToUpload() { shouldUpload in
            if !shouldUpload {
                return
            }
            
            let onUserWantsUpload: (UIAlertAction) -> () = { action in
                self.workoutSessionReporter.generateMeditationSessionCSVForUpload() { workout, csvPath in

                    let composeVC = MFMailComposeViewController()
                    if (MFMailComposeViewController.canSendMail()) {
                        composeVC.mailComposeDelegate = self

                        // Configure the fields of the interface.
                        composeVC.setToRecipients(["info@zenbf.org"])
                        composeVC.setSubject("Session Data")

                        do {
                            let data = try Data(contentsOf: csvPath)
                            composeVC.addAttachmentData(data, mimeType: "text/csv", fileName: "zazen.csv")
                        } catch {
                            print("Cannot read data")
                        }

                        // Present the view controller modally.
                        self.window.topViewController?.present(composeVC, animated: true)
                        Settings.lastUploadDateStr = workout.startDate.toUTCSubscriptionString
                    } else {
                        self.showSendMailErrorAlert()
                    }

                }

            }
            
            let alert = UIAlertController(title: "Sessions ready for upload",
                                          message: "Some meditation sessions are ready to upload via email. Would you like to upload them now?",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: onUserWantsUpload))
            alert.addAction(UIAlertAction(title: "Not now", style: .cancel))
            DispatchQueue.main.async {
                Settings.isUploadDate = false
                self.window.topViewController?.present(alert, animated: true)
            }
        }

    }
}

