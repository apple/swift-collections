import Future
import XCTest

extension Range<Int> {
  func _offset(by start: Int) -> Range<Int> {
    start + lowerBound ..< start + upperBound
  }
}

private func utf8Validate(
  _ bytes: Array<UInt8>,
  expectedErrors errors: [UTF8.EncodingError]
) throws {
  let span = bytes.storage
  if errors.isEmpty {
    // No errors expected
    _ = try UTF8Span(validating: span)
    return
  }

  // Check for each error.
  // NOTE: We currently do it by slicing, which will change the
  // error classification.
  for expectedError in errors {
    let start = expectedError.range.lowerBound
    do throws(UTF8.EncodingError) {
      _ = try UTF8Span(validating: span.extracting(start...))
      XCTAssert(false)
    } catch {
      let adjustedErr = UTF8.EncodingError(
        error.kind,
        error.range._offset(by: start)
      )
      XCTAssertEqual(expectedError, adjustedErr)
    }
  }

  // Rest of input should be error-free
  if let start = errors.last?.range.upperBound, start < bytes.count {
    _ = try UTF8Span(validating: span.extracting(start...))
  }
}

private struct ValidationError {
  var error: UTF8.EncodingError

  // When fetching all errors, we'll get the error kind given. When
  // slicing in order to get the next error (e.g.
  // `UTF8Span.init(validating:))`, we'll get `.unexpectedContinuation`.
  var errorStart: Bool

  init(_ error: UTF8.EncodingError, errorStart: Bool) {
    self.error = error
    self.errorStart = errorStart
  }

  public static func unexpectedContinuationByte(
    at i: Int, errorStart: Bool = true
  ) -> Self {
    Self(UTF8.EncodingError(.unexpectedContinuationByte, at: i), errorStart: errorStart)
  }

  public static func surrogateCodePointByte(
    at i: Int, errorStart: Bool = true
  ) -> Self {
    Self(UTF8.EncodingError(.surrogateCodePointByte, at: i), errorStart: errorStart)
  }

  public static func invalidNonSurrogateCodePointByte(
    at i: Int, errorStart: Bool = true
  ) -> Self {
    Self(UTF8.EncodingError(.invalidNonSurrogateCodePointByte, at: i), errorStart: errorStart)
  }

  public static func overlongEncodingByte(
    at i: Int, errorStart: Bool = true
  ) -> Self {
    Self(UTF8.EncodingError(.overlongEncodingByte, at: i), errorStart: errorStart)
  }

  public static func truncatedScalar(
    _ range: some RangeExpression<Int>, errorStart: Bool = true
  ) -> Self {
    Self(UTF8.EncodingError(.truncatedScalar, range), errorStart: errorStart)
  }
}

private struct ValidationTestCase {
  var bytes: [UInt8]

  // When fetching all errors, we'll get the error kind given. When
  // slicing in order to get the next error (e.g.
  // `UTF8Span.init(validating:))`, we'll get `.unexpectedContinuation`.
  var errors: [ValidationError]

  init(
    _ bytes: [UInt8],
    _ errors: [ValidationError]
  ) {
    self.bytes = bytes
    self.errors = errors
  }

  func fetchError(
    at i: Int, wasSliced: Bool
  ) -> UTF8.EncodingError {
    let err = errors[i]
    if wasSliced && !err.errorStart {
      return .init(.unexpectedContinuationByte, err.error.range)
    }
    return err.error
  }

  func testAllErrors() {
    let caughtErrors = Array(UTF8._checkAllErrors(bytes))
    for i in 0..<Swift.min(caughtErrors.count, errors.count) {
      XCTAssertEqual(fetchError(at: i, wasSliced: false), caughtErrors[i])
    }
    XCTAssertEqual(caughtErrors.count, errors.count)
  }

  func testSpanSlicedErrors() {
    let span = bytes.storage
    if errors.isEmpty {
      do throws(UTF8.EncodingError) {
        // No errors expected
        _ = try UTF8Span(validating: span)
      } catch {
        XCTFail("Unexpected error: \(error)")
      }
      return
    }

    // Check for each error.
    // NOTE: We currently do it by slicing, which will change the
    // error classification.
    for errorIdx in errors.indices {
      let expectedError = fetchError(at: errorIdx, wasSliced: true)
      let start = expectedError.range.lowerBound
      do throws(UTF8.EncodingError) {
        _ = try UTF8Span(validating: span.extracting(start...))
        XCTAssert(false)
      } catch {
        let adjustedErr = UTF8.EncodingError(
          error.kind,
          error.range._offset(by: start)
        )
        XCTAssertEqual(expectedError, adjustedErr)
      }
    }

    // Rest of input should be error-free
    if let start = errors.last?.error.range.upperBound,
        start < bytes.count
    {
      do throws(UTF8.EncodingError) {
        _ = try UTF8Span(validating: span.extracting(start...))
      } catch {
        XCTFail("Found subsequent error \(error)")
      }
    }
  }

  func run() {
    testSpanSlicedErrors()
    testAllErrors()
  }
}

extension UTF8SpanTests {
  func testUTF8ValidationErrors() throws {
    func test(_ t: ValidationTestCase) {
      t.run()
    }

    // Valid string
    test(.init(Array("abcde\u{301}f😀🇺🇸🧟‍♀️🧟‍♀️".utf8), []))

    // Bad URL
    test(.init(
      Array("http://servername/scripts/..".utf8)
      + [0xC0, 0xAF]
      + Array("../winnt/system32/cmd.exe".utf8),
      [.overlongEncodingByte(at: 28),                    // C0
       .overlongEncodingByte(at: 29, errorStart: false), // AF
      ]))

    test(.init(
      [0xC0, 0xAF, 0xE0, 0x80, 0xBF, 0xF0, 0x81, 0x82, 0x41],
      [.overlongEncodingByte(at: 0),                    // C0
       .overlongEncodingByte(at: 1, errorStart: false), // AF
       .overlongEncodingByte(at: 2),                    // E0
       .overlongEncodingByte(at: 3, errorStart: false), // 80
       .overlongEncodingByte(at: 4, errorStart: false), // BF
       .overlongEncodingByte(at: 5),                    // F0
       .overlongEncodingByte(at: 6, errorStart: false), // 81
       .overlongEncodingByte(at: 7, errorStart: false), // 82
      ]))
    test(.init(
      [0x41, 0xC0, 0xAF, 0x41, 0xF4, 0x80, 0x80, 0x41],
      [.overlongEncodingByte(at: 1),                    // C0
       .overlongEncodingByte(at: 2, errorStart: false), // AF
       .truncatedScalar(4...6),                         // F4 80 80
      ]))
    test(.init(
      [0xED, 0xAF, 0x41],
      [.surrogateCodePointByte(at: 0),                    // ED
       .surrogateCodePointByte(at: 1, errorStart: false), // AF
      ]))
    test(.init(
      [0xED, 0xA0, 0x80, 0xED, 0xBF, 0xBF, 0xED, 0xAF, 0x41],
      [.surrogateCodePointByte(at: 0),                    // ED
       .surrogateCodePointByte(at: 1, errorStart: false), // A0
       .surrogateCodePointByte(at: 2, errorStart: false), // 80
       .surrogateCodePointByte(at: 3),                    // ED
       .surrogateCodePointByte(at: 4, errorStart: false), // BF
       .surrogateCodePointByte(at: 5, errorStart: false), // BF
       .surrogateCodePointByte(at: 6),                    // ED
       .surrogateCodePointByte(at: 7, errorStart: false), // AF
      ]))
    test(.init(
      [0xF4, 0x91, 0x92, 0x93, 0xFF, 0x41, 0x80, 0xBF, 0x42],
      [.invalidNonSurrogateCodePointByte(at: 0),                    // F4
       .invalidNonSurrogateCodePointByte(at: 1, errorStart: false), // 91
       .invalidNonSurrogateCodePointByte(at: 2, errorStart: false), // 92
       .invalidNonSurrogateCodePointByte(at: 3, errorStart: false), // 93
       .invalidNonSurrogateCodePointByte(at: 4),                    // FF
       .unexpectedContinuationByte(at: 6),                          // 80
       .unexpectedContinuationByte(at: 7),                          // BF
      ]))
    test(.init(
      [0xE1, 0x80, 0xE2, 0xF0, 0x91, 0x92, 0xF1, 0xBF, 0x41],
      [.truncatedScalar(0...1), // E1 80
       .truncatedScalar(2...2), // E2
       .truncatedScalar(3...5), // F0 91 92
       .truncatedScalar(6...7), // F1 BF
      ]))
    test(.init(
      [0xE0, 0x81, 0x80],
      [.overlongEncodingByte(at: 0), // E0
       .overlongEncodingByte(at: 1, errorStart: false), // 81
       .overlongEncodingByte(at: 2, errorStart: false), // 80
      ]))
  }
}
