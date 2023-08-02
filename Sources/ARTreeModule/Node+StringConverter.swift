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
    if let node = root?.asNode(of: Value.self) {
      return "○ " + node.prettyPrint(depth: 0, value: Value.self)
    } else {
      return "<>"
    }
  }
}

extension Node {
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
    "\(self.keyLength)\(self.key) -> \(self.value)"
  }
}

extension Node4: NodePrettyPrinter {
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String {
    var output = "Node4 {childs=\(count), partial=\(partial)}\n"
    for idx in 0..<count {
      let key = keys[idx]
      let last = idx == count - 1
      output += indent(depth, last: last)
      output += String(key) + ": "
      output += child(forKey: key)!.asNode(of: Value.self)!.prettyPrint(
        depth: depth + 1,
        value: value)
      if !last {
        output += "\n"
      }
    }

    return output
  }
}

extension Node16: NodePrettyPrinter {
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String {
    var output = "Node16 {childs=\(count), partial=\(partial)}\n"
    for idx in 0..<count {
      let key = keys[idx]
      let last = idx == count - 1
      output += indent(depth, last: last)
      output += String(key) + ": "
      output += child(forKey: key)!.asNode(of: Value.self)!.prettyPrint(
        depth: depth + 1,
        value: value)
      if !last {
        output += "\n"
      }
    }

    return output
  }
}

extension Node48: NodePrettyPrinter {
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String {
    var output = "Node48 {childs=\(count), partial=\(partial)}\n"
    var total = 0
    for (key, slot) in keys.enumerated() {
      if slot >= 0xFF {
        continue
      }

      total += 1
      let last = total == count
      output += indent(depth, last: last)
      output += String(key) + ": "
      output += child(at: Int(slot))!.asNode(of: Value.self)!.prettyPrint(
        depth: depth + 1,
        value: value)
      if !last {
        output += "\n"
      }
    }

    return output
  }
}

extension Node256: NodePrettyPrinter {
  func prettyPrint<Value>(depth: Int, value: Value.Type) -> String {
    var output = "Node256 {childs=\(count), partial=\(partial)}\n"
    var total = 0
    for (key, child) in childs.enumerated() {
      if child == nil {
        continue
      }

      total += 1
      let last = total == count
      output += indent(depth, last: last)
      output += String(key) + ": "
      output += child!.asNode(of: Value.self)!.prettyPrint(
        depth: depth + 1,
        value: value)
      if !last {
        output += "\n"
      }
    }
    return output
  }
}
