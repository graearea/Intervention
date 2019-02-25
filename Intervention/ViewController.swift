//
//  ViewController.swift
//  Intervention
//
//  Created by Rae, John, Springer UK on 22/02/2019.
//  Copyright © 2019 Naughty Server. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    //MARK: Properties
    
    @IBOutlet weak var currentHeartRate: UILabel!
    @IBOutlet weak var averageHeartRate: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var intervalLabel: UILabel!
    @IBOutlet weak var intervalSlider: UISlider!
    @IBOutlet weak var restingSlider: UISlider!
    @IBOutlet weak var intervalVal: UILabel!
    @IBOutlet weak var restingVal: UILabel!
    
    var seconds = 0
    var timer = Timer()
    var isTimerRunning = false
    var restingSeconds = 0
    var intervalSeconds = 0
    var resting = true
    
    override func viewDidLoad() {
        super.viewDidLoad();
        initTimes();
        // Do any additional setup after loading the view, typically from a nib.
    }

    //MARK: Actions
    
    @IBAction func setIntervalLength(_ sender: UISlider) {
        intervalVal.text=String(Int(sender.value));
        intervalSeconds=Int(sender.value)
    }

    @IBAction func setRestingLength(_ sender: UISlider) {
        restingVal.text=String(Int(sender.value));
        restingSeconds=Int(sender.value)
    }
    

    func runTimer() {
        isTimerRunning = true;
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                     selector: (#selector(ViewController.updateTimer)),
                                     userInfo: nil, repeats: true)
    }
    
    @objc
    func updateTimer() {
        if(resting){
            restingSeconds -= 1
            if (restingSeconds<5){
                playTick()
            }
            if (restingSeconds==0){
                self.view.backgroundColor = UIColor.red
                intervalSeconds = Int(intervalSlider.value)
                resting=false
                playAlarm()
            }
            intervalLabel.text = "\(restingSeconds)"
        } else{
            intervalSeconds -= 1
            if (intervalSeconds<5){
                playTick()
            }
            if (intervalSeconds==0){
                self.view.backgroundColor = UIColor.white
                restingSeconds = Int(restingSlider.value)
                resting=true
                playAlarm()
            }
            intervalLabel.text = "\(intervalSeconds)"
        }
        
        seconds += 1
        
        timerLabel.text = "\(seconds)" //This will update the label.
    }
    
    func stopTimer() {
        isTimerRunning=false;
        timer.invalidate();
        timer = Timer();
    }
    
    func initTimes() {
        intervalVal.text=String(Int(intervalSlider.value));
        restingVal.text=String(Int(restingSlider.value));

        intervalLabel.text=String(Int(restingSlider.value));
        
        intervalSeconds = Int(intervalSlider.value)
        restingSeconds = Int(restingSlider.value)
        seconds = 0
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
    

    
}

