//
//  Zipper.swift
//  CBZed
//
//  Created by Joseph Toronto on 5/20/16.
//  Copyright © 2016 Janken Studios. All rights reserved.
//

import Cocoa

protocol ZipperProgressDelegate {
    func startWithTotal(total:Int)
    func advanceNext()
    func addTextToConsole(text:String)
}


class Zipper: NSObject {
    var delegate:ZipperProgressDelegate?
    var itemCount = 0
    var progressCount = 0
    var opQueue = NSOperationQueue()
    var currentTask:NSTask?
    
    func zipItems(items:Array<String>, outputpath:String){
        print("zipItems")
        itemCount = items.count
        print(itemCount)
       
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Zipper.userCancelled), name: "cancelled from progress modal", object: nil)
        let mainQueue = NSOperationQueue.mainQueue()
        
        let fileManager = NSFileManager()
        var isDir = ObjCBool(false)
        fileManager.fileExistsAtPath(items[0], isDirectory: &isDir)
       
        
        if !isDir {
             delegate?.startWithTotal(1)
            
             let dirOnlyPathString = (NSURL.fileURLWithPath(items[0]).URLByDeletingLastPathComponent)?.path
             let dirname = (NSURL.fileURLWithPath(items[0]).URLByDeletingLastPathComponent)?.lastPathComponent
            self.opQueue.addOperationWithBlock {
                
               
                    if self.opQueue.operations[0].cancelled == true{
                        return
                    }
                    let outputfilename = {
                        ()  -> String in
                        //let returnString = ""
                        var filename = dirname! + ".cbz"
                        filename = outputpath + "/" + filename
                        
                        return filename
                    }

                    
                    let task = NSTask()
                    self.currentTask = task
                    task.currentDirectoryPath = dirOnlyPathString!
                    print("Working Directory: \(task.currentDirectoryPath)")
                    task.launchPath = "/usr/bin/zip"
                    let arguments : [String] = ["-r", "-v", outputfilename(), dirOnlyPathString!]
                    task.arguments = arguments
                    // Pipe the standard out to an NSPipe, and set it to notify us when it gets data
                    let pipe = NSPipe()
                    task.standardOutput = pipe
                    let fh = pipe.fileHandleForReading
                    fh.waitForDataInBackgroundAndNotify()
                    
                    // Set up the observer function
                    let notificationCenter = NSNotificationCenter.defaultCenter()
                    notificationCenter.addObserver(self, selector: #selector(Zipper.receivedData(_:)), name: NSFileHandleDataAvailableNotification, object: nil)
                
                
                    task.launch()
                    task.waitUntilExit()
                    let status = task.terminationStatus
                    if status == 0 {
                        
                        mainQueue.addOperationWithBlock({
                            print("Task termination status \(status)")
                            if self.itemCount > self.progressCount{
                                self.delegate?.advanceNext()
                                self.progressCount += 1
                                
                            }
                            else if self.itemCount == self.progressCount{
                                self.itemCount = 0
                                self.progressCount = 0
                            }
                            
                        })
                        
                        
                    }

                
                
            
            }//end if statement
            // Process for array of files.
        }

        else{
            // Process for dir tree.
         delegate?.startWithTotal(itemCount)
                self.opQueue.addOperationWithBlock {
                    
                    for singlePath in items{
                        if self.opQueue.operations[0].cancelled == true{
                            return
                        }
                        
                        
                        let outputfilename = {
                            ()  -> String in
                            //let returnString = ""
                            var filename = NSURL(fileURLWithPath: singlePath).lastPathComponent! + ".cbz"
                            filename = outputpath + "/" + filename
                            
                            return filename
                        }
                        
                        let task = NSTask()
                        self.currentTask = task
                        task.currentDirectoryPath = singlePath
                        print("Working Directory: \(singlePath)")
                        task.launchPath = "/usr/bin/zip"
                        let arguments : [String] = ["-r", "-v", outputfilename(), singlePath]
                        task.arguments = arguments
                        // Pipe the standard out to an NSPipe, and set it to notify us when it gets data
                        let pipe = NSPipe()
                        task.standardOutput = pipe
                        let fh = pipe.fileHandleForReading
                        fh.waitForDataInBackgroundAndNotify()
                        
                        // Set up the observer function
                        let notificationCenter = NSNotificationCenter.defaultCenter()
                        notificationCenter.addObserver(self, selector: #selector(Zipper.receivedData(_:)), name: NSFileHandleDataAvailableNotification, object: nil)
                        
                        task.launch()
                        task.waitUntilExit()
                        let status = task.terminationStatus
                        if status == 0 {
                            
                            mainQueue.addOperationWithBlock({ 
                                print("Task termination status \(status)")
                                if self.itemCount > self.progressCount{
                                    self.delegate?.advanceNext()
                                    self.progressCount += 1
                                    
                                }
                                else if self.itemCount == self.progressCount{
                                    self.itemCount = 0
                                    self.progressCount = 0
                                }

                            })
                            
                            
                        }
                        
                        
                    }//End for loop

        
        
               }//end block
        }//end else statement
        
        self.progressCount = 0
    }
    
    
    func receivedData(notif : NSNotification) {
        // Unpack the FileHandle from the notification
        let fh:NSFileHandle = notif.object as! NSFileHandle
        // Get the data from the FileHandle
        let data = fh.availableData
        // Only deal with the data if it actually exists
        if data.length > 1 {
            // Since we just got the notification from fh, we must tell it to notify us again when it gets more data
            fh.waitForDataInBackgroundAndNotify()
            // Convert the data into a string
            let outputAsString = (NSString(data: data, encoding: NSASCIIStringEncoding)) as! String
            
            dispatch_async(dispatch_get_main_queue(), {
                self.delegate?.addTextToConsole(outputAsString)
            })


        }
    }
    
    func userCancelled() {
     opQueue.cancelAllOperations()
     currentTask?.terminate()
    }
    
    
}