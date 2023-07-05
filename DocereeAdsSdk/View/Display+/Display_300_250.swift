//
//  Display_300_250.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 19/06/23.
//

import UIKit

class Display_300x250: UIView, UITextFieldDelegate {
    var completionHandler: (([String : Any]) -> Void)?
    var contentView: UIView?
    var activeTextField: UITextField?
    
    @IBOutlet weak var imgRepCheck: UIImageView!
    @IBOutlet weak var imgRepProfile: UIImageView!
    @IBOutlet weak var btnRep: UIButton!
    
    @IBOutlet weak var imgSampleCheck: UIImageView!
    @IBOutlet weak var imgSamplePlus: UIImageView!
    @IBOutlet weak var btnSample: UIButton!
    
    @IBOutlet weak var lblrequiredField: UILabel!
    @IBOutlet weak var lblrequiredDate: UILabel!
    @IBOutlet weak var lblrequiredTime: UILabel!
    
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblTime: UILabel!
   
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
    @IBOutlet weak var btnCheckbox: UIButton!
    @IBOutlet weak var checkboxErrorLbl: UILabel!
    let myPicker: MyDatePicker = {
        let v = MyDatePicker()
        return v
    }()
    var ctas: Set = ["request_call"]
    
    override init(frame: CGRect) {
        super.init(frame:frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    internal convenience init(frame: CGRect, completion: @escaping (([String : Any]) -> Void)) {
        self.init(frame: frame)
        commonInit(frame: frame)
        completionHandler = completion
    }
    
    func commonInit(frame: CGRect) {
        addObserver()
        guard let view = loadViewFromNib(frame: frame) else { return }
        view.frame = self.bounds
        self.addSubview(view)
        
        self.btnRep.isSelected = !self.btnRep.isSelected

        self.txtFieldName.delegate = self
        self.txtFieldPhone.delegate = self
        self.txtFieldEmail.delegate = self
        self.txtFieldAddress.delegate = self
        self.txtFieldPincode.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            //call any function
            self.addCalendarPicker()
         }
    }
    
    func loadViewFromNib(frame: CGRect) -> UIView? {
        let nibN = "Display_\(Int(frame.width))x\(Int(frame.height))"
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibN, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }

    @IBAction func backBtnHandler(_ sender: Any) {
        self.removeFromSuperview()
        self.removeObserver()
        completionHandler!([:])
    }
    
    @IBAction func btnHandlerCallRep(_ sender: Any) {
        
        addCalendarPicker()
        self.btnRep.isSelected = !self.btnRep.isSelected
        let bundle = Bundle(for: type(of: self))
        if self.btnRep.isSelected {
            ctas.insert("request_call")
            self.imgRepCheck.image = UIImage(named: "checkbox_purple", in: bundle, compatibleWith: nil)
            self.imgRepProfile.image = UIImage(named: "profile_purple", in: bundle, compatibleWith: nil)
        } else {
            ctas.remove("request_call")
            self.imgRepCheck.image = UIImage(named: "checkbox", in: bundle, compatibleWith: nil)
            self.imgRepProfile.image = UIImage(named: "profile", in: bundle, compatibleWith: nil)
        }
        if !self.btnRep.isSelected && !self.btnSample.isSelected {
            self.lblrequiredField.isHidden = false
        } else {
            self.lblrequiredField.isHidden = true
        }
    }
    
    @IBAction func btnHandlerReqSample(_ sender: Any) {
        self.btnSample.isSelected = !self.btnSample.isSelected
        let bundle = Bundle(for: type(of: self))
        if self.btnSample.isSelected {
            ctas.insert("request_sample")
            self.imgSampleCheck.image = UIImage(named: "checkbox_purple", in: bundle, compatibleWith: nil)
            self.imgSamplePlus.image = UIImage(named: "plus_purple", in: bundle, compatibleWith: nil)
        } else {
            ctas.remove("request_sample")
            self.imgSampleCheck.image = UIImage(named: "checkbox", in: bundle, compatibleWith: nil)
            self.imgSamplePlus.image = UIImage(named: "plus", in: bundle, compatibleWith: nil)
        }
        if !self.btnRep.isSelected && !self.btnSample.isSelected {
            self.lblrequiredField.isHidden = false
        } else {
            self.lblrequiredField.isHidden = true
        }
    }

    @IBAction func nextBtnHandler(_ sender: Any) {
        if !self.btnRep.isSelected && !self.btnSample.isSelected {
            self.lblrequiredTime.isHidden = true
            return
        } else if self.lblDate.text == "yyyy-mm-dd" {
            self.lblrequiredDate.isHidden = false
            return
        } else if self.lblTime.text == "h:mm a" {
            self.lblrequiredDate.isHidden = true
            self.lblrequiredTime.isHidden = false
            return
        }
        self.lblrequiredDate.isHidden = true
        self.lblrequiredTime.isHidden = true
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
        nameErrorLbl.isHidden = true
        phoneErrorLbl.isHidden = true
        emailErrorLbl.isHidden = true
        self.nextView2.isHidden = false
    }
    
    @IBAction func backBtn3Handler(_ sender: Any) {
        self.nextView2.isHidden = true
    }
    
    @IBAction func checkboxBtnHandler(_ sender: Any) {
        self.btnCheckbox.isSelected = !self.btnCheckbox.isSelected
    }
    
    @IBAction func submitBtnHandler(_ sender: Any) {
        if txtFieldAddress.text == "" {
            addressErrorLbl.isHidden = false
            return
        } else if txtFieldPincode.text == "" {
            addressErrorLbl.isHidden = true
            pincodeErrorLbl.isHidden = false
            return
        } else if !self.btnCheckbox.isSelected {
            pincodeErrorLbl.isHidden = true
            checkboxErrorLbl.isHidden = false
            return
        }
        addressErrorLbl.isHidden = true
        pincodeErrorLbl.isHidden = true
        checkboxErrorLbl.isHidden = true
        
        let dict = createJson()
        
        self.removeFromSuperview()
        self.removeObserver()
        completionHandler!(dict)
    }

}

extension Display_300x250 {
    
    func addCalendarPicker() {
        
        [myPicker].forEach { v in
            v.translatesAutoresizingMaskIntoConstraints = false
            self.parentViewController?.view.addSubview(v)
        }
        if #available(iOS 11.0, *) {
            let g = self.parentViewController!.view.safeAreaLayoutGuide
            
            NSLayoutConstraint.activate([
                
                // custom picker view should cover the whole view
                myPicker.topAnchor.constraint(equalTo: g.topAnchor),
                myPicker.leadingAnchor.constraint(equalTo: g.leadingAnchor),
                myPicker.trailingAnchor.constraint(equalTo: g.trailingAnchor),
                myPicker.bottomAnchor.constraint(equalTo: g.bottomAnchor),
                
            ])
        } else {
            // Fallback on earlier versions
        }
        
        // hide custom picker view
        myPicker.isHidden = true
        
        // add closures to custom picker view
        myPicker.dismissClosure = { [self, weak parentViewController = self.parentViewController] in
            guard let self = parentViewController else {
                return
            }
            myPicker.isHidden = true
            editingDidEnd()
        }
        myPicker.changeClosure = { [self, weak parentViewController = self.parentViewController] val in
            guard let self = parentViewController else {
                return
            }
            print(val)
            // do something with the selected date
        }
        
    }
    
    func editingDidEnd() {
        if self.myPicker.dPicker.datePickerMode == .date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.lblDate.text = formatter.string(from: self.myPicker.dPicker.date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            self.lblTime.text = formatter.string(from: self.myPicker.dPicker.date)
        }
    }
    
    @IBAction func dateTimerBtn(_ sender: Any) {
        self.myPicker.dPicker.minimumDate = Date()
        self.myPicker.dPicker.datePickerMode = .date
        self.myPicker.isHidden = false
    }
    
    @IBAction func timeTimerBtn(_ sender: Any) {
        self.myPicker.dPicker.datePickerMode = .time
        self.myPicker.isHidden = false
    }
    
}
