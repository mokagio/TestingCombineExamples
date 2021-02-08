import Combine
import XCTest

class TestingCombineExamples: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    /*
     Possible scenarios:

     values \ completion    | failure   | finished  | unknown
     ---------------------------------------------------------
     no value               | 1         | 2         | 3
     at least one value     | 4         | 5         | 6
     exactly one value      | 7         | 8         | 9
     many values            | 10        | 11        | 12
     unknown                | 13        | 14        | n.a.

     */

    // 1
    func testPublishesOnlyFailure() {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(completion: .failure(.errorCase1))
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Fails without publishing values")

        publisher
            .sink(
                receiveCompletion: { completion in
                    guard case .failure(let error) = completion else { return }
                    XCTAssertEqual(error, .errorCase1)
                    expectation.fulfill()
                },
                receiveValue: {
                    XCTFail("Expected to fail without receiving any value, got \($0)")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)
    }

    // 2
    func testFinishesWithoutPublishingValues() {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(completion: .finished)
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Finishes without publishing values")

        publisher
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else { return }
                    expectation.fulfill()
                },
                receiveValue: {
                    XCTFail("Expected to finish without receiving any value, got \($0)")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)
    }

    // 3
    func testCompletesWithoutPublishingValues() {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            // For this test, it doesn't matter which completion we send here.
            subject.send(completion: .finished)
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "First published value is <# value #>")

        publisher
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: {
                    XCTFail("Expected to complete with no value, got \($0)")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)
    }

    // 4
    func testPublishesAtLeastOneValueThenFails() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(completion: .failure(.errorCase1))
        }

        let publisher = subject.eraseToAnyPublisher()
        var receivedValue: Int?

        let expectation = XCTestExpectation(
            description: "Publishes only once with value <# value #> then fails with <# error #>"
        )

        publisher
            .sink(
                receiveCompletion: { completion in
                    guard case .failure(let error) = completion else { return }
                    XCTAssertEqual(error, .errorCase1)
                    expectation.fulfill()
                },
                receiveValue: { value in
                    guard receivedValue == .none else {
                        return XCTFail("Expected to receive only one value, got another (\(value))")
                    }
                    XCTAssertEqual(value, 1)
                    receivedValue = value
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)
    }

    // 5
    func testPublishesAtLeastOneValueThenFinishes() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(completion: .finished)
        }

        let publisher = subject.eraseToAnyPublisher()
        var values: [Int] = []

        let expectation = XCTestExpectation(
            description: "Publishes once with value <# value #> then finishes"
        )

        publisher
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else { return }
                    expectation.fulfill()
                },
                receiveValue: { value in
                    guard values.isEmpty else {
                        return XCTFail("Expected to receive only one value, got another (\(value))")
                    }
                    XCTAssertEqual(value, 1)
                    values.append(value)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)
    }

    // 5 - Alternative
    // Instead of failing as soon as we get the value, we can collect all of them so the failure
    // message can better show the entire behavior of the Publisher.
    func testPublishesAtLeastOneValueThenFinishes_Alternative() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(42)
            subject.send(completion: .finished)
        }

        let publisher = subject.eraseToAnyPublisher()
        var values: [Int] = []

        let expectation = XCTestExpectation(
            description: "Publishes once with value <# value #> then finishes"
        )

        publisher
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else { return }
                    expectation.fulfill()
                },
                receiveValue: { value in
                    values.append(value)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual(values.count, 1) // Should only have one value
        XCTAssertEqual(values.first, 42)
    }

    // 6
    func testFirstPublishedValue() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(completion: .finished)
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "First published value is <# value #>")

        publisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: {
                    XCTAssertEqual($0, 1)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)
    }

    func testPublishesOnlyOneValue() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(completion: .finished)
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Publishes only once with value <# value #>")

        publisher
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else { return }
                    expectation.fulfill()
                },
                receiveValue: {
                    XCTAssertEqual($0, 1)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)
    }


    // 8
    func testPublishesManyValues() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .finished)
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Publishes many values")

        var values: [Int] = []

        publisher
            .sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else { return }
                    expectation.fulfill()
                },
                receiveValue: {
                    values.append($0)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual([1,2,3], values)
    }

    // 10
    func testEventuallyPublishesAFailure() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .failure(.errorCase1))
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Eventually publishes a failure")

        publisher
            .sink(
                receiveCompletion: { completion in
                    guard case .failure(let error) = completion else { return }
                    XCTAssertEqual(.errorCase1, error)
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)
    }

    // 7
    // Similar to the previous one, but now we're interested in the published values, too.
    func testPublishesSomeValuesThenFails() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .failure(.errorCase2))
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Publishes values then a failure")

        var values: [Int] = []

        publisher.sink(
            receiveCompletion: { completion in
                guard case .failure(let error) = completion else { return }
                XCTAssertEqual(.errorCase2, error)
                expectation.fulfill()
            },
            receiveValue: {
                values.append($0)
            }
        )
        .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual([1,2,3], values)
    }

    // The difference here is that we use an array of `Result` to collect all the values and then
    // run an equality assertion on that. It only works if both `Output` and `Failure` conform to
    // `Equatable`
    func testPublishesSomeValuesThenFails_Alternative() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .failure(.errorCase2))
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Publishes values then a failure")

        var values: [Result<Int, TestError>] = []

        publisher
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error): values.append(.failure(error))
                    case .finished: break
                    }
                    expectation.fulfill()
                },
                receiveValue: {
                    values.append(.success($0))
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)

        let expectedValues: [Result<Int, TestError>] = [
            .success(1), .success(2), .success(3), .failure(.errorCase2)
        ]
        XCTAssertEqual(expectedValues, values)
    }
}
