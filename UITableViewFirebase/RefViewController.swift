//
//  RefViewController.swift
//  UITableViewFirebase
//
//  Created by deast on 6/11/15.
//  Copyright (c) 2015 davideast. All rights reserved.
//

import UIKit

class RefViewController: UITableViewController {

  // MARK: Properties
  var ref: Firebase!
  var syncArray: [FDataSnapshot]!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    ref = Firebase(url: "https://uitableview-firebase.firebaseio-demo.com/values")
    syncArray = [FDataSnapshot]()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    // Start syncing events when the view is loaded
    appendToListWhenRemoteItemIsAdded(ref)
    removeFromListWhenRemoteItemIsRemoved(ref)
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    
    // Stop syncing when the view is off screen
    ref.removeAllObservers()
  }
  
  // MARK: UITableViewDelegate
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return syncArray.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCellWithIdentifier("Basic") as! UITableViewCell
    var data: FDataSnapshot! = syncArray[indexPath.row]
    cell.textLabel?.text = (data.value["value"] as? Int)?.description
    return cell
  }
  
  // MARK: Firebase Observers
  
  func appendToListWhenRemoteItemIsAdded(ref: Firebase) {
    
    ref.observeEventType(.ChildAdded, withBlock: { snap  in
      
      self.syncArray.append(snap)
      // Create an NSIndexPath from the array's length - 1
      var path = NSIndexPath(forRow: self.syncArray.count - 1, inSection: 0)
      self.tableView.insertRowsAtIndexPaths([path], withRowAnimation: .Fade)
      
    })
    
  }
  
  func removeFromListWhenRemoteItemIsRemoved(ref: Firebase) {
    
    ref.observeEventType(.ChildRemoved, withBlock: { snap in
      
      // Find the index of the removed item
      var position = self.findKeyPosition(snap.key, list: self.syncArray)
      if let position = position {
        
        // Remove from the syncronized array
        self.syncArray.removeAtIndex(position)
        
        // Create an NSIndexPath from the index of the removed item
        var path = NSIndexPath(forRow: position, inSection: 0)
        self.tableView.deleteRowsAtIndexPaths([path], withRowAnimation: .Fade)
        
      }
      
    })
    
  }
  
  // MARK: Array Helper Methods
  
  private func findKeyPosition(key: String, list: [FDataSnapshot!]) -> Int? {
    for var i = 0; i < list.count; i++ {
      var item = list[i]
      if item.key == key {
        return i
      }
    }
    return nil
  }
  
}
