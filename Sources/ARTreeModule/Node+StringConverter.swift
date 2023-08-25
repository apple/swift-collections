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

#if !COLLECTIONS_SINGLE_MODULE
  import _CollectionsUtilities
#endif

protocol NodePrettyPrinter {
  func print() -> String
  func prettyPrint(depth: Int) -> String
}

extension NodePrettyPrinter {
  func print() -> String {
    return "○ " + prettyPrint(depth: 0)
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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension ARTreeImpl: CustomStringConvertible {
  public var description: String {
    if let node = _root {
      return "○ " + node.prettyPrint(depth: 0, with: Spec.self)
    } else {
      return "<>"
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension ArtNode {
  public var description: String {
    return "○ " + prettyPrint(depth: 0)
  }

  func prettyPrint(depth: Int) -> String {
    switch self.type {
    case .leaf:
      return (self as! NodeLeaf<Spec>).prettyPrint(depth: depth)
    case .node4:
      return (self as! Node4<Spec>).prettyPrint(depth: depth)
    case .node16:
      return (self as! Node16<Spec>).prettyPrint(depth: depth)
    case .node48:
      return (self as! Node48<Spec>).prettyPrint(depth: depth)
    case .node256:
      return (self as! Node256<Spec>).prettyPrint(depth: depth)
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension RawNode {
  func print<Spec: ARTreeSpec>(with: Spec.Type) -> String {
    return "○ " + prettyPrint(depth: 0, with: Spec.self)
  }

  func prettyPrint<Spec: ARTreeSpec>(depth: Int, with: Spec.Type) -> String {
    let n: any ArtNode<Spec> = toArtNode()
    return n.prettyPrint(depth: depth)
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension NodeStorage {
  func print() -> String {
    return node.description
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
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

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension NodeLeaf: NodePrettyPrinter {
  func prettyPrint(depth: Int) -> String {
    let addr = Const.testPrintAddr ? "\(_addressString(for: self.rawNode.buf))" : ""
    return "\(addr)\(self.keyLength)\(self.key) -> \(self.value)"
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension Node4: NodePrettyPrinter {
  func prettyPrint(depth: Int) -> String {
    let addr = Const.testPrintAddr ? " \(_addressString(for: self.rawNode.buf))" : " "
    var output = "Node4\(addr){childs=\(count), partial=\(partial)}\n"

    for idx in 0..<count {
      let key = keys[idx]
      let last = idx == count - 1
      output += indent(depth, last: last)
      output += String(key) + ": "
      output += child(at: idx)!.prettyPrint(depth: depth + 1, with: Spec.self)
      if !last {
        output += "\n"
      }
    }

    return output
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension Node16: NodePrettyPrinter {
  func prettyPrint(depth: Int) -> String {
    let addr = Const.testPrintAddr ? " \(_addressString(for: self.rawNode.buf))" : " "
    var output = "Node16\(addr){childs=\(count), partial=\(partial)}\n"

    for idx in 0..<count {
      let key = keys[idx]
      let last = idx == count - 1
      output += indent(depth, last: last)
      output += String(key) + ": "
      output += child(at: idx)!.prettyPrint(depth: depth + 1, with: Spec.self)
      if !last {
        output += "\n"
      }
    }

    return output
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension Node48: NodePrettyPrinter {
  func prettyPrint(depth: Int) -> String {
    let addr = Const.testPrintAddr ? " \(_addressString(for: self.rawNode.buf))" : " "
    var output = "Node48\(addr){childs=\(count), partial=\(partial)}\n"
    var total = 0

    for (key, slot) in keys.enumerated() {
      if slot >= 0xFF {
        continue
      }

      total += 1
      let last = total == count
      output += indent(depth, last: last)
      output += String(key) + ": "
      output += child(at: Int(slot))!.prettyPrint(depth: depth + 1, with: Spec.self)
      if !last {
        output += "\n"
      }
    }

    return output
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension Node256: NodePrettyPrinter {
  func prettyPrint(depth: Int) -> String {
    let addr = Const.testPrintAddr ? " \(_addressString(for: self.rawNode.buf))" : " "
    var output = "Node256\(addr){childs=\(count), partial=\(partial)}\n"
    var total = 0

    for (key, child) in childs.enumerated() {
      if child == nil {
        continue
      }

      total += 1
      let last = total == count
      output += indent(depth, last: last)
      output += String(key) + ": "
      output += child!.prettyPrint(depth: depth + 1, with: Spec.self)
      if !last {
        output += "\n"
      }
    }

    return output
  }
}
