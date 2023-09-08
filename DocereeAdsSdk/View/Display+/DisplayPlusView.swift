//
//  Display_300_250.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 19/06/23.
//

import UIKit

class DisplayPlusView: UIView, UITextFieldDelegate, UITextViewDelegate {
    var completionHandler: (([String : Any]) -> Void)?
    var contentView: UIView?
    var activeTextField: UITextField?
    
    @IBOutlet weak var imgRepCheck: UIImageView!
    @IBOutlet weak var imgRepProfile: UIImageView!
    @IBOutlet weak var btnRep: UIButton!
    
    @IBOutlet weak var imgSampleCheck: UIImageView!
    @IBOutlet weak var imgSamplePlus: UIImageView!
    @IBOutlet weak var btnSample: UIButton!
    @IBOutlet weak var lblRequestASample: UILabel!
    
    @IBOutlet weak var lblrequiredField: UILabel!
    @IBOutlet weak var lblrequiredDate: UILabel!
    @IBOutlet weak var lblrequiredTime: UILabel!
    
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblTime: UILabel!
   
    @IBOutlet weak var nextView: UIView!
    @IBOutlet weak var tvAddress: UITextView!
    @IBOutlet weak var lblAddressError: UILabel!
    @IBOutlet weak var lblCountryCode: UILabel!
    @IBOutlet weak var tfCountry: UITextField!
    @IBOutlet weak var lblCountryError: UILabel!
    @IBOutlet weak var tfZipcode: UITextField!
    @IBOutlet weak var lblzipError: UILabel!
    
    @IBOutlet weak var nextView2: UIView!
    @IBOutlet weak var tfName: UITextField!
    @IBOutlet weak var lblNameError: UILabel!
    @IBOutlet weak var tfPhone: UITextField!
    @IBOutlet weak var tfEmail: UITextField!
    @IBOutlet weak var lblEmailError: UILabel!
    @IBOutlet weak var btnCheckbox: UIButton!
    @IBOutlet weak var lblSuccessMsg: UILabel!
    let myPicker: MyDatePicker = {
        let v = MyDatePicker()
        return v
    }()
    var ctas: Set = ["request_call"]
    var mappedCountries = [String : String]()
    var selectedCountry: String?
    var countryList = [String]()
    var displayCtaType = ""
    
    override init(frame: CGRect) {
        super.init(frame:frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    internal convenience init(frame: CGRect, displayCtaType: String, completion: @escaping (([String : Any]) -> Void)) {
        self.init(frame: frame)
        self.displayCtaType = displayCtaType
        commonInit(frame: frame)
        completionHandler = completion
    }
    
    func commonInit(frame: CGRect) {
        addObserver()
        guard let view = loadViewFromNib(frame: frame) else { return }
        view.frame = self.bounds
        self.addSubview(view)
        
        self.btnRep.isSelected = !self.btnRep.isSelected

        self.tvAddress.delegate = self
        self.tfCountry.delegate = self
        self.tfZipcode.delegate = self
        self.tfName.delegate = self
        self.tfPhone.delegate = self
        self.tfEmail.delegate = self
        self.lblRequestASample.text = displayCtaType.breakString()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            //call any function
            self.addCalendarPicker()
        }
        createPickerView()
        dismissPickerView()
        
        let _ = countries.map { element in
            let arr = element.components(separatedBy: "_")
            mappedCountries[arr[0]] = arr[1]
        }
        countryList = Array(mappedCountries.keys)
        countryList = countryList.sorted()
        self.btnCheckbox.isSelected = true
        print("mapped: \(countryList[0])")
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
            ctas.insert(displayCtaType)
            self.imgSampleCheck.image = UIImage(named: "checkbox_purple", in: bundle, compatibleWith: nil)
            self.imgSamplePlus.image = UIImage(named: "plus_purple", in: bundle, compatibleWith: nil)
        } else {
            ctas.remove(displayCtaType)
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
        } else if self.lblDate.text == "mm/dd/yyyy" {
            self.lblrequiredDate.isHidden = false
            return
        } else if self.lblTime.text == "--:-- --" {
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
        if tvAddress.text == "" {
            lblAddressError.isHidden = false
            return
        } else if tfCountry.text == "" {
            lblAddressError.isHidden = true
            lblCountryError.isHidden = false
            return
        } else if tfZipcode.text == "" {
            lblAddressError.isHidden = true
            lblCountryError.isHidden = true
            lblzipError.isHidden = false
            return
        }
        lblAddressError.isHidden = true
        lblCountryError.isHidden = true
        lblzipError.isHidden = true
        self.nextView2.isHidden = false
    }
    
    @IBAction func backBtn3Handler(_ sender: Any) {
        self.nextView2.isHidden = true
    }
    
    @IBAction func checkboxBtnHandler(_ sender: Any) {
        self.btnCheckbox.isSelected = !self.btnCheckbox.isSelected
    }
    
    @IBAction func submitBtnHandler(_ sender: Any) {
        if tfName.text == "" {
            lblNameError.isHidden = false
            return
        } else if tfEmail.text == "" {
            lblEmailError.text = "This is a required field."
            lblNameError.isHidden = true
            lblEmailError.isHidden = false
            return
        } else if tfEmail.text!.count > 0 {
            if let email = tfEmail.text, !email.isValidEmail() {
                lblEmailError.text = "Please enter a valid email."
                lblEmailError.isHidden = false
                return
            }
        } else if !self.btnCheckbox.isSelected {
            lblEmailError.isHidden = true
            return
        }
        lblNameError.isHidden = true
        lblEmailError.isHidden = true
        lblEmailError.isHidden = true
        
        let dict = createJson()
        
        self.removeObserver()
        self.completionHandler!(dict)
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            self.removeFromSuperview()
         }
        self.lblSuccessMsg.isHidden = false
    }

}

extension DisplayPlusView {
    
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
            guard parentViewController != nil else {
                return
            }
            myPicker.isHidden = true
            editingDidEnd()
        }
        myPicker.changeClosure = { [weak parentViewController = self.parentViewController] val in
            guard parentViewController != nil else {
                return
            }
            print(val)
            // do something with the selected date
        }
        
    }
    
    func editingDidEnd() {
        if self.myPicker.dPicker.datePickerMode == .date {
            let formatter = DateFormatter()
            formatter.dateFormat = "mm/dd/yyyy"
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
