//
//  ZenTextField.swift
//  Zendo
//
//  Created by Anton Pavlov on 30/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//
    
import UIKit

enum ZenTextFieldType: Int {
    case fullName = 0, email, wallet
    
    var placeholder: String {
        switch self {
        case .fullName: return "enter full name"
        case .email: return "email"
        case .wallet : return "ilp wallet"
        }
    }
    
}

class TextFieldPlaceHolder: UITextField {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "", attributes:[.foregroundColor: UIColor.zenLightGreen, .font: UIFont.zendo(font: .antennaRegular, size: 14.0)])

    }
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        var superRect = super.caretRect(for: position)
        
        superRect.size.height = frame.height - 2
        superRect.size.width = 1
        superRect.origin.y = 1.0
        
        return superRect
    }

}

@IBDesignable class ZenTextField: UIView {
    
    @IBOutlet weak var textField: UITextField!
    
    var zenTextFieldType = ZenTextFieldType.fullName
    var editingChanged: ((String)->())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textField.placeholder = zenTextFieldType.placeholder
        textField.tag = zenTextFieldType.rawValue
        
        switch zenTextFieldType {
        case .fullName:
            textField.textContentType = .name
            textField.autocapitalizationType = .words
            textField.keyboardType = .default
        case .email:
            textField.textContentType = .emailAddress
            textField.autocapitalizationType = .none
            textField.keyboardType = .emailAddress
            textField.returnKeyType = .next
        case .wallet:
            textField.textContentType = .name
            textField.autocapitalizationType = .none
            textField.keyboardType = .asciiCapableNumberPad
        }
        
    }
    
    
    @IBAction func editingChanged(_ sender: TextFieldPlaceHolder) {
        editingChanged?(sender.text?.trimmingCharacters(in: .whitespaces) ?? "")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }
    
}
