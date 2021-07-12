# Heap

A partially-ordered tree of elements with performant insertion and removal operations.

## Declaration

```swift
public struct Heap<Element: Comparable>
```

## Overview

Array-backed [binary heaps](https://en.wikipedia.org/wiki/Heap_(data_structure)) provide performant lookups (`O(1)`) of the smallest or largest element (depending on whether it's a min-heap or a max-heap, respectively) as well as insertion and removal (`O(log n)`). Heaps are commonly used as the backing storage for a priority queue.

A variant on this, the [min-max heap](https://en.wikipedia.org/wiki/Min-max_heap), allows for performant lookups and removal of both the smallest **and** largest elements by interleaving min and max levels in the backing array. `Heap` is an implementation of a min-max heap.

### Initialization

There are a couple of options for initializing a `Heap`. To create an empty `Heap`, call `init()`:

```swift
var heap = Heap<Int>()
```

You can also create a `Heap` from an existing sequence in linear time:

```swift
var heap = Heap((1...).prefix(20))
```

Finally, a `Heap` can be created from an array literal:

```swift
var heap: Heap<Double> = [0.1, 0.6, 1.0, 0.15, 0.42]
```

### Insertion

#### Of a single element

To insert an element into a `Heap`, call `insert(_:)`:

```swift
var heap = Heap<Int>()
heap.insert(6)
heap.insert(2)
```

This works by adding the new element into the end of the backing array and then bubbling it up to where it belongs in the heap.

#### Of a sequence of elements

You can also insert a sequence of elements into a `Heap`:

```swift
var heap = Heap((0..<10))
heap.insert(contentsOf: (20...100).shuffled())
heap.insert(contentsOf: [-5, -6, -8, -12, -3])
```

### Lookup

As mentioned earlier, the smallest and largest elements can be queried in constant time:

```swift
var heap = Heap((1...20))
let min = heap.min()  // min = 1
let max = heap.max()  // max = 20
```

In a min-max heap, the smallest element is stored at index 0 in the backing array; the largest element is stored at either index 1 or index 2, the first max level in the heap (so to look up the largest, we compare the two and return the larger one).

We also expose a read-only view into the backing array, should somebody need that.

```swift
let heap = Heap((1...100).shuffled())
for val in heap.unordered {
   ...
}
```

> Note: The elements aren't _arbitrarily_ ordered (it is, after all, a heap). However, no guarantees are given as to the ordering of the elements or that this won't change in future versions of the library.

### Removal

Removal has logarithmic complexity, and removing both the smallest and largest elements is supported:

```swift
var heap = Heap((1...20).shuffled())
var heap2 = heap

while let min = heap.popMin() {
    print("Next smallest element:", min)
}

while let max = heap2.popMax() {
    print("Next largest element:", max)
}
```

To remove the smallest element, we remove and return the element at index 0. The element at the end of the backing array is put in its place at index 0, and then we trickle it down to where it belongs in the heap. To remove the largest element, we do the same except the index is whatever the index of the largest element is (see above) instead of 0.

We also have non-optional flavors that assume the heap isn't empty, `removeMin()` and `removeMax()`.

### Iteration

`Heap` itself doesn't conform to `Sequence` because of the potential confusion around which direction it should iterate (largest-to-smallest? smallest-to-largest?). Instead, we expose two iterators that conform to `Sequence`:

```swift
for val in heap.ascending {
    ...
}

for val in heap.descending {
    ...
}
```

### Performance

## Implementation Details

The implementation is based off [Atkinson et al. Min-Max Heaps and Generalized Priority Queues (1986)](http://akira.ruc.dk/~keld/teaching/algoritmedesign_f03/Artikler/02/Atkinson86.pdf).

In a min-max heap, each node at an even level in the tree is less than all its descendants, while each node at an odd level in the tree is greater than all of its descendants.

["A min-max heap is a complete binary tree data structure."](https://en.wikipedia.org/wiki/Min-max_heap) This means that all the levels in the tree are filled except the last and that they are filled from left to right. The tree can be stored in an array:

```
// Min-max heap:
level 0:                 8
level 1:         71              41
level 2:     31      10      11      16
level 3:   46  51  31  21  13

// Array representation:
[8, 71, 41, 31, 10, 11, 16, 46, 51, 31, 21, 13]
```

**Heap property**: Each element in an even level in the tree is less than all its descendants; each element in an odd level in the tree is greater than all its descendants. _Mutations to the heap **must** maintain this heap property._

The levels start at 0 (even), so the smallest element in the tree is at the root. In the example above, the root of the tree is 8, which is the smallest element. The next level in the tree (containing 71 and 41) is a max level, so those elements are greater than all their respective descendants. Because this is the first max level in the tree, the largest element in the tree is one of the two elements (71).

Note that the comparisons only take into account descendants — it is possible, for example, for elements at a lower level to be larger than elements in a different branch that are higher up the tree. In the example above, 41 isn't the second-largest element in the tree, but _it is_ the largest element in the right branch of the root node.

---

M.D. Atkinson, J.-R. Sack, N. Santoro, T. Strothotte. October 1986. Min-Max Heaps and Generalized Priority Queues. Communications of the ACM. 29(10):996-1000.
