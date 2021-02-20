//
//  ContactsInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Doug Purdy on 4/30/20.
//  Copyright © 2020 zenbf. All rights reserved.
//

import Foundation
import UIKit
import Contacts
import WatchKit


class ContactsInterfaceController : WKInterfaceController
{
    
    @IBOutlet var contactsTable: WKInterfaceTable!
    
    
    //for when we ask for friends on the watch, we are going to do it on the phone for now
    
    func checkForContactsAccess(andThen f:(()->())? = nil) {
        let status = CNContactStore.authorizationStatus(for:.contacts)
        switch status {
        case .authorized:
            f?()
        case .notDetermined:
            CNContactStore().requestAccess(for:.contacts) { ok, err in
                if ok {
                    DispatchQueue.main.async {
                        f?()
                    }
                }
            }
        case .restricted:
            // do nothing
            break
        case .denied:
            // do nothing, or beg the user to authorize us in Settings
            print("denied")
            break
        @unknown default: fatalError()
        }
    }
    
}
