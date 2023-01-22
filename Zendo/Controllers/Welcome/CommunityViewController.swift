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

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet weak var topSpace: NSLayoutConstraint!
    @IBOutlet weak var topSpaceTextField: NSLayoutConstraint!
    @IBOutlet weak var TOSPP: UITextView!
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
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        Mixpanel.mainInstance().time(event: "community")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        Mixpanel.mainInstance().track(event: "community")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        
        if UIDevice.small || checkZoomed() {
            topSpace.constant = 10.0
            topSpaceTextField.constant = 15.0
            stackView.spacing = 20.0
            nextBottomSpace.constant = 10
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
        
        nextButton.action = {
            self.next()
        }
        
        fullName.editingChanged = { _ in
            self.check()
        }
        
        email.editingChanged = { _ in
            self.check()
        }
        
        setTOSPP()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillChangeFrame,
                                               object: nil,
                                               queue: .main)
        { [weak self] (notification) in
            
            if let userInfo = notification.userInfo,
                let rect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect {
                self?.scrollView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: rect.size.height, right: 0)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide,
                                               object: nil,
                                               queue: .main)
        { [weak self] (notification) in
            
            self?.scrollView.contentInset = .zero
        }
    }
    
    static func loadFromStoryboard() -> CommunityViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CommunityViewController") as! CommunityViewController
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
           // Settings.ilpAddress = wallet.textField.text
            
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
    
    let kTAndPP = "kTAndPP"
    let kTAndPP2 = "kTAndPP2"
    
    func setTOSPP() {
        
        let fontLabel = UIFont.zendo(font: .antennaRegular, size: 14)
        
        let string = "By joining the community, you are agreeing to our Terms and Privacy Policy"
        let attributedString = NSMutableAttributedString(string: string)
        
        let foundRange = attributedString.mutableString.range(of: "By joining the community, you are agreeing to our")
        let foundRange2 = attributedString.mutableString.range(of: "Terms")
        let foundRange3 = attributedString.mutableString.range(of: "and")
        let foundRange4 = attributedString.mutableString.range(of: "Privacy Policy")
        
        attributedString.addAttribute(.font, value: fontLabel, range: foundRange)
        attributedString.addAttribute(.font, value: fontLabel, range: foundRange3)
        
        attributedString.addAttributes([
            .link: kTAndPP,
            .font: fontLabel
        ], range: foundRange2)
        
        attributedString.addAttributes([
            .link: kTAndPP2,
            .font: fontLabel
        ], range: foundRange4)
                
        TOSPP.delegate = self
        TOSPP.attributedText = attributedString
        TOSPP.textColor = UIColor.zenLightGray2
        TOSPP.textAlignment = .left
        
        TOSPP.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor.rawValue: UIColor.zenDarkGreen
        ]
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


extension CommunityViewController: UITextViewDelegate {
    
    
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        guard let urlT = URL(string: "https://app.termly.io/document/terms-of-use-for-website/4c956fe5-e097-47f2-9b91-5da9fcc50a1a"),
            let urlPP = URL(string: "http://zendo.tools/privacy") else { return false }
        
        if url.absoluteString == kTAndPP {
            UIApplication.shared.open(urlT)
        } else if url.absoluteString == kTAndPP2 {
            print("Privacy Policy")
            UIApplication.shared.open(urlPP)
        }
        
        return false
    }
    
}
