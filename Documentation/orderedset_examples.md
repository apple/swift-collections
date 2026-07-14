
# OrderedSet Examples

An `OrderedSet` maintains the order of elements while ensuring each element is unique.

## Creating an OrderedSet

```swift
// Importing the library
import SwiftCollections

// Creating an OrderedSet and adding elements
var orderedSet: OrderedSet<String> = ["apple", "banana", "cherry"]
orderedSet.insert("date", at: 1)
print(orderedSet)  // Output: ["apple", "date", "banana", "cherry"]
```

## Accessing Elements

```swift
// Accessing elements by index
let firstElement = orderedSet[0]
print(firstElement)  // Output: "apple"
```

## Checking for Existence

```swift
// Checking if an element exists
print(orderedSet.contains("banana"))  // Output: true
print(orderedSet.contains("grape"))   // Output: false
```

## Removing Elements

```swift
// Removing elements
orderedSet.remove("banana")
print(orderedSet)  // Output: ["apple", "date", "cherry"]
```

These examples illustrate how to use `OrderedSet` effectively in Swift.
