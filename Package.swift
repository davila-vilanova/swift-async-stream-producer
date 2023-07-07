// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "swift-async-stream-producer",
  platforms: [
    .iOS(.v14),
    .macOS(.v10_15),
  ],
  products: [
    .library( // vend shareable code as a library product
      name: "AsyncStreamProducer",
      targets: ["AsyncStreamProducer"]),
  ],
  targets: [
    .target( // compile sources to binary products
      name: "AsyncStreamProducer",
      dependencies: []),
    .testTarget( // compile sources to test binary products
      name: "AsyncStreamProducerTests",
      dependencies: ["AsyncStreamProducer"]),
  ]
)
