//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import CollectionsBenchmark
import _RopeModule
import Foundation

let someLatinSymbols: [UnicodeScalar] = [
  0x20 ..< 0x7f,
  0xa1 ..< 0xad,
  0xae ..< 0x2af,
  0x300 ..< 0x370,
  0x1e00 ..< 0x1eff,
].flatMap {
  $0.map { UnicodeScalar($0)! }
}

extension UnicodeScalar {
  static func randomLatin(
    using rng: inout some RandomNumberGenerator
  ) -> Self {
    someLatinSymbols.randomElement(using: &rng)!
  }
}

extension String.UnicodeScalarView {
  static func randomLatin(
    runeCount: Int, using rng: inout some RandomNumberGenerator
  ) -> Self {
    var result = String.UnicodeScalarView()
    for _ in 0 ..< runeCount {
      result.append(UnicodeScalar.randomLatin(using: &rng))
    }
    return result
  }
}

extension String {
  static func randomLatin(
    runeCount: Int, using rng: inout some RandomNumberGenerator
  ) -> Self {
    let text = String.UnicodeScalarView.randomLatin(
      runeCount: runeCount, using: &rng)
    return String(text)
  }
}

struct NativeStringInput {
  let value: String

  init(runeCount: Int, using rng: inout some RandomNumberGenerator) {
    self.value = String.randomLatin(runeCount: runeCount, using: &rng)
  }
}

struct BridgedStringInput {
  let value: String

  init(runeCount: Int, using rng: inout some RandomNumberGenerator) {
    let string = String.randomLatin(runeCount: runeCount, using: &rng)
    let utf16 = Array(string.utf16)
    let cocoa = utf16.withUnsafeBufferPointer {
      NSString(characters: $0.baseAddress!, length: $0.count)
    }
    self.value = cocoa as String
  }
}


extension Benchmark {
  public mutating func addBigStringBenchmarks() {
    guard #available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *) else {
      return
    }

    self.registerInputGenerator(for: NativeStringInput.self) { c in
      var rng = SystemRandomNumberGenerator()
      return NativeStringInput(runeCount: c, using: &rng)
    }

    self.registerInputGenerator(for: BridgedStringInput.self) { c in
      var rng = SystemRandomNumberGenerator()
      return BridgedStringInput(runeCount: c, using: &rng)
    }

    self.addSimple(
      title: "BigString init from native string",
      input: NativeStringInput.self
    ) { input in
      blackHole(BigString(input.value))
    }

    self.addSimple(
      title: "BigString init from bridged string",
      input: BridgedStringInput.self
    ) { input in
      blackHole(BigString(input.value))
    }
  }
}
