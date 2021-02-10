import Combine
import XCTest

class TestingCombineExamples: XCTestCase {

    func testDumb() {
        XCTAssertTrue(true)
    }
}

class TestObserver: NSObject, XCTestObservation {
    func testCaseDidFinish(_ testCase: XCTestCase) {
        print("✅")
    }

    func testCase(_ testCase: XCTestCase, didRecord issue: XCTIssueReference) {
        // I'm getting an ambiguous expression error when trying to coalesce the optional and I
        // don't understand why. Using an `if let` for the moment™
        if let line = issue.sourceCodeContext.location?.lineNumber {
            print("❌ Tests failed at line \(line) with:\n\t\(issue.description)")
            assertionFailure(issue.description, line: UInt(line))
        } else {
            print("❌ Tests failed with:\n\t\(issue.description)")
            assertionFailure(issue.description)
        }
    }
}

let testObserver = TestObserver()
XCTestObservationCenter.shared.addTestObserver(testObserver)

let testSuite = TestingCombineExamples.defaultTestSuite
testSuite.run()
_ = testSuite.testRun as! XCTestSuiteRun
