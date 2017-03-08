//
//  ServiceViewController.swift
//  eswiftBLE
//
//  Created by 　mac on 2017/3/8.
//  Copyright © 2017年 Razil. All rights reserved.
//

import UIKit
import CoreBluetooth

class ServiceViewController: UIViewController,CBCentralManagerDelegate,UITextFieldDelegate, CBPeripheralDelegate{
    
    /************************ 类变量 *********************/
    //控件
    @IBOutlet weak var trTextInfo: UITextView!
    
    @IBOutlet weak var trTextDataRead: UITextView!
    @IBOutlet weak var trTextDataWrite: UITextField!
    //属性
    
    //容器，保存搜索到的蓝牙设备
    var PeripheralToConncet : CBPeripheral!
    var peripheralConnected : CBPeripheral!
    var trPeripheralManger : CBPeripheralManager!
    var trCBCentralManager : CBCentralManager!
    var trCharactisics : NSMutableArray = NSMutableArray() //初始化用于储存Charactisic
    var trServices : NSMutableArray = NSMutableArray() //初始化动态数组用于储存Service
    
    /************************ 系统函数 *********************/
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
            //连接设备
            //trCBCentralManager.connect(PeripheralToConncet, options: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /****************** 控件响应 *********************/
    @IBAction func trWriteData(_ sender: Any) {
    }
    @IBAction func trEnterData(_ sender: Any) {
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        //输入完成 键盘消失
        trTextDataWrite.resignFirstResponder()
        return true
    }
    //点击屏幕其他位置可以关闭键盘
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        trTextDataWrite.resignFirstResponder() //关闭数字键盘
    }
    /****************  蓝牙函数委托响应   ***************/
    func centralManagerDidUpdateState(_ central: CBCentralManager){
        switch central.state{
            case CBManagerState.poweredOn:  //蓝牙已打开正常
                NSLog("启动成功，开始搜索")
            case CBManagerState.unauthorized: //无BLE权限
                NSLog("无BLE权限")
            case CBManagerState.poweredOff: //蓝牙未打开
                NSLog("蓝牙未开启")
            default:
                NSLog("状态无变化")
        }
    }

    
    //链接成功，相应函数
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //停止搜索并发现服务
        NSLog("正在连接")
        self.peripheralConnected! = peripheral
        self.peripheralConnected.delegate = self //绑定外设
        self.peripheralConnected.discoverServices(nil)//搜索服务
        NSLog("已连接上设备\(peripheral.name)")
    }
    
    //链接失败，响应函数
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("连接\(peripheral.name)失败 ， 错误原因: \(error)")
    }
    
    //搜索到服务，开始搜索Charactisic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
       NSLog("搜索到\(peripheral.services?.count)个服务")
    }
    
    //搜索到Charactistic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        NSLog("从服务\(service.description) 搜索到\(service.characteristics?.count)个服务")
    }

}
