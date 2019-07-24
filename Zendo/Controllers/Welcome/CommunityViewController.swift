//
//  CommunityViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 30/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Mixpanel

class CommunityViewController: UIViewController {
    class var storyboardIdentifier: String { get { return "CommunityViewController" } }
    class var skipToHealthKitSegueID: String { get { return "SkipToHealthKit" } }

    @IBOutlet weak var topSpace: NSLayoutConstraint!
    @IBOutlet weak var topSpaceTextField: NSLayoutConstraint!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var nextBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var nextButton: ZenButton! {
        didSet {
            nextButton.alpha = 0.0
        }
    }
    @IBOutlet weak var fullName: ZenTextField! {
        didSet {
            fullName.zenTextFieldType = .fullName
            fullName.textField.delegate = self
        }
    }
    @IBOutlet weak var email: ZenTextField! {
        didSet {
            email.zenTextFieldType = .email
            email.textField.delegate = self
        }
    }
    @IBOutlet var labels: [UILabel]!
    @IBOutlet weak var skipButton: UIBarButtonItem!

    @IBOutlet weak var wallet: ZenTextField! {
        didSet {
            wallet.zenTextFieldType = .wallet
            wallet.textField.delegate = self
        }
    }
    
    
    var bottomSpaceNext: CGFloat = 37.0

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.mainInstance().time(event: "community")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "community")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.small {
            bottomSpaceNext = 20.0
            topSpace.constant = 20.0
            topSpaceTextField.constant = 15.0
            stackView.spacing = 20.0
            nextBottomSpace.constant = bottomSpaceNext
        }
        
        for label in labels {
            label.font = UIFont.zendo(font: .antennaRegular, size: label.font.pointSize - (UIDevice.small ? 2 : 0))
            if label.tag == 2 {
                let attributedString = NSMutableAttributedString(string: label.text ?? "")
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineHeightMultiple = 1.43
                
                attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
                
                label.attributedText = attributedString
            }
        }
        
        hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
        nextButton.action = {
            self.next()
        }
        
        fullName.editingChanged = { _ in
            self.check()
        }
        
        email.editingChanged = { _ in
            self.check()
        }
    }
    
    static func loadFromStoryboard() -> CommunityViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CommunityViewController") as! CommunityViewController
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            if nextBottomSpace.constant == bottomSpaceNext {
                nextBottomSpace.constant += keyboardSize.height
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            }
            
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            if nextBottomSpace.constant > bottomSpaceNext {
                nextBottomSpace.constant -= keyboardSize.height
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            }
            
        }
    }
    
    func check() {
        if (fullName.textField.text?.isEmpty)! {
            isHiddenNextButton(true)
        } else if (email.textField.text?.isEmpty)! {
            isHiddenNextButton(true)
        } else if !(email.textField.text?.isEmail())! {
            isHiddenNextButton(true)
        } else {
            isHiddenNextButton(false)
        }
    }
    
    func isHiddenNextButton(_ isHidden: Bool) {
        if (nextButton.alpha == 0.0 && !isHidden || nextButton.alpha == 1.0 && isHidden) {
            UIView.animate(withDuration: 0.3) {
                self.nextButton.alpha = isHidden ? 0.0 : 1.0
            }
        }
    }
    
    func next() {
        if (fullName.textField.text?.isEmpty)! {
            showAlert(text: "Name required")
        } else if (email.textField.text?.isEmpty)! {
            showAlert(text: "Email required")
        } else if !(email.textField.text?.isEmail())! {
            showAlert(text: "Invalid Email")
        } else {
            Settings.didFinishCommunitySignup = true
            Settings.fullName = fullName.textField.text
            Settings.email = email.textField.text
            Settings.ilpAddress = wallet.textField.text
            
            if let name = Settings.fullName, let email = Settings.email
            {
                Mixpanel.mainInstance().createAlias(email, distinctId: Mixpanel.mainInstance().distinctId)
                
                Mixpanel.mainInstance().identify(distinctId: email)
                
                Mixpanel.mainInstance().people.set(properties: ["$name": name])
                Mixpanel.mainInstance().people.set(properties: ["$email": email])
            }
            
            view.endEditing(true)
            let healthKit = HealthKitViewController.loadFromStoryboard()
            self.navigationController?.pushViewController(healthKit, animated: true)
        }
    }
    
    func showAlert(text: String) {
        let alert = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @IBAction func didSkip(sender: Any?) {
        Settings.skippedCommunitySignup = true
        performSegue(withIdentifier: CommunityViewController.skipToHealthKitSegueID, sender: nil)
    }
}

extension CommunityViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == ZenTextFieldType.fullName.rawValue {
            email.textField.becomeFirstResponder()
            return true
        } else if textField.tag == ZenTextFieldType.email.rawValue {
            next()
            return true
        }
        return false
    }
    
}
