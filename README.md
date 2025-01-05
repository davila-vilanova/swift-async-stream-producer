# swift-async-stream-producer

A micro-framework for Swift that facilitates single producer - multiple consumer async streams of values.

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
    .package(url: "git@github.com:glooko/swift-async-stream-producer.git", "1.2.0"..<"1.3.0"),
```

And then add the product to any targets that will use it:

```swift
.product(name: "AsyncStreamProducer", package: "swift-async-stream-producer"),
```

Don't forget to `import AsyncStreamProducer` in any files that use it.

## Usage

Say there's a part of your system that produces values asynchronously and another or several other parts that consumes them. You want to connect them with an async stream. This framework provides a `AsyncStreamProducer` class that you can use to create one or multiple `AsyncStream` instances that can be consumed by multiple consumers.

Your producer code can instantiate an `AsyncStreamProducer` like this:

```swift
let streamProducer = AsyncStreamProducer<Int>()
```

then expose async streams to any consumers that need it:

```swift
var output: AsyncStream<Int> {
  get {
    streamProducer.makeAsyncStream()
  }
}
```

and then produce values asynchronously:

```swift
streamProducer.setCurrentValue(24)
```

Consumers can then consume the async streams normally:

```swift
let stream = producer.output
for await value in stream {
  print(value) // prints 24
}
```
