//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if false // SortedCollections is not a thing yet
import CollectionsBenchmark
import SortedCollections

extension Benchmark {
  public mutating func addSortedDictionaryBenchmarks() {
    self.add(
      title: "SortedDictionary<Int, Int> init(keysWithValues:)",
      input: [Int].self
    ) { input in
      let keysAndValues = input.map { (key: $0, value: 2 * $0) }

      return { timer in
        blackHole(SortedDictionary(keysWithValues: keysAndValues))
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> init(sortedKeysWithValues:)",
      input: Int.self
    ) { input in
      let keysAndValues = (0..<input).lazy.map { (key: $0, value: 2 * $0) }

      return { timer in
        blackHole(SortedDictionary(sortedKeysWithValues: keysAndValues))
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> sort, then init(sortedKeysWithValues:)",
      input: [Int].self
    ) { input in
      return { timer in
        var keysAndValues = input.map { (key: $0, value: 2 * $0) }

        timer.measure {
          keysAndValues.sort(by: { $0.key < $1.key })
          blackHole(SortedDictionary(sortedKeysWithValues: keysAndValues))
        }
      }
    }

    self.add(
      title: "SortedDictionary<Int, Int> sequential iteration",
      input: [Int].self
    ) { input in
      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
      let d = SortedDictionary(keysWithValues: keysAndValues)
      
      return { timer in
        for item in d {
          blackHole(item)
        }
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> index-based iteration",
      input: [Int].self
    ) { input in
      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
      let d = SortedDictionary(keysWithValues: keysAndValues)
      
      return { timer in
        var i = d.startIndex
        while i != d.endIndex {
          blackHole(d[i])
          d.formIndex(after: &i)
        }
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> offset-based iteration",
      input: [Int].self
    ) { input in
      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
      let d = SortedDictionary(keysWithValues: keysAndValues)
      
      return { timer in
        for offset in 0..<keysAndValues.count {
          var i = d.endIndex
          d.formIndex(&i, offsetBy: offset - d.count)
          blackHole(d[i])
        }
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> forEach iteration",
      input: [Int].self
    ) { input in
      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
      let d = SortedDictionary(keysWithValues: keysAndValues)
      
      return { timer in
        d.forEach({ blackHole($0) })
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int>.Keys sequential iteration",
      input: [Int].self
    ) { input in
      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
      let d = SortedDictionary(keysWithValues: keysAndValues)
      
      return { timer in
        for item in d.keys {
          blackHole(item)
        }
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int>.Values sequential iteration",
      input: [Int].self
    ) { input in
      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
      let d = SortedDictionary(keysWithValues: keysAndValues)
      
      return { timer in
        for item in d.values {
          blackHole(item)
        }
      }
    }

    self.add(
      title: "SortedDictionary<Int, Int> subscript, successful lookups",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let sortedDictionary = SortedDictionary(
        keysWithValues: input.map { ($0, 2 * $0) })

      return { timer in
        for key in lookups {
          precondition(sortedDictionary[key] == key * 2)
        }
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> subscript, unsuccessful lookups",
      input: ([Int], [Int]).self
    ) { input, lookups in
      let sortedDictionary = SortedDictionary(
        keysWithValues: input.map { ($0, 2 * $0) })
      
      let c = input.count
      return { timer in
        for key in lookups {
          precondition(sortedDictionary[key + c] == nil)
        }
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> subscript, setter append",
      input: [Int].self
    ) { input in
      let keysAndValues = input.lazy.map { (key: $0, value: 2 * $0) }
      var sortedDictionary = SortedDictionary<Int, Int>()

      return { timer in
        for (key, value) in keysAndValues {
          sortedDictionary[key] = value
        }
        blackHole(sortedDictionary)
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> subscript, setter noop",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        var d = SortedDictionary(
          keysWithValues: input.map { ($0, 2 * $0) })
        
        let c = input.count
        timer.measure {
          for i in lookups {
            d[i + c] = nil
          }
        }
        precondition(d.count == input.count)
        blackHole(d)
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> subscript, setter update",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        var d = SortedDictionary(
          keysWithValues: input.map { ($0, 2 * $0) })
        
        timer.measure {
          for i in lookups {
            d[i] = 0
          }
        }
        precondition(d.count == input.count)
        blackHole(d)
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> subscript, setter remove",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        var d = SortedDictionary(
          keysWithValues: input.map { ($0, 2 * $0) })
        
        timer.measure {
          for i in lookups {
            d[i] = nil
          }
        }
        precondition(d.count == 0)
        blackHole(d)
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> subscript, _modify insert",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        var d = SortedDictionary<Int, Int>()
        
        @inline(__always)
        func modify(_ i: inout Int?, to value: Int?) {
          i = value
        }
        
        timer.measure {
          for i in lookups {
            modify(&d[i], to: i * 2)
          }
        }
        
        precondition(d.count == input.count)
        blackHole(d)
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> subscript, _modify update",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        var d = SortedDictionary(
          keysWithValues: input.map { ($0, 2 * $0) })
        
        timer.measure {
          for i in lookups {
            d[i]! *= 2
          }
        }
        precondition(d.count == input.count)
        blackHole(d)
      }
    }
    
    self.add(
      title: "SortedDictionary<Int, Int> subscript, _modify remove",
      input: ([Int], [Int]).self
    ) { input, lookups in
      return { timer in
        var d = SortedDictionary(
          keysWithValues: input.map { ($0, 2 * $0) })
        
        @inline(__always)
        func modify(_ i: inout Int?, to value: Int?) {
          i = value
        }
        
        timer.measure {
          for i in lookups {
            modify(&d[i], to: nil)
          }
        }
        
        precondition(d.count == 0)
        blackHole(d)
      }
    }
  }
}
#endif
