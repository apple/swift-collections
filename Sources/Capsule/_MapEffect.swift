//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct MapEffect {
    var modified: Bool = false
    var replacedValue: Bool = false

    mutating func setModified() {
        self.modified = true
    }

    mutating func setReplacedValue() {
        self.modified = true
        self.replacedValue = true
    }
}
