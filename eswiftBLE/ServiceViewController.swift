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
    @IBOutlet weak var trSwitchNotifyPro: UISwitch!
    
    @IBOutlet weak var trReadAdd: UITextField!
    
    //属性
    var trFlagLastConnectState : Bool! = false
    var trWriteBuffer : [UInt8] = [UInt8]()  //写入的缓存区，用于判断数据是否传输完成，完成后清空
    let trWrtieBufferMAXLENGTH = 30 //写入数据长度限制
    var trCommunicationArray : [UInt8] = [UInt8](repeating: 0,count: 3) //创建传输数据
    //容器，保存搜索到的蓝牙设备
    var PeripheralToConncet : CBPeripheral!
    var trPeripheralManger : CBPeripheralManager!
    var trCBCentralManager : CBCentralManager!
    var trIOService : CBService!               //用于储存读写操作对应的CBService uuid  = AABB
    var trWriteCharactisic : CBCharacteristic! //用于储存待写入的Charactisic   uuid =
    var trReadCharactisic : CBCharacteristic! //用于储存待读取的Charactisic   uuid =
    var trNotifyCharactistic : CBCharacteristic! //用处储存通知的Charactistic uuid =
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
        trTextDataWrite.delegate = self

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /****************** 控件响应 *********************/
    //写入按钮 响应函数
    @IBAction func trWriteData(_ sender: Any) {
        if let tx = trTextDataWrite.text {
            if PeripheralToConncet.state == CBPeripheralState.connected {
                  //原理：先获取到输入框数据<string>，转换为Uint8[]数组，再用Data.init()转为Data型发送
               let byArr = stringToByteArray(stringArray: tx)
               let hexArr =   uint8ToHexArray(uint8Array:  byArr!)
                   // NSLog("写入数据为\(hexArr),长度为\(hexArr.count)")
                var dataToTrans :Data = Data()
                dataToTrans.append(hexArr, count: hexArr.count)
                 NSLog("写入数据为\(dataToTrans),长度为\(dataToTrans.count)")
                    if trWriteCharactisic != nil {
                        //启动写入， 向trWriteCharactistic写入数据
                    PeripheralToConncet.writeValue(dataToTrans, for:   trWriteCharactisic, type: CBCharacteristicWriteType.withResponse)
                    trWriteBuffer = hexArr  //传入到Buffer里
                    }
            }
        }
    }
    //读取按钮 响应函数
    @IBAction func trReadData(_ sender: Any) {
        if PeripheralToConncet.state == CBPeripheralState.connected {
            //启动读取， 读取trReadCharactistic的数据
            if trWriteCharactisic != nil{
            PeripheralToConncet.readValue(for: trWriteCharactisic)    //因为当前读写都是同一个属性
            }else{
                NSLog("读取失败，未获取到写入属性")
                addScollTextView(text: "读取失败，未获取到写入属性")
            }
        }else{
            NSLog("读取失败，当前未连接设备")
            addScollTextView(text: "读取失败，当前未连接设备")
        }
    }
    
    //Notify开关
    @IBAction func trSwitchNotify(_ sender: Any) {
        if trNotifyCharactistic != nil {
            if trSwitchNotifyPro.isOn {
                PeripheralToConncet.setNotifyValue(true, for: trNotifyCharactistic)
                NSLog("打开notify,uuid=\(trNotifyCharactistic.uuid.uuidString)")
            }else{
                  PeripheralToConncet.setNotifyValue(false, for: trNotifyCharactistic)
                NSLog("关闭notify,uuid=\(trNotifyCharactistic.uuid.uuidString)")
            }
        }else{
        addScollTextView(text: "无Notify属性")
            
        }
    }
    
    @IBAction func trButtonClear(_ sender: Any) {
        trTextDataRead.text = " "
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
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool // return YES to allow 
    {
        trTextDataWrite.resignFirstResponder()
        return true
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
                if service.uuid.uuidString.contains("FF00") {
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
                if trIOService != nil {
                    if  trIOService == service {
                        if aC.uuid.uuidString.contains("FF01") {
                            NSLog("获取到指定属性\(aC.uuid.uuidString)")
                            trWriteCharactisic = aC as CBCharacteristic   //获取到指定写入的属性
                            trNotifyCharactistic = trWriteCharactisic   //获得Notify属性
                            trReadCharactisic = trWriteCharactisic  //获得读取属性
                        }
                        
                    }
                    trTextInfo.insertText("\(aC.uuid.uuidString) \n")
                    trTextInfo.insertText("Properties:\(propertiesString(properties: aC.properties)!) \n")
                }
            }
        }
    }
    //Notify状态更新响应
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        NSLog("Notify状态改变,当前状态为\(characteristic.isNotifying),uuid=\(characteristic.uuid.uuidString),错误提示\(error.debugDescription)")
        addScollTextView(text: "\nNotify: 状态:\(characteristic.isNotifying) UUid:\(characteristic.uuid.uuidString),错误提示：\(error.debugDescription)")
    }
    //读取响应
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if error == nil {
            //显示数据
            
            var readValue : [UInt8] = [UInt8]()
            for readData in characteristic.value! {
                readValue += [readData]
            }
        
                //characteristic.value?.copyBytes(to: UnsafeMutableBufferPointer<UInt8>)
            addScollTextView(text: "\n data:<\(readValue)>")
            NSLog("data:<\(readValue)>")
        }else{
            NSLog("读取错误 \(error.debugDescription)")
        }
    }
    //写入响应
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
         // NSLog("写入数据状态 \(error.debugDescription)")
        if error == nil {
            NSLog("写入成功，数据：\(trWriteBuffer)成功")
            addScollTextView(text: "\n 写入成功:\(trWriteBuffer)")
            trWriteBuffer.removeAll()  //清空数据
        }else{
            NSLog("写入错误 \(error.debugDescription)")
            addScollTextView(text: "\n 写入错误:\(error.debugDescription)")
        }
    }

    /********************* 辅助函数 **********************/
    //将string转为UInt8数组类型的
    func stringToByteArray(stringArray: String)->([UInt8])!{
        var byteArray = [UInt8]()
        for char in stringArray.utf8{
                if (char > 0x2F && char < 0x3A ) {
                byteArray += [char-0x30]
                    }else if (char > 0x60 && char < 0x67 )  {
                        byteArray += [char-0x60]
                        }
                        else if (char > 0x40 ) && (char < 0x47 ){
                        byteArray += [char-0x40]
                        }
                            else {
                                NSLog("输入错误")
                            }
        }
      //      NSLog("原始输入 \(stringArray)")
      //      NSLog("输出\(byteArray)")
            return byteArray
    }
    //将UInt8中数值转为十六进制数数组
    func uint8ToHexArray(uint8Array: [UInt8])->([UInt8]){
        var hexArray = [UInt8]()
        if (uint8Array.count != 0) {
            var hexData: UInt8 = 0 //中间函数
            var cnt = 0
            for data in uint8Array {
                if cnt % 2 == 0 {
                    hexData += data*16
                    if cnt == uint8Array.count - 1 {
                        hexArray += [data]
                        NSLog("输入长度为奇数，最后一个值为\(hexData)")
                    }
                }else {
                    hexData += data
                    hexArray += [hexData]
                }
                cnt += 1
            }
        }
       // NSLog("原始输入 \(uint8Array)")
       // NSLog("输出\(hexArray)")
        return hexArray
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
    func addScollTextView(text: String){
        trTextDataRead.text.append(text)
        trTextDataRead.scrollRangeToVisible(NSMakeRange(trTextDataRead.text.lengthOfBytes(using: String.Encoding.utf8), 0))
    }

}
