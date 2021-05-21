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

// MARK: CustomDebugStringConvertible
extension _Node.UnsafeHandle: CustomDebugStringConvertible {
  #if DEBUG
  private enum PrintPosition { case start, end, middle }
  private func indentDescription(_ node: _Node<Key, Value>.UnsafeHandle, position: PrintPosition) -> String {
    let label = "(\(node.numTotalElements))"
    
    let spaces = String(repeating: " ", count: label.count)
    
    let lines = describeNode(node).split(separator: "\n")
    return lines.enumerated().map({ index, line in
      var lineToInsert = line
      let middle = (lines.count - 1) / 2
      if index < middle {
        if position == .start {
          return "   " + spaces + lineToInsert
        } else {
          return "┃  " + spaces + lineToInsert
        }
      } else if index > middle {
        if position == .end {
          return "   " + spaces + lineToInsert
        } else {
          return "┃  " + spaces + lineToInsert
        }
      } else {
        switch line[line.startIndex] {
        case "╺": lineToInsert.replaceSubrange(...line.startIndex, with: "━")
        case "┗": lineToInsert.replaceSubrange(...line.startIndex, with: "┻")
        case "┏": lineToInsert.replaceSubrange(...line.startIndex, with: "┳")
        case "┣": lineToInsert.replaceSubrange(...line.startIndex, with: "╋")
        default: break
        }
        
        switch position {
        case .start: return "┏━\(label)━" + lineToInsert
        case .middle: return "┣━\(label)━" + lineToInsert
        case .end: return "┗━\(label)━" + lineToInsert
        }
      }
    }).joined(separator: "\n")
  }
  
  /// A textual representation of this instance, suitable for debugging.
  private func describeNode(_ node: _Node<Key, Value>.UnsafeHandle) -> String {
    var result = ""
    for slot in 0..<node.numElements {
      if !node.isLeaf {
        let child = node[childAt: slot]
        let childDescription = child.read {
          indentDescription($0, position: slot == 0 ? .start : .middle)
        }
        result += childDescription + "\n"
      }
      
      if node.isLeaf {
        if node.numElements == 1 {
          result += "╺━ "
        } else if slot == node.numElements - 1 {
          result += "┗━ "
        } else if slot == 0 {
          result += "┏━ "
        } else {
          result += "┣━ "
        }
      } else {
        result += "┣━ "
      }
      
      debugPrint(node[keyAt: slot], terminator: ": ", to: &result)
      debugPrint(node[valueAt: slot], terminator: "", to: &result)
      
      if !node.isLeaf && slot == node.numElements - 1 {
        let childDescription = node[childAt: slot + 1].read {
          indentDescription($0, position: .end)
        }
        result += "\n" + childDescription
      }
      
      result += "\n"
    }
    return result
  }
  
  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    return indentDescription(self, position: .end)
  }
  #else
  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    var result = "Node<\(Key.self), \(Value.self)>(["
    var first = true
    for slot in 0..<self.numElements {
      if first {
        first = false
      } else {
        result += ", "
      }
      result += "("
      debugPrint(self[keyAt: slot], terminator: ", ", to: &result)
      debugPrint(self[valueAt: slot], terminator: ")", to: &result)
    }
    result += "], "
    if let children = self.children {
      debugPrint(Array(UnsafeBufferPointer(start: children, count: self.numChildren)), terminator: ")", to: &result)
    } else {
      result += "[])"
    }
    return result
  }
  #endif // DEBUG
}
