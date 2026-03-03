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

/// A type that supplies the values of an in-place consumable sequence through
/// a series of `InputSpan` instances. This iterator-like construct allows
/// directly consuming elements from some container's storage, in bulk,
/// without requiring them to be moved into any temporary buffer.
///
/// Drains are inherently also producers -- they can produce items by simply
/// moving their consumable contents to the client-supplied series of
/// output spans.
@available(SwiftStdlib 5.0, *)
public protocol Drain<Element>: Producer, ~Copyable, ~Escapable
where ProducerError == Never
{
  /// Returns the next span of consumable items in the sequence underlying this
  /// drain, of at most the specified maximum count. A `maximumCount` of nil
  /// indicates no limit, meaning that the client is able to process an
  /// arbitrarily large number of elements.
  ///
  /// Repeatedly calling this method returns, in order, all the elements of the
  /// underlying consumable sequence. As soon as the sequence has run out of
  /// elements, all subsequent calls return empty spans.
  ///
  /// While the returned input spans exist, they continue to mutate the drain,
  /// extending the exclusive access initiated by the call to
  /// `drainNext(maximumCount:)`. To call this (or any other) method again, the
  /// returned input span needs to be consumed or otherwise destroyed.
  ///
  /// Once this method returns, the contents of the resulting input span are
  /// already destined for consumption, either gradually by invoking explicit
  /// methods such as `InputSpan.popFirst`, or all at once when
  /// the input span is destroyed. There is no way to "put items back" into
  /// the consumable sequence, other than by moving them into a
  /// temporary location and later reinserting them into the underlying
  /// construct through some type-specific operations.
  ///
  /// - Parameter maximumCount: The maximum number of items that the client
  ///       is prepared to consume, or nil if the client is able to process an
  ///       arbitrary number of elements. If this is non-nil, then it must be a
  ///       positive integer.
  /// - Returns: An input span of at most the specified maximum count (if any),
  ///       containing the next elements of the underlying consumable sequence.
  ///       This method returns an empty span to indicate that it has reached
  ///       the end of the sequence.
  @_lifetime(&self)
  @_lifetime(self: copy self)
  mutating func drainNext(maximumCount: Int) -> InputSpan<Element>
  // TODO: The primary use case does not need this to throw; do we need to allow that?
  // Note: making this failable is not entirely straightforward, as there is no
  // easy way to signal partial success -- conforming implementations
  // would likely need to store errors they encounter midway through a
  // chunk and report them at the beginning of the next iteration.
  // I take this as an indication that we don't need to do that.
  // (Contrast with this `Producer.generate(into:)`; the shape of that method
  // allows it to partially populate its client-supplied target and still
  // report an error.)
  //
  // Note: We can also express this with a higher-order shape:
  //
  //     mutating func drainNext<E: Error, R: ~Copyable>(
  //       _ body: (inout InputSpan<Element>) throws(E) -> R
  //     ) throws(E) -> R
  //
  // This would allow partial consumption, eliminating the need for
  // `maximumCount`, but at the cost of having to deal with closures --
  // it can be tricky to elegantly flow data/control in & out higher-order
  // functions. Allowing the function argument to throw also precludes
  // the drain itself from throwing, unless they are both required
  // to use the same error type, which would be impractical.
}

@available(SwiftStdlib 5.0, *)
extension Drain where Self: ~Copyable & ~Escapable {
  /// Returns the next span of consumable items in the sequence underlying this
  /// drain, of an arbitrarily large count.
  ///
  /// Repeatedly calling this method returns, in order, all the elements of the
  /// underlying consumable sequence. As soon as the sequence has run out of
  /// elements, all subsequent calls return empty spans.
  ///
  /// While the returned input spans exist, they continue to mutate the drain,
  /// extending the exclusive access initiated by the call to
  /// `drain(maximumCount:)`. To call this (or any other) method again, the
  /// returned input span needs to be consumed or otherwise destroyed.
  ///
  /// Once this method returns, the contents of the resulting input span are
  /// already destined for consumption, either gradually by invoking explicit
  /// methods such as `InputSpan.popFirst`, or all at once when
  /// the input span is destroyed. There is no way to "put items back" into
  /// the consumable sequence, other than by moving them into a
  /// temporary location and later reinserting them into the underlying
  /// construct through some type-specific operations.
  ///
  /// - Returns: An input span containing the next elements of the underlying
  ///       consumable sequence. This method returns an empty span to indicate
  ///       that it has reached the end of the sequence.
  @_lifetime(&self)
  @_lifetime(self: copy self)
  @_transparent
  public mutating func drainNext() -> InputSpan<Element> {
    drainNext(maximumCount: Int.max)
  }

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
  @inlinable
  @_lifetime(target: copy target)
  public mutating func generate(
    into target: inout OutputSpan<Element>
  ) throws(Never) -> Bool {
    var source = self.drainNext(maximumCount: target.freeCapacity)
    if source.isEmpty { return false }
    target._append(moving: &source)
    return true
  }
  
  /// Skip at most the given number items in the underlying generative sequence,
  /// decreasing it by the number of items successfully skipped.
  ///
  /// This is equivalent to generating the same number of items then immediately
  /// discarding them, except it may avoid the overhead of actually
  /// materializing them.
  ///
  /// As soon as the producer has run out of items, all subsequent calls to
  /// this method stop decrementing `remainder` and return false.
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
  /// skipping a batch of items, in which case the `remainder` will still be
  /// decremented by the number of elements that were successfully skipped
  /// before encountering the problem.
  ///
  /// - Parameter remainder: The maximum number of items remaining to skip.
  ///     This method decrements this value by the number of items it
  ///     successfully skipped before returning.
  /// - Returns: A boolean value indicating whether the operation was able to
  ///    satisfy the request at least partially without hitting the end of the
  ///    underlying consumable sequence.
  @inlinable
  @_lifetime(self: copy self)
  public mutating func skip(
    upTo n: inout Int
  ) throws(ProducerError) -> Bool {
    precondition(n >= 0, "Cannot skip a negative number of elements")
    guard n > 0 else { return true }
    let span = drainNext(maximumCount: n)
    let success = span.count > 0
    n &-= span.count
    return success
  }
}

#endif
