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
                    VStack {
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
                        }.padding([.horizontal, .top],16)
                        if let vtr = request.modules.compactMap({$0 as! VirusTotalModule}).first
                        {
                            VStack {
                                HStack {
                                    Text("VirusTotal")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
//                                    Text(vtr.reports?.description ?? "nil!")
//                                        .font(.title2)
//                                        .fontWeight(.bold)
//                                        .foregroundStyle(.primary)
                                    Spacer()
                                    HStack {
                                        if let sum = vtr.summary {
                                            if sum[AVState.malicious]! > 0 {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                Text(vtr.summary![AVState.malicious]!.description).offset(CGSize(width: -4, height: 0))
                                            }
                                            if sum[AVState.suspicious]! > 0 {
                                                Image(systemName: "exclamationmark.circle.fill")
                                                    .foregroundColor(.yellow)
                                                Text(vtr.summary![AVState.suspicious]!.description).offset(CGSize(width: -4, height: 0))
                                            }
                                            if sum[AVState.harmless]! > 0 {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                Text(vtr.summary![AVState.harmless]!.description).offset(CGSize(width: -4, height: 0))
                                            }
                                            if sum[AVState.undetected]! > 0 {
                                                Image(systemName: "questionmark.app.fill")
                                                    .foregroundColor(.black.opacity(0.8))
                                                Text(vtr.summary![AVState.undetected]!.description).offset(CGSize(width: -4, height: 0))
                                            }
                                            if sum[AVState.timeout]! > 0 {
                                                Image(systemName: "clock.badge.exclamationmark.fill")
                                                    .foregroundColor(.gray)
                                                Text(vtr.summary![AVState.harmless]!.description).offset(CGSize(width: -4, height: 0))
                                            }
                                      
                                        }
                                    }.padding(4)
                                        .padding(.horizontal, 8)
                                        .background(Color(
                                            nsColor: NSColor.lightGray.withAlphaComponent(0.1)))
                                        .clipShape(Capsule())
                                }
                                ForEach(vtr.reports!) { rep in
                                    HStack {
                                        Text(rep.engineName)
                                        Spacer()
                                        Text(rep.result)
                                    }.padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                }
                            }.padding(16)
                        }
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

extension AVReport: Identifiable {
    var id: String { self.engineName }
}
