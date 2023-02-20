//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

private func _addressString(for pointer: UnsafeRawPointer) -> String {
  let address = UInt(bitPattern: pointer)
  return "0x\(String(address, radix: 16))"
}

private func _addressString(for object: AnyObject) -> String {
  _addressString(for: Unmanaged.passUnretained(object).toOpaque())
}

private func _addressString<T: AnyObject>(for object: Unmanaged<T>) -> String {
  _addressString(for: object.toOpaque())
}

extension _Rope.UnmanagedLeaf: CustomStringConvertible {
  var description: String {
    _addressString(for: _ref.toOpaque())
  }
}

extension _Rope {
  var nodeCount: Int { _root?.nodeCount ?? 0 }
}

extension _Rope.Node {
  var nodeCount: Int {
    guard !isLeaf else { return 1 }
    return readInner { $0.children.reduce(into: 1) { $0 += $1.nodeCount } }
  }
}

extension _Rope {
  internal func dump(
    heightLimit: Int = .max,
    firstPrefix: String = "",
    restPrefix: String = ""
  ) {
    guard _root != nil else {
      print("<Empty>")
      return
    }
    root.dump(heightLimit: heightLimit, firstPrefix: firstPrefix, restPrefix: restPrefix)
  }
}

extension _Rope.Node: CustomStringConvertible {
  var description: String {
        """
        \(height > 0 ? "Inner@\(height)" : "Leaf")(\
        at: \(_addressString(for: object)), \
        summary: \(summary), \
        childCount: \(childCount)/\(Summary.maxNodeSize))
        """
  }
}

extension _Rope.Node {
  internal func dump(
    heightLimit: Int = .max,
    firstPrefix: String = "",
    restPrefix: String = ""
  ) {
    print("\(firstPrefix)\(description)")
    
    guard heightLimit > 0 else { return }
    
    if height > 0 {
      readInner {
        let c = $0.children
        for slot in 0 ..< c.count {
          c[slot].dump(
            heightLimit: heightLimit - 1,
            firstPrefix: "\(restPrefix)\(slot): ",
            restPrefix: "\(restPrefix)   ")
        }
      }
    } else {
      readLeaf {
        let c = $0.children
        for slot in 0 ..< c.count {
          print("\(restPrefix)\(slot): \(c[slot])")
        }
      }
    }
  }
}
