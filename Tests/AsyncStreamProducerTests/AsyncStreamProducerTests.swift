import Foundation
import XCTest
import AsyncStreamProducer

class AsyncStreamProducerTest: XCTestCase {
  @available(macOS 13.0, *)
  func testInitialValuesAreEmitted() async {
    let producer = AsyncStreamProducer(
      initialValue: 1,
      nextValue: {
        // TODO: use a non-time-based approach
        try? await Task.sleep(for: .milliseconds(100))
        return 2
      }
    )
    let asyncStream = producer.makeAsyncStream()
    var iterator = asyncStream.makeAsyncIterator()

    let first = await iterator.next()
    XCTAssertEqual(first, 1)

    let second = await iterator.next()
    XCTAssertEqual(second, 2)
  }

  func testSetValuesAreEmitted() async {
    let producer = AsyncStreamProducer<Int>()
    let asyncStream = producer.makeAsyncStream()
    var iterator = asyncStream.makeAsyncIterator()

    producer.setCurrentValue(10)
    let first = await iterator.next()
    XCTAssertEqual(first, 10)

    producer.setCurrentValue(20)
    let second = await iterator.next()
    XCTAssertEqual(second, 20)
  }

  func testBroadcastToMultipleStreams() async {
    let producer = AsyncStreamProducer<Int>()

    let firstStream = producer.makeAsyncStream()
    var firstIterator = firstStream.makeAsyncIterator()

    let secondStream = producer.makeAsyncStream()
    var secondIterator = secondStream.makeAsyncIterator()

    producer.setCurrentValue(100)
    let valueFromFirstStream = await firstIterator.next()
    let valueFromSecondStream = await secondIterator.next()

    XCTAssertEqual(valueFromFirstStream, 100)
    XCTAssertEqual(valueFromSecondStream, 100)
  }
}
