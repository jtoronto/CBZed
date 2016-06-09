//
//  FileSystemObject.swift
//  CBZed
//
//  Created by Joseph Toronto on 5/11/16.
//  Copyright © 2016 Janken Studios. All rights reserved.
//

import Cocoa

class FileSystemObject: NSObject {
    enum NodeType{
        case RootNode
        case Inode
        case Leafnode
    }
    
    var parentObject:FileSystemObject?
    var children:Array<FileSystemObject> = []
    var selfType:NodeType?
    var path:String?
    var pathRoot:String?
    var name:String?
    
    init (rootObjectWithPath: String){ //This is the initializer that gets called outisde of the class
        super.init()
        self.selfType = NodeType.RootNode
        self.path = rootObjectWithPath
        self.name = (self.path! as NSString).lastPathComponent
        self.searchForChildren()
        
        
    }
    
    init (path: String, parent: FileSystemObject){ //This is the initialized that gets called from within the class to create new children
        super.init()
        self.parentObject = parent
        self.path = path
        self.name = (self.path! as NSString).lastPathComponent
        self.searchForChildren()
    }
    
    func searchForChildren(){
        let fileManager = NSFileManager()
        
        //First check to see if we're a leaf-node or not.
        
        var isDir = ObjCBool(false)
        let exists = fileManager.fileExistsAtPath(self.path!, isDirectory: &isDir)
        
        if exists{
            if !isDir{
                print("\(self.path) is a leaf node")
                self.selfType = NodeType.Leafnode
                
            }
            else if isDir{
                //Search for children
               // var children:Array<FileSystemObject> = []
                var dirContents:Array<String> = []
                self.selfType = NodeType.Inode
                do {
                    dirContents = try fileManager.contentsOfDirectoryAtPath(path!)
                    
                    
                } catch NSCocoaError.FileReadNoSuchFileError {
                    print("No such file")
                } catch {
                    // other errors
                    print(error)
                }
                let numberofChildren = dirContents.count
                print("\(self.path)'s children \(dirContents)")
                
                for i in 0 ..< numberofChildren{
                     if dirContents[i] != ".DS_Store"{
                    let path = self.path! + "/" + dirContents [i]
                    let newChild = FileSystemObject (path: path, parent: self)
                    self.children.append(newChild)
                    }
                }
                
            }
        }
        
        self.children.sortInPlace({ $0.name < $1.name })
    }// end search for children
    
    
}//End FilesystemObject class