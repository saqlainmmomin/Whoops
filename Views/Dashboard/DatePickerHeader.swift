import SwiftUI

/// Date picker header for dashboard navigation
/// Shows current date with dropdown calendar picker
struct DatePickerHeader: View {
    @Binding var selectedDate: Date
    @State private var showDatePicker = false

    var body: some View {
        HStack {
            Button(action: { showDatePicker.toggle() }) {
                HStack(spacing: 8) {
                    Text(selectedDate.isToday ? "TODAY" : selectedDate.formatted(.dateTime.month().day()))
                        .font(Theme.Fonts.label(15))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .rotationEffect(showDatePicker ? .degrees(180) : .zero)
                }
            }

            Spacer()

            // Quick navigation buttons
            HStack(spacing: 16) {
                Button(action: goToPreviousDay) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Button(action: goToToday) {
                    Text("Today")
                        .font(Theme.Fonts.label(13))
                        .foregroundColor(selectedDate.isToday ? Theme.Colors.textTertiary : Theme.Colors.neutral)
                }
                .disabled(selectedDate.isToday)

                Button(action: goToNextDay) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(canGoForward ? Theme.Colors.textSecondary : Theme.Colors.textTertiary)
                }
                .disabled(!canGoForward)
            }
        }
        .padding(.horizontal, Theme.Spacing.moduleP)
        .padding(.vertical, 12)
        .background(Theme.Colors.primary)
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedDate,
                isPresented: $showDatePicker
            )
        }
    }

    // MARK: - Navigation

    private var canGoForward: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }

    private func goToPreviousDay() {
        withAnimation {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    private func goToNextDay() {
        guard canGoForward else { return }
        withAnimation {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        }
    }

    private func goToToday() {
        withAnimation {
            selectedDate = Date()
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
            }
            .background(Theme.Colors.primary)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Theme.Colors.neutral)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Compact Date Header

/// Minimal date display for inline use
struct CompactDateHeader: View {
    let date: Date

    var body: some View {
        HStack(spacing: 4) {
            if date.isToday {
                Text("Today")
                    .font(Theme.Fonts.label(13))
                    .foregroundColor(Theme.Colors.textPrimary)
            } else if date.isYesterday {
                Text("Yesterday")
                    .font(Theme.Fonts.label(13))
                    .foregroundColor(Theme.Colors.textPrimary)
            } else {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(Theme.Fonts.label(13))
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(Theme.Fonts.label(13))
                    .foregroundColor(Theme.Colors.textPrimary)
            }
        }
    }
}

// MARK: - Week Navigation Header

/// Header for week-based views with navigation
struct WeekNavigationHeader: View {
    @Binding var weekStart: Date
    let onWeekChange: (Date) -> Void

    var body: some View {
        HStack {
            Button(action: goToPreviousWeek) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            Text(weekRangeText)
                .font(Theme.Fonts.label(15))
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Button(action: goToNextWeek) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(canGoForward ? Theme.Colors.textSecondary : Theme.Colors.textTertiary)
            }
            .disabled(!canGoForward)
        }
        .padding(.horizontal, Theme.Spacing.moduleP)
        .padding(.vertical, 12)
    }

    private var weekRangeText: String {
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: endDate))"
    }

    private var canGoForward: Bool {
        let calendar = Calendar.current
        guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
            return false
        }
        return nextWeek <= Date()
    }

    private func goToPreviousWeek() {
        guard let newWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { return }
        withAnimation {
            weekStart = newWeek
            onWeekChange(newWeek)
        }
    }

    private func goToNextWeek() {
        guard canGoForward,
              let newWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { return }
        withAnimation {
            weekStart = newWeek
            onWeekChange(newWeek)
        }
    }
}

// MARK: - Date Extension

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}

// MARK: - Preview

#Preview("Date Headers") {
    VStack(spacing: 20) {
        DatePickerHeader(selectedDate: .constant(Date()))

        CompactDateHeader(date: Date())

        WeekNavigationHeader(weekStart: .constant(Date()), onWeekChange: { _ in })
    }
    .background(Theme.Colors.primary)
}
