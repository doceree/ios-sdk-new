//
//  Display_300_250.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 19/06/23.
//

import UIKit

class customView: UIView, UITextFieldDelegate {
    var delegate: (DisplayPlusProtocol)?
    var contentView: UIView?
    var activeTextField: UITextField?
    @IBOutlet weak var repCheckboxBtnOutlet: UIButton!
    @IBOutlet weak var sampleCheckboxBtnOutlet: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateImg: UIImageView!
    @IBOutlet weak var timeImg: UIImageView!
   
    @IBOutlet weak var nextView: UIView!
    @IBOutlet weak var txtFieldName: UITextField!
    @IBOutlet weak var nameErrorLbl: UILabel!
    @IBOutlet weak var txtFieldPhone: UITextField!
    @IBOutlet weak var phoneErrorLbl: UILabel!
    @IBOutlet weak var txtFieldEmail: UITextField!
    @IBOutlet weak var emailErrorLbl: UILabel!
    
    @IBOutlet weak var nextView2: UIView!
    @IBOutlet weak var txtFieldAddress: UITextField!
    @IBOutlet weak var addressErrorLbl: UILabel!
    @IBOutlet weak var txtFieldPincode: UITextField!
    @IBOutlet weak var pincodeErrorLbl: UILabel!
    
    override init(frame: CGRect) {
        
        super.init(frame:frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func commonInit() {
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        initializeDate()

        self.txtFieldName.delegate = self
        self.txtFieldPhone.delegate = self
        self.txtFieldEmail.delegate = self
        self.txtFieldAddress.delegate = self
        self.txtFieldPincode.delegate = self
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "Display_300_250", bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    func initializeDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.datePicker.date = formatter.date(from: formatter.string(from: Date()))!
        self.datePicker.setDate(formatter.date(from: "1290-08-19")!, animated: false)
    }
    
    
    
    @IBAction func backBtnHandler(_ sender: Any) {
        delegate?.resumeAd()
        self.removeFromSuperview()
    }
    
    @IBAction func nextBtnHandler(_ sender: Any) {
        self.nextView.isHidden = false
    }
    
    
    
    @IBAction func backBtn2Handler(_ sender: Any) {
        self.nextView.isHidden = true
    }
    
    @IBAction func nextBtn2Handler(_ sender: Any) {
        if txtFieldName.text == "" {
            nameErrorLbl.isHidden = false
            return
        } else if txtFieldPhone.text == "" {
            nameErrorLbl.isHidden = true
            phoneErrorLbl.isHidden = false
            return
        } else if txtFieldEmail.text == "" {
            phoneErrorLbl.isHidden = true
            emailErrorLbl.isHidden = false
            return
        }
        emailErrorLbl.isHidden = true
        self.nextView2.isHidden = false
    }
    
    
    
    @IBAction func backBtn3Handler(_ sender: Any) {
        self.nextView2.isHidden = true
    }
    
    @IBAction func checkboxBtnHandler(_ sender: Any) {
        
    }
    
    @IBAction func submitBtnHandler(_ sender: Any) {
        if txtFieldAddress.text == "" {
            addressErrorLbl.isHidden = false
            return
        } else if txtFieldPincode.text == "" {
            addressErrorLbl.isHidden = true
            pincodeErrorLbl.isHidden = false
            return
        }
        pincodeErrorLbl.isHidden = true
    }
    
}

extension customView {
    
    @IBAction func dateTimerBtn(_ sender: Any) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.datePicker.date = formatter.date(from: formatter.string(from: Date()))!
//        datePicker.addTarget(self, action: #selector(datePickerChanged(picker:)), for: .valueChanged)
    }
    
    @IBAction func timeTimerBtn(_ sender: Any) {
        self.datePicker.isHidden = false
        self.datePicker.datePickerMode = .time
//        datePicker.addTarget(self, action: #selector(datePickerChanged(picker:)), for: .valueChanged)
    }
    
    @IBAction func onEditingDidEnd(_ sender: Any) {
        if self.datePicker.datePickerMode == .date {
            self.datePicker.isHidden = true
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
        } else {
            self.datePicker.isHidden = true
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
        }
    }

}

protocol DisplayPlusProtocol {
    func resumeAd()
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

extension UIViewController {
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if touch?.phase == UITouch.Phase.began {
            touch?.view?.endEditing(true)
        }
    }
}
