//
//  ProgressIndicatorViewController.swift
//  CBZed
//
//  Created by Joseph Toronto on 5/21/16.
//  Copyright © 2016 Janken Studios. All rights reserved.
//

import Cocoa

protocol ProgressIndicatorDelegate {
    func progressIndicatorReadyToRock()
}

class ProgressIndicatorViewController: NSViewController, ZipperProgressDelegate {

    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet var outputTextView: NSTextView!
    @IBOutlet weak var spinner: NSProgressIndicator!
    
    enum operatingMode{
        case finished
        case running
        case idle
    }
    var numberofitems = 0
    var currentProgress = 0
    var ready = false
    var delegate:ProgressIndicatorDelegate?
    var currentMode:operatingMode = .idle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        delegate?.progressIndicatorReadyToRock()
    }
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        
        switch (currentMode) {
        case .finished:
            self.view.window?.close()
            
        case .idle:
            self.view.window?.close()
            
        case .running:
             NSNotificationCenter.defaultCenter().postNotificationName("cancelled from progress modal", object: nil)
            currentMode = .idle
            cancelButton.title = "Done"
            spinner.stopAnimation(nil)
            spinner.hidden = true
        }
        
        
    }
    
    func startWithTotal(total:Int){
        self.numberofitems = total
        print("startWIthTotal")
        progressLabel.stringValue = "0 of \(total)"
        progressIndicator.minValue = 0
        progressIndicator.maxValue = Double(total)
        currentMode = .running
        spinner.startAnimation(nil)
        spinner.hidden = false
    }
    
    func advanceNext(){
        
        currentProgress += 1
        print("Advance to \(currentProgress)")
        progressLabel.stringValue = "\(currentProgress) of \(numberofitems)"
        //progressIndicator.incrementBy(1)
        progressIndicator.doubleValue = Double(currentProgress)
        if currentProgress == numberofitems{
            currentMode = .finished
            cancelButton.title = "Done"
            spinner.stopAnimation(nil)
            spinner.hidden = true
        }
    }
    
    func addTextToConsole(text:String){
    
        let newtext = NSMutableAttributedString(string: text, attributes: [NSForegroundColorAttributeName:NSColor.greenColor()])
            print(newtext)
        outputTextView.textStorage?.appendAttributedString(newtext)
        outputTextView.scrollToEndOfDocument(nil)
            
    }
    
       
}

