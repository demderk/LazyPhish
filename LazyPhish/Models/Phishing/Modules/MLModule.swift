//
//  MLModule.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 09.10.2024.
//

import Foundation

class MLModule: RequestModule {
    var dependences: DependencyCollection = DependencyCollection([
        OPRModule(),
        SQIModule()
    ])
    
    var status: ModuleStatus = .planned
    
    func execute(remote: RequestInfo) async {
        print(await dependences[0].status)
        print(await dependences[1].status)
    }
    
}
