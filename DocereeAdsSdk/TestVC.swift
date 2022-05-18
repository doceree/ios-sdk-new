//
//  TestVC.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 12/05/22.
//

import Foundation
import UIKit

public class TestVC: UIView {
    @IBOutlet public weak var rootViewController: UIViewController?
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func addButton() {
        print("Test")
        let myFirstLabel = UILabel()
        let myFirstButton = UIButton()
        myFirstLabel.text = "I made a label on the screen #toogood4you"
        myFirstLabel.font = UIFont(name: "MarkerFelt-Thin", size: 45)
        myFirstLabel.textColor = .red
        myFirstLabel.textAlignment = .center
        myFirstLabel.numberOfLines = 5
        myFirstLabel.frame = CGRect(x: 15, y: 54, width: 300, height: 500)
        myFirstButton.setTitle("✸", for: .normal)
        myFirstButton.setTitleColor(.blue, for: .normal)
        myFirstButton.frame = CGRect(x: 15, y: -50, width: 300, height: 500)
        myFirstButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
        self.addSubview(myFirstButton)
    }
    
    @objc func pressed() {
        print("Test")
    }
}


