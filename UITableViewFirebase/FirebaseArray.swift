//
//  FirebaseArray.swift
//  UITableViewFirebase
//
//  Created by deast on 6/11/15.
//  Copyright (c) 2015 davideast. All rights reserved.
//

//
//  FirebaseArray.swift
//  FireKit
//
//  Created by deast on 5/13/15.
//  Copyright (c) 2015 davideast. All rights reserved.
//

@objc protocol FirebaseArrayDelegate {
  optional func firebaseArray(firebaseArray: [FDataSnapshot], indexAdded: Int, data: FDataSnapshot)
  optional func firebaseArray(firebaseArray: [FDataSnapshot], indexChanged: Int, data: FDataSnapshot)
  optional func firebaseArray(firebaseArray: [FDataSnapshot], indexRemoved: Int, data: FDataSnapshot)
  optional func firebaseArray(firebaseArray: [FDataSnapshot], oldIndex: Int, newIndex: Int, data: FDataSnapshot)
}

class FirebaseArray {
  
  var list: [FDataSnapshot]!
  let ref: Firebase!
  var delegate: FirebaseArrayDelegate?
  
  // MARK: Initializers
  
  init(ref: Firebase) {
    list = []
    self.ref = ref
  }
  
  // MARK: Syncing
  
  func sync() {
    initializeListeners()
  }
  
  func dispose() {
    stopSyncing()
    list.removeAll(keepCapacity: false)
  }
  
  func stopSyncing() {
    ref.removeAllObservers()
  }
  
  // MARK: Data updates
  
  func append(data: AnyObject!) {
    var pushIdref = ref.childByAutoId()
    pushIdref.setValue(data)
  }
  
  func removeAtIndex(index: Int) {
    var item = list[index]
    var itemRef = ref.childByAppendingPath(item.key)
    itemRef.removeValue()
  }
  
  func updateAtIndex(index: Int, data: [NSObject : AnyObject]!) {
    var item = list[index]
    var itemRef = ref.childByAppendingPath(item.key)
    itemRef.updateChildValues(data)
  }
  
  // MARK: Event Listeners
  
  private func initializeListeners() {
    addListenerWithPrevKey(FEventType.ChildAdded, method: serverAdd)
    addListenerWithPrevKey(FEventType.ChildMoved, method: serverMove)
    addListener(FEventType.ChildChanged, method: serverChange)
    addListener(FEventType.ChildRemoved, method: serverRemove)
  }
  
  private func addListener(event: FEventType, method: (FDataSnapshot!) -> Void) {
    ref.observeEventType(event, withBlock: method)
  }
  
  private func addListenerWithPrevKey(event: FEventType, method: (FDataSnapshot!, String?) -> Void) {
    ref.observeEventType(event, andPreviousSiblingKeyWithBlock: method)
  }
  
  private func serverAdd(snap: FDataSnapshot!, prevKey: String?) {
    var position = moveTo(snap.key, data: snap, prevKey: prevKey)
    delegate?.firebaseArray?(list, indexAdded: position, data: snap)
  }
  
  private func serverChange(snap: FDataSnapshot!) {
    var position = findKeyPosition(snap.key)
    if let position = position {
      list[position] = snap
      delegate?.firebaseArray?(list, indexChanged: position, data: snap)
    }
  }
  
  private func serverRemove(snap: FDataSnapshot!) {
    var position = findKeyPosition(snap.key)
    if let position = position {
      list.removeAtIndex(position)
      delegate?.firebaseArray?(list, indexRemoved: position, data: snap)
    }
  }
  
  private func serverMove(snap: FDataSnapshot!, prevKey: String?) {
    var key = snap.key
    var oldPosition = findKeyPosition(key)
    if let oldPosition = oldPosition {
      var data = list[oldPosition]
      list.removeAtIndex(oldPosition)
      var newPosition = moveTo(key, data: data, prevKey: prevKey)
      delegate?.firebaseArray?(list, oldIndex: oldPosition, newIndex: newPosition, data: snap)
    }
  }
  
  private func moveTo(key: String, data: FDataSnapshot, prevKey: String?) -> Int {
    var position = placeRecord(key, prevKey: prevKey)
    list.insert(data, atIndex: position)
    return position
  }
  
  private func placeRecord(key: String, prevKey: String?) -> Int {
    
    if let prevKey = prevKey {
      var i = findKeyPosition(prevKey)
      if let i = i {
        return i + 1
      } else {
        return list.count
      }
    } else {
      return 0
    }
    
  }
  
  private func findKeyPosition(key: String) -> Int? {
    for var i = 0; i < list.count; i++ {
      var item = list[i]
      if item.key == key {
        return i
      }
    }
    return nil
  }
  
}
