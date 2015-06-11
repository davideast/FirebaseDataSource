//
//  FirebaseDataSource.swift
//  UITableViewFirebase
//
//  Created by deast on 6/11/15.
//  Copyright (c) 2015 davideast. All rights reserved.
//

import Foundation
import UIKit

@objc protocol FirebaseDataSourceDelegate {
  optional func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemAddedAtIndexPath: NSIndexPath, data: FDataSnapshot)
  optional func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemChangedAtIndexPath: NSIndexPath, data: FDataSnapshot)
  optional func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemRemovedAtIndexPath: NSIndexPath, data: FDataSnapshot)
  optional func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemMovedAtIndexPath: NSIndexPath, toIndexPath: NSIndexPath, data: FDataSnapshot)
}

class FirebaseDataSource: NSObject, FirebaseArrayDelegate {

  // MARK: Properties
  
  private var syncArray: FirebaseArray
  var delegate: FirebaseDataSourceDelegate?
  
  // MARK: Computed properties
  
  var count: Int {
    return syncArray.list.count
  }
  
  var list: [FDataSnapshot] {
    return syncArray.list
  }
  
  // MARK: Initializers
  
  init(ref: Firebase) {
    syncArray = FirebaseArray(ref: ref)
    super.init()
    syncArray.delegate = self
  }
  
  // MARK: Data Updates
  
  func append(data: AnyObject!) {
    syncArray.append(data)
  }
  
  func updateAtIndex(index: Int, data: [NSObject: AnyObject!]) {
    syncArray.updateAtIndex(index, data: data)
  }
  
  func removeAtIndex(index: Int) {
    syncArray.removeAtIndex(index)
  }
  
  // MARK: Syncing
  
  func startSync() {
    syncArray.sync()
  }
  
  func stopSync() {
    syncArray.dispose()
  }
  
  // MARK: FirebaseArrayDelegate
  
  func firebaseArray(list: [FDataSnapshot], indexAdded: Int, data: FDataSnapshot) {
    var path = createNSIndexPath(indexAdded)
    delegate?.firebaseDataSource?(self, itemAddedAtIndexPath: path, data: data)
  }
  
  func firebaseArray(list: [FDataSnapshot], indexChanged: Int, data: FDataSnapshot) {
    var path = createNSIndexPath(indexChanged)
    delegate?.firebaseDataSource?(self, itemChangedAtIndexPath: path, data: data)
  }
  
  func firebaseArray(list: [FDataSnapshot], indexRemoved: Int, data: FDataSnapshot) {
    var path = createNSIndexPath(indexRemoved)
    delegate?.firebaseDataSource?(self, itemRemovedAtIndexPath: path, data: data)
  }
  
  func firebaseArray(list: [FDataSnapshot], oldIndex: Int, newIndex: Int, data: FDataSnapshot) {
    var oldPath = createNSIndexPath(oldIndex)
    var newPath = createNSIndexPath(newIndex)
    delegate?.firebaseDataSource?(self, itemMovedAtIndexPath: oldPath, toIndexPath: newPath, data: data)
  }
  
  // MARK: NSIndexPath Helpers
  
  func createNSIndexPath(forItem: Int, inSection: Int = 0) -> NSIndexPath {
    return NSIndexPath(forItem: forItem, inSection: inSection)
  }
  
}