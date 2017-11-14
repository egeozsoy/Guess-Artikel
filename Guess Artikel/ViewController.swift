//
//  ViewController.swift
//  Guess Artikel
//
//  Created by Ege on 04.08.17.
//  Copyright © 2017 Ege Özsoy. All rights reserved.
//

import UIKit
import Speech
import Firebase

class ViewController: UIViewController ,UITextFieldDelegate , SFSpeechRecognizerDelegate{
    var guess: Guess?
    
    @IBOutlet weak var text: UITextField!
    //crashes if no text, fix that
    @IBOutlet weak var successRateLabel: UILabel!
    
    @IBOutlet weak var successRateBar: UIProgressView!
    var tmptext: String?
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var looper:UISwitch!
    public let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "de"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    var totalAttempts: Int{
        get{
            return UserDefaults.standard.integer(forKey: "totalAttempts")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "totalAttempts")
        }
    }
    
    var totalSuccess: Int{
        get{
            return UserDefaults.standard.integer(forKey: "totalSuccess")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "totalSuccess")
        }
    }
    var successRate: Float{
        get{
            return UserDefaults.standard.float(forKey: "successRate")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "successRate")
        }
    }
    //    @IBOutlet weak var mylabel: UILabel!
    
    var storedInFirebase = [String]()
    
    
    @objc func endThatEdit(){
        text.resignFirstResponder()
    }
        
    
    
    override func viewDidLoad() {
        updateSuccessRate()
        guess = Guess()
        guess?.learnArtikel()
        
        
        if (try? NSString(contentsOf: documentURL().appendingPathComponent("gewicht.txt"), encoding: String.Encoding.utf8.rawValue)) != nil{
            print("file is there")
        }else{
            print("file is not there")
            
            let path = Bundle.main.path(forResource: "gewicht", ofType: "txt")
            
            let file = try! NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue)
            try! file.write(to: documentURL().appendingPathComponent("gewicht.txt"), atomically: true,  encoding: String.Encoding.utf8.rawValue)
        }
        if (try? NSString(contentsOf: documentURL().appendingPathComponent("article.txt"), encoding: String.Encoding.utf8.rawValue)) != nil{
            print("file is there")
        }else{
            print("file is not there")
            
            let path = Bundle.main.path(forResource: "article", ofType: "txt")
            
            let file = try! NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue)
            try! file.write(to: documentURL().appendingPathComponent("article.txt"), atomically: true,  encoding: String.Encoding.utf8.rawValue)
        }
        text.becomeFirstResponder()
        microphoneButton.isEnabled = false
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
        
        
        //very basic hide keyboard implementation
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.endThatEdit))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
    }


    
    @IBAction func send(_ sender: Any)  {
        print("send")
        
        do{
            let set = CharacterSet.init(charactersIn: " ")
            let t = try? guess!.mainGuess(originalwort: text.text!.lowercased().trimmingCharacters(in: set))
            //            print("text length " + "\(text.text!.length)")
            //            print("new length  " + " \(p.length)")
            print("myGuess " + t! + " " + text.text!)
            let alert = UIAlertController(title: "My Guess", message: t! + " " + text.text!, preferredStyle: .alert)
            let right = UIAlertAction(title: "True", style: .default, handler: {right in try? self.guess?.newGewicht(Artikel: t!, towort: self.text.text!)
                self.text.text! = ""
                self.totalAttempts += 1
                self.totalSuccess += 1
                self.updateSuccessRate()
                if self.looper.isOn{
                    self.microphoneTapped()
                }
                })
            let wrong = UIAlertAction(title: "False", style: .default, handler: {wrong in self.giveRightArticle()
                self.totalAttempts += 1
                self.updateSuccessRate()
                if self.looper.isOn{
                    self.microphoneTapped()
                }})
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(right)
            alert.addAction(wrong)
            alert.addAction(cancel)
            present(alert, animated: true, completion: nil )
            //            mylabel.text = t! + " " +  text.text!
            //            text.text = ""
        }
        
    }
    func sendviaVoice(_ sender:String?){
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setImage(#imageLiteral(resourceName: "microphone1600"), for: .normal)
            microphoneButton.setTitle("Start Recording", for: .normal)
            
        }
        print("sendviavoice")
        if sender != nil {
            print("in if")
            text.text = sender
            text.text = ""
            
        }
    
        
    }
    class func tapmic(){
        print("tapmic")
    }
    
   
    
    
    
    @IBAction func microphoneTapped() {
        print("mic")
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setImage(#imageLiteral(resourceName: "microphone1600"), for: .normal)
            microphoneButton.setTitle("Start Recording", for: .normal)
            
        } else {
            startRecording()
            microphoneButton.setImage(#imageLiteral(resourceName: "microphoneturon"), for: .normal)
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func startRecording() {
        view.endEditing(true)
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            
            if result != nil {
                
                self.tmptext = result?.bestTranscription.formattedString  //9
                isFinal = (result?.isFinal)!
                self.sendviaVoice(self.tmptext)
                self.tmptext = ""
                
                
            }
            
            if error != nil || isFinal {  //10
                print("in error if")
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
            
            
            
            
            
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    

    
    func giveRightArticle(){
        let alert = UIAlertController(title: "Right Article ? ", message: text.text! , preferredStyle: .alert)
        
        let der = UIAlertAction(title: "der", style: .default, handler: { der in try? self.guess?.newGewicht(Artikel: "der", towort: self.text.text! )
            self.addToDic(rightArticle: "der")
            self.text.text! = ""} )
        let das = UIAlertAction(title: "das", style: .default, handler: {das in try? self.guess?.newGewicht(Artikel: "das", towort: self.text.text! )
            self.addToDic(rightArticle: "das")
            self.text.text! = ""} )
        let die = UIAlertAction(title: "die", style: .default, handler: {die in try? self.guess?.newGewicht(Artikel: "die", towort: self.text.text! )
            self.addToDic(rightArticle: "die")
            self.text.text! = ""} )
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(der)
        alert.addAction(das)
        alert.addAction(die)
        alert.addAction(cancel)
        present(alert, animated: false, completion: nil)
    }
    
    @IBAction func addToDic(_ sender: Any) {
        
        
        let current = try! NSString(contentsOf: documentURL().appendingPathComponent("article.txt"), encoding: String.Encoding.utf8.rawValue)
        let newfile = String(current) + "\n" + text.text!
        
        try! newfile.write(to: documentURL().appendingPathComponent("article.txt"), atomically: true, encoding: String.Encoding.utf8)
        
    }
    func addToDic(rightArticle article:String){
        let ref = Database.database().reference().child("words")
        let childRef = ref.childByAutoId()
        childRef.updateChildValues([ text.text! : article])
        
        let current = try! NSString(contentsOf: documentURL().appendingPathComponent("article.txt"), encoding: String.Encoding.utf8.rawValue)
        let newfile = String(current) + "\n" + article + " " + text.text!
        
        try! newfile.write(to: documentURL().appendingPathComponent("article.txt"), atomically: true, encoding: String.Encoding.utf8)
        
    }
    
    func documentURL() -> URL{
        
        let path =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(path)
        return path[0]
        
    }
    func articleURL() -> URL{
        let path = documentURL().appendingPathComponent("article.txt")
        return path
    }
    func gewichtURL() -> URL{
        let path = documentURL().appendingPathComponent("gewicht.txt")
        return path
        
    }
    
    
    @IBAction func wordsknown(_ sender: Any){
        //        let path = documentURL().appendingPathComponent()
        //        (contentsOfFile: (filePath + "/gewicht.txt") , encoding: String.Encoding.ascii.rawValue)
        ////        let pathx = documentURL().appendingPathComponent("article")
        //        print(documentURL())
        //        let text = "ege"
        //        do{
        //
        //            try? text.write(to: documentURL().appendingPathComponent("article.txt"), atomically: true, encoding: String.Encoding.ascii)
        //        }
        let file = try! NSString(contentsOf: documentURL().appendingPathComponent("article.txt"), encoding: String.Encoding.ascii.rawValue)
        
        var counter = 0
        file.enumerateLines { e, _ in
            counter += 1
            
        }
        let alert = UIAlertController(title: "Knows Words", message: "", preferredStyle: .actionSheet)
        let notify = UIAlertAction(title: "\(counter)", style: .default, handler: nil)
        alert.addAction(notify)
        present(alert, animated: true, completion: nil)
        //        mylabel.text = String(counter)
        
        
    }
    @IBAction func showGewicht(_ sender: Any){
        let file = try! NSString(contentsOf: gewichtURL(), encoding: String.Encoding.ascii.rawValue)
        let alert = UIAlertController(title: "Gewichts", message: String(file), preferredStyle: .alert)
        let close = UIAlertAction(title: "close", style: .cancel, handler: nil)
        alert.addAction(close)
        present(alert, animated: true, completion: nil)
        
    }
    
    func updateSuccessRate(){
        //how to scale any object including bar
        successRateBar.transform = CGAffineTransform(scaleX: 1.0, y: 5.0)
        if(totalAttempts != 0 ){
            successRate = Float(Float(totalSuccess) / Float(totalAttempts))
        }
        else{
            successRate = 0.0
        }
        successRateLabel.text = "\(Int(successRate*100)) %"
        successRateBar.progress = successRate
        
        
    }
    @IBAction func resetProgress(){
        totalAttempts = 0
        totalSuccess = 0
        updateSuccessRate()
    }
}


