//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://www.jessesquires.com/JSQCoreDataKit
//
//
//  GitHub
//  https://github.com/jessesquires/JSQCoreDataKit
//
//
//  License
//  Copyright © 2015 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

import XCTest
import CoreData

import ExampleModel

@testable
import JSQCoreDataKit


class SaveTests: TestCase {

    func test_ThatSaveAndWait_WithoutChanges_CompletionHandlerIsNotCalled() {
        // GIVEN: a stack and context without changes
        let stack = self.inMemoryStack
        var didCallCompletion = false

        // WHEN: we attempt to save the context

        // THEN: the save operation is ignored
        saveContext(stack.mainContext) { result in
            didCallCompletion = true
        }

        XCTAssertFalse(didCallCompletion, "Save should be ignored")
    }

    func test_ThatSaveAndWait_WithChangesSucceeds_CompletionHandlerIsCalled() {
        // GIVEN: a stack and context with changes
        let stack = self.inMemoryStack

        generateCompaniesInContext(stack.mainContext, count: 3)

        var didSaveMain = false
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: stack.mainContext) { (notification) -> Bool in
            didSaveMain = true
            return true
        }

        var didUpdateBackground = false
        expectationForNotification(NSManagedObjectContextObjectsDidChangeNotification, object: stack.backgroundContext) { (notification) -> Bool in
            didUpdateBackground = true
            return true
        }

        let saveExpectation = expectationWithDescription("\(#function)")

        // WHEN: we attempt to save the context
        saveContext(stack.mainContext, wait: true) { result in

            // THEN: the save succeeds without an error
            XCTAssertTrue(result == .success, "Save should not error")
            saveExpectation.fulfill()
        }

        // THEN: then the main and background contexts are saved and the completion handler is called
        waitForExpectationsWithTimeout(DefaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveMain, "Main context should be saved")
            XCTAssertTrue(didUpdateBackground, "Background context should be updated")
        })
    }

    func test_ThatSaveAndWait_WithChanges_WithoutCompletionClosure_Succeeds() {
        // GIVEN: a stack and context with changes
        let stack = self.inMemoryStack

        generateCompaniesInContext(stack.mainContext, count: 3)

        var didSaveMain = false
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: stack.mainContext) { (notification) -> Bool in
            didSaveMain = true
            return true
        }

        var didUpdateBackground = false
        expectationForNotification(NSManagedObjectContextObjectsDidChangeNotification, object: stack.backgroundContext) { (notification) -> Bool in
            didUpdateBackground = true
            return true
        }

        // WHEN: we attempt to save the context

        // THEN: the save succeeds without an error
        saveContext(stack.mainContext)

        // THEN: then the main and background contexts are saved
        waitForExpectationsWithTimeout(DefaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveMain, "Main context should be saved")
            XCTAssertTrue(didUpdateBackground, "Background context should be updated")
        })
    }

    func test_ThatSaveAsync_WithoutChanges_ReturnsImmediately() {
        // GIVEN: a stack and context without changes
        let stack = self.inMemoryStack
        var didCallCompletion = false

        // WHEN: we attempt to save the context asynchronously
        saveContext(stack.mainContext, wait: false) { result in
            didCallCompletion = true
        }

        // THEN: the save operation is ignored
        XCTAssertFalse(didCallCompletion, "Save should be ignored")
    }

    func test_ThatSaveAsync_WithChanges_Succeeds() {
        // GIVEN: a stack and context with changes
        let stack = self.inMemoryStack

        generateCompaniesInContext(stack.mainContext, count: 3)

        var didSaveMain = false
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: stack.mainContext) { (notification) -> Bool in
            didSaveMain = true
            return true
        }

        var didUpdateBackground = false
        expectationForNotification(NSManagedObjectContextObjectsDidChangeNotification, object: stack.backgroundContext) { (notification) -> Bool in
            didUpdateBackground = true
            return true
        }

        let saveExpectation = expectationWithDescription("\(#function)")

        // WHEN: we attempt to save the context asynchronously
        saveContext(stack.mainContext, wait: false) { result in

            // THEN: the save succeeds without an error
            XCTAssertTrue(result == .success, "Save should not error")
            saveExpectation.fulfill()
        }

        // THEN: then the main and background contexts are saved and the completion handler is called
        waitForExpectationsWithTimeout(DefaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveMain, "Main context should be saved")
            XCTAssertTrue(didUpdateBackground, "Background context should be updated")
        })
    }

    func test_ThatSavingChildContext_SucceedsAndSavesParentMainContext() {
        // GIVEN: a stack and child context with changes
        let stack = self.inMemoryStack
        let childContext = stack.childContext(concurrencyType: .MainQueueConcurrencyType)

        generateCompaniesInContext(childContext, count: 3)

        var didSaveChild = false
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: childContext) { (notification) -> Bool in
            didSaveChild = true
            return true
        }

        var didSaveMain = false
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: stack.mainContext) { (notification) -> Bool in
            didSaveMain = true
            return true
        }

        var didUpdateBackground = false
        expectationForNotification(NSManagedObjectContextObjectsDidChangeNotification, object: stack.backgroundContext) { (notification) -> Bool in
            didUpdateBackground = true
            return true
        }

        let saveExpectation = expectationWithDescription("\(#function)")

        // WHEN: we attempt to save the context
        saveContext(childContext) { result in

            // THEN: the save succeeds without an error
            XCTAssertTrue(result == .success, "Save should not error")
            saveExpectation.fulfill()
        }

        // THEN: then all contexts are saved, synchronized and the completion handler is called
        waitForExpectationsWithTimeout(DefaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveChild, "Child context should be saved")
            XCTAssertTrue(didSaveMain, "Main context should be saved")
            XCTAssertTrue(didUpdateBackground, "Background context should be updated")
        })
    }

    func test_ThatSavingChildContext_SucceedsAndSavesParentBackgroundContext() {
        // GIVEN: a stack and child context with changes
        let stack = self.inMemoryStack
        let childContext = stack.childContext(concurrencyType: .PrivateQueueConcurrencyType)

        generateCompaniesInContext(childContext, count: 3)

        var didSaveChild = false
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: childContext) { (notification) -> Bool in
            didSaveChild = true
            return true
        }

        var didSaveBackground = false
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: stack.backgroundContext) { (notification) -> Bool in
            didSaveBackground = true
            return true
        }

        var didUpdateMain = false
        expectationForNotification(NSManagedObjectContextObjectsDidChangeNotification, object: stack.mainContext) { (notification) -> Bool in
            didUpdateMain = true
            return true
        }

        let saveExpectation = expectationWithDescription("\(#function)")

        // WHEN: we attempt to save the context
        saveContext(childContext) { result in

            // THEN: the save succeeds without an error
            XCTAssertTrue(result == .success, "Save should not error")
            saveExpectation.fulfill()
        }

        // THEN: then all contexts are saved, synchronized and the completion handler is called
        waitForExpectationsWithTimeout(DefaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveChild, "Child context should be saved")
            XCTAssertTrue(didSaveBackground, "Background context should be saved")
            XCTAssertTrue(didUpdateMain, "Main context should be updated")
        })
    }

    func test_ThatSavingBackgroundContext_SucceedsAndUpdateMainContext() {
        // GIVEN: a stack and context with changes
        let stack = self.inMemoryStack

        generateCompaniesInContext(stack.backgroundContext, count: 3)

        var didSaveBackground = false
        expectationForNotification(NSManagedObjectContextDidSaveNotification, object: stack.backgroundContext) { (notification) -> Bool in
            didSaveBackground = true
            return true
        }

        var didUpdateMain = false
        expectationForNotification(NSManagedObjectContextObjectsDidChangeNotification, object: stack.mainContext) { (notification) -> Bool in
            didUpdateMain = true
            return true
        }

        let saveExpectation = expectationWithDescription("\(#function)")

        // WHEN: we attempt to save the context asynchronously
        saveContext(stack.backgroundContext, wait: false) { result in

            // THEN: the save succeeds without an error
            XCTAssertTrue(result == .success, "Save should not error")
            saveExpectation.fulfill()
        }

        // THEN: then the main and background contexts are saved and the completion handler is called
        waitForExpectationsWithTimeout(DefaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
            XCTAssertTrue(didSaveBackground, "Background context should be saved")
            XCTAssertTrue(didUpdateMain, "Main context should be updated")
        })
    }
    
}
