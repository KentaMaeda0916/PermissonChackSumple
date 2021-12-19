//
//  ViewController.swift
//  Permisson
//
//  Created by まえけん on 2021/11/23.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var securityLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var bluetoothLabel: UILabel!

    let statusDevice = StatusDevice()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        statusDevice.restCheakDetermined()
        self.checkPermissions()


    }
    @IBAction func reload(_ sender: Any) {
        print("更新")
        self.checkPermissions()
        setLabel()
    }
    func checkPermissions() {
        statusDevice.checkPermissions() { result in
            switch result {
            case .authorized, .denied:
                print("全ての項目確認済み")
                self.setLabel()
            case .notDetermined:
                print("未確認項目がある")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.checkPermissions()
                }
            }
        }
    }
    func setLabel() {
        notificationLabel.text = setText(result: StatusDevice.cheakResult[.notification]!)
        securityLabel.text = setText(result: StatusDevice.cheakResult[.security]!)
        locationLabel.text = setText(result: StatusDevice.cheakResult[.location]!)
        bluetoothLabel.text = setText(result: StatusDevice.cheakResult[.bluetooth]!)
    }
    func setText(result: PermissionCheakResult) -> String {
        switch result {
        case .authorized:
            return "許可"
        case .denied:
            return "不許可"
        case .notDetermined:
            return "不明"
        }
    }
}

