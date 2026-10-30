
# Deque Examples

A `Deque` (double-ended queue) allows you to efficiently add and remove elements from both ends.

## Creating a Deque

```swift
// Importing the library
import SwiftCollections

// Creating a deque and adding elements
var deque = Deque<Int>()
deque.append(10)  // Add to the back
deque.append(20)
deque.prepend(5)  // Add to the front

// Accessing elements
print(deque.first)  // Output: Optional(5)
print(deque.last)   // Output: Optional(20)
```

## Removing Elements

```swift
// Removing elements from the deque
deque.popFirst()    // Removes 5
deque.popLast()     // Removes 20
```

## Iterating Over a Deque

```swift
// Iterating through the deque
deque.append(contentsOf: [1, 2, 3])
for element in deque {
    print(element)
}
```

These examples demonstrate basic usage of `Deque` in Swift.
