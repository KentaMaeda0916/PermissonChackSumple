//
//  CheckDevice.swift
//  Toyota
//
//  Copyright © 2020 CEC-ltd. All rights reserved.
//

import UserNotifications
import CoreBluetooth
import Foundation
import CoreLocation
import LocalAuthentication
import UIKit

/// 許可状態チェック結果
enum PermissionCheakResult {
    /// 許可されている
    case authorized
    /// 許可されていない
    case denied
    /// わからない
    case notDetermined
}
/// デバイスの状態をチェックするクラス
class StatusDevice {

    // パーミッション許可状態を選択したか
    static var cheakDetermined: [CheakItem: Bool] = [
        //　通知
        .notification: false,
        //　生体認証
        .security: false,
        //　位置情報
        .location: false,
        //　Bluetooth
        .bluetooth: false,
    ]
    // パーミッション確認結果
    static var cheakResult: [CheakItem: PermissionCheakResult] = [
        //　通知
        .notification: .notDetermined,
        //　生体認証
        .security: .notDetermined,
        //　位置情報
        .location: .notDetermined,
        //　Bluetooth
        .bluetooth: .notDetermined,
    ]
    // 生体認証の許可状態を確認
    let context = LAContext()
    var error: NSError?
    // 初回判定
    var isFirst = true

    var bluetoothStatus: BluetoothStatus!

    // パーミッション確認項目
    enum CheakItem {
        //　通知
        case notification
        //　生体認証
        case security
        //　位置情報
        case location
        //　Bluetooth
        case bluetooth
    }
    /// パーミッション許可状態を確認する項目があるかを調査
    /// - Parameters:
    ///   - handler: パーミッション確認項目
    func checkPermissionsItem(handler: @escaping (CheakItem?) -> Void) {
        print("許可状態未確認項目がないかを確認")
        if StatusDevice.cheakDetermined[.notification]! {
            print("通知確認済み")
            if StatusDevice.cheakDetermined[.security]! {
                print("生体認証確認済み")
                if StatusDevice.cheakDetermined[.location]! {
                    print("位置情報確認済み")
                    if StatusDevice.cheakDetermined[.bluetooth]! {
                        print("Bluetooth確認済み")
                    } else {
                        print("Bluetooth未確認")
                        handler(.bluetooth)
                        return
                    }
                } else {
                    print("位置情報未確認")
                    handler(.location)
                    return
                }
            } else {
                print("生体認証未確認")
                handler(.security)
                return
            }
        } else {
            print("通知未確認")
            handler(.notification)
            return
        }
    }
    
    /// パーミッション許可状態確認
    /// - Parameters:
    ///   - handler: パーミッション確認結果
    func checkPermissions(handler: @escaping (PermissionCheakResult) -> Void) {
        checkPermissionsItem() { [self] result in
            switch result {
            case .none:
                // 許可状態を確認する項目がない場合、全て許可済みとする
                print("パーミッション確認項目なし")
                handler(.authorized)
                return
                
            case .notification:
                //  通知の許可状態を確認
                print("通知の許可状態を確認")
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    print("通知の許可状況確認")
                    DispatchQueue.main.async {
                        switch settings.authorizationStatus {
                            // 許可
                        case .authorized, .provisional, .ephemeral:
                            StatusDevice.cheakDetermined[.notification] = true
                            StatusDevice.cheakResult[.notification] = .authorized
                            self.checkPermissions(handler: handler)
                            return
                            // 不許可
                        case .denied:
                            StatusDevice.cheakDetermined[.notification] = true
                            StatusDevice.cheakResult[.notification] = .denied
                            self.checkPermissions(handler: handler)
                            return
                            // 不明
                        default:
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _ , _  in
                                handler(.notDetermined)
                                return
                            }
                        }
                    }
                }

            case .security:

                checkSecurityPermisssion() { result in
                    switch result {
                    case .authorized:
                        print("生体認証許可済み")
                        StatusDevice.cheakDetermined[.security] = true
                        StatusDevice.cheakResult[.security] = .authorized
                        self.checkPermissions(handler: handler)
                        return

                    case .denied:
                        print("生体認証不許可")
                        StatusDevice.cheakDetermined[.security] = true
                        StatusDevice.cheakResult[.security] = .denied
                        self.checkPermissions(handler: handler)
                        return

                    case .notDetermined:
                        print("生体認証許可状態不明")
                        handler(.notDetermined)
                        return
                    }
                }
            case .location:
                //  位置情報の許可状態を確認
                print("位置情報の許可状態を確認")
                let locationStatus = LocationStatus()
                // 位置情報が利用可能
                locationStatus.locationManager.requestWhenInUseAuthorization()

                switch locationStatus.locationManager.authorizationStatus {
                case .authorized, .authorizedAlways, .authorizedWhenInUse:
                    print("位置情報許可済み")
                    StatusDevice.cheakDetermined[.location] = true
                    StatusDevice.cheakResult[.location] = .authorized
                    self.checkPermissions(handler: handler)
                    return
                case .denied, .restricted:
                    print("位置情報不許可")
                    StatusDevice.cheakDetermined[.location] = true
                    StatusDevice.cheakResult[.location] = .denied
                    self.checkPermissions(handler: handler)
                    return
                default:
                    print("位置情報許可状態不明")
                    locationStatus.locationManager.requestWhenInUseAuthorization()
                    handler(.notDetermined)
                    return
                }
            case .bluetooth:
                // Bluetoothの許可状態を確認
                print("Bluetoothの許可状態を確認")

                if isFirst {
                    bluetoothStatus = BluetoothStatus()
                    isFirst = false
                }
                bluetoothStatus.chack()

                switch bluetoothStatus.centralManager.state {
                    // アプリにBluetooth権限が許可されている、かつ端末のBluetooth設定がオンになっている
                case .poweredOn:
                    print("Bluetooth許可済み")
                    StatusDevice.cheakDetermined[.bluetooth] = true
                    StatusDevice.cheakResult[.bluetooth] = .authorized
                    self.checkPermissions(handler: handler)
                    return

                case .unauthorized, .poweredOff, .resetting, .unsupported:
                    print("Bluetooth不許可")
                    StatusDevice.cheakDetermined[.bluetooth] = true
                    StatusDevice.cheakResult[.bluetooth] = .denied
                    self.checkPermissions(handler: handler)
                    return
                default:
                    print("Bluetooth許可状態不明")
                    bluetoothStatus.chack()
                    handler(.notDetermined)
                    return
                }
            }
        }
    }
    /// 全ての項目を未確認に戻す
    func restCheakDetermined() {
        StatusDevice.cheakDetermined[.notification] = false
        StatusDevice.cheakDetermined[.security] = false
        StatusDevice.cheakDetermined[.location] = false
        StatusDevice.cheakDetermined[.bluetooth] = false
    }
    func checkSecurityPermisssion(handler: @escaping(PermissionCheakResult) -> Void) {
        print("生体認証の許可状態を確認")
        // Touch ID・Face IDが利用できるデバイスか確認する
        if self.context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &self.error) {
            handler(.authorized)
        } else {
            // Touch ID・Face IDが利用できない場合の処理
            handler(.denied)
        }
    }
}

class LocationStatus: NSObject, CLLocationManagerDelegate {
    // 位置情報の許可状態
    let locationManager = CLLocationManager()
    /// 位置情報サービスの許可状態が変更されたとき。
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("位置情報サービスの許可状態が変更:\(status)")
    }
}

class BluetoothStatus: NSObject, CBCentralManagerDelegate {
    // Bluetoothの許可状態
    var centralManager: CBCentralManager!
    var centralManagerState: CBManagerState?

    override init() {
        super.init()
        centralManagerState = .unknown
        // 端末でBluetoothをOffにしている場合メッセージを表示するOS標準機能を無効化
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    }

    func chack() {
        centralManager.delegate = self
    }

    // Bluetoothの許可状態を取得or許可状態が変化したときの処理
    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        switch central.state {
        case .poweredOn:
            print("UpdateState:端末のBluetooth設定がONで許可されている")
            self.centralManagerState = .poweredOn
        case .poweredOff:
            print("UpdateState:端末のBluetooth設定がOFF")
            self.centralManagerState = .poweredOff
        case .unauthorized:
            print("UpdateState:アプリが許可していない")
            self.centralManagerState = .unauthorized
        case .unknown:
            print("UpdateState:許可状態不明")
            self.centralManagerState = .unknown
        case .resetting:
            print("UpdateState:システムサービスとの接続が一時的に失われた")
        case .unsupported:
            print("UpdateState:端末がBluetoothをサポートしていない")
        default:
            print("許可状態不明")
        }
    }
}
