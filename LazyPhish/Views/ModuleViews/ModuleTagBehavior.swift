//
//  ModuleTagBehavior.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 26.09.2024.
//

enum ModulePriority: Int {
    case unknown = 0
    case whois = 99
    case opr = 3
    case sqi = 2
    case regex = 1

    static func getModulePriority(module: ModuleTagBehavior) -> ModulePriority {
        switch module {
        case is OPRModule:      return self.opr
        case is WhoisModule:    return self.whois
        case is SQIModule:      return self.sqi
        case is RegexModule:    return self.regex
        default:                return self.unknown
        }
    }

    func rawWithTag(tagPriotiry: Int) -> Int {
        return self.rawValue * 10 + tagPriotiry
    }
}

protocol ModuleTagBehavior {
    var modulePriority: ModulePriority { get }
    var tags: [ModuleTag] { get }
    var tagViews: [TagView] { get }
}

extension ModuleTagBehavior {
    var modulePriority: ModulePriority { ModulePriority.getModulePriority(module: self) }
    var tagViews: [TagView] {
        var result: [TagView] = []
        for tag in tags {
            result.append(TagView(tag: tag))
        }
        return result
    }
}
