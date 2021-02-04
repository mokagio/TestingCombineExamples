import Combine
import XCTest

class TestingCombineExamples: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    func testReceivesOneValue() throws {
        let publisher = PassthroughSubject<Int, TestError>()

        let expectation = XCTestExpectation(description: "Receives one value")

        publisher.sink(
            receiveCompletion: { _ in },
            receiveValue: {
                XCTAssertEqual($0, 1)
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)

        publisher.send(1)

        wait(for: [expectation], timeout: 0.5)
    }

    func testReceivesManyValues() throws {
        let publisher = PassthroughSubject<Int, TestError>()

        let expectation = XCTestExpectation(description: "Receives values in order")

        var values: [Int] = []

        publisher.sink(
            receiveCompletion: { completion in
                guard case .finished = completion else { return }
                expectation.fulfill()
            },
            receiveValue: {
                values.append($0)
            }
        )
        .store(in: &cancellables)

        publisher.send(1)
        publisher.send(2)
        publisher.send(3)
        publisher.send(completion: .finished)

        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual([1,2,3], values)
    }

    func testReceivesError() throws {
        let publisher = PassthroughSubject<Int, TestError>()

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

        publisher.send(completion: .failure(.errorCase1))

        wait(for: [expectation], timeout: 0.5)
    }

    func testReceivesSomeValuesThenFails() throws {
        let publisher = PassthroughSubject<Int, TestError>()

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

        publisher.send(1)
        publisher.send(2)
        publisher.send(3)
        publisher.send(completion: .failure(.errorCase2))

        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual([1,2,3], values)
    }

    func testReceivesSomeValuesThenFails_Alternative() throws {
        let publisher = PassthroughSubject<Int, TestError>()

        let expectation = XCTestExpectation(description: "Receives values in order")

        var values: [Result<Int, TestError>] = []

        publisher.sink(
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

        publisher.send(1)
        publisher.send(2)
        publisher.send(3)
        publisher.send(completion: .failure(.errorCase2))

        wait(for: [expectation], timeout: 0.5)

        let expectedValues: [Result<Int, TestError>] = [
            .success(1),
            .success(2),
            .success(3),
            .failure(.errorCase2)
        ]
        XCTAssertEqual(expectedValues, values)
    }

    func testReceivesSomeValuesThenFails_Alternative2() throws {
        let subject = PassthroughSubject<Int, TestError>()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .failure(.errorCase2))
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectation = XCTestExpectation(description: "Receives values in order")

        var values: [Result<Int, TestError>] = []

        publisher.sink(
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
            .success(1),
            .success(2),
            .success(3),
            .failure(.errorCase2)
        ]
        XCTAssertEqual(expectedValues, values)
    }
}

enum TestError: Equatable, Error {
    case errorCase1
    case errorCase2
}
