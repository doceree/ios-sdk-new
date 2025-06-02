//
//  Untitled.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 13/05/25.
//

import UIKit

public class HcpValidationViewManager {
    public static func showIfNeeded(on viewController: UIViewController, delegate: HcpValidationViewDelegate?) {
        guard let data = UserDefaultsManager.shared.loadConfig(), data.hcpValidation else {
            return
        }

        let hcpValidationView = HcpValidationView()
        hcpValidationView.delegate = delegate
        viewController.view.addSubview(hcpValidationView)

        // Optionally add constraints if needed
        // Example: pin to edges
        hcpValidationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hcpValidationView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            hcpValidationView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            hcpValidationView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            hcpValidationView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
    }
}
