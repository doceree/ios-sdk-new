//
//  Display_300_250.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 19/06/23.
//

import UIKit

class customView: UIView {
    var delegate: (DisplayPlusProtocol)?
    var contentView: UIView?
    @IBOutlet weak var repCheckboxBtnOutlet: UIButton!
    @IBOutlet weak var sampleCheckboxBtnOutlet: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateImg: UIImageView!
    @IBOutlet weak var timeImg: UIImageView!
   
    @IBOutlet weak var nextView: UIView!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var nameErrorLbl: UILabel!
    @IBOutlet weak var phoneTF: UITextField!
    @IBOutlet weak var phoneErrorLbl: UILabel!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var emailErrorLbl: UILabel!
    
    @IBOutlet weak var nextView2: UIView!
    @IBOutlet weak var addressTF: UITextField!
    @IBOutlet weak var addressErrorLbl: UILabel!
    @IBOutlet weak var pincodeTF: UITextField!
    @IBOutlet weak var pincodeErrorLbl: UILabel!
    
    override init(frame: CGRect) {
        
        super.init(frame:frame)
//
//        let myLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
//        myLabel.text = "Farzi"
//        myLabel.textColor = .red
//        addSubview(myLabel)
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
        //        contentView = view
        //        datePicker.addTarget(self, action: #selector(datePickerChanged(picker:)), for: .valueChanged)
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
        if nameTF.text == "" {
            nameErrorLbl.isHidden = false
            return
        } else if phoneTF.text == "" {
            nameErrorLbl.isHidden = true
            phoneErrorLbl.isHidden = false
            return
        } else if emailTF.text == "" {
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
        if addressTF.text == "" {
            addressErrorLbl.isHidden = false
            return
        } else if pincodeTF.text == "" {
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
