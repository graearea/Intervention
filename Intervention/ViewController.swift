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
    @IBOutlet weak var intervalVal: UILabel!
    @IBOutlet weak var restingVal: UILabel!
    @IBOutlet weak var statusBar: UITextField!
    @IBOutlet weak var intervalCounter: UILabel!
    @IBOutlet weak var breakCounter: UILabel!
    
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
    
    @IBAction func breakSlider(_ sender: UISlider) {
        breakCounter.text=String(Int(sender.value))
        
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
            if (restingSeconds<5){
                playTick()
            }
            if (restingSeconds==0){
                currentColour=UIColor.white
                self.view.backgroundColor = currentColour
                intervalSeconds = Int(intervalSlider.value*5)
                resting=false
                playTick()
//                playAlarm()
            }
            intervalLabel.text = "\(restingSeconds)"
        } else{
            intervalSeconds -= 1
            if (intervalSeconds<5){
                playTick()
            }
            if (intervalSeconds==0){
                intervalCount+=1
                intervalCounter.text=String(intervalCount)
                currentColour=UIColor.yellow
                self.view.backgroundColor = currentColour
                if((intervalCount%Int(breakCounter.text!)!)==0){
                    restingSeconds = Int(restingSlider.value*5*4)
                } else{
                    restingSeconds = Int(restingSlider.value*5)
                }
                
                resting=true
                playTick()
            }
            intervalLabel.text = "\(intervalSeconds)"
        }
        
        seconds += 1
        let secs=seconds%60
        let mins=seconds/60
        if(secs>10){
            timerLabel.text = "\(mins):\(secs)"
        }else{
            timerLabel.text = "\(mins):0\(secs)"
        }
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
        intervalCounter.text="0"
        
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
            print("central.state is .poweredOn")

            centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        heartRatePeripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(heartRatePeripheral)
        heartRatePeripheral.delegate=self
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        printStatus("connected")
        heartRatePeripheral.discoverServices([heartRateServiceCBUUID])
        
    }
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            printStatus("found HRM")
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
