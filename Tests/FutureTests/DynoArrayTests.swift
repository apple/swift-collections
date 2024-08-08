import XCTest
import _CollectionsTestSupport
import Future

struct Counted: ~Copyable {
  var value: Int
  nonisolated(unsafe) static var instances: Int = 0

  init(_ value: Int) {
    self.value = value
    Counted.instances += 1
  }

  deinit {
    Counted.instances -= 1
    expectGreaterThanOrEqual(Counted.instances, 0)
  }
}

class DynoArrayTests: CollectionTestCase {

  func test_basics() {
    var array = DynoArray<Counted>()
    expectTrue(array.isEmpty)
    expectEqual(array.count, 0)
    expectEqual(array.capacity, 0)
    expectEqual(Counted.instances, 0)

    array.append(Counted(42))
    expectFalse(array.isEmpty)
    expectEqual(array.count, 1)
    expectEqual(array[0].value, 42)
    expectEqual(Counted.instances, 1)

    array.append(Counted(23))
    expectFalse(array.isEmpty)
    expectEqual(array.count, 2)
    expectEqual(array[0].value, 42)
    expectEqual(array[1].value, 23)
    expectEqual(Counted.instances, 2)

    let old = array.remove(at: 0)
    expectEqual(old.value, 42)
    expectFalse(array.isEmpty)
    expectEqual(array.count, 1)
    expectEqual(array[0].value, 23)
    expectEqual(Counted.instances, 2)
    _ = consume old
    expectEqual(Counted.instances, 1)

    let old2 = array.remove(at: 0)
    expectEqual(old2.value, 23)
    expectEqual(array.count, 0)
    expectTrue(array.isEmpty)
    expectEqual(Counted.instances, 1)
    _ = consume old2
    expectEqual(Counted.instances, 0)
  }

  func test_read_access() {
    let c = 100
    let array = DynoArray<Counted>(count: c) { Counted($0) }

    for i in 0 ..< c {
      expectEqual(array.borrowElement(at: i) { $0.value }, i)
      expectEqual(array[i].value, i)
    }
  }

  func test_update_access() {
    let c = 100
    var array = DynoArray<Counted>(count: c) { Counted($0) }

    for i in 0 ..< c {
      array.updateElement(at: i) { $0.value += 100 }
      array[i].value += 100
    }

    for i in 0 ..< c {
      expectEqual(array[i].value, 200 + i)
    }

    expectEqual(Counted.instances, c)
    _ = consume array
    expectEqual(Counted.instances, 0)
  }

  func test_append() {
    var array = DynoArray<Counted>()
    let c = 100
    for i in 0 ..< c {
      array.append(Counted(100 + i))
    }
    expectEqual(Counted.instances, c)
    expectEqual(array.count, c)

    for i in 0 ..< c {
      // FIXME: unexpected exclusivity violation (rdar://128441125)
      //expectEqual(array.borrowElement(at: i) { $0.value }, 100 + i)
      expectEqual(array[i].value, 100 + i)
    }

    _ = consume array
    expectEqual(Counted.instances, 0)
  }

  func test_insert() {
    var array = DynoArray<Counted>()
    let c = 100
    for i in 0 ..< c {
      array.insert(Counted(100 + i), at: 0)
    }
    expectEqual(Counted.instances, c)
    expectEqual(array.count, c)

    for i in 0 ..< c {
      // FIXME: unexpected exclusivity violation (rdar://128441125)
      //expectEqual(array.borrowElement(at: i) { $0.value }, c + 99 - i)
      expectEqual(array[i].value, c + 99 - i)
    }

    _ = consume array
    expectEqual(Counted.instances, 0)
  }

  func test_remove() {
    let c = 100
    var array = DynoArray<Counted>(count: c) { Counted(100 + $0) }
    expectEqual(Counted.instances, c)
    expectEqual(array.count, c)

    for i in 0 ..< c {
      array.remove(at: 0)
      expectEqual(array.count, c - 1 - i)
      expectEqual(Counted.instances, c - 1 - i)
    }

    expectTrue(array.isEmpty)
    expectEqual(Counted.instances, 0)
  }

  func test_iterate_full() {
    let c = 100
    let array = DynoArray<Counted>(count: c) { Counted(100 + $0) }

    var state = array.startBorrowingIteration()
    do {
      let span = state.nextChunk(maximumCount: Int.max)
      expectEqual(span.count, c)
      for i in 0 ..< span.count {
        expectEqual(span[i].value, 100 + i)
      }
    }
    do {
      let span2 = state.nextChunk(maximumCount: Int.max)
      expectEqual(span2.count, 0)
    }
  }

  func test_iterate_stepped() {
    let c = 100
    let array = DynoArray<Counted>(count: c) { Counted($0) }

    withEvery("stride", in: 1 ... c) { stride in
      var state = array.startBorrowingIteration()
      var i = 0
      while true {
        let span = state.nextChunk(maximumCount: stride)
        if span.count == 0 { break }
        expectEqual(span.count, i + stride <= c ? stride : c % stride)
        for j in 0 ..< span.count {
          expectEqual(span[j].value, i)
          i += 1
        }
      }
      expectEqual(i, c)
      expectEqual(state.nextChunk(maximumCount: Int.max).count, 0)
    }
  }
}
