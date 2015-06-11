//
//  ViewController.swift
//  UITableViewFirebase
//
//  Created by deast on 6/11/15.
//  Copyright (c) 2015 davideast. All rights reserved.
//

import UIKit

class DataSourceViewController: UITableViewController, FirebaseDataSourceDelegate {
  
  var dataSource: FirebaseDataSource!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    var ref = Firebase(url: "https://uitableview-firebase.firebaseio-demo.com/values")
    dataSource = FirebaseDataSource(ref: ref)
    dataSource.delegate = self
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    // When the view "wakes up" we'll need to start from a fresh
    // set of data on the tableView
    tableView.reloadData()
    
    
    // Once the tableView has been reloaded we can start syncing
    // from Firebase again
    dataSource.startSync()
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    
    // When the view goes off the screen we'll need to reserve
    // resources by canceling and sync events
    dataSource.stopSync()
  }
  
  // MARK: UITableViewDelegate
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataSource.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCellWithIdentifier("Basic") as! UITableViewCell
    var data: FDataSnapshot! = dataSource.list[indexPath.row]
    cell.textLabel?.text = (data.value["value"] as? Int)?.description
    return cell
  }
  
  // MARK: FirebaseDataSourceDelegate
  
  func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemAddedAtIndexPath: NSIndexPath, data: FDataSnapshot) {
    tableView.insertRowsAtIndexPaths([itemAddedAtIndexPath], withRowAnimation: .None)
  }
  
  func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemChangedAtIndexPath: NSIndexPath, data: FDataSnapshot) {
    tableView.reloadRowsAtIndexPaths([itemChangedAtIndexPath], withRowAnimation: .None)
  }
  
  func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemRemovedAtIndexPath: NSIndexPath, data: FDataSnapshot) {
    tableView.deleteRowsAtIndexPaths([itemRemovedAtIndexPath], withRowAnimation: .None)
  }
  
  func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemMovedAtIndexPath: NSIndexPath, toIndexPath: NSIndexPath, data: FDataSnapshot) {
    tableView.moveRowAtIndexPath(itemMovedAtIndexPath, toIndexPath: toIndexPath)
  }


}

