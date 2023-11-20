import Foundation

/// Produces `AsyncStream`s of values of type `Element`.
///
/// Each call to `makeAsyncStream` will produce a new stream whose initial value
/// is the current value of this producer, and whose subsequent values are
/// produced by calling `setValue` on this producer.
//
// This is an actor instead of a struct because `continuation.onTermination` will
// mutate its internal state asynchronously, which seems not allowed for a value type.
public actor AsyncStreamProducer<Element: Sendable> {
  /// Creates a new `AsyncStreamProducer`.
  ///
  /// - Parameters:
  ///   - initialValue: Optionally, the initial value of the stream.
  ///   - nextValue: Optionally, a closure that will be called to produce the
  ///     first value of the stream, if `initialValue` is not provided, or
  ///     otherwise the second value of the stream.
  public init(
    initialValue: Element? = nil,
    nextValue: (@Sendable () async -> Element)? = nil
  ) {
    self.currentValue = initialValue
    if let nextValueProducer = nextValue {
      Task {
        setCurrentValue(await nextValueProducer())
      }
    }
  }

  /// Creates a new `AsyncStreamProducer` whose values are produced whenever
  /// `setValue` is called with a new value.
  ///
  /// If this producer has currently a value, that will be the first value of
  /// the stream.
  ///
  /// - Returns: An `AsyncStreamProducer` that produces values of type `Element`.
  public nonisolated func makeAsyncStream() -> AsyncStream<Element> {
    AsyncStream { continuation in
      let listener = ValueListener {
        continuation.yield($0)
      }
      Task {
        await addListener(listener)
      }
      continuation.onTermination = { @Sendable [weak self] _ in
        Task { [self] in
          await self?.removeListener(listener)
        }
      }
    }
  }

  /// Sets a value in this producer, and sends that value via any currently
  /// active streams.
  public nonisolated func setCurrentValue(_ newValue: Element) {
    Task {
      await _setCurrentValue(newValue)
      await valueListeners.forEach { $0.onValue(newValue) }
    }
  }

  /// The current value of this producer.
  public private(set) var currentValue: Element?

  /// Sets the current value privately, without notifying any streams.
  ///
  /// Use to set the value from a private but non-isolated context.
  private func _setCurrentValue(_ value: Element) {
    currentValue = value
  }

  /// The listeners that are currently active, which belong to the streams that
  /// have been produced and are currently active.
  private var valueListeners: Set<ValueListener<Element>> = []

  /// Adds a listener to this producer.
  private func addListener(_ listener: ValueListener<Element>) {
    valueListeners.insert(listener)
    if let value = currentValue {
      listener.onValue(value)
    }
  }

  /// Removes a listener from this producer.
  private func removeListener(_ listener: ValueListener<Element>) {
    valueListeners.remove(listener)
  }
}

extension AsyncStreamProducer where Element == Void {
  /// Notifies any active streams that a new event has occurred.
  func notifyOfNewEvent() {
    setCurrentValue(())
  }
}

/// A listener for a value of type `T` that can be equated for easy removal.
private struct ValueListener<T>: Hashable, Sendable {
  /// A UUID is what makes this listener equatable.
  let uuid = UUID()

  /// The actual listener closure.
  let onValue: @Sendable (T) -> Void

  /// Creates a new `ValueListener`.
  ///
  /// - Parameters:
  ///   - onValue: The closure that will be called when a new value is available.
  init(onValue: @escaping @Sendable (T) -> Void) {
    self.onValue = onValue
  }

  static func == (lhs: ValueListener, rhs: ValueListener) -> Bool {
    lhs.uuid == rhs.uuid
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }
}
