//
//  Operation.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

// Represents an operational period (blue-sky training/class OR gray-sky incident)
// Mirrors the `operations` table in the database.
struct Operation: Identifiable, Equatable, Sendable {

    // MARK: - Core Fields (Schema-Aligned)
    let id: UUID
    let category: String          // "blue" or "gray"
    let name: String
    let description: String?
    let isActive: Bool
    let createdAt: Date
    let startDate: Date?
    let endDate: Date?
    let startTime: String?
    let endTime: String?
    let isVisible: Bool

    // MARK: - Recurrence Fields
    let isRecurring: Bool
    let recurrenceType: RecurrenceType
    let recurrenceConfig: RecurrenceConfig?
    let recurrenceEndDate: Date?

    // MARK: - Memberwise Initializer
    init(
        id: UUID,
        category: String,
        name: String,
        description: String?,
        isActive: Bool,
        createdAt: Date,
        startDate: Date?,
        endDate: Date?,
        startTime: String?,
        endTime: String?,
        isVisible: Bool,
        isRecurring: Bool = false,
        recurrenceType: RecurrenceType = .oneTime,
        recurrenceConfig: RecurrenceConfig? = nil,
        recurrenceEndDate: Date? = nil
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.description = description
        self.isActive = isActive
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.startTime = startTime
        self.endTime = endTime
        self.isVisible = isVisible
        self.isRecurring = isRecurring
        self.recurrenceType = recurrenceType
        self.recurrenceConfig = recurrenceConfig
        self.recurrenceEndDate = recurrenceEndDate
    }

    // MARK: - Computed Helpers
    // Returns true if the current date is within the defined start/end window.
    var isCurrentlyActive: Bool {
        guard let start = startDate else { return true }
        let now = Date()
        if let end = endDate {
            return now >= start && now <= end
        }
        return now >= start
    }
    
    // Combines date + time fields into a cleaner UI label.
    var formattedSchedule: String {
        var parts: [String] = []
        
        if let startDate = startDate {
            parts.append(Self.dateFormatter.string(from: startDate))
        }
        
        if let startTime = startTime {
            parts.append("Start: \(startTime)")
        }
        
        if let endTime = endTime {
            parts.append("End: \(endTime)")
        }
        
        return parts.isEmpty ? "No schedule" : parts.joined(separator: " • ")
    }

    // MARK: - Coding Keys (Matches Database Exactly)
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case name
        case description
        case isActive           = "is_active"
        case createdAt          = "created_at"
        case startDate          = "start_date"
        case endDate            = "end_date"
        case startTime          = "start_time"
        case endTime            = "end_time"
        case isVisible          = "is_visible"
        case isRecurring        = "is_recurring"
        case recurrenceType     = "recurrence_type"
        case recurrenceConfig   = "recurrence_config"
        case recurrenceEndDate  = "recurrence_end_date"
    }
    
    // MARK: - Date Formatting Helper (UI Only)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    // MARK: - Custom Decoding (handles PostgreSQL date type)
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        category = try container.decode(String.self, forKey: .category)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)

        // Recurrence fields
        isRecurring = try container.decode(Bool.self, forKey: .isRecurring)
        recurrenceType = try container.decode(RecurrenceType.self, forKey: .recurrenceType)
        recurrenceConfig = try container.decodeIfPresent(RecurrenceConfig.self, forKey: .recurrenceConfig)

        // Handle PostgreSQL date type (returns "yyyy-MM-dd" string)
        if let startDateString = try container.decodeIfPresent(String.self, forKey: .startDate) {
            startDate = Self.dateOnlyFormatter.date(from: startDateString)
        } else {
            startDate = nil
        }

        if let endDateString = try container.decodeIfPresent(String.self, forKey: .endDate) {
            endDate = Self.dateOnlyFormatter.date(from: endDateString)
        } else {
            endDate = nil
        }

        if let recurrenceEndDateString = try container.decodeIfPresent(String.self, forKey: .recurrenceEndDate) {
            recurrenceEndDate = Self.dateOnlyFormatter.date(from: recurrenceEndDateString)
        } else {
            recurrenceEndDate = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(category, forKey: .category)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(isVisible, forKey: .isVisible)

        // Recurrence fields
        try container.encode(isRecurring, forKey: .isRecurring)
        try container.encode(recurrenceType, forKey: .recurrenceType)
        try container.encodeIfPresent(recurrenceConfig, forKey: .recurrenceConfig)

        // Encode dates as "yyyy-MM-dd" strings for PostgreSQL date type
        if let startDate = startDate {
            try container.encode(Self.dateOnlyFormatter.string(from: startDate), forKey: .startDate)
        } else {
            try container.encodeNil(forKey: .startDate)
        }

        if let endDate = endDate {
            try container.encode(Self.dateOnlyFormatter.string(from: endDate), forKey: .endDate)
        } else {
            try container.encodeNil(forKey: .endDate)
        }

        if let recurrenceEndDate = recurrenceEndDate {
            try container.encode(Self.dateOnlyFormatter.string(from: recurrenceEndDate), forKey: .recurrenceEndDate)
        } else {
            try container.encodeNil(forKey: .recurrenceEndDate)
        }
    }
}

// MARK: - Codable Conformance
extension Operation: Codable {}

// MARK: - Recurrence Types

/// Defines the type of recurrence for an operation
enum RecurrenceType: String, Codable, Sendable {
    case oneTime = "one_time"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

// Configuration for recurring operations
// Decoded from JSONB column in database
struct RecurrenceConfig: Codable, Equatable, Sendable {
    // For weekly recurrence
    let daysOfWeek: [Int]?      // 0 = Sunday, 1 = Monday, ..., 6 = Saturday

    // For monthly recurrence
    let dayOfMonth: Int?         // 1-31

    // Common fields
    let startTime: String?       // "HH:mm" format
    let endTime: String?         // "HH:mm" format

    enum CodingKeys: String, CodingKey {
        case daysOfWeek = "days_of_week"
        case dayOfMonth = "day_of_month"
        case startTime = "start_time"
        case endTime = "end_time"
    }

    init(
        daysOfWeek: [Int]? = nil,
        dayOfMonth: Int? = nil,
        startTime: String? = nil,
        endTime: String? = nil
    ) {
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.startTime = startTime
        self.endTime = endTime
    }
}
