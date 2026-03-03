//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.2) && COLLECTIONS_UNSTABLE_CONTAINERS_PREVIEW

/// A type that supplies the values of a generative sequence by populating
/// a client-supplied series of `OutputSpan` instances. "Generative" sequences
/// transfer the ownership of items they produce to their clients, rather than
/// merely providing borrowing access to them. A `Producer` instance represents
/// an ongoing iteration over such a generative sequence.
@available(SwiftStdlib 5.0, *)
public protocol Producer<Element, ProducerError>: ~Copyable, ~Escapable {
  /// The type of the items that this producer generates.
  associatedtype Element: ~Copyable
  
  /// The error that this producer may throw, or `Never` if this producer
  /// always succeeds.
  associatedtype ProducerError: Error = Never
  
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
  @_lifetime(target: copy target)
  @_lifetime(self: copy self)
  @discardableResult
  mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(ProducerError) -> Bool
  
  /// Skip at most the given number items in the underlying generative sequence,
  /// decreasing it by the number of items successfully skipped.
  ///
  /// This is equivalent to generating the same number of items then immediately
  /// discarding them, except it may avoid the overhead of actually
  /// materializing them.
  ///
  /// As soon as the producer has run out of items, all subsequent calls to
  /// this method stop decrementing `n` and return false.
  ///
  /// The default implementation of this method calls `generate(into:)` with
  /// a small temporary buffer, immediately discarding all generated items.
  /// Conforming types are encouraged to replace this default approach
  /// with a more efficient implementation whenever it is possible to do so.
  ///
  /// ### Error handling
  ///
  /// This method throws an error to indicate a failure while trying to skip
  /// the upcoming next item in the sequence. Failure may happen midway through
  /// skipping a batch of items, in which case `n` will still be
  /// decremented by the number of elements that were successfully skipped
  /// before encountering the problem.
  ///
  /// - Parameter n: The maximum number of items remaining to skip. This
  ///     must be greater than zero. This method decrements this value by the
  ///     number of items it successfully skipped before returning.
  /// - Returns: A boolean value indicating whether the operation was able to
  ///    skip at least one item without hitting the end of the underlying
  ///    sequence.
  @_lifetime(self: copy self)
  mutating func skip(upTo n: inout Int) throws(ProducerError) -> Bool
  
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
  /// available in the bulk method). Custom implementations of `generateNext()`
  /// must produce results that are indistinguishable from the default
  /// implementation, but they may exhibit observably different performance
  /// metrics.
  @_lifetime(self: copy self)
  mutating func generateNext() throws(ProducerError) -> Element?
}

@available(SwiftStdlib 5.0, *)
extension Producer where Self: ~Copyable & ~Escapable {
  /// A value less than or equal to the number of remaining items that this
  /// producer is able to generate until it reaches its end.
  ///
  /// The default implementation returns 0. If you provide your own
  /// implementation, make sure to compute the value nondestructively.
  @inlinable
  @inline(__always)
  public var underestimatedCount: Int { 0 }

  /// Skip at most the given number items in the underlying generative sequence,
  /// decreasing it by the number of items successfully skipped.
  ///
  /// This is equivalent to generating the same number of items then immediately
  /// discarding them, except it may avoid the overhead of actually
  /// materializing them.
  ///
  /// As soon as the producer has run out of items, all subsequent calls to
  /// this method stop decrementing `n` and return false.
  ///
  /// The default implementation of this method calls `generate(into:)` with
  /// a small temporary buffer, immediately discarding all generated items.
  /// Conforming types are encouraged to replace this default approach
  /// with a more efficient implementation whenever it is possible to do so.
  ///
  /// ### Error handling
  ///
  /// This method throws an error to indicate a failure while trying to skip
  /// the upcoming next item in the sequence. Failure may happen midway through
  /// skipping a batch of items, in which case `n` will still be
  /// decremented by the number of elements that were successfully skipped
  /// before encountering the problem.
  ///
  /// - Parameter n: The maximum number of items remaining to skip. This
  ///     must be greater than zero. This method decrements this value by the
  ///     number of items it successfully skipped before returning.
  /// - Returns: A boolean value indicating whether the operation was able to
  ///    skip at least one item without hitting the end of the underlying
  ///    sequence.
  @inlinable
  @_lifetime(self: copy self)
  public mutating func skip(upTo n: inout Int) throws(ProducerError) -> Bool {
    precondition(n > 0, "Cannot skip fewer than one item")
    let maxBufferSize = 8
    return try withTemporaryOutputSpan(
      of: Element.self, capacity: Swift.min(maxBufferSize, n)
    ) { span throws(ProducerError) in
      defer { n &-= span.count }
      return try self.generate(into: &span)
    }
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
  /// available in the bulk method). Custom implementations of `generateNext()`
  /// must produce results that are indistinguishable from the default
  /// implementation, but they may exhibit observably different performance
  /// metrics.
  @inlinable
  @_lifetime(self: copy self)
  public mutating func generateNext() throws(ProducerError) -> Element? {
    try withUnsafeTemporaryAllocation(
      of: Element.self, capacity: 1
    ) { buffer throws(ProducerError) in
      var span = OutputSpan(buffer: buffer, initializedCount: 0)
      guard try self.generate(into: &span) else { return nil }
      return span.removeLast()
    }
  }
}

@available(SwiftStdlib 5.0, *)
extension Producer where Self: ~Copyable & ~Escapable {
  /// Returns true if the producer has no more elements, consuming it in
  /// the process. This is implemented by checking if it is possible to
  /// skip one item.
  ///
  /// This is useful in preconditions.
  @inlinable
  public consuming func _isAtEnd() throws(ProducerError) -> Bool {
    var c = 1
    return try !skip(upTo: &c)
  }
}

#endif
