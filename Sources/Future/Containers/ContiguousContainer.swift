//===---------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@available(SwiftCompatibilitySpan 5.0, *)
public protocol ContiguousContainer<Element>: ~Copyable, ~Escapable {
  associatedtype Element: ~Copyable/* & ~Escapable*/

  var span: Span<Element> { @lifetime(copy self) get }
}

@available(SwiftCompatibilitySpan 5.0, *)
extension Span: ContiguousContainer where Element: ~Copyable {
  public var span: Self {
    @lifetime(copy self)
    get { self }
  }
}

@available(SwiftStdlib 6.2, *)
extension Array: ContiguousContainer {}

@available(SwiftStdlib 6.2, *)
extension ContiguousArray: ContiguousContainer {}

@available(SwiftStdlib 6.2, *)
extension CollectionOfOne: ContiguousContainer {}

@available(SwiftStdlib 6.2, *)
extension String.UTF8View: ContiguousContainer {}
