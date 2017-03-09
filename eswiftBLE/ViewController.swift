//
//  ViewController.swift
//  eswiftBLE
//
//  Created by 　mac on 2017/3/8.
//  Copyright © 2017年 Razil. All rights reserved.
//


import UIKit
import CoreBluetooth

class ViewController: UIViewController,CBCentralManagerDelegate,UITableViewDelegate,UITableViewDataSource {
    //控件
    @IBOutlet weak var myButtonScan: UIButton!
    @IBOutlet weak var myTableView: UITableView!

    let alertConnect = UIAlertController(title: "系统提示",
                                            message: "正在连接:...", preferredStyle: .alert)
    let alertError = UIAlertController(title: "系统提示",
                                       message: "连接失败", preferredStyle: .alert)
    let alertTIMEOUT = UIAlertController(title: "系统提示",
                                       message: "连接超时", preferredStyle: .alert)
    //属性
    var flagScan : Bool! = false
    var myCentralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    var myCBError : CBError!
    //容器，保存搜索到的蓝牙设备
    var myPeripheralToMainView :CBPeripheral! //初始化外设，用以传递给主页面
    var myPeripherals: NSMutableArray = NSMutableArray() //初始化动态数组 用以储存字典
    //服务和UUID  可用于过滤器限定（限定条件：1.UUID 2.服务UUID）
    //let mySevericeUUID = [CBUUID(string: "")]
    //let myCharateristicUUID = [CBUUID(string:"01")]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //添加Tableview的绑定
        myTableView.delegate = self
        myTableView.dataSource = self
        self.view.addSubview(myTableView)
        //添加提示框
        let cancelAction = UIAlertAction(title: "取消连接", style: .default, handler: {
            action in
            self.myCentralManager.cancelPeripheralConnection(self.myPeripheralToMainView)
        })
        alertConnect.addAction(cancelAction)
        let okAction = UIAlertAction(title: "好的", style: .cancel, handler: nil)
        alertError.addAction(okAction)
        alertTIMEOUT.addAction(okAction)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //***************控件响应函数**************
    
    @IBAction func acScan(_ sender: Any) {
        if flagScan == true {
            NSLog("停止搜索")
            self.myCentralManager.stopScan()
            myButtonScan.setTitle("搜索", for: UIControlState.normal)
            flagScan = false
            
        }else{
            NSLog("开始搜索")
            myButtonScan.setTitle("停止", for: UIControlState.normal)
            self.myCentralManager = CBCentralManager(delegate: self , queue: nil)
            flagScan = true
        }
        
    }
    //清除屏幕
    @IBAction func acClear(_ sender: Any) {
        myPeripherals.removeAllObjects()
        myTableView.reloadData()
        
    }
    /********************** 蓝牙响应函数 **********************/
    
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
    
    //检查到设备，响应函数
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var nsPeripheral : NSArray
        nsPeripheral = myPeripherals.value(forKey: "peripheral") as! NSArray   //读取全部的外设值
        if(!nsPeripheral.contains(peripheral)){                                //判断数组内的peripheral与当前读取到的是否相同，若重复则不添加
            
            if(peripheral.name?.isEmpty == false){
                //新建字典
                let r : NSMutableDictionary = NSMutableDictionary()
                r.setValue(peripheral, forKey: "peripheral")
                r.setValue(RSSI, forKey: "RSSI")
                r.setValue(advertisementData, forKey: "advertisementData")
                myPeripherals.add(r)
                
                
                NSLog("搜索到设备，Name=\(peripheral.name!) UUID=\(peripheral.identifier)")
            }
        }
        self.myTableView.reloadData()
        NSLog("刷新屏幕")
    }
    //链接成功，相应函数
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("已连接\(peripheral.name)")
        self.myPeripheralToMainView! = peripheral
        alertConnect.dismiss(animated: true)
        self.performSegue(withIdentifier: "SearchViewtoServiceView", sender: nil)
    }
    //自定义的连接函数，会弹出提示框
    func connectPeripheral(peripheral:CBPeripheral){
       myCentralManager.connect(peripheral, options: nil)
        var nameToConnect : String!
        if peripheral.name == nil {
           nameToConnect = "无名设备"
        }else{ nameToConnect = peripheral.name! }
        alertConnect.message = "正在连接:\(nameToConnect)..."
        self.present(alertConnect, animated: true, completion: nil)
        
    }
    
    //**************** 绑定tableView数据 **************
    //数据列数
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 //1列
    }
    //数据行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return myPeripherals.count
    }
    
    //设置CELL
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        //使用自定义cell
        let cell = self.myTableView.dequeueReusableCell(withIdentifier: "myCustomCell")! as UITableViewCell
        //获取自定义cell控件
        let labelName = cell.viewWithTag(1) as! UILabel
        let labelRSSI = cell.viewWithTag(2) as! UILabel
        let labelUUID = cell.viewWithTag(3) as! UILabel
        
        //获取数据
        let s:NSDictionary = myPeripherals[indexPath.row] as! NSDictionary
        let p:CBPeripheral = s.value(forKey: "peripheral") as! CBPeripheral
        let d:NSDictionary = s.value(forKey: "advertisementData") as! NSDictionary
        let rsi:NSNumber  = s.value(forKey: "RSSI") as! NSNumber
        
        //传递数据到控件
        labelName.text? = "\(p.name!)  "
        labelRSSI.text? = "\(rsi)dB"
        labelUUID.text? = "\(p.identifier)"
        
        NSLog("设备名\(p.name),状态\(p.state),UUID\(p.identifier),信号\(rsi)")
        NSLog("广播内容\(d.allValues)")
        return cell
    }
    
    
    //******************* 响应tableview动作**************
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        NSLog("停止搜索")
        self.myCentralManager.stopScan()
        myButtonScan.setTitle("搜索", for: UIControlState.normal)
        flagScan = false
        //跳转到第二个页面
        myTableView.deselectRow(at: indexPath, animated: true)
        //提取设备库中当前所选的设备传递到全局变量
        let myPeriDict:NSDictionary = myPeripherals[indexPath.row] as! NSDictionary
        myPeripheralToMainView = myPeriDict.value(forKey:"peripheral") as! CBPeripheral
        NSLog("传送外设变量 \(myPeripheralToMainView.name!)到下一页面")
        connectPeripheral(peripheral: myPeripheralToMainView)
    }
    
    
    //页面数据传递
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SearchViewtoServiceView" {
        
            
            let vc = segue.destination as! ServiceViewController   //传递器
            vc.PeripheralToConncet = myPeripheralToMainView
            vc.trCBCentralManager = myCentralManager
            
        }
        
    }
    
}
