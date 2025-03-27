//
//  PopupModel.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 12/02/25.
//

import UIKit

enum PopupTemplate: Int {
    case basic = 1
    case withIcon = 2
    case withIllustration = 3
}

struct PopupData {
    let title: String
    let description: String
    let noButtonText: String
    let yesButtonText: String
    let image: UIImage?
    
    static func getTemplate(for id: PopupTemplate) -> PopupData {
        switch id {
        case .basic:
            return PopupData(
                title: Popup.title,
                description: Popup.description,
                noButtonText: Popup.noButtonText,
                yesButtonText: Popup.yesButtonText,
                image: nil
            )
        case .withIcon:
            return PopupData(
                title: Popup.title,
                description: Popup.description,
                noButtonText: Popup.noButtonText,
                yesButtonText: Popup.yesButtonText,
                image: UIImage(named: "doctorIcon") // Add image in assets
            )
        case .withIllustration:
            return PopupData(
                title: Popup.title,
                description: Popup.description,
                noButtonText: Popup.noButtonText,
                yesButtonText: Popup.yesButtonText,
                image: UIImage(named: "doctorIllustration") // Add illustration in assets
            )
        }
    }
}
