//
//  CustomViewExtenstion.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 26/06/23.
//

import Foundation
import UIKit

extension DisplayPlusView {
    func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    func removeObserver() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension DisplayPlusView {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == tfZipcode {
            textField.resignFirstResponder()
        }

        if textField == tfName {
            textField.resignFirstResponder()
            tfPhone.becomeFirstResponder()
        } else if textField == tfPhone {
            textField.resignFirstResponder()
            tfEmail.becomeFirstResponder()
        } else if textField == tfEmail {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if textView == tvAddress {
            textView.resignFirstResponder()
            tfZipcode.becomeFirstResponder()
        }
        return true
    }
}

extension DisplayPlusView {
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

extension DisplayPlusView {
    
    func createJson() -> [String : Any] {
        var dict = [String : Any]()
        dict["date"] = self.lblDate.text
        dict["time"] = self.lblTime.text
        dict["name"] = self.tfName.text
        dict["email"] = self.tfEmail.text
        dict["address"] = self.tvAddress.text
        dict["zip"] = self.tfZipcode.text
        dict["country"] = self.tfCountry.text
        dict["cta"] = Array(ctas)
        if let mobile = self.tfPhone.text, mobile.count > 0 {
            dict["mobile"] = self.lblCountryCode.text! + mobile
        }
        
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
