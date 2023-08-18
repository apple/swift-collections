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

protocol NodePrettyPrinter {
  func print<Value>(value: Value.Type) -> String
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String
}

extension NodePrettyPrinter {
  func print<Value>(value: Value.Type) -> String {
    return "○ " + prettyPrint(depth: 0, value: value)
  }
}

func indent(_ width: Int, last: Bool) -> String {
  let end = last ? "└──○ " : "├──○ "
  if width > 0 {
    // let rep = "" + String(repeating: " ", count: Const.indentWidth - 1)
    return String(repeating: "│  ", count: width) + end
  } else {
    return end
  }
}

extension ARTree: CustomStringConvertible {
  public var description: String {
    if let node = root {
      return "○ " + node.toManagedNode().prettyPrint(depth: 0, value: Value.self)
    } else {
      return "<>"
    }
  }
}

extension RawNode: NodePrettyPrinter {
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String {
    return toManagedNode().prettyPrint(depth: depth, value: Value.self)
  }
}

extension InternalNode {
  fileprivate var partial: [UInt8] {
    var arr = [UInt8](repeating: 0, count: partialLength)
    let bytes = partialBytes
    for idx in 0..<partialLength {
      arr[idx] = bytes[idx]
    }
    return arr
  }
}

extension NodeLeaf: NodePrettyPrinter {
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String {
    let val: Value = self.value()
    return "\(self.keyLength)\(self.key) -> \(val)"
  }
}

extension Node4: NodePrettyPrinter {
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String {
    var output = "Node4 {childs=\(count), partial=\(partial)}\n"
    withBody { keys, childs in
      for idx in 0..<count {
        let key = keys[idx]
        let last = idx == count - 1
        output += indent(depth, last: last)
        output += String(key) + ": "
        output += child(forKey: key)!.prettyPrint(
          depth: depth + 1,
          value: value)
        if !last {
          output += "\n"
        }
      }
    }

    return output
  }
}

extension Node16: NodePrettyPrinter {
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String {
    var output = "Node16 {childs=\(count), partial=\(partial)}\n"
    withBody { keys, childs in
      for idx in 0..<count {
        let key = keys[idx]
        let last = idx == count - 1
        output += indent(depth, last: last)
        output += String(key) + ": "
        output += child(forKey: key)!.prettyPrint(
          depth: depth + 1,
          value: value)
        if !last {
          output += "\n"
        }
      }
    }

    return output
  }
}

extension Node48: NodePrettyPrinter {
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String {
    var output = "Node48 {childs=\(count), partial=\(partial)}\n"
    var total = 0
    withBody { keys, childs in
      for (key, slot) in keys.enumerated() {
        if slot >= 0xFF {
          continue
        }

        total += 1
        let last = total == count
        output += indent(depth, last: last)
        output += String(key) + ": "
        output += child(at: Int(slot))!.prettyPrint(
          depth: depth + 1,
          value: value)
        if !last {
          output += "\n"
        }
      }
    }

    return output
  }
}

extension Node256: NodePrettyPrinter {
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String {
    var output = "Node256 {childs=\(count), partial=\(partial)}\n"
    var total = 0
    withBody { childs in
      for (key, child) in childs.enumerated() {
        if child == nil {
          continue
        }

        total += 1
        let last = total == count
        output += indent(depth, last: last)
        output += String(key) + ": "
        output += child!.prettyPrint(
          depth: depth + 1,
          value: value)
        if !last {
          output += "\n"
        }
      }
    }
    return output
  }
}
