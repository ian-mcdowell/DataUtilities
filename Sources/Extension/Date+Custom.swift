//
//  Date+Custom.swift
//  Source
//
//  Created by Ian McDowell on 12/27/16.
//  Copyright © 2016 Ian McDowell. All rights reserved.
//

import Foundation

extension Date {
    
    /// Instantiate a date object from a darwin timespec
    public init?(timespec: timespec) {
        let sec = TimeInterval(timespec.tv_sec)
        if sec <= 0 { return nil }
        self.init(timeIntervalSince1970: sec)
    }

    /// Does this date take place today?
    public var isToday: Bool {
        return isDateInComponents([.era, .year, .month, .day])
    }

    /// Does this date take place yesterday?
    public var isYesterday: Bool {
        return isDateInComponents([.era, .year, .month, .day], subtractingComponent: .day)
    }

    /// Does this date take place during the current week?
    public var isThisWeek: Bool {
        return isDateInComponents([.era, .year, .month, .weekOfYear])
    }

    /// Does this date take place during the current month?
    public var isInThisMonth: Bool {
        return isDateInComponents([.era, .year, .month])
    }

    /// Does this date take place during the previous month?
    public var isInLastMonth: Bool {
        return isDateInComponents([.era, .year, .month], subtractingComponent: .month)
    }

    // Does this date take place during the current year?
    public var isInThisYear: Bool {
        return isDateInComponents([.era, .year])
    }

    // Does this date take place during the previous year?
    public var isInLastYear: Bool {
        return isDateInComponents([.era, .year], subtractingComponent: .year)
    }

    /// Given the list of components, determines if this date is in the current date's components
    ///
    /// - Parameter components: list of calendar components
    /// - Returns: if this date is in the current date's components
    private func isDateInComponents(_ components: Set<Calendar.Component>, subtractingComponent: Calendar.Component? = nil) -> Bool {
        let cal = NSCalendar.current

        // Get the components out of the current date
        var c = cal.dateComponents(components, from: Date())
        if let subtractingComponent = subtractingComponent {
            let cVal = c.value(for: subtractingComponent)
            c.setValue((cVal ?? 1) - 1, for: subtractingComponent)
        }
        let current = cal.date(from: c)

        // Get components out of this date
        c = cal.dateComponents(components, from: self)
        let this = cal.date(from: c)

        // If they are the same, they are in the same components
        return this == current
    }
}
