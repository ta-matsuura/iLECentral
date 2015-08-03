//
//  ViewController.swift
//  iLECentral
//
//  Created by txm on 2015/08/03.
//  Copyright (c) 2015年 txm. All rights reserved.
//

import UIKit
import CoreBluetooth



class ViewController: UIViewController, CBCentralManagerDelegate, UITableViewDataSource, UITableViewDelegate, CBPeripheralDelegate{
//class ViewController: UIViewController{
    var mTableView: UITableView!
    var mCentralManager: CBCentralManager!
    var mPeripheral: NSMutableArray = NSMutableArray()
    var mNames: NSMutableArray = NSMutableArray()
    var mUuids: NSMutableArray = NSMutableArray()
    var mItems: NSMutableArray = NSMutableArray()
    var mTargetPeripheral: CBPeripheral!
    private var myActivityIndicator: UIActivityIndicatorView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // インジケータを作成する.
        myActivityIndicator = UIActivityIndicatorView()
        myActivityIndicator.frame = CGRectMake(0, 0, 50, 50)
        myActivityIndicator.color = UIColor.blueColor()
        myActivityIndicator.center = self.view.center
        
        
        
        // Status Barの高さを取得.
        let barHeight: CGFloat = (UIApplication.sharedApplication().statusBarFrame.size.height)
        
        // Viewの高さと幅を取得.
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        // TableViewの生成( status barの高さ分ずらして表示 ).
        mTableView = UITableView(frame: CGRect(x: 0, y: barHeight+50, width: displayWidth, height: displayHeight - barHeight - 370))
        
        // Cellの登録.
        mTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "MyCell")

        
        // DataSourceの設定.
        mTableView.dataSource = self
        
        // Delegateを設定.
        mTableView.delegate = self
        
        self.view.addSubview(mTableView)
        self.view.addSubview(myActivityIndicator)

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        println("state \(central.state)");
        switch (central.state) {
        case .PoweredOff:
            println("Bluetoothの電源がOff")
        case .PoweredOn:
            println("Bluetoothの電源はOn")
            // BLEデバイスの検出を開始.
            self.mCentralManager.scanForPeripheralsWithServices(nil, options: nil)
        case .Resetting:
            println("レスティング状態")
        case .Unauthorized:
            println("非認証状態")
        case .Unknown:
            println("不明")
        case .Unsupported:
            println("非対応")
        }
    }
    /*
    BLEデバイスが検出された際に呼び出される.
    */
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("--------------------------")
        println("pheripheral.name: \(peripheral.name)")
        println("advertisementData:\(advertisementData)")
        println("RSSI: \(RSSI)")
        println("peripheral.identifier.UUIDString: \(peripheral.identifier.UUIDString)")
        println("--------------------------")
        
        var name: NSString? = advertisementData["kCBAdvDataLocalName"] as? NSString
        if (name == nil) {
            name = "no name";
        }
        
        mNames.addObject(name!)
        
        mPeripheral.addObject(peripheral)
        mUuids.addObject(peripheral.identifier.UUIDString)
        
        mTableView.reloadData()
    }
    
    /*
    Cellが選択された際に呼び出される.
    */
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("tableView : Cellが選択された際に呼び出される")
        println("Num: \(indexPath.row)")
        println("Uuid: \(mUuids[indexPath.row])")
        println("Name: \(mNames[indexPath.row])")
        
        // アニメーションを開始する.
        myActivityIndicator.startAnimating()
        
        self.mTargetPeripheral = mPeripheral[indexPath.row] as! CBPeripheral
        mCentralManager.connectPeripheral(self.mTargetPeripheral, options: nil)
        
        println("stop Scan")
        self.mCentralManager .stopScan()
        
    }
    
    /*
    Cellの総数を返す.
    */
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        println("tableView : Cellの総数を返す")
        return mUuids.count
    }
    /*
    Cellに値を設定する.
    */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        println("tableView : Cellに値を設定する")

        var cell:UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier:"MyCell" )
        
        // Cellに値を設定.
        cell.textLabel!.sizeToFit()
        cell.textLabel!.textColor = UIColor.redColor()
        cell.textLabel!.text = "\(mNames[indexPath.row])"
        cell.textLabel!.font = UIFont.systemFontOfSize(20)
        // Cellに値を設定(下).
        cell.detailTextLabel!.text = "\(mUuids[indexPath.row])"
        cell.detailTextLabel!.font = UIFont.systemFontOfSize(12)
        return cell
    }
    
    /*
    Peripheralに接続
    */
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!)
    {
        println("connect")
        // アニメーションを開始する.
        myActivityIndicator.stopAnimating()
        mTargetPeripheral.delegate = self
        mTargetPeripheral.discoverServices(nil)
    }
    
    /*
    Peripheralに接続失敗した際
    */
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!)
        
    {
        println("not connnect")
        
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        
        if (error != nil) {
            println("error: \(error)")
            return
        }
        
        let services: NSArray = peripheral.services
        println("Found \(services.count) services! :\(services)")
    }


    
    @IBAction func startScan(sender: UIButton) {
        println("start Scan")
        // 配列をリセット.
        mNames = NSMutableArray()
        mUuids = NSMutableArray()
        mPeripheral = NSMutableArray()
        self.mCentralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    @IBAction func stopScan(sender: UIButton) {
        println("stop Scan")
        self.mCentralManager .stopScan()
        
    }
}