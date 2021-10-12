//
//  File.swift
//  CombinePracticeTests
//
//  Created by Ashraf Uddin on 1/7/21.
//

import XCTest
@testable import CombinePractice

class ViewControllerTest: XCTest {
    
    var test: String?
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        
        test = "OK"
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        test = nil
        try super.tearDownWithError()
    }
    
}
