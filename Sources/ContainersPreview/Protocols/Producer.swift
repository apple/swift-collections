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

#if !COLLECTIONS_SINGLE_MODULE
import InternalCollectionsUtilities
#endif

#if compiler(>=6.4) && UnstableContainersPreview

@_alwaysEmitIntoClient
@_transparent
public var _producerBufferSize: Int { 8 }

/// A type that supplies the values of a generative sequence by populating
/// a client-supplied series of `OutputSpan` instances. "Generative" sequences
/// transfer the ownership of items they produce to their clients, rather than
/// merely providing borrowing access to them. A `Producer` instance represents
/// an ongoing iteration over such a generative sequence.
@available(SwiftStdlib 5.0, *)
public protocol Producer<Element, Failure>: ~Copyable, ~Escapable {
  /// The type of the items that this producer generates.
  associatedtype Element: ~Copyable
  
  /// The error that this producer may throw, or `Never` if this producer
  /// always succeeds.
  associatedtype Failure: Error = Never
  
  /// A value less than or equal to the number of remaining items that this
  /// producer is able to generate until it reaches its end.
  ///
  /// The default implementation returns 0. If you provide your own
  /// implementation, make sure to compute the value nondestructively.
  var underestimatedCount: Int { get }
  
  /// Generate the next batch of items into the supplied output span instance,
  /// which must have room for at least one new element.
  ///
  /// Repeatedly calling this method produces, in order, all the elements of the
  /// underlying generative sequence. As soon as the sequence has run out of
  /// elements, all subsequent calls return false without appending any new
  /// items to their target. This method is not guaranteed to fully populate the
  /// given output span, but it always appends at least one item until the end
  /// of the underlying generative sequence.
  ///
  /// The ownership of all generated elements is transferred to the caller of
  /// this method -- it can arbitrarily store, mutate, consume or discard them
  /// as needed, even across invocations of this method, or after the producer
  /// is destroyed.
  ///
  /// The returned Boolean value can be used to easily determine if the
  /// method was able to make progress towards filling `target` without hitting
  /// the end of the underlying sequence.
  ///
  /// If `target` is a full span, this method is allowed to unconditionally
  /// return true. Passing an empty span is not a reliable way to test if the
  /// producer has reached its end. (Some producers may only be able to detect
  /// that they are finished while trying to generate the next item.)
  ///
  /// ### Error handling
  ///
  /// This method throws an error to indicate a failure while trying to generate
  /// the upcoming next item in the sequence. Failure may happen midway through
  /// populating `target`, in which case the output span will still gain
  /// new items despite the error. (Those items are successfully
  /// generated, and do not necessarilly need to be discarded.)
  ///
  /// This protocol does not specify the meaning of a failure, or the
  /// precise state of the iterator after an error is thrown; however, the
  /// error must not trigger runtime traps in subsequent attempts at iteration.
  /// (After a failure, conforming types may choose to produce new items, or
  /// signal the end of the iteration, or throw another error, which may or may
  /// not match the first.)
  ///
  /// Absent of more specific information, generic code should stop
  /// iterating, discard the producer and rethrow the error when it encounters
  /// a failure. Generic code is encouraged to preserve the items that got
  /// successfully produced before the throw (including ones appended by
  /// the call that ultimately ended in failure); however, whether this is
  /// possible (or desirable) ultimately depends on the specific problem that
  /// the algorithm is solving.
  ///
  /// - Parameter target: An output span ready to take newly generated items.
  /// - Returns: A boolean value indicating whether the operation was able to
  ///    append at least one item to the supplied output span without hitting
  ///    the end of the underlying sequence.
  @discardableResult
  @_lifetime(target: copy target)
  @_lifetime(self: copy self)
  mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Failure) -> Bool
  
  /// Skip the given number items in the underlying generative sequence,
  /// decreasing it by the number of items successfully skipped before hitting
  /// the end of the sequence or an error.
  ///
  /// This is equivalent to generating the same number of items then immediately
  /// discarding them, except it may avoid the overhead of actually
  /// materializing the elements.
  ///
  /// As soon as the producer has run out of items, all subsequent calls to
  /// this method stop decrementing `n` and return false.
  ///
  /// The default implementation of this method repeatedly calls
  /// `generate(into:)` with a small temporary buffer, immediately discarding
  /// all generated items. Conforming types are encouraged to replace this
  /// default approach with a more efficient implementation whenever it is
  /// possible to do so.
  ///
  /// ### Error handling
  ///
  /// This method throws an error to indicate a failure while trying to skip
  /// an upcoming item in the sequence. Failure may happen midway through
  /// skipping a batch of items, in which case `n` will still be
  /// decremented by the number of elements that were successfully skipped
  /// before encountering the problem. This can be used to precisely track
  /// the current position of the failed producer, allowing better diagnostics,
  /// and allowing iteration to continue if the failure is resolvable.
  ///
  /// - Parameter n: The number of items to skip. This must be greater than
  ///     zero. This method decrements this value by the number of items it
  ///     successfully skipped before returning.
  @_lifetime(self: copy self)
  mutating func skip(by n: inout Int) throws(Failure)

  /// Generate and return the next element in the underlying generative
  /// sequence.
  ///
  /// Repeatedly calling this method produces, in order, all the elements of the
  /// underlying generative sequence. As soon as the sequence has run out of
  /// elements, all subsequent calls return `nil`.
  ///
  /// The ownership of all generated elements is transferred to the
  /// caller of this method -- it can arbitrarily store, mutate,
  /// consume or discard them as needed, even across invocations of this method,
  /// or after the producer is destroyed.
  ///
  /// This method throws an error to indicate a failure. This protocol does not
  /// specify the meaning of such errors, or the precise state of the
  /// iterator after an error is thrown; however, the error must not trigger
  /// runtime traps in subsequent attempts at iteration.
  /// (Conforming types may choose to produce new items, or signal the end of
  /// the iteration, or throw another error, which may or may not match the
  /// first.) Absent of more specific information, generic code should stop
  /// iterating, discard the producer and rethrow the error when it encounters
  /// a failure.
  ///
  /// The default implementation of this method calls `generate(into:)` with
  /// a temporary output span with room for a single item, and returns the
  /// resulting contents. This often produces satisfactory results; but the
  /// protocol allows conformances to customize this entry point if they believe
  /// it to be necessary (for example, if they can take shortcuts that aren't
  /// available in the bulk method). Custom implementations of `next()`
  /// must produce results that are indistinguishable from the default
  /// implementation, but they may exhibit observably different performance
  /// metrics.
  @_lifetime(self: copy self)
  mutating func next() throws(Failure) -> Element?
}

@available(SwiftStdlib 5.0, *)
extension Producer where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  /// A value less than or equal to the number of remaining items that this
  /// producer is able to generate until it reaches its end.
  ///
  /// The default implementation returns 0. If you provide your own
  /// implementation, make sure to compute the value nondestructively.
  @inlinable
  @inline(__always)
  public var underestimatedCount: Int { 0 }

  /// Skip the given number items in the underlying generative sequence,
  /// decreasing it by the number of items successfully skipped before hitting
  /// the end of the sequence or an error.
  ///
  /// This is equivalent to generating the same number of items then immediately
  /// discarding them, except it may avoid the overhead of actually
  /// materializing the elements.
  ///
  /// As soon as the producer has run out of items, all subsequent calls to
  /// this method stop decrementing `n` and return false.
  ///
  /// The default implementation of this method repeatedly calls
  /// `generate(into:)` with a small temporary buffer, immediately discarding
  /// all generated items. Conforming types are encouraged to replace this
  /// default approach with a more efficient implementation whenever it is
  /// possible to do so.
  ///
  /// ### Error handling
  ///
  /// This method throws an error to indicate a failure while trying to skip
  /// an upcoming item in the sequence. Failure may happen midway through
  /// skipping a batch of items, in which case `n` will still be
  /// decremented by the number of elements that were successfully skipped
  /// before encountering the problem. This can be used to precisely track
  /// the current position of the failed producer, allowing better diagnostics,
  /// and allowing iteration to continue if the failure is resolvable.
  ///
  /// - Parameter n: The number of items to skip. This must be greater than
  ///     zero. This method decrements this value by the number of items it
  ///     successfully skipped before returning.
  @inlinable
  @_lifetime(self: copy self)
  public mutating func skip(by n: inout Int) throws(Failure) {
    precondition(n > 0, "Cannot skip fewer than one item")
    let maxBufferSize = _producerBufferSize
    return try withTemporaryAllocation(
      of: Element.self,
      capacity: Swift.min(maxBufferSize, n)
    ) { buffer throws(Failure) in
      repeat {
        defer { n &-= buffer.count }
        guard try self.generate(into: &buffer) else { return }
        buffer.removeAll()
      } while n > 0
    }
  }

  /// Skip the given number items in the underlying generative sequence,
  /// returning the number of items successfully skipped before hitting the end
  /// of the sequence.
  ///
  /// This is equivalent to generating the same number of items then immediately
  /// discarding them, except it may avoid the overhead of actually
  /// materializing the elements.
  ///
  /// If the producer runs out of items, all subsequent calls to
  /// this method return zero without skipping any elements.
  ///
  /// ### Error handling
  ///
  /// This method throws an error to indicate a failure while trying to skip
  /// an upcoming item in the sequence. Failure may happen midway through
  /// skipping a batch of items, in which case this operation has no way to
  /// report which item triggered the error. This is not an issue in the common
  /// case when the iterator simply gets discarded anyway; however, when losing
  /// position is not acceptable, it is recommended to avoid calling this
  /// algorithm, and instead call the variant of `skip(by:)` that takes an inout
  /// integer value. For example, this applies to use cases that need to report
  /// the precise location of errors, and cases that are able to recover some
  /// error conditions and want to be able to continue iterating without losing
  /// data.
  ///
  /// - Returns: The number of items successfully skipped. This can be less than
  ///    `n` if the operation hits the end of the underlying sequence before
  ///    managing to skip the requested number of elements.
  @inlinable
  @_lifetime(self: copy self)
  public mutating func skip(by n: Int) throws(Failure) -> Int {
    var remainder = n
    try self.skip(by: &remainder)
    return n - remainder
  }

  /// Generate and return the next element in the underlying generative
  /// sequence.
  ///
  /// Repeatedly calling this method produces, in order, all the elements of the
  /// underlying generative sequence. As soon as the sequence has run out of
  /// elements, all subsequent calls return `nil`.
  ///
  /// The ownership of all generated elements is transferred to the
  /// caller of this method -- it can arbitrarily store, mutate,
  /// consume or discard them as needed, even across invocations of this method,
  /// or after the producer is destroyed.
  ///
  /// This method throws an error to indicate a failure. This protocol does not
  /// specify the meaning of such errors, or the precise state of the
  /// iterator after an error is thrown; however, the error must not trigger
  /// runtime traps in subsequent attempts at iteration.
  /// (Conforming types may choose to produce new items, or signal the end of
  /// the iteration, or throw another error, which may or may not match the
  /// first.) Absent of more specific information, generic code should stop
  /// iterating, discard the producer and rethrow the error when it encounters
  /// a failure.
  ///
  /// The default implementation of this method calls `generate(into:)` with
  /// a temporary output span with room for a single item, and returns the
  /// resulting contents. This often produces satisfactory results; but the
  /// protocol allows conformances to customize this entry point if they believe
  /// it to be necessary (for example, if they can take shortcuts that aren't
  /// available in the bulk method). Custom implementations of `next()`
  /// must produce results that are indistinguishable from the default
  /// implementation, but they may exhibit observably different performance
  /// metrics.
  @inlinable
  @_lifetime(self: copy self)
  public mutating func next() throws(Failure) -> Element? {
    try withTemporaryAllocation(
      of: Element.self, capacity: 1
    ) { buffer throws(Failure) in
      guard try self.generate(into: &buffer) else { return nil }
      return buffer.removeLast()
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension Producer where Self: ~Copyable & ~Escapable, Element: ~Copyable {
  /// Triggers a runtime trap if the producer is not at its end, consuming it in
  /// the process. This is implemented by checking if it is possible to
  /// skip one item.
  @inlinable
  public consuming func _expectEnd(
    _ message: String = "Invalid Producer"
  ) throws(Failure) {
    var c = 1
    try skip(by: &c)
    precondition(c == 0, message)
  }
}

#endif
