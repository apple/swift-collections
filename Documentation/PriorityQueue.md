# Priority Queue
A sequence implementing a binary heap based priority queue.

## Declaration
```
import PriorityQueue
public struct PriorityQueue<Element>
```

## Overview
`PriorityQueue` is a queue that orders its elements according to their natural ordering, while maintaining efficient enqueue and dequeue operations. During construction `PriorityQueue` must be passed a `HeapType` which indicates whether larger or smaller elements have a higher priority. 

```
var numbers = PriorityQueue<Int>(HeapType.min)
```

`PriorityQueue`s do not conform to the Collections protocol, and thus are unable to be accessed and mutated like their counterparts. Because of this, functions such as `enqueue(value:)`, `dequeue()` , and `peek()` are used to insert, remove, and read elements respectively. 

```
numbers.enqueue(value: 5)
numbers.enqueue(value: -3)
numbers.enqueue(value: 13)
print(numbers.peek()) // prints -1
print(numbers.dequeue()) //prints -1
print(numbers.peek()) //prints 5
```

`PriorityQueue`s, however, conform to the Sequence protocol, which provides a familiar method of traversing through them.

```
var sum:Int
for value in numbers {
	sum += value
}
print(sum) //prints 15
```

`PriorityQueue`s are passed around by value with copy-on-write optimization, so more memory is not allocated until it’s absolutely necessary.

## Efficiency
Due to the `PriorityQueue`’s underlying storage being represented as a binary heap, both its `enqueue(value:)` and `dequeue()` functions have O(log(n)) time-complexity. This superb performance, however, does not allow `PriorityQueue` to conform to the Collections protocol because of its inability to index its elements. While this tradeoff may seem unacceptable, most of the use cases that use the `PriorityQueue` module will never require random access of its elements, as that would defeat the purpose of maintaining priority within the elements.  But even in the _rare_ circumstances where access to an element in the middle of the priority queue is necessary, a series of `dequeue()`s and `enqueue(value:)`s can circumvent this issue.  

## Usage
The `PriorityQueue` module should be used in scenarios where elements must maintain a certain order when removed, regardless of the order they were added. While the same effect of the `PriorityQueue` module can be accomplished using an Array and its `sort()` function, it is considerably more inefficient, as it requires O(n*log(n)) for its time complexity. 
