# ``BasicContainers``

## Overview

This module provides previews of ownership-aware reimplementations of basic data structures that have been shipping in the Swift Standard Library.

This currently consists of two noncopyable variants of the standard `Array` type: ``UniqueArray`` and ``RigidArray``. Both of these allow noncopyable elements, and they store them in heap-allocated storage buffers.

Unlike `Array`, these new types do not support copy-on-write value semantics -- indeed, they aren't (implicitly) copyable at all, even if their element type happens to be copyable.

### struct UniqueArray

``UniqueArray`` is a dynamically self-resizing array type that automatically grows its storage as needed to accommodate inserted items. Its name highlights that unlike `Array`, instances of this type are always uniquely owned, never shared. Mutations of a `UniqueArray` therefore never need to copy their storage. 

Not having to ever copy their contents means that `UniqueArray` can be used to hold noncopyable elements, unlike the classic `Array`.

`Array`'s value semantics with the copy-on-write optimization is a powerful feature: it adds a great deal of flexibility and expressibility that tends to make it easy and comfortable to use. However, it also makes it relatively easy to accidentally write code where a series of small mutations of the "same" array all end up performing a full copy of the underlying storage -- a relatively common performance issue:

```swift
    var items = Array(100 ..< 200)
    for i in items.indices {
        let old = items
        items[i] *= 2 // 🐌
        precondition(old[i] != items[i])
    }
```

Note how preserving a copy of the array at the start of the loop forces the subscript mutation to end up copying the entire array on every iteration. Nothing distinguishes this really expensive mutation from a more typical subscript access with constant complexity -- it looks exactly the same. ``UniqueArray`` eliminates this entire class of issues by not letting you create a shared reference at all:

```swift
    var items = UniqueArray(copying: 100 ..< 200)
//      `- error: 'items' used after consume
    for i in items.indices {
        let old = items
//                `- note: consumed here
        items[i] *= 2
//      `- note: used here
        precondition(old[i] != items[i])
    }
```

Taking away the freedom to make implicit copies forces you to think a lot more about ownership concerns when using this type -- it can feel a lot more constrained and nitpicky. In exchange though, it gets much easier to reason about the runtime performance of your code; the subscript mutation looks the same as before, but now it is guaranteed to _always_ have constant complexity.

### struct RigidArray

``RigidArray`` goes a step even further than ``UniqueArray`` by also disabling automatic storage reallocations: it is a fixed-capacity array type. Rigid array instances get created with a specific capacity, and they never resize themselves. If they run out of room, they report a runtime error!

```swift
    var items = RigidArray(capacity: 5, copying: 1 ..< 4) // 1, 2, 3
    items.append(4) // OK
    items.append(5) // OK
    items.append(6) // runtime error: RigidArray capacity overflow
```

The name is apt -- that's quite inflexible behavior indeed. But sometimes this sort of inflexibility is exactly what we need! For instance, it makes it easy to ensure that the code we write will never use more memory than what we budgeted for it.

It also avoids wildly varying performance: in dynamically sized array types, `append` invocations usually have constant complexity, but once in a while they randomly spike to linear cost to resize the underlying storage. Of course, the use of a geometric growth strategy still allows the average complexity of an append operation to remain constant; but if a task must _always_ complete within a strict deadline, then statistical averages may not be good enough. Some engineers with a low-level mindset may choose to work within the constaints of carefully precalculated static capacities, and may prefer to consider it a hard fault if it is ever exceeded.  

Unlike ``InlineArray``, the capacity of a ``RigidArray`` is not part of its type declaration (nor its count) -- it is still a dynamic value. 

This allows ``RigidArray`` to still provide _explicit_ resizing operations: it has a `reallocate(capacity:)` method that can be used to arbitrarily resize its storage, as well as the familiar ``reserveCapacity(_:)`` operation. This enables building dynamic array types on top of ``RigidArray``; indeed, `UniqueArray` is a relatively simple wrapper around rigid array instance, forwarding operations to it when possible.

## Topics

### Types

- ``UniqueArray``
- ``RigidArray``
