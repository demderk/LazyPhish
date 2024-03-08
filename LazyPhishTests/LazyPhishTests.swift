//
//  LazyPhishTests.swift
//  LazyPhishTests
//
//  Created by Roman Zheglov on 04.03.2024.
//

import XCTest
@testable import LazyPhish

final class LazyPhishTests: XCTestCase {

    func testIPModeIPv4() throws {
        let urli = URLInfo(URL(string: "http://127.0.0.1")!)
                
        XCTAssertEqual(urli.isIP, .ip)
    }
    
    func testIPModeIPv4Extra() throws {
        let urli = URLInfo(URL(string: "http://127.0.0.1/31/fasf/tt.php")!)
        XCTAssertEqual(urli.isIP, .ip)
    }
    
    func testIPModeIPv4HEX() throws {
        let urli = URLInfo(URL(string: "http://0xc0a80001")!)
                
        XCTAssertEqual(urli.isIP, .ip)
    }
    
    func testIPModeIPv4HEXExtra() throws {
        let urli = URLInfo(URL(string: "http://0xc0a80001/31/fasf/tt.php")!)
        XCTAssertEqual(urli.isIP, .ip)
    }
    
//    func testIPModeIPv4HEXDivided() throws {
//        let urli = URLInfo(URL(string: "http://0xc0.0xa8.0x00.0x01")!)
//                
//        XCTAssertEqual(urli.isIP, .ip)
//    }
//    
//    func testIPModeIPv4HEXDividedExtra() throws {
//        let urli = URLInfo(URL(string: "http://0xc0.0xa8.0x00.0x01")!)
//        XCTAssertEqual(urli.isIP, .ip)
//    }
    

}
