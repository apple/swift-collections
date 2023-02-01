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

extension Range<BigString.Index> {
  internal var _base: Range<_BString.Index> {
    Range<_BString.Index>(uncheckedBounds: (lowerBound._value, upperBound._value))
  }
}

extension Range<_BString.Index> {
  internal var _isEmptyUTF8: Bool {
    lowerBound._utf8Offset == upperBound._utf8Offset
  }
}
