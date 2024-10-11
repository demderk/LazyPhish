//
//  DependencyCollection.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 09.10.2024.
//

actor DependencyCollection {
    private var dependencyModules: [any RequestModule] = []
      
    init () {
        
    }
    
    init(_ dependencyModules: [any RequestModule]) {
        self.dependencyModules = dependencyModules
    }
    
    var collection: [any RequestModule] {
        get { dependencyModules }
    }
    
    nonisolated func pushDependencyInsecure(_ dep: any RequestModule) {
        Task {
            await pushDependency(dep)
        }
    }
    
    func pushDependency(_ dep: any RequestModule) {
        dependencyModules.append(dep)
    }
    
    func pushDependency(_ contentsOf: [any RequestModule]) {
        dependencyModules.append(contentsOf: contentsOf)
    }
    
    func pushDependency(_ dependency: DependencyCollection) async {
        await dependencyModules.append(contentsOf: dependency.collection)
    }
    
    func getDependency<T: RequestModule>(module: T.Type) -> RequestModule? {
        return dependencyModules.first(where: {type(of: $0) == module})
    }
    
    func getDependencyIndex(module: RequestModule.Type) -> Int? {
        return dependencyModules.firstIndex(where: {type(of: $0) == module})
    }
    
    func getDependency(module: any RequestModule) -> RequestModule? {
        return dependencyModules.first(where: {type(of: $0) == type(of: module)})
    }
    
    func getDependencyIndex(module: any RequestModule) -> Int? {
        return dependencyModules.firstIndex(where: {type(of: $0) == type(of: module)})
    }
    
    @discardableResult
    func putDependency(oldModule: RequestModule, newModule: RequestModule) -> Bool {
        if let foundIndex = getDependencyIndex(module: oldModule) {
            dependencyModules[foundIndex] = newModule
            return true
        } else {
            return false
        }
    }
    
    subscript(index: Int) -> RequestModule {
        get {
            dependencyModules[index]
        }
        set {
            dependencyModules[index] = newValue
        }
    }
    
    subscript(module: RequestModule) -> RequestModule? {
        if let foundIndex = getDependencyIndex(module: module) {
            return dependencyModules[foundIndex]
        } else {
            return nil
        }
    }
}
