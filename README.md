eswiftBLE
==================
## Introduction
基于苹果官方外设库CoreBluetooth的一款Swift语言的IOS Demo程序。经测试已实现
外设BLE的查找，连接，服务发现，数据读写，通知开关和读取。程序提供了较好的中文注释，可以使开发者理解和快速应用蓝牙外设。  

欢迎提交建议和意见.如有其他需求比如外设模式和后台模式，可邮件联系，时间充裕都可以提供。

开发语言：swift 3.0  
平台:Xcode 7.1

## Package:
BTM: CoreBluetooth
## Function
+ 外设搜索 ✅
+ 连接与断开 ✅
+ 服务搜索 ✅
+ 属性搜索 ✅
+ 数据发送 ✅
+ 数据接收 ✅
+ 通知开关与接收 ✅

## Usage
详细开发文档[CoreBluetooth开发文档](https://github.com/DennisMao/eswiftBLE/blob/master/CoreBluetooth开发文档.md)
### 下载
使用指令,切换到需要目标文件夹，以【~/Document】举例 Mac平台
>cd ~/Document
>git clone git@github.com:DennisMao/eswiftBLE.git



## Develop

假定我们有一个外设,读取电量的最大值，改写电量的最小值  
设备 name = Mobike UUID = FF00  
服务 
Battery  UUID = FFEE  
   属性  
	Max UUID = FFE1  
	Min UUID = FFE2  
	Avg UUID = FFE3  


### 初始化

1. 引入中心库，委托   
```
import CoreBluetooth
``` 
2. 导入委托Delegate 
```
class ServiceViewController: UIViewController,CBCentralManagerDelegate, CBPeripheralDelegate  
```

3. 实例化变量  
```
    var PeripheralToConncet : CBPeripheral!   //实例化外设
```
```
    var trCBCentralManager : CBCentralManager!  //实例化外设管理区
```

4. 初始化变量，绑定delegate  

```
self.PeripheralToConncet.delegate = self
```
```
self.trCentralManager = CBCentralManager(delegate: self , queue: nil)
```

### 获得当前设备状态

```
//检查外设管理器状态
func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
        
    case CBManagerState.poweredOn:  //蓝牙已打开正常
        NSLog("启动成功，开始搜索")
        self.myCentralManager.scanForPeripherals(withServices: nil, options: nil) //不限制
    case CBManagerState.unauthorized: //无BLE权限
        NSLog("无BLE权限")
    case CBManagerState.poweredOff: //蓝牙未打开
        NSLog("蓝牙未开启")
    default:
        NSLog("状态无变化")
    }
}

```

### 搜索外设
开启搜索前应先确定系统蓝牙已经打开，状态可以由上个函数获得  
【动作】开启搜索

```
self.myCentralManager.scanForPeripherals(withServices: nil, options: nil) //不设置过滤条件

```

【响应】搜索到设备,其UUID为“FF00”,将外设参数赋值到已经定义的 PeripheralToConnect 保存起来

```
func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
	if(peripheral.identifier.uuidString.contains("FFEE")){
         PeripheralToConnect = peripheral 
          NSLog("搜索到设备，Name=\(peripheral.name!) UUID=\(peripheral.identifier)")
    }
}

```

### 建立链接和断开链接

【动作】建立连接  

```
trCentralManager.connect(PeripheralToConnect, options: nil)
```

【响应】已建立连接  

```
func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    NSLog("已连接\(peripheral.name!)")
    self.myPeripheralToMainView! = peripheral
}
```

【响应】建立连接失败

```
func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?){
    NSLog("连接失败，设备名\(peripheral.name!),原因\(error)")
}
```

### 扫描服务和特征

声明定义变量，以储存所需服务和特征

```
trCharactisticMax: CBCharactistic!  
trCharactisticMin: CBCharactistic! 
trService: CBService!  
```
【动作】扫描服务

```
PeripheralToConnect.discoverServices(nil)//搜索服务,不做过滤
```
【响应】成功扫描到服务

```
func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
   NSLog("搜索到\(peripheral.services?.count)个服务")
    if peripheral.services?.count != 0{
        for service in peripheral.services! {
            //trTextInfo.insertText("服务:\(service.description)")
            if service.uuid.uuidString.contains("FFEE") { //遍历所有搜索到的服务，查找Battery服务
                NSLog("获取到指定服务 \(service.uuid.uuidString)")
                trService = service as CBService  //获取到指定读写的服务Battery，同理可以用名字做筛选，但比较推荐是用UUID  
            }
        }
    }else{
        NSLog("无有效服务") //未能搜索到服务
    }
}
```
【动作】扫描特征

```
PeripheralToConnect.discoverCharacteristics(nil, for: trService) //将已搜到的服务参数传入
```
【响应】成功扫描到特征

```
//搜索到Charactistic   查找指定读写的属性
func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
    if service.characteristics!.count != 0 {
      for charactistic in service.characteristics!{
        //此处有未知bug for in 循环无法给变量正确定义属性，所需要我们自己找个中介变量定义一下
         let aC :CBCharacteristic = charactistic as CBCharacteristic
         if trService == service {
            if aC.uuid.uuidString.contains("FFE1") {
                trCharactisticMax = aC as CBCharacteristic   //获取到Max属性
            }else if aC.uuid.uuidString.contains("FFE2"){
            	trCharactisticMin = aC as CBCharacteristic   //获取到Max属性
            }
          }
       }     
	}else{
		NSLog("未能搜索到属性")
	}
}
```

### 读取数据
搜索到属性后，可以对属性进行读写等操作。操作前建议先检查该属性的权限，是否提供读写功能。
此处自己写了个属性显示函数，具体在下一章节有介绍。
【动作】查看功能

```
propertiesString(properties: trCharactisticMin)! //查看Min属性所含有的功能
propertiesString(properties: trCharactisticMax)!

```
#### Read方式

```
PeripheralToConncet.readValue(for: trCharactisticMax)  //读取Max值
```

#### Notify方式
 
```
PeripheralToConncet.setNotifyValue(true, for: trCharactisticMax) //打开Notify
PeripheralToConncet.setNotifyValue(false, for: trCharactisticMax) //关闭Notify

``` 

不管是Read还是Notify，接收到数据都会相应以下函数  
【响应】接收响应

```
func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
    if error == nil {
        NSLog("成功读取到数据:\(characteristic.value!)")
    }else{
        NSLog("读取错误 \(error.debugDescription)")
    }
}
```

### 写入数据
	
>蓝牙4.0 BLE数据限制每次发送Payload即有效数据长度只有20bytes，后续版本该数据包大小会有增加 
	
	
#### Write方式

Write方式的特点是写入数据后蓝牙外设会返回写入结果以显示上一次写入操作是否成功，
通过判断响应可知道写入的情况，适用于数据量小或者数据类型较分类的情况。    

【动作】写入

```
PeripheralToConncet.writeValue(dataToTrans, for:   trCharactisticMin, type: CBCharacteristicWriteType.withResponse)
```

【响应】已写入数据

```
func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
    if error == nil {
        NSLog("写入成功，数据：\(characteristic.value!)成功")
    }else{
        NSLog("写入错误 \(error.debugDescription)")
    }
}
```
#### Write Without Response方式

Write Without Response方式的特点是写入数据后蓝牙外设不返回写入结果以显示上一次写入操作是否成功。适用于数据连续，量大且自带头尾校验情况。    

【动作】写入

```
PeripheralToConncet.writeValue(dataToTrans, for:   trWriteCharactisic, type: CBCharacteristicWriteType.withoutResponse)
```




## Report issues and Contribute
Please contect 
>raymond_2008@yahoo.com 



