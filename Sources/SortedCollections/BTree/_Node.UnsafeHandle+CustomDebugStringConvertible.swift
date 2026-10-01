//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

#if UnstableSortedCollections

#if !$Embedded
// MARK: CustomDebugStringConvertible
extension _Node.UnsafeHandle: CustomDebugStringConvertible {
  #if DEBUG
  private enum PrintPosition { case start, end, middle }
  private func indentDescription(_ _node: _Node.UnsafeHandle, position: PrintPosition) -> String {
    let label = unsafe "(\(_node.elementCount)/\(_node.subtreeCount) \(_node.depth))"

    let spaces = String(repeating: " ", count: label.count)
    
    let lines = unsafe describeNode(_node).split(separator: "\n")
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
  private func describeNode(_ _node: _Node.UnsafeHandle) -> String {
    if unsafe _node.elementCount == 0 {
      var result = ""
      if !_node.isLeaf {
        unsafe _node[childAt: 0].read { handle in
          result += unsafe indentDescription(handle, position: .start) + "\n"
        }
        
        result += "┗━ << EMPTY >>"
      } else {
        result = "╺━ << EMPTY >>"
      }
      return result
    }
    
    var result = ""
    for slot in unsafe 0..<_node.elementCount {
      if !_node.isLeaf {
        let child = unsafe _node[childAt: slot]
        let childDescription = unsafe child.read {
          unsafe indentDescription($0, position: slot == 0 ? .start : .middle)
        }
        result += childDescription + "\n"
      }
      
      if _node.isLeaf {
        if unsafe _node.elementCount == 1 {
          result += "╺━ "
        } else if unsafe slot == _node.elementCount - 1 {
          result += "┗━ "
        } else if slot == 0 {
          result += "┏━ "
        } else {
          result += "┣━ "
        }
      } else {
        result += "┣━ "
      }
      
      if _Node.hasValues {
        debugPrint(unsafe _node[keyAt: slot], terminator: ": ", to: &result)
        debugPrint(unsafe _node[valueAt: slot], terminator: "", to: &result)
      } else {
        debugPrint(unsafe _node[keyAt: slot], terminator: "", to: &result)
      }
      
      if unsafe !_node.isLeaf && slot == _node.elementCount - 1 {
        let childDescription = unsafe _node[childAt: slot + 1].read {
          unsafe indentDescription($0, position: .end)
        }
        result += "\n" + childDescription
      }
      
      result += "\n"
    }
    return result
  }
  
  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    return unsafe indentDescription(self, position: .end)
  }
  #else
  /// A textual representation of this instance, suitable for debugging.
  public var debugDescription: String {
    var result = "Node<\(Key.self), \(Value.self)>(["
    var first = true
    for slot in 0..<self.elementCount {
      if first {
        first = false
      } else {
        result += ", "
      }
      if _Node.hasValues {
        result += "("
        debugPrint(self[keyAt: slot], terminator: ", ", to: &result)
        debugPrint(self[valueAt: slot], terminator: ")", to: &result)
      } else {
        debugPrint(self[keyAt: slot], terminator: "", to: &result)
      }
    }
    result += "], "
    if let children = self.children {
      debugPrint(Array(UnsafeBufferPointer(
        start: children,
        count: self.childCount
      )), terminator: ")", to: &result)
    } else {
      result += "[])"
    }
    return result
  }
  #endif // DEBUG
}
#endif

#endif
