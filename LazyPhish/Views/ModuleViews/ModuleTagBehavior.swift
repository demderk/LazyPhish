//
//  ModuleTagBehavior.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 26.09.2024.
//

protocol ModuleTagBehavior {
    var tags: [ModuleTag] { get }
    var tagViews: [TagView] { get }
}

extension ModuleTagBehavior {
    var tagViews: [TagView] {
        var result: [TagView] = []
        for tag in tags {
            result.append(TagView(tag: tag))
        }
        return result
    }
}
