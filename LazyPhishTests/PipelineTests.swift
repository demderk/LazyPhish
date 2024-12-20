//
//  LazyPhishTests.swift
//  LazyPhishTests
//
//  Created by Roman Zheglov on 20.12.2024.
//

import Testing
@testable import LazyPhish
import Foundation

class DependencyMockModuleChild: RequestModule {
    init(str: String) {
        self.str = str
    }
    
    init () { }
    
    var str: String = "no"
    var executed: Bool = false
    var uuid = UUID()
    var dependences: LazyPhish.DependencyCollection = DependencyCollection()
    var status: LazyPhish.RemoteJobStatus = .planned
    
    func execute(remote: LazyPhish.RemoteRequest) async {
        status = .executing
        
        executed = true
        
        status = .completed
    }
}

class DependencyMockModuleParent: RequestModule {
    var dependences: LazyPhish.DependencyCollection = DependencyCollection([
        DependencyMockModuleChild()
    ])
    
    var executed: Bool = false
    var childCount: Int = 0
    var status: LazyPhish.RemoteJobStatus = .planned
    
    func execute(remote: LazyPhish.RemoteRequest) async {
        status = .executing
        
        let child = await dependences.getDependency(module: DependencyMockModuleChild.self)
        executed = true
        
        status = .completed
    }
}

enum MockModuleError : ModuleError {
    case anyError
}

class ModuleStatusMock: RequestModule {
    var executed: Bool = false
    var dependences: LazyPhish.DependencyCollection = DependencyCollection()
    var status: LazyPhish.RemoteJobStatus = .executing
    
    let setStatus: RemoteJobStatus
    
    init(_ status: RemoteJobStatus) {
        setStatus = status
    }
    
    func execute(remote: LazyPhish.RemoteRequest) async {
        executed = true
        status = setStatus
    }
}

@Suite("Pipeline Testing")
struct LazyPhishTests {

    @Test("Dependency Neighbours Barrier")
    func dependencyInjectionNoNeighbours() async throws {
        var remoteRequest = RemoteRequest(url: try .init(url: "https://google.com"))
        remoteRequest.addModule(DependencyMockModuleChild(str: "testing"))
        remoteRequest.addModule(DependencyMockModuleParent())
        
        await remoteRequest.executeAll()
        
        let parent = remoteRequest.modules.first(where: { $0 is DependencyMockModuleParent }) as? DependencyMockModuleParent
        let child = await parent?.dependences.getDependency(module: DependencyMockModuleChild.self)
        
        #expect(child!.str == "no")
        #expect(child!.executed == true)
        #expect(child!.status.isCompleted)
        #expect(parent!.executed == true)
        #expect(parent!.status.isCompleted)
    }
    
    @Test("Dependency Injection")
    func dependencyInjection() async throws {
        var remoteRequest = RemoteRequest(url: try .init(url: "https://google.com"))
        await remoteRequest.forcePushDependency(DependencyMockModuleChild(str: "testing"))
        remoteRequest.addModule(DependencyMockModuleParent())
        
        await remoteRequest.executeAll()
        
        let parent = remoteRequest.modules.first(where: { $0 is DependencyMockModuleParent }) as? DependencyMockModuleParent
        let child = await parent?.dependences.getDependency(module: DependencyMockModuleChild.self)
        
        #expect(child!.str == "testing")
        #expect(child!.executed == true)
        #expect(child!.status.isCompleted)
        #expect(parent!.executed == true)
        #expect(parent!.status.isCompleted)
    }
    
    @Test("Failed Module Is Failed Request")
    func failedModuleIsFailedRequest() async throws {
        var remoteRequest = RemoteRequest(url: try .init(url: "https://google.com"))
        remoteRequest.addModule(ModuleStatusMock(.failed(MockModuleError.anyError)))
        await remoteRequest.executeAll()
        
        
        
        var correctError = false
        if case .failed(let error as RemoteRequestError) = remoteRequest.status,
            case .anyModulesFailed(collection: let innerErrorCollection) = error,
           innerErrorCollection.contains(where: { ($0 as? MockModuleError) == .anyError }){
            correctError = true
        }
        
        #expect(correctError)
        #expect(remoteRequest.status.isFinished == false)
        #expect(remoteRequest.status.isFailed)
        #expect(remoteRequest.status.completedWithErrors == false)
        #expect(remoteRequest.status.isCompleted == false)
        
    }
    
    @Test("Warned Module Is Warned Request")
    func WariningModuleIsWarningRequest() async throws {
        var remoteRequest = RemoteRequest(url: try .init(url: "https://google.com"))
        remoteRequest.addModule(ModuleStatusMock(.completedWithErrors([MockModuleError.anyError])))
        await remoteRequest.executeAll()
        
        var correctError = false
        if case .completedWithErrors(let innerErrorCollection) = remoteRequest.status,
           innerErrorCollection!.contains(where: { ($0 as? MockModuleError) == .anyError }){
            correctError = true
        }
        
        #expect(correctError)
        #expect(remoteRequest.status.isFinished == true)
        #expect(remoteRequest.status.isFailed == false)
        #expect(remoteRequest.status.completedWithErrors == true)
        #expect(remoteRequest.status.isCompleted == false)

    }
    
}
