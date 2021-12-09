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

extension PersistentDictionary: CustomStringConvertible {
    public var description: String {
        guard count > 0 else {
            return "[:]"
        }

        var result = "["
        var first = true
        for (key, value) in self {
            if first {
                first = false
            } else {
                result += ", "
            }
            result += "\(key): \(value)"
        }
        result += "]"
        return result
    }
}
