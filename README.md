# Syncing Data with UITableView and Firebase
This repo shows two examples of syncing data with UITableView and Firebase. 

There is a short tutorial at the bottom of the readme.

## RefViewController
The RefViewController demonstrates the process of manually syncing data from Firebase to a UITableView. 
This view controller has a `ref: Firebase` property and a `syncArray: [FDataSnapshot!]` property. In the
`viewDidAppear` lifecycle method, Firebase observers are attached that mutate the `syncArray` whenever an add or remove
event has occurred. 

```swift
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
    appendToListWhenRemoteItemIsAdded(ref) // Check the source for implementations
    removeFromListWhenRemoteItemIsRemoved(ref)
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    
    // Stop syncing when the view is off screen
    ref.removeAllObservers()
  }
```

This example only demonstrates events for added and removed. This example is also not portable. If we need to create
another UITableViewController that syncs data, we'll be writing the same code. To fix this problem we can create a 
synchronized array that alerts us when items have been added, removed, changed, or moved in the array. The second
example, `DataSourceViewController`, uses a synchronized array.

## DataSourceViewController
The DataSourceViewController uses the `FirebaseDataSource` class to sync data between Firebase and the UITableView. 
The 'FirebaseDataSource' class is a small wrapper around a `FirebaseArray` that provides the `NSIndexPath` of the
item of the data update.

#### FirebaseArray
The `FirebaseArray` has a delegate which fires off functions when `FEventType` events have 
occurred (`.ChildAdded`, `.ChildChanged`, `.ChildRemoved`, `.ChildMoved`).

```swift
@objc protocol FirebaseArrayDelegate {
  optional func firebaseArray(firebaseArray: [FDataSnapshot], indexAdded: Int, data: FDataSnapshot)
  optional func firebaseArray(firebaseArray: [FDataSnapshot], indexChanged: Int, data: FDataSnapshot)
  optional func firebaseArray(firebaseArray: [FDataSnapshot], indexRemoved: Int, data: FDataSnapshot)
  optional func firebaseArray(firebaseArray: [FDataSnapshot], oldIndex: Int, newIndex: Int, data: FDataSnapshot)
}
```

```swift
class SomeClass : FirebaseArrayDelegate {

  init(ref: Firebase) {
    var syncArray = FirebaseArray(ref: ref)
    // set the delegate to the class to listen for data updates
    syncArray.delegate = self
  }
  
  func firebaseArray(list: [FDataSnapshot], indexAdded: Int, data: FDataSnapshot) {
    // do something when the item has been added  
  }
  
}

```

Each delegate method provides the current list, the index of the item, and the snapshot from Firebase. The index as
an integer isn't useful for UIKit controls like `UITableView` and `UICollectionView`. UIKit controls require the
`NSIndexPath` type for modifying rows. This is where we use the `FirebaseDataSource` class.

#### FirebaseDataSource
The `FirebaseDataSource` provides a thin wrapper around the `FirebaseArray` that provides delegate methods 
that return the snapshot as well as the `NSIndexPath`.

```swift
@objc protocol FirebaseDataSourceDelegate {
  optional func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemAddedAtIndexPath: NSIndexPath, data: FDataSnapshot)
  optional func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemChangedAtIndexPath: NSIndexPath, data: FDataSnapshot)
  optional func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemRemovedAtIndexPath: NSIndexPath, data: FDataSnapshot)
  optional func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemMovedAtIndexPath: NSIndexPath, toIndexPath: NSIndexPath, data: FDataSnapshot)
}
```

We can use this delegate protocol on UIKit controls like `UITableViewController` and `CollectionViewController`.

```swift
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

}
```

From here we can wire up the tableView delegate and firebaseDataSource delegate methods.

#### tableView delegate

##### `numberOfRowsInSection`
First, we'll need to provide the row count in the `numberOfRowsInSection` delegate method. 
The data source should have a length or a count method to provide the rows in section count.
 ```swift
   override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataSource.count
  }
 ```

##### `cellForRowAtIndexPath`
Dequeue the cell prototype in the `cellForRowAtIndexPath` delegate method. The tableView delegate has 
a `cellForRowAtIndexPath` method that fires off every time an item from the data source is updated.
 ```swift
   override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCellWithIdentifier("<SOME-CELL-IDENTIFIER>") as! UITableViewCell
    var data: FDataSnapshot! = dataSource[indexPath.row] // dataSource is of [FDataSnapshot]
    cell.textLabel?.text = data.value["text"] // Assume we are syncing an object with a string property of "text"
    return cell
  }
 ```
 
#### firebaseDataSource delegate

##### `itemAddedAtIndexPath`
When an item has been added, we can insert the rows into the tableView.
```swift
func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemAddedAtIndexPath: NSIndexPath, data: FDataSnapshot) {
  tableView.insertRowsAtIndexPaths([itemAddedAtIndexPath], withRowAnimation: .None)
}
```

##### `itemChangedAtIndexPath`
When an item has been changed, we can reload the tableView at the specified `NSIndexPath`.
```swift
func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemChangedAtIndexPath: NSIndexPath, data: FDataSnapshot) {
  tableView.reloadRowsAtIndexPaths([itemChangedAtIndexPath], withRowAnimation: .None)
}
```

##### `itemRemovedAtIndexPath`
When an item has been removed, we can remove the item from the tableView at the specified `NSIndexPath`.
```swift
func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemRemovedAtIndexPath: NSIndexPath, data: FDataSnapshot) {
  tableView.deleteRowsAtIndexPaths([itemRemovedAtIndexPath], withRowAnimation: .None)
}
```

##### `itemMovedAtIndexPath`
When an item has been moved, we can specify the old `NSIndexPath` position and then the new `NSIndePath` position to move the item to.
```swift
func firebaseDataSource(firebaseDataSource: FirebaseDataSource, itemMovedAtIndexPath: NSIndexPath, toIndexPath: NSIndexPath, data: FDataSnapshot) {
  tableView.moveRowAtIndexPath(itemMovedAtIndexPath, toIndexPath: toIndexPath)
}
```

### License: Apache 2.0

