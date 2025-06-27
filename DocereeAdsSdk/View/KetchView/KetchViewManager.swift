//
//  KetchViewManager.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 26/06/25.
//

import Foundation
import SwiftUI
import UIKit

public class KetchViewManager {
    public static let shared = KetchViewManager()

    private init() {}

    public enum KetchUIType {
        case swiftUI
        case uiKit
    }

    // Condition check example: You can customize this
    private var shouldUseSwiftUI: Bool {
        // Example logic
        return false // Change this to your actual condition
    }

    public func presentKetchView(from viewController: UIViewController) {
        guard let data = UserDefaultsManager.shared.loadConfig(), data.ketchConsent else {
            return
        }

        if shouldUseSwiftUI {
            presentSwiftUIView(from: viewController)
        } else {
            presentUIKitView(from: viewController)
        }
    }

    private func presentSwiftUIView(from viewController: UIViewController) {
        
        let swiftUIView = MyKetchView()
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        viewController.addChild(hostingController)
        viewController.view.addSubview(hostingController.view)

        // Set constraints if needed
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])

        hostingController.didMove(toParent: viewController)
        
    }

    private func presentUIKitView(from viewController: UIViewController) {
//        let myKetchViewController = MyKetchUIKitViewController()
//
//        // Add MyKetchViewController as a child view controller
//        viewController.addChild(myKetchViewController)
//        viewController.view.addSubview(myKetchViewController.view)
        
        viewController.view.addSubview(CreateCMPView())
    }
}
