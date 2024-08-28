//
//  File.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 28.08.2024.
//

import Foundation

protocol PhishingPipelineObject {
    func execute(data: StrictRemote) async -> StrictRemote
}

protocol PhishingArrayPipelineObject: PhishingPipelineObject {
    func executeAll(data: [StrictRemote]) async -> [StrictRemote]
}
