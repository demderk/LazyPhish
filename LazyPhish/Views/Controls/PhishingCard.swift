//
//  PhishingCard.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 29.08.2024.
//

import SwiftUI
import WrappingHStack

struct PhishingCard: View {
    @Binding var request: RemoteRequest!
    @Binding var bussy: Bool
    @State var MLTag: ModuleTag?
    
    var body: some View {
        VStack {
            VStack {
                if bussy {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(
                            CGSize(width: 0.6, height: 0.6))
                        .frame(width: 17, height: 17)
                        .padding([.horizontal], 24)
                        .padding([.vertical], 23)
                    HStack {
                        Spacer()
                    }
                } else {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Summary")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                Spacer().frame(width: 8)
                            }

                            WrappingHStack(getTags(), id: \.self) { tag in
                                tag
                            }.frame(minWidth: 512, minHeight: 64)
                        }.padding(16)
                        //                                Spacer()
                    }
                }
            }
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 16, height: 16)))
        }
    }

    func getTags() -> [TagView] {
        var result: [TagView] = []
        for module in request.modules.compactMap({ $0 as? ModuleTagBehavior }) {
            for tag in module.tags {
                var current: ModuleTag = tag
                switch tag.risk {
                case .unknown:
                    current.tagPriority -= 1000
                case .common:
                    current.tagPriority += 0
                case .suspicious:
                    current.tagPriority += 1000
                case .danger:
                    current.tagPriority += 2000
                }
                result.append(TagView(tag: current))
            }
        }
        result.sort(by: {
            $0.tag.tagPriority > $1.tag.tagPriority
        })
        return result
    }
    
    func getMLTag() -> ModuleTag? {
        if let tag = MLTag {
            return tag
        } else {
            for module in request.modules where module is MLModule {
                if let tag = module as? ModuleTagBehavior,
                   let text = tag.tags.first
                {
                    return text
                }
            }
        }
        return nil
    }
}
