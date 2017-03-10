//
//  ServiceViewController.swift
//  eswiftBLE
//
//  Created by 　mac on 2017/3/8.
//  Copyright © 2017年 Razil. All rights reserved.
//

import UIKit
import CoreBluetooth

class ServiceViewController: UIViewController,UITextFieldDelegate,CBCentralManagerDelegate, CBPeripheralDelegate{
    
    /************************ 类变量 *********************/
    
    //控件
    @IBOutlet weak var trTextConnectState: UILabel!
    @IBOutlet weak var trTextDeviceName: UILabel!
    @IBOutlet weak var trTextInfo: UITextView!
    @IBOutlet weak var trTextDataRead: UITextView!
    @IBOutlet weak var trTextDataWrite: UITextField!

    //属性
    var trFlagLastConnectState : Bool! = false
    //容器，保存搜索到的蓝牙设备
    var PeripheralToConncet : CBPeripheral!
    var trPeripheralManger : CBPeripheralManager!
    var trCBCentralManager : CBCentralManager!
    var trIOService : CBService!               //用于储存读写操作对应的CBService uuid  D2AE0000
    var trWriteCharactisic : CBCharacteristic! //用于储存待写入的Charactisic   uuid = D2AE0001
    var trReadCharactisic : CBCharacteristic! //用于储存待读取的Charactisic   uuid = EE
    var trServices : NSMutableArray = NSMutableArray() //初始化动态数组用于储存Service
    /************************ 系统函数 *********************/
    override func viewDidLoad() {
        super.viewDidLoad()
        //绑定CBPeripheral委托
        self.PeripheralToConncet.delegate = self
        peripheralStateDetect(currentPeripheral: PeripheralToConncet)   //获取当前设备状态
        //初始化UI控件
        trTextInfo.text = ""
        trTextDataRead.text = ""
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /****************** 控件响应 *********************/
    //写入按钮 响应函数
    @IBAction func trWriteData(_ sender: Any) {
        if PeripheralToConncet.state == CBPeripheralState.connected {
            //启动写入， 向trWriteCharactistic写入数据
            PeripheralToConncet.writeValue(trTextDataWrite.text, for: trWriteCharactisic, type: CBCharacteristicWriteType.withoutResponse)
        }else{
            NSLog("读取失败，当前未连接设备")
            trTextDataRead.insertText("读取失败，当前未连接设备")
        }
    }
    //读取按钮 响应函数
    @IBAction func trReadData(_ sender: Any) {
        if PeripheralToConncet.state == CBPeripheralState.connected {
            //启动读取， 读取trReadCharactistic的数据
            PeripheralToConncet.readValue(for: trWriteCharactisic)    //因为当前读写都是同一个属性
        }else{
            NSLog("读取失败，当前未连接设备")
            trTextDataRead.insertText("读取失败，当前未连接设备")
        }
    }
    
    //点击“重新连接”响应函数
    @IBAction func trReconnect(_ sender: Any) {
        
        if PeripheralToConncet.state == CBPeripheralState.disconnected{
             NSLog("重新连接\(PeripheralToConncet.name!)")
             trCBCentralManager.connect(PeripheralToConncet, options: nil)
        }else{
             NSLog("当前处于连接状态，重连失败")
        }

    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //输入完成 键盘消失
        trTextDataWrite.resignFirstResponder()
        return true
    }
    //点击屏幕其他位置可以关闭键盘
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        trTextDataWrite.resignFirstResponder() //关闭数字键盘
    }
    //向下滑动关闭键盘
    @IBAction func trPan(_ sender: Any) {
        trTextDataWrite.resignFirstResponder()
    }
    
    //页面数据传递
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ServiceToSearchView" {
            NSLog("断开连接")
            trCBCentralManager.cancelPeripheralConnection(PeripheralToConncet) //页面关闭时断开连接
        }
        
    }
    func peripheralStateDetect(currentPeripheral: CBPeripheral){
        //设备状态判断
        switch currentPeripheral.state {
        case CBPeripheralState.connected:
            NSLog("已连接")
            trTextConnectState.text = "已连接"
            trTextConnectState.textColor = UIColor.green
            if currentPeripheral.name != nil {
                trTextDeviceName.text = currentPeripheral.name!
            }
            currentPeripheral.discoverServices(nil)//搜索服务
            trFlagLastConnectState = true
        case CBPeripheralState.disconnected:
            NSLog("未连接")
            trTextConnectState.text = "未连接"
            trTextConnectState.textColor = UIColor.gray
            if !trFlagLastConnectState {
                NSLog("设备\(currentPeripheral.name!)已断开连接")
                trFlagLastConnectState = false
            }
        default:
            NSLog("状态错误")
            trTextConnectState.text = "状态错误"
            trTextConnectState.textColor = UIColor.red
        }
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

    
    //链接成功，响应函数
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //停止搜索并发现服务
        NSLog("正在连接")
        self.PeripheralToConncet! = peripheral
        self.PeripheralToConncet.delegate = self //绑定外设
       // self.PeripheralToConncet.discoverServices(nil)//搜索服务
        NSLog("重新连接上设备\(peripheral.name)")
    }
    
    //链接失败，响应函数
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("连接\(peripheral.name)失败 ， 错误原因: \(error)")
        trFlagLastConnectState = false
    }
    
    //搜索到服务，开始搜索Charactisic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
       NSLog("搜索到\(peripheral.services?.count)个服务")
        //数据显示
        if peripheral.services?.count != 0{
            for service in peripheral.services! {
                //trTextInfo.insertText("服务:\(service.description)")
                if service.uuid.uuidString.contains("D2AE0000") {
                    NSLog("获取到指定服务 \(service.uuid.uuidString)")
                    trIOService = service as CBService  //获取到指定读写的服务
                }
                peripheral.discoverCharacteristics(nil, for: service)
            }
            
        }else{
            trTextInfo.insertText("无有效服务")
        }
    }
    
    //搜索到Charactistic   查找指定读写的属性
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        NSLog("从服务\(service.uuid.uuidString) 搜索到\(service.characteristics?.count)个属性")
         trTextInfo.insertText("服务: \n")
         trTextInfo.insertText("\(service.uuid.uuidString) \n")
          trTextInfo.insertText("属性: \n")
        if service.characteristics!.count != 0 {
            for charactistic in service.characteristics!{
                //此处有未知bug for in 循环无法给变量正确定义属性，所需要我们自己找个中介变量定义一下
                let aC :CBCharacteristic = charactistic as CBCharacteristic
                if  trIOService == service {
                    if aC.uuid.uuidString.contains("D2AE0001") {
                        NSLog("获取到指定属性\(aC.uuid.uuidString)")
                        trWriteCharactisic = aC as CBCharacteristic   //获取到指定写入的属性
                    }else if aC.uuid.uuidString.contains("EE") {
                        trReadCharactisic = aC as CBCharacteristic    //获取到指定读取的属性
                    }
                }
                trTextInfo.insertText("\(aC.uuid.uuidString) \n")
                trTextInfo.insertText("Properties:\(propertiesString(properties: aC.properties)!) \n")
            }
        }
    }
    
    
    
    
    //显示属性权限
    func propertiesString(properties: CBCharacteristicProperties)->(String)!{
        var propertiesReturn : String = ""
        // Just to see what we are dealing with
        if (properties.rawValue & CBCharacteristicProperties.broadcast.rawValue) != 0 {
            propertiesReturn += "broadcast|"
        }
        if (properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            propertiesReturn += "read|"
        }
        if (properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
            propertiesReturn += "write without response|"
        }
        if (properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 {
            propertiesReturn += "write|"
        }
        if (properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0 {
            propertiesReturn += "notify|"
        }
        if (properties.rawValue & CBCharacteristicProperties.indicate.rawValue) != 0 {
            propertiesReturn += "indicate|"
        }
        if (properties.rawValue & CBCharacteristicProperties.authenticatedSignedWrites.rawValue) != 0 {
            propertiesReturn += "authenticated signed writes|"
        }
        if (properties.rawValue & CBCharacteristicProperties.extendedProperties.rawValue) != 0 {
            propertiesReturn += "indicate|"
        }
        if (properties.rawValue & CBCharacteristicProperties.notifyEncryptionRequired.rawValue) != 0 {
            propertiesReturn += "notify encryption required|"
        }
        if (properties.rawValue & CBCharacteristicProperties.indicateEncryptionRequired.rawValue) != 0 {
            propertiesReturn += "indicate encryption required|"
        }
        return propertiesReturn
    }
    

}
