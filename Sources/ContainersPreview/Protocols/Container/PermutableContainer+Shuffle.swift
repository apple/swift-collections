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

#if compiler(>=6.4) && UnstableContainersPreview

@available(SwiftStdlib 6.4, *)
extension PermutableContainer
where Self: RandomAccessContainer, Element: ~Copyable {
  /// Shuffles the container in place, using the given generator as a source
  /// for randomness.
  ///
  /// You use this method to randomize the order of elements in a container
  /// when you are using a custom random number generator. For example, you
  /// can use the `shuffle(using:)` method to randomly reorder the elements
  /// of an array.
  ///
  ///     var names = ["Alejandro", "Camila", "Diego", "Luciana", "Luis", "Sofía"]
  ///     names.shuffle(using: &myGenerator)
  ///     // names == ["Sofía", "Alejandro", "Camila", "Luis", "Diego", "Luciana"]
  ///
  /// - Parameter generator: The random number generator to use when shuffling
  ///   the container.
  ///
  /// - Complexity: O(`count`)
  /// - Note: The algorithm used to shuffle a container may change in a future
  ///   version of Swift. If you're passing a generator that results in the
  ///   same shuffled order each time you run your program, that sequence may
  ///   change when your program is compiled using a different version of
  ///   Swift.
  @inlinable
  public mutating func shuffle<T: RandomNumberGenerator>(
    using generator: inout T
  ) {
    // Fisher-Yates shuffle
    var remaining = self.count
    guard remaining > 1 else { return }
    var i = startIndex
    while remaining > 1 {
      let random = Int.random(in: 0 ..< remaining, using: &generator)
      self.swapAt(i, self.index(i, offsetBy: random))
      self.formIndex(after: &i)
      remaining -= 1
    }
  }

  /// Shuffles the container in place.
  ///
  /// Use the `shuffle()` method to randomly reorder the elements of an array.
  ///
  ///     var names = ["Alejandro", "Camila", "Diego", "Luciana", "Luis", "Sofía"]
  ///     names.shuffle()
  ///     // names == ["Luis", "Camila", "Luciana", "Sofía", "Alejandro", "Diego"]
  ///
  /// This method is equivalent to calling `shuffle(using:)`, passing in the
  /// system's default random generator.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func shuffle() {
    var g = SystemRandomNumberGenerator()
    shuffle(using: &g)
  }
}

#endif
