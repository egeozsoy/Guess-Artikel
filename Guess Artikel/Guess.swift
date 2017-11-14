//
//  AppDelegate.swift
//  Guess Artikel
//
//  Created by Ege on 04.08.17.
//  Copyright © 2017 Ege Özsoy. All rights reserved.
//

import UIKit
import Foundation
import Firebase

extension String {
    
    var length: Int {
        return self.count
    }
    subscript (i: Int) -> String {
        return self[Range(i ..< i + 1)]
    }
    func substring(from: Int) -> String {
        return self[Range(min(from, length) ..< length)]
    }
    func substring(to: Int) -> String {
        return self[Range(0 ..< max(0, to))]
    }
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return self[Range(start ..< end)]
    }
}

var der = [String]();
var die = [String]();
var das = [String]();

    class Guess {
        
        var gw1 : Float=1
        var gw2 : Float=1
        var gw3 : Float=1
        var gw4 : Float=1
        var gw5 : Float=1
        
        let ref = Database.database().reference().child("words")
        
        func documentURL() -> URL{
            let path =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
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
        
        func sigmoid(x:Double) -> Double {
            return Double(1) - (2/(pow(M_E, 2*Double(x))+1));
        }
        
        func reversesigmoid(y:Double) -> Double{
            return (log((y + 1) / (-y + 1)) / Double(2));
        }
        
        func updateGewicht() -> (Float , Float, Float, Float, Float){
            
            let file = try! NSString(contentsOf: gewichtURL(), encoding: String.Encoding.ascii.rawValue)
            gw1 = 1
            gw2 = 1
            gw3 = 1
            gw4 = 1
            gw5 = 1
            
            //    iterate over lines of string
            file.enumerateLines { e, _ in
                
                if let k = Float(e[2..<100]){
        
                    if(e[0] == "1"){
                        self.gw1 = k
                    }
                    else if(e[0] == "2"){
                        self.gw2 = k
                    }
                    else if (e[0] == "3"){
                        self.gw3 = k
                    }
                    else if (e[0] == "4"){
                        self.gw4 = k
                    }
                    else if(e[0] == "5"){
                        self.gw5 = k
                    }
                }
            }
            return (gw1,gw2,gw3,gw4,gw5)
        }
        
        func updateGewichtfile(gw: [Float]) throws{
            var text = "";
            for i in 0...4{
                text = text + "\n" + "\(i+1)" + " " +  String(gw[i]);
            }
            try text.write(to: gewichtURL(), atomically: true, encoding: String.Encoding.ascii)
        }
//        old method using text
//        func learnArtikel() -> ([String] , [String] , [String]){
//            print("learngin artikel")
//
//            let file = try! NSString(contentsOf: articleURL(), encoding: String.Encoding.utf8.rawValue)
//
//            der = [String]();
//            das = [String]();
//            die = [String]();
//            var counter = 0;
//            file.enumerateLines { e, _ in
////                let childRef = self.ref.childByAutoId()
//                let line = e.lowercased();
//                if(line.length >= 3){
//                    if((line[0] + line[1] + line[2]) == "der"){
////                        childRef.updateChildValues([line[4 ..< (line.length)].lowercased() : "der"])
//                        der.append(line[4 ..< (line.length)].lowercased())
//
//                    }
//                    else if ((e[0] + e[1] + e[2]) == "das"){
////                        childRef.updateChildValues([line[4 ..< (line.length)].lowercased() : "das"])
//                        das.append(line[4 ..< (line.length)].lowercased())
//                    }
//                    else if ((e[0] + e[1] + e[2]) == "die"){
////                        childRef.updateChildValues([line[4 ..< (line.length)].lowercased() : "die"])
//                        die.append(line[4 ..< (line.length)].lowercased())
//                    }
//                    counter += 1;
////                    print("learned articles " + String(counter))
//                }
//            }
//
//            return (der,die,das);
//
//        }
        
//        fireabse
        
//        does not work correcly make it persistant make two different article methods
        func learnArtikel(){

//        let file = try! NSString(contentsOf: articleURL(), encoding: String.Encoding.utf8.rawValue)

//        der = [String]();
//        das = [String]();
//        die = [String]();
        var counter = 0;
            ref.observe(.childAdded, with: {(snapshot) in
                let childId = snapshot.key
                let currentRef = self.ref.child(childId)
                currentRef.observeSingleEvent(of: .value, with: { snapshot in
                    if let dictionary = snapshot.value as? [String : String]{
                        guard let currentArticle = dictionary.first?.value else {return}
                        guard let currentWord = dictionary.first?.key.lowercased() else{return}
                        counter += 1
                        switch (currentArticle){
                            
                        case "der" :
                            if der.contains(currentWord){
                                
                            }
                            else{
                            der.append(currentWord)
                            }
                        case "das":
                            if das.contains(currentWord){
                                
                            }else{
                                das.append(currentWord)
                            }
                            
                        case "die":
                            if die.contains(currentWord){
                                
                            }
                            else{
                               
                                die.append(currentWord)
                            }
                        default :
                            break
                    }
                    }
                })
            })

            }

        
        //# 1
        func similarBegin(wort:String ,comparewort:String) -> Double{
//            print(comparewort)
            let startbias = wort.length;
            var similarcounter = 0.0;
//            print(wort)
//            print(comparewort)
            for i in 0...wort.length{
                if(i<wort.length && i<comparewort.length){
                    if(wort[i] == comparewort[i]){
                        
                        similarcounter += 1;
                    }
                    else{
                        break;
                    }
                    
                }
            }
//            print( pow((10*similarcounter/Double(startbias)) , 5.0))
            return pow((similarcounter/Double(startbias)) , 5.0)
        }
        
        //# 2
        
        func similarEnd(wort:String ,comparewort:String) -> Double{
            let startbias = wort.length;
//            print(startbias)
            var similarcounter = 0.0;
            for i in 0...comparewort.length{
//                print(i)
//                print(wort)
//                print(comparewort)
                if(i<wort.length && i<comparewort.length){
                   
                    if(wort[wort.length - 1 - i] == comparewort[comparewort.length - 1 - i]){
                        similarcounter += 1;
                    }
                    else{
                        break;
                    }
                    
                }
            }
//            print(similarcounter)
            return pow((similarcounter/Double(startbias)) , 5.0)
        }
        
        func findvocalandconsantentcount(wort:String) -> Double{
            var vocal = 0.0
            var consantent = 0.0
            for e in wort{
                if(e == "a" || e=="ä" || e=="e" || e=="i" || e=="o" || e=="ö" || e=="u" || e=="ü"){
                    vocal+=1
                }
                else{
                    consantent+=1
                }
            }
            if(consantent == 0){
                return vocal
            }
            return (vocal/consantent);
        }
        
        
        
        //# 3
        
        func vocalvsconsantent(wort:String ,comparewort:String) -> Double{
            let wortvs = Double(findvocalandconsantentcount(wort: wort))
            
            let comparewortvs = Double(findvocalandconsantentcount(wort: comparewort))
            
            
            if(comparewortvs<=wortvs){
//                print(wort + " A " + comparewort + " " +  "\(pow((comparewortvs/wortvs) , 5.0))")
                return pow((comparewortvs/wortvs) , 5.0)
                
            }
            else{
//                print( wort + " B " + comparewort + " " + "\(wortvs)" + " " + "\(comparewortvs)" +  " " + "\(pow((wortvs/comparewortvs) , 5.0))")
                return pow((wortvs/comparewortvs) , 5.0)
            }
            
        }
        
        
        //# 4
        func vocalsimilarity(wort:String ,comparewort:String) -> Double{
            var vocalamount = 0.0
            var similarvocalamount = 0.0
            for e in (wort){
                if(e == "a" || e=="ä" || e=="e" || e=="i" || e=="o" || e=="ö" || e=="u" || e=="ü"){
                    vocalamount += 1
                
                for k in comparewort{
                    if(e == k){
                        similarvocalamount+=1
                        break;
                    }
                    }
                }
            }
            if(vocalamount == 0){
                return 0
            }
           
            return pow((similarvocalamount/vocalamount) , 5.0)
            
        }
        
        func findGuesses(towort: String) -> ([Double] , [Double] , [Double] , [Double]){
            //    # der, das ,die
            var Guess1 = [0.0, 0.0, 0.0]
            var Guess2 = [0.0, 0.0, 0.0]
            var Guess3 = [0.0, 0.0, 0.0]
            var Guess4 = [0.0, 0.0, 0.0]
            
            for wort in der{
//                print(wort)
                Guess1[0] += similarBegin(wort: towort, comparewort: wort)
                Guess2[0] += similarEnd(wort: towort,comparewort: wort)
                Guess3[0] += vocalvsconsantent(wort: towort,comparewort: wort)
                Guess4[0] += vocalsimilarity(wort: towort,comparewort: wort)
            }
            
            for wort in das{
//                print(wort)
//                print(similarBegin(wort: towort, comparewort: wort))
                Guess1[1] += similarBegin(wort: towort, comparewort: wort)
                Guess2[1] += similarEnd(wort: towort,comparewort: wort)
                Guess3[1] += vocalvsconsantent(wort: towort,comparewort: wort)
                Guess4[1] += vocalsimilarity(wort: towort,comparewort: wort)
            }
            for wort in die{
               
                Guess1[2] += similarBegin(wort: towort, comparewort: wort)
                Guess2[2] += similarEnd(wort: towort,comparewort: wort)
                Guess3[2] += vocalvsconsantent(wort: towort,comparewort: wort)
                Guess4[2] += vocalsimilarity(wort: towort,comparewort: wort)
            }
            print(Guess1, Guess2, Guess3 , Guess4)
            return (Guess1,Guess2,Guess3,Guess4)
            
        }
        
        func guessasArtikel(Guess: [Double]) -> String{
            if(Guess[0] > Guess[1] && Guess[0]>Guess[2]){
                return "der"
            }
                
            else if(Guess[1] > Guess[0] && Guess[1] > Guess[2]){
                return "das"
            }
                
            else if (Guess[2] > Guess[0] && Guess[2] > Guess[1]){
                return "die"
            }
            return ""
            
        }
        
        func mostGuess(towort: String) -> String{
            var der = 0.0
            var das = 0.0
            var die = 0.0
            
            let (Guess1,Guess2,Guess3,Guess4) = findGuesses(towort: towort);
          
            var Guess = [Guess1,Guess2,Guess3,Guess4]
//            print(Guess[0])
            var gw = [gw1,gw2,gw3,gw4]
            print(gw)
            gw[0] *= Float((8.0 / Float(towort.length)))
            gw[1] *= Float((Float(towort.length) / 8.0))
            print(gw)
            for i in 0...3{
                if(guessasArtikel(Guess: Guess[i]) == "der"){
                    print("der")
                    //    # print(str(i+1) + ':der')
                    print(gw[i])
                    der += Double(1*gw[i])
                }
                else if(guessasArtikel(Guess: Guess[i]) == "das"){
                    print("das")
                    //    # print(str(i+1) + ':das')
                    das += Double(1*gw[i])
                }
                else if(guessasArtikel(Guess: Guess[i])=="die"){
                    print("die")
                    //    print(str(i+1) + ':die')
                    die += Double(1*gw[i])
                }
            }
            print("Der " + String(der))
            print("Die " + String(die))
            print("Das " + String(das))
            if(der >= die && der>=das){
                return "der"
            }
            else if(die>=der && die>=das){
                return "die"
            }
            else if(das>=der && das>=der){
                return "das"
            }
            return " "
        }
        
        func newGewicht(Artikel:String , towort:String) throws{
//            print(Artikel)
//            print(towort)
            let(gw1, gw2, gw3, gw4, gw5) = updateGewicht()
            var gw = [gw1, gw2,gw3,gw4,gw5]
            let (Guess1, Guess2, Guess3, Guess4) = findGuesses(towort: towort)
            var Guess = [Guess1,Guess2,Guess3,Guess4]
//            print(Guess)
            for i in 0...3{
                //    # print(Artikel)
                if(guessasArtikel(Guess: Guess[i]) == Artikel){
//                    print("true article")
                    var value = gw[i]
                    let valuex = (reversesigmoid(y: Double(value)))
                    value = Float(sigmoid(x: (valuex + 0.01)))
                    gw[i] = value
                    //    # print(str(tmp) + ' > ' +str(gw[i]))
                }
                else{
//                    print("false article")
                    
                    var value = gw[i]
                    let valuex = (reversesigmoid(y: Double(value)))
                    value = Float(sigmoid(x: (valuex*(0.98))))
                    gw[i] = value
                    //    # print(str(tmp) + ' < ' + str(gw[i]))
                }
            }
//            print(gw)
            try updateGewichtfile(gw: gw)
        }
        
        func mainGuess(originalwort : String) throws -> String{
//            print(originalwort)
        (gw1,gw2,gw3,gw4,gw5) = updateGewicht()
        
        learnArtikel();

//        (der, die, das) = learnArtikel()
        let wort = originalwort.lowercased();
        let guess = mostGuess(towort: wort);
//        print(guess + " " + originalwort)
        return guess
        }
        }

        



