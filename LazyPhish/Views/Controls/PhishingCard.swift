//
//  PhishingCard.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 29.08.2024.
//

import SwiftUI
import WrappingHStack

struct PhishingCard: View {
    @Binding var request: PhishInfo!
    @Binding var bussy: Bool
    @State var tagList: [MetricData] = []
    
    var legitPercent: (percent: Int, risk: RiskLevel) {
        let predictML = try! PhishML()
        let mlResult = predictML.predictPhishing(input: request.getMLEntry()!)
        if let prob = mlResult.IsPhishingProbability.first(where: { $0.key == 0 })?.value {
            let percent = Int(prob * 100)
            let risk: RiskLevel = 100 - percent > 80 ? .danger : (100 - percent > 50 ? .suspicious : .common)
            return (percent, risk)
        }
        return (-1, .danger)
    }
    
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
                                HStack {
                                    Text("AI Trust")
                                    Divider()
                                    Text("􀫸  \(legitPercent.percent)%")
                                        .offset(CGSize(width: 0, height: -1))
                                }.fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .padding(4)
                                    .padding(.horizontal, 4)
                                    .background(legitPercent.risk.getColor())
                                    .clipShape(.capsule)
                            }
                            
                            WrappingHStack(getTags(), id: \.self) { tag in
                                Text(tag.value)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding([.horizontal], 8)
                                    .padding([.vertical], 4)
                                    .background(tag.risk.getColor())
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerSize:
                                                CGSize(
                                                    width: 16,
                                                    height: 16)))
                                    .padding([.vertical], 8)
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
    
    func getTags() -> [MetricData] {
        return request.getMetricSet()!.sorted(by: {
            if $0.value.risk == $1.value.risk {
                $0.key.rawValue < $1.key.rawValue
            } else {
                $0.value.risk > $1.value.risk
            }
        }).map({$0.value})
    }
}
