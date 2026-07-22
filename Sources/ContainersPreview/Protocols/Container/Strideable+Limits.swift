//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

extension Strideable {
  @_alwaysEmitIntoClient
  package func _clampedUp(
    towards boundary: Self, maxDistance: Stride, limitedBy limit: Self
  ) -> Self {
    assert(self <= boundary)
    assert(maxDistance >= 0)
    let limit = (limit >= self ? Swift.min(limit, boundary) : boundary)
    if limit.distance(to: self) <= maxDistance {
      return limit
    }
    return self.advanced(by: maxDistance)
  }

  @_alwaysEmitIntoClient
  package func _clampedDown(
    towards boundary: Self, maxDistance: Stride, limitedBy limit: Self
  ) -> Self {
    assert(self >= boundary)
    assert(maxDistance >= 0)
    let limit = (limit <= self ? Swift.max(limit, boundary) : boundary)
    if self.distance(to: limit) <= maxDistance {
      return limit
    }
    return self.advanced(by: -maxDistance)
  }
}

extension Strideable {
  @inlinable
  package mutating func _advance(
    by distance: inout Stride, limitedBy limit: Self
  ) {
    if distance >= 0 {
      guard limit >= self else {
        self = self.advanced(by: distance)
        distance = 0
        return
      }
      let d = Swift.min(distance, self.distance(to: limit))
      self = self.advanced(by: d)
      distance -= d
    } else {
      guard limit <= self else {
        self = self.advanced(by: distance)
        distance = 0
        return
      }
      let d = Swift.max(distance, self.distance(to: limit))
      self = self.advanced(by: d)
      distance -= d
    }
  }

#if UnstableContainersPreview
  @inlinable
  public mutating func advance(
    by distance: inout Stride, limitedBy limit: Self
  ) {
    _advance(by: &distance, limitedBy: limit)
  }
#endif
}
