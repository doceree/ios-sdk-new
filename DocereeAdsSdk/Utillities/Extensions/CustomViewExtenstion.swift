//
//  CustomViewExtenstion.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 26/06/23.
//

import Foundation
import UIKit

extension customView {
    func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    func removeObserver() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension customView {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtFieldName {
            textField.resignFirstResponder()
            txtFieldPhone.becomeFirstResponder()
        } else if textField == txtFieldPhone {
            txtFieldPhone.resignFirstResponder()
            txtFieldEmail.becomeFirstResponder()
        } else if textField == txtFieldEmail {
            textField.resignFirstResponder()
        }
        
        if textField == txtFieldAddress {
            textField.resignFirstResponder()
            txtFieldPincode.becomeFirstResponder()
        } else if textField == txtFieldPincode {
            textField.resignFirstResponder()
        }
        
        return true
    }
}

extension customView {
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

            if let textfield = activeTextField {
                let parentVC = self.parentViewController
                let frame = parentVC?.view.getConvertedFrame(fromSubview: textfield)
                if (frame!.origin.y + frame!.height) > keyboardSize.origin.y {
                    self.parentViewController?.view.frame.origin.y -= (frame!.origin.y + frame!.height) - keyboardSize.origin.y
                }
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.parentViewController?.view.frame.origin.y != 0 {
            self.parentViewController?.view.frame.origin.y = 0
        }
    }
}

extension customView {
    
    func createJson() -> [String : Any] {
        var dict = [String : Any]()
        dict["date"] = self.lblDate.text
        dict["time"] = self.lblTime.text
        dict["name"] = self.txtFieldName.text
        dict["mobile"] = self.txtFieldPhone.text
        dict["email"] = self.txtFieldEmail.text
        dict["address"] = self.txtFieldAddress.text
        dict["zip"] = self.txtFieldPincode.text
        dict["cta"] = Array(ctas)
        
        return dict
    }
}

extension UIViewController {
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if touch?.phase == UITouch.Phase.began {
            touch?.view?.endEditing(true)
        }
    }
}
