//
//  UnlockHistoryView.swift
//  Health_BLOCKFEATURE
//
//  Calendar-style view showing when blocked apps were unlocked.
//  Displays time blocks similar to Google Calendar with toggleable day view options.
//

import SwiftUI

// MARK: - Models

/// Represents a single unlock session
struct UnlockSession: Identifiable {
    let id = UUID()
    let appName: String
    let category: IntentCategory
    let startTime: Date
    let endTime: Date
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Day View Options

enum DayViewOption: Int, CaseIterable {
    case one = 1
    case three = 3
    case five = 5
    case seven = 7
    
    var displayName: String {
        "\(rawValue) Day\(rawValue > 1 ? "s" : "")"
    }
}

// MARK: - Main View

struct UnlockHistoryView: View {
    @State private var selectedDayOption: DayViewOption = .three
    @State private var selectedDay: Date?
    
    // Sage palette to match the rest of the app
    private let sagePrimary = Color(red: 0.40, green: 0.63, blue: 0.47)
    private let sageDeep = Color(red: 0.22, green: 0.45, blue: 0.33)
    
    // Sample data
    private let sampleSessions: [UnlockSession] = generateSampleData()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Day view selector
                dayViewSelector
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                
                Divider()
                
                // Calendar view with fixed height
                CalendarTimelineView(
                    sessions: sampleSessions,
                    numberOfDays: selectedDayOption.rawValue,
                    selectedDay: $selectedDay
                )
                .frame(height: 400)
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // Analytics section
                ScrollView {
                    analyticsSection
                        .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Unlock History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var dayViewSelector: some View {
        HStack(spacing: 8) {
            ForEach(DayViewOption.allCases, id: \.rawValue) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDayOption = option
                    }
                } label: {
                    Text(option.displayName)
                        .font(.subheadline)
                        .fontWeight(selectedDayOption == option ? .semibold : .regular)
                        .foregroundStyle(
                            selectedDayOption == option ? .white : sagePrimary
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedDayOption == option 
                                ? sagePrimary 
                                : Color.clear
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(sagePrimary, lineWidth: 1.5)
                                .opacity(selectedDayOption == option ? 0 : 1)
                        )
                }
            }
        }
    }
    
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let selectedDay = selectedDay {
                // Show analytics for selected day
                DayAnalyticsView(
                    day: selectedDay,
                    sessions: sessionsForDay(selectedDay),
                    sagePrimary: sagePrimary
                )
            } else {
                // Show overall analytics
                OverallAnalyticsView(
                    sessions: sampleSessions,
                    numberOfDays: selectedDayOption.rawValue,
                    sagePrimary: sagePrimary
                )
            }
        }
    }
    
    private func sessionsForDay(_ day: Date) -> [UnlockSession] {
        let calendar = Calendar.current
        return sampleSessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: day)
        }
    }
}

// MARK: - Calendar Timeline View

private struct CalendarTimelineView: View {
    let sessions: [UnlockSession]
    let numberOfDays: Int
    @Binding var selectedDay: Date?
    
    private let sagePrimary = Color(red: 0.40, green: 0.63, blue: 0.47)
    
    // Hours to display (6 AM to 11 PM)
    private let startHour = 6
    private let endHour = 23
    private let hourHeight: CGFloat = 60
    
    var body: some View {
        let days = getDays()
        
        // When 1 day is selected, show full width single day
        if numberOfDays == 1, let day = days.first {
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    // Time labels column
                    timeLabelsColumn
                    
                    // Single full-width day column
                    DayColumn(
                        day: day,
                        sessions: sessionsForDay(day),
                        startHour: startHour,
                        endHour: endHour,
                        hourHeight: hourHeight,
                        isSelected: selectedDay != nil && Calendar.current.isDate(day, inSameDayAs: selectedDay!),
                        isFullWidth: true,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedDay != nil && Calendar.current.isDate(day, inSameDayAs: selectedDay!) {
                                    selectedDay = nil
                                } else {
                                    selectedDay = day
                                }
                            }
                        }
                    )
                }
                .padding(.bottom, 20)
            }
        } else {
            // Multi-day scrollable view
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        // Time labels column
                        timeLabelsColumn
                        
                        // Day columns
                        ForEach(days, id: \.self) { day in
                            DayColumn(
                                day: day,
                                sessions: sessionsForDay(day),
                                startHour: startHour,
                                endHour: endHour,
                                hourHeight: hourHeight,
                                isSelected: selectedDay != nil && Calendar.current.isDate(day, inSameDayAs: selectedDay!),
                                isFullWidth: false,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if selectedDay != nil && Calendar.current.isDate(day, inSameDayAs: selectedDay!) {
                                            selectedDay = nil
                                        } else {
                                            selectedDay = day
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
    
    private var timeLabelsColumn: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Header spacer
            Text("Time")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(height: 60)
            
            // Hour labels
            ForEach(startHour...endHour, id: \.self) { hour in
                Text(formatHour(hour))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, height: hourHeight, alignment: .top)
                    .padding(.top, -8)
            }
        }
        .padding(.trailing, 8)
    }
    
    private func getDays() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<numberOfDays).compactMap { offset in
            calendar.date(byAdding: .day, value: -numberOfDays + 1 + offset, to: today)
        }
    }
    
    private func sessionsForDay(_ day: Date) -> [UnlockSession] {
        let calendar = Calendar.current
        return sessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: day)
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }
}

// MARK: - Day Column

private struct DayColumn: View {
    let day: Date
    let sessions: [UnlockSession]
    let startHour: Int
    let endHour: Int
    let hourHeight: CGFloat
    let isSelected: Bool
    let isFullWidth: Bool
    let onTap: () -> Void
    
    private let columnWidth: CGFloat = 120
    private let sagePrimary = Color(red: 0.40, green: 0.63, blue: 0.47)
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Day header
                dayHeader
                
                // Time grid with sessions
                ZStack(alignment: .topLeading) {
                    // Grid lines
                    gridLines
                    
                    // Session blocks
                    ForEach(sessions) { session in
                        SessionBlock(session: session, startHour: startHour, hourHeight: hourHeight)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: isFullWidth ? nil : columnWidth)
        .frame(maxWidth: isFullWidth ? .infinity : nil)
    }
    
    private var dayHeader: some View {
        VStack(spacing: 4) {
            Text(day, format: .dateTime.weekday(.abbreviated))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(day, format: .dateTime.day())
                .font(.title3)
                .fontWeight(isToday || isSelected ? .bold : .semibold)
                .foregroundStyle(isToday ? sagePrimary : .primary)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(
            isSelected
                ? sagePrimary.opacity(0.2)
                : (isToday ? sagePrimary.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            Rectangle()
                .fill(isSelected ? sagePrimary : Color(.systemGray5))
                .frame(width: isSelected ? 2 : 1)
            , alignment: .trailing
        )
    }
    
    private var gridLines: some View {
        VStack(spacing: 0) {
            ForEach(startHour...endHour, id: \.self) { _ in
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                    .frame(height: hourHeight - 1)
            }
        }
        .overlay(
            Rectangle()
                .fill(isSelected ? sagePrimary : Color(.systemGray5))
                .frame(width: isSelected ? 2 : 1)
            , alignment: .trailing
        )
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }
}

// MARK: - Session Block

private struct SessionBlock: View {
    let session: UnlockSession
    let startHour: Int
    let hourHeight: CGFloat
    
    var body: some View {
        let offset = calculateOffset()
        let height = calculateHeight()
        
        VStack(alignment: .leading, spacing: 2) {
            Text(session.appName)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            if height > 35 {
                Text(formatDuration(session.duration))
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(session.category.badgeColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 4)
        .offset(y: offset)
    }
    
    private func calculateOffset() -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: session.startTime)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        
        let hourOffset = CGFloat(hour - startHour)
        let minuteOffset = CGFloat(minute) / 60.0
        
        return (hourOffset + minuteOffset) * hourHeight
    }
    
    private func calculateHeight() -> CGFloat {
        let durationInHours = session.duration / 3600.0
        let calculatedHeight = CGFloat(durationInHours) * hourHeight - 4 // -4 for padding
        return max(calculatedHeight, 25) // Minimum height
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Analytics Views

/// Shows analytics for a specific selected day
private struct DayAnalyticsView: View {
    let day: Date
    let sessions: [UnlockSession]
    let sagePrimary: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day, format: .dateTime.weekday(.wide))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(day, format: .dateTime.month(.wide).day().year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(formatTotalDuration(sessions))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(sagePrimary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Per-app breakdown
            if !sessions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time by App")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(appBreakdown(), id: \.0) { appName, duration, category in
                        AppTimeRow(
                            appName: appName,
                            duration: duration,
                            category: category,
                            totalDuration: totalDuration(sessions)
                        )
                    }
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("No app unlocks on this day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func appBreakdown() -> [(String, TimeInterval, IntentCategory)] {
        var breakdown: [String: (TimeInterval, IntentCategory)] = [:]
        
        for session in sessions {
            if let existing = breakdown[session.appName] {
                breakdown[session.appName] = (existing.0 + session.duration, session.category)
            } else {
                breakdown[session.appName] = (session.duration, session.category)
            }
        }
        
        return breakdown.map { ($0.key, $0.value.0, $0.value.1) }
            .sorted { $0.1 > $1.1 }
    }
    
    private func totalDuration(_ sessions: [UnlockSession]) -> TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    private func formatTotalDuration(_ sessions: [UnlockSession]) -> String {
        let total = totalDuration(sessions)
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Shows overall analytics across all visible days
private struct OverallAnalyticsView: View {
    let sessions: [UnlockSession]
    let numberOfDays: Int
    let sagePrimary: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last \(numberOfDays) Day\(numberOfDays > 1 ? "s" : "")")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Tap a day above for details")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Stats grid
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Time",
                    value: formatTotalDuration(sessions),
                    color: sagePrimary
                )
                
                StatCard(
                    title: "Daily Avg",
                    value: formatTotalDuration([UnlockSession](repeating: sessions.first ?? generateDummySession(), count: 1)),
                    color: .orange
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Sessions",
                    value: "\(sessions.count)",
                    color: .blue
                )
                
                StatCard(
                    title: "Unique Apps",
                    value: "\(uniqueAppCount())",
                    color: .purple
                )
            }
            
            // Most used apps
            VStack(alignment: .leading, spacing: 12) {
                Text("Most Used Apps")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(topApps(), id: \.0) { appName, duration, category in
                    AppTimeRow(
                        appName: appName,
                        duration: duration,
                        category: category,
                        totalDuration: totalDuration(sessions)
                    )
                }
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func uniqueAppCount() -> Int {
        Set(sessions.map { $0.appName }).count
    }
    
    private func topApps() -> [(String, TimeInterval, IntentCategory)] {
        var breakdown: [String: (TimeInterval, IntentCategory)] = [:]
        
        for session in sessions {
            if let existing = breakdown[session.appName] {
                breakdown[session.appName] = (existing.0 + session.duration, session.category)
            } else {
                breakdown[session.appName] = (session.duration, session.category)
            }
        }
        
        return breakdown.map { ($0.key, $0.value.0, $0.value.1) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0 }
    }
    
    private func totalDuration(_ sessions: [UnlockSession]) -> TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    private func formatTotalDuration(_ sessions: [UnlockSession]) -> String {
        let total = totalDuration(sessions)
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func generateDummySession() -> UnlockSession {
        let avgDuration = sessions.isEmpty ? 0 : totalDuration(sessions) / Double(numberOfDays)
        return UnlockSession(
            appName: "Dummy",
            category: .social,
            startTime: Date(),
            endTime: Date().addingTimeInterval(avgDuration)
        )
    }
}

/// Small stat card for overview
private struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Row showing app usage time
private struct AppTimeRow: View {
    let appName: String
    let duration: TimeInterval
    let category: IntentCategory
    let totalDuration: TimeInterval
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon placeholder
            Circle()
                .fill(category.badgeColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(appName.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(appName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                        
                        Capsule()
                            .fill(category.badgeColor)
                            .frame(width: geometry.size.width * percentage)
                    }
                }
                .frame(height: 4)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(duration))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(Int(percentage * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var percentage: CGFloat {
        guard totalDuration > 0 else { return 0 }
        return CGFloat(duration / totalDuration)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Sample Data Generator

private func generateSampleData() -> [UnlockSession] {
    let calendar = Calendar.current
    let today = Date()
    
    var sessions: [UnlockSession] = []
    
    // Sample app list - broken up for compiler type-checking
    let sampleApps: [(String, IntentCategory)] = createSampleAppList()
    
    // Generate sessions for the past 7 days
    for dayOffset in 0..<7 {
        guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
        
        // Random number of sessions per day (2-5)
        let sessionCount = Int.random(in: 2...5)
        
        for _ in 0..<sessionCount {
            let hour = Int.random(in: 8...20)
            let minute = Int.random(in: 0...59)
            let durationMinutes = [15, 20, 30, 45, 60, 90, 120].randomElement() ?? 30
            
            guard let startTime = calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: day
            ) else { continue }
            
            let endTime = calendar.date(
                byAdding: .minute,
                value: durationMinutes,
                to: startTime
            ) ?? startTime
            
            let randomApp = sampleApps.randomElement() ?? ("Instagram", IntentCategory.social)
            
            sessions.append(UnlockSession(
                appName: randomApp.0,
                category: randomApp.1,
                startTime: startTime,
                endTime: endTime
            ))
        }
    }
    
    return sessions.sorted { $0.startTime < $1.startTime }
}

private func createSampleAppList() -> [(String, IntentCategory)] {
    var apps: [(String, IntentCategory)] = []
    
    apps.append(("Instagram", IntentCategory.social))
    apps.append(("Twitter", IntentCategory.social))
    apps.append(("TikTok", IntentCategory.entertainment))
    apps.append(("YouTube", IntentCategory.entertainment))
    apps.append(("Candy Crush", IntentCategory.entertainment))
    apps.append(("Facebook", IntentCategory.social))
    apps.append(("Snapchat", IntentCategory.social))
    apps.append(("Reddit", IntentCategory.social))
    apps.append(("Netflix", IntentCategory.entertainment))
    apps.append(("Games", IntentCategory.entertainment))
    
    return apps
}

// MARK: - Preview

#Preview {
    UnlockHistoryView()
}
