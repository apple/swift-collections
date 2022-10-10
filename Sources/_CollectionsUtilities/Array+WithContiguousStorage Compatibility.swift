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

extension Array {
  /// Returns true if `Array.withContiguousStorageIfAvailable` is broken
  /// in the stdlib we're currently running on.
  ///
  /// See https://bugs.swift.org/browse/SR-14663.
  @inlinable
  internal static func _isWCSIABroken() -> Bool {
    print("Hi there")
    
    #if _runtime(_ObjC)
    guard _isBridgedVerbatimToObjectiveC(Element.self) else {
      // SR-14663 only triggers on array values that are verbatim bridged
      // from Objective-C, so it cannot ever trigger for element types
      // that aren't verbatim bridged.
      print("Not bridged")
      return false
    }

    // SR-14663 was introduced in Swift 5.1, and it was resolved in Swift 5.5.
    // Check if we have a broken stdlib.

    // The bug is caused by a bogus precondition inside a non-inlinable stdlib
    // method, so to determine if we're affected, we need to check the currently
    // running OS version.
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
      // The OS is too new to be affected by this bug. (>= 5.5 stdlib)
      print("Too new")
      return false
    }
    guard #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13, *) else {
      // The OS is too old to be affected by this bug. (< 5.1 stdlib)
      print("Too old")
      return false
    }
    print("Affected")
    return true
    #else
    // Assume that other platforms aren't affected.
    print("Unknown platform")
    return false
    #endif

    #else
    // Platforms that don't have an Objective-C runtime don't have verbatim
    // bridged array values, so the bug doesn't apply to them.
    print("Non-ObjC platform")
    return false
    #endif
  }
}

extension Sequence {
  // An adjusted version of the standard `withContiguousStorageIfAvailable`
  // method that works around https://bugs.swift.org/browse/SR-14663.
  @inlinable @inline(__always)
  public func _withContiguousStorageIfAvailable_SR14663<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    if Self.self == Array<Element>.self && Array<Element>._isWCSIABroken() {
      return nil
    }

    return try self.withContiguousStorageIfAvailable(body)
  }
}
