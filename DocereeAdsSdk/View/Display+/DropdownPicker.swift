//
//  DropdownPicker.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 06/07/23.
//

import UIKit

extension DisplayPlusView: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return countryList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return countryList[row]
       
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCountry = countryList[row]
        tfCountry.text = selectedCountry
//        tfPhone.text = "+" + mappedCountries[selectedCountry!]! + " "
        lblCountryCode.text = "+" + mappedCountries[selectedCountry!]!
    }
    
    func createPickerView() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        tfCountry.inputView = pickerView
    }
    
    func dismissPickerView() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(action(_:)))
        toolBar.setItems([button], animated: true)
        toolBar.isUserInteractionEnabled = true
        tfCountry.inputAccessoryView = toolBar
    }
    
    @objc func action(_ sender: UIDatePicker) {
       self.endEditing(true)
    }

}
