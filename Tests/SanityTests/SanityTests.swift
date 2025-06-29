import XCTest

final class SanityTests: XCTestCase {

  func testBasicMath() {
    XCTAssertEqual(1 + 1, 2, "Basic addition should work")
    XCTAssertEqual(2 * 3, 6, "Basic multiplication should work")
    XCTAssertTrue(5 > 3, "Basic comparison should work")
  }

  func testStringOperations() {
    let hello = "Hello"
    let world = "World"
    let combined = "\(hello) \(world)"
    XCTAssertEqual(combined, "Hello World", "String interpolation should work")
  }

  func testArrayOperations() {
    let numbers = [1, 2, 3, 4, 5]
    XCTAssertEqual(numbers.count, 5, "Array count should work")
    XCTAssertEqual(numbers.first, 1, "Array first element should work")
    XCTAssertEqual(numbers.last, 5, "Array last element should work")
  }

  func testAsyncOperation() async {
    // Test that async/await works
    let result = await performAsyncOperation()
    XCTAssertEqual(result, 42, "Async operation should work")
  }

  private func performAsyncOperation() async -> Int {
    // Simulate some async work
    try? await Task.sleep(nanoseconds: 1_000_000)  // 1ms
    return 42
  }
}
