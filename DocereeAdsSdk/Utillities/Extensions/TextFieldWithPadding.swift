//
//  TextFieldWithPadding.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 08/08/23.
//

import UIKit

class CountryTextField: UITextField {
    var textPadding = UIEdgeInsets(
        top: 0,
        left: 2,
        bottom: 0,
        right: 20
    )

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }
}
