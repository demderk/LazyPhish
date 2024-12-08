//
//  WhoisRecievedDate.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.12.2024.
//

import Foundation

struct WhoisRecievedDate {
    var day: Int?
    var year: Int?

    var monthText: String?

    var date: Date? {
        var monthInt: Int?
        let allMonthText: [String: Int] = [
             "january": 1,
             "february": 2,
             "march": 3,
             "april": 4,
             "may": 5,
             "june": 6,
             "july": 7,
             "august": 8,
             "september": 9,
             "october": 10,
             "november": 11,
             "december": 12
        ]
        let allMonthTextShort: [String: Int] = [
             "jan": 1,
             "feb": 2,
             "mar": 3,
             "apr": 4,
             "may": 5,
             "jun": 6,
             "jul": 7,
             "aug": 8,
             "sep": 9,
             "oct": 10,
             "nov": 11,
             "dec": 12
        ]

        guard let monthText = self.monthText else {
            return nil
        }

        if let mInt = allMonthText[monthText] {
            monthInt = mInt
        } else if let mInt = allMonthTextShort[monthText] {
            monthInt = mInt
        } else if let mInt = Int(monthText) {
            monthInt = mInt
        }
        guard let year = self.year, let monthInt = monthInt, let day = day else {
            return nil
        }

        let dateString = "\(year)-\(monthInt)-\(day)T0:0:0Z"
        if let date = try? Date(dateString, strategy: .iso8601) {
            return date
        } else { return nil }
    }

    static func fromDictionary(dictionary: [String: String?]) -> WhoisRecievedDate? {
        var day, year: Int?
        var monthText: String?
        for item in dictionary.keys {
            switch item {
            case "month", "monthText", "monthTextShort":
                if let ditem = dictionary[item], let val = ditem {
                    monthText = val
                }
            case "day":
                if let ditem = dictionary[item], let val = ditem {
                    day = Int(val)
                }
            case "year":
                if let ditem = dictionary[item], let val = ditem {
                    year = Int(val)
                }
            default:
                continue
            }
        }
        if let day = day, let year = year, let monthText = monthText {
            return WhoisRecievedDate(day: day, year: year, monthText: monthText)
        } else { return nil }
    }
}
