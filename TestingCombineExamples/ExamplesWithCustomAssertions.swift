import Combine
import XCTest

class TestingCombineExamplesWithCustomAssertions: XCTestCase {

    func testReceivesSomeValuesThenFails() throws {
        let subject = PassthroughSubject<Int, TestError>()
        asyncAfter(0.1) {
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .failure(.errorCase2))
        }

        let publisher = subject.eraseToAnyPublisher()

        let expectedValues: [Result<Int, TestError>] = [
            .success(1), .success(2), .success(3), .failure(.errorCase2)
        ]

        assert(publisher, eventuallyPublishes: expectedValues)
    }
}
