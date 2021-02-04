import Combine
import XCTest

class TestingCombineExamples: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    func testFirstReceivedValue() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(completion: .finished)
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Receives one value")

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

    func testReceivesOnlyOneValue() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(completion: .finished)
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Receives one value")

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

    func testReceivesManyValues() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .finished)
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Receives values in order")

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

    func testEventuallyReceivesError() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .failure(.errorCase1))
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Receives an error")

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

    func testOnlyReceivesError() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(completion: .failure(.errorCase1))
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Receives an error")

        publisher
            .sink(
                receiveCompletion: { completion in
                    guard case .failure(let error) = completion else { return }
                    XCTAssertEqual(.errorCase1, error)
                    expectation.fulfill()
                },
                receiveValue: {
                    XCTFail("Expected to only receive error, got \($0)")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)
    }


    func testReceivesSomeValuesThenFails() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .failure(.errorCase2))
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Receives values in order")

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
    func testReceivesSomeValuesThenFails_Alternative() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .failure(.errorCase2))
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Receives values in order")

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
