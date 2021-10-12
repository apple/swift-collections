# PriorityQueue

A double-ended queue where elements are arranged by their priority.

## Declaration

```swift
import PriorityQueueModule

public struct PriorityQueue<Value, Priority: Comparable>
```

## Overview

[Priority queues](https://en.wikipedia.org/wiki/Priority_queue) are useful data structures that can be leveraged across a variety of applications (sorting algorithms, graph algorithms, network clients, task managers, etc).

This implementation is built on top of the [`Heap`](Documentation/Heap.md), which provides performant lookups (`O(1)`) of the lowest- and highest-priority elements as well as insertion and removal (`O(log n)`). The main difference between `Heap` and `PriorityQueue` is that the latter separates the value from the comparable priority of it. This is useful in cases where a type doesn't conform to `Comparable` directly but it may have a property that does — e.g. `Task.priority`. `PriorityQueue` also keeps track of insertion order, so dequeueing of elements with the same priority happens in FIFO order.

## Implementation Details

We define a small `_Element` struct to hold the `Value`, `Priority`, and insertion order of an element. This is the type that is stored in the underlying `Heap`.

```swift
public struct PriorityQueue<Value, Priority: Comparable> {
  public struct _Element: Comparable {
    let value: Value
    let priority: Priority
    let insertionCounter: UInt64

    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.priority == rhs.priority
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
      if lhs.priority < rhs.priority {
        return true
      } else if lhs.priority == rhs.priority {
        return lhs.insertionCounter < rhs.insertionCounter
      } else {
        return false
      }
    }
  }

  ...
  internal var _base: Heap<_Element>
  ...
```

All of the querying and removal functions wrap those on `Heap` and simply return the `Value` in the `_Element`.

### Insertion

Insertion is a little different, as the priority of the element to insert also needs to be passed in:

```swift
public mutating func insert(_ value: Value, priority: Priority)
```

In cases where the priority already exists on the `Value` inserted (e.g. `Task.priority`) we incur a small space penalty (as the priority would be stored in both places). Storing the priority separately does help prevent mutations that would otherwise invalidate the heap property of the storage in cases where the `Value` being stored is a reference type:

```swift
class Task {
  var priority: Int
  var work: () -> Void
}

let task = Task(priority: 10, work: { ... })
queue.insert(task, priority: task.priority)

task.priority = 100  // This is fine, as changing it doesn't matter to the PriorityQueue
```

We keep track of the number of insertions that have happened in the `PriorityQueue` and increment it whenever `insert(_:priority:)` is called. This allows us to dequeue elements in FIFO order.
