//
//  ViewController.swift
//  Intervention
//
//  Created by Rae, John, Springer UK on 22/02/2019.
//  Copyright © 2019 Naughty Server. All rights reserved.
//

import UIKit
import AVFoundation
import CoreBluetooth

class ViewController: UIViewController {

    //MARK: Properties
    
    @IBOutlet weak var currentHeartRate: UILabel!
    @IBOutlet weak var averageHeartRate: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var intervalLabel: UILabel!
    @IBOutlet weak var intervalSlider: UISlider!
    @IBOutlet weak var restingSlider: UISlider!
    @IBOutlet weak var breakSlider: UISlider!
    @IBOutlet weak var breakTimeSlider: UISlider!
    @IBOutlet weak var intervalVal: UILabel!
    @IBOutlet weak var restingVal: UILabel!
    @IBOutlet weak var statusBar: UITextField!
    @IBOutlet weak var intervalCounter: UILabel!
    @IBOutlet weak var breakCounter: UILabel!
    @IBOutlet weak var breakTimeCounter: UILabel!
    
    var centralManager: CBCentralManager!
    var seconds = 0
    var beat = true
    var timer = Timer()
    var isTimerRunning = false
    var hrmConnected=false
    var restingSeconds = 0
    var intervalSeconds = 0
    var intervalCount = 0
    var resting = true
    var heartRatePeripheral: CBPeripheral!
    let heartRateServiceCBUUID = CBUUID(string: "0x180D")
    let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
    let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")
    var heartRates = Array<Int>()

    override func viewDidLoad() {
        super.viewDidLoad();
        initTimes();
        startupBluetooth()
        

        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func startupBluetooth(){
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }

    //MARK: Actions
    
    @IBAction func setIntervalLength(_ sender: UISlider) {
        intervalVal.text=String(Int(sender.value)*5);
        intervalSeconds=Int(sender.value)*5
    }

    @IBAction func setRestingLength(_ sender: UISlider) {
        restingVal.text=String(Int(sender.value)*5);
        restingSeconds=Int(sender.value)*5
    }
    
    @IBAction func breakTimeSlider(_ sender: UISlider) {
        breakTimeCounter.text=String(Int(sender.value))
    }
    
    @IBAction func breakSlider(_ sender: UISlider) {
        intervalCount=Int(sender.value)
        breakCounter.text=String(intervalCount)
        intervalCounter.text=String(intervalCount)
    }
    

    func runTimer() {
        UIApplication.shared.isIdleTimerDisabled = true
        isTimerRunning = true;
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                     selector: (#selector(ViewController.updateTimer)),
                                     userInfo: nil, repeats: true)
    }
    
    var ignore = 5
    func addToAverage(){
        ignore-=1
        if ignore>0 {return}
        heartRates.append(Int(currentHeartRate.text!)!)
        var total=0
        heartRates.forEach{
            total = total + $0
        }
        averageHeartRate.text = String(total / heartRates.count)
    }
    
    var currentColour=UIColor.white
    @objc
    func updateTimer() {
        if(hrmConnected) {addToAverage()}
        if(resting){
            restingSeconds -= 1
            setTime(intervalLabel,restingSeconds)
            if (restingSeconds<5){
                playTick()
            }
            if (restingSeconds==0){
                intervalCount-=1
                intervalCounter.text=String(intervalCount)
                currentColour=UIColor.yellow
                self.view.backgroundColor = currentColour
                intervalSeconds = Int(intervalSlider.value)*5
                resting=false
                playTick()

                setTime(intervalLabel,intervalSeconds)
            }

            
        } else{
            intervalSeconds -= 1
            setTime(intervalLabel,intervalSeconds)
            if (intervalSeconds<5){
                playTick()
            }
            if (intervalSeconds==0){
                
                printStatus("Interval count: \(intervalCount)")
                
                if(intervalCount == 0){
                    currentColour=UIColor.gray
                    restingSeconds = Int(breakTimeSlider.value)*60
                    intervalCount=Int(breakSlider.value)
                } else{
                    currentColour=UIColor.white
                    restingSeconds = Int(restingSlider.value)*5
                }
                intervalCounter.text=String(intervalCount)
                self.view.backgroundColor = currentColour

                resting=true
                playTick()
                setTime(intervalLabel,restingSeconds)
            }
            
        }
        
        seconds += 1
        setTime(timerLabel,seconds)
    }

    func setTime(_ label: UILabel, _ time: Int){
        let secs=time%60
        let mins=time/60
        let secsText: String = secs>9 ? "\(secs)": "0\(secs)"
        let minsText: String = mins>0 ? "\(mins):": ""
        label.text = minsText+secsText
    }
    
    func stopTimer() {
        UIApplication.shared.isIdleTimerDisabled = false;
        isTimerRunning=false;
        timer.invalidate();
        timer = Timer();
    }
    
    func initTimes() {
        intervalVal.text=String(Int(intervalSlider.value)*5);
        restingVal.text=String(Int(restingSlider.value)*5);
        breakCounter.text=(String(Int(breakSlider.value)))
        intervalLabel.text=String(Int(restingSlider.value)*5);
        intervalCounter.text=(String(Int(breakSlider.value)))
        intervalCount=Int(breakSlider.value)
        breakTimeCounter.text=String(Int(breakTimeSlider.value))
        
        intervalSeconds = Int(intervalSlider.value)*5
        restingSeconds = Int(restingSlider.value)*5
        seconds = 0
    }
    
    func onHeartRateReceived(_ heartRate: Int){
        currentHeartRate.text=String(heartRate)
        print(".")
        beat = (!beat)
        if (beat){
            currentHeartRate.textColor = UIColor.green
            self.view.backgroundColor = (heartRate>180) ? UIColor.orange : currentColour
            
        }
        else {
            currentHeartRate.textColor = UIColor.blue
            self.view.backgroundColor = (heartRate>180) ? UIColor.red : currentColour
        }
    }
    
    @IBAction func btClicked(_ sender: UIButton) {
        printStatus("disconnecting")
        centralManager.cancelPeripheralConnection(heartRatePeripheral)
        printStatus("scanning again")
        centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])

    }
    
    @IBAction func goClicked(_ sender: UIButton) {
        if (!isTimerRunning){
            goButton.setTitle("STOP", for: .normal);
            runTimer();
            
        }else{
            goButton.setTitle("GO", for: .normal);
            stopTimer();
        }
    }
    
    var player: AVAudioPlayer?
    
    func playTick() {
        AudioServicesPlaySystemSound (1203)
    }

    func playAlarm() {
        AudioServicesPlaySystemSound (1304)
    }
    
    func printStatus(_ status: String){
        print(status)
        statusBar.text=status
    }
}

extension ViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            printStatus("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        printStatus(peripheral.description)
        heartRatePeripheral = peripheral
        centralManager.stopScan()
        printStatus("stopped scan, connecting")
        centralManager.connect(heartRatePeripheral)
        heartRatePeripheral.delegate=self
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        printStatus("connected, discovering services")
        heartRatePeripheral.discoverServices([heartRateServiceCBUUID])
        
    }
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            printStatus("found HRM, discovering characteristics")
            peripheral.discoverCharacteristics(nil, for: service)

        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,  error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
                printStatus("found HRM function")
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        hrmConnected=false
        printStatus("HRM disconnected?")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        switch characteristic.uuid {
        case heartRateMeasurementCharacteristicCBUUID:
            let bpm = heartRate(from: characteristic)
            onHeartRateReceived(bpm)
            hrmConnected=true
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            // Heart Rate Value Format is in the 2nd byte
            return Int(byteArray[1])
        } else {
            // Heart Rate Value Format is in the 2nd and 3rd bytes
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }
    }
}
