//
//  ViewController.swift
//  CBZed
//
//  Created by Joseph Toronto on 5/5/16.
//  Copyright © 2016 Janken Studios. All rights reserved.
//

import Cocoa



class ViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, ProgressIndicatorDelegate {

    @IBOutlet weak var outputDirLabel: NSTextField!
    @IBOutlet weak var inputDirLabel: NSTextField!
    @IBOutlet weak var filenameOutlineView: NSOutlineView!
    @IBOutlet weak var previewImageView: NSImageView!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var selectedPath:NSURL?
    var imageList:Array<String>? = []
    var rootItem:FileSystemObject?
    var outputPath:NSURL?
    var zipper = Zipper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        filenameOutlineView.setDataSource(self)
        filenameOutlineView.setDelegate(self)
        previewImageView.wantsLayer = true
//        previewImageView.layer?.backgroundColor = NSColor(calibratedRed: 23, green: 44, blue: 54, alpha: 1).CGColor
        previewImageView.layer?.backgroundColor = NSColor.gridColor().CGColor

        if let inputPath = defaults.URLForKey("InputPath"){
            
            self.selectedPath = inputPath
            
        }
        
        if let outPath = defaults.URLForKey("OutputPath"){
           
            self.outputPath = outPath
            self.outputDirLabel.stringValue = (outPath.path)!
        }
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func parseSelectedDir(url: NSURL){
        let fm = NSFileManager()
        
        do {
            let filelist = try fm.contentsOfDirectoryAtPath(url.path!)
            imageList = filelist
            print(filelist)
            filenameOutlineView.reloadData()

        } catch NSCocoaError.FileReadNoSuchFileError {
            print("No such file")
        } catch {
            // other errors
            print(error)
        }
        
    }
    

    
   
    @IBAction func browseButtonPressed(sender: AnyObject) {
        
        
        
        let openPanel = NSOpenPanel()
        if let inputPath = defaults.URLForKey("InputPath"){
            
          openPanel.directoryURL = inputPath
            
        }
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.previewImageView.image = nil
                print(openPanel.URL)
                self.selectedPath = openPanel.URL
                self.defaults.setURL(openPanel.URL, forKey: "InputPath")
                self.defaults.synchronize()
                //self.inputDirLabel.stringValue = (openPanel.URL?.relativeString)!
                let header = (self.filenameOutlineView.tableColumns.first)?.headerCell
                header?.stringValue = (openPanel.URL?.path)!
                //let rootObject = FileSystemObject.init(path: (openPanel.URL?.relativeString)!, parent: nil)
                let rootObject = FileSystemObject.init(rootObjectWithPath: (openPanel.URL?.path)!)
                self.rootItem = rootObject
                self.filenameOutlineView.reloadData()
            }
        }
    }
    
    @IBAction func outputDirBrowseButtonPressed(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.outputPath = openPanel.URL
                self.defaults.setURL(openPanel.URL, forKey: "OutputPath")
                self.defaults.synchronize()
                self.outputDirLabel.stringValue = (openPanel.URL?.path)!
            }
        }
    }
    
    //Outlineview data source methods
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil{
            return (self.rootItem?.children[index])!
        }
        else{
            return (item as! FileSystemObject).children[index]
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        let fileSystemitem:FileSystemObject = item as! FileSystemObject
        return (fileSystemitem.children.count > 0)
        
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int{
        var returnvalue = 0
        if rootItem != nil{ // So it doesn't crash after the app starts and nothing has been loaded yet.
        
        if item == nil{
            returnvalue = (self.rootItem?.children.count)!
        }
        else{
            returnvalue = (item?.children.count)!
        }
        
    }
        return returnvalue
    }
    
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject?{
        if item == nil{
            let emptyString = ""
            return emptyString
        }
        else {
            return (item as! FileSystemObject).name
        }
    }
    
    
   //Outlineview delegate methods
    
   
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        if filenameOutlineView.selectedRow != -1 {
            let selectedItem = filenameOutlineView.itemAtRow(filenameOutlineView.selectedRow) as! FileSystemObject
            
            self.previewImageView.image = NSImage(contentsOfFile: selectedItem.path!)
        }
    }
    
// Task handling
    
    @IBAction func startButtonPressed(sender: AnyObject) {
           }
    
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        var yesno = true
        if identifier == "progressSegue"{
            if rootItem == nil {
                let alert = NSAlert()
                alert.messageText = "Nothing to do!"
                alert.informativeText = "Need to select input and output paths first."
                alert.addButtonWithTitle("Ok")
                alert.alertStyle = .WarningAlertStyle
                alert.runModal()
               yesno = false
            }
        }
        return yesno
    }
    
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?){
        
        
        if segue.identifier == "progressSegue" {
            
            if let destViewController:ProgressIndicatorViewController = segue.destinationController as? ProgressIndicatorViewController{
                 zipper.delegate = destViewController
                destViewController.delegate = self
            
            }
            
        }
        
    }
    
    func progressIndicatorReadyToRock(){
        
        var pathsArray:Array<String> = []
        for singleObject:FileSystemObject in (rootItem?.children)!{
            if singleObject.selfType != FileSystemObject.NodeType.RootNode{
                pathsArray.append(singleObject.path!)
                
            }
        }
        zipper.zipItems(pathsArray, outputpath: (outputPath?.path)!)
    }
    
}

