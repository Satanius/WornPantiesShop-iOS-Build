import SwiftUI

struct IOSAnnouncementFilters {
    var filterColor = "ALL"
    var filterSize = "ALL"
    var minPrice = ""
    var maxPrice = ""
    var minAge = ""
    var maxAge = ""
    var daysWorn = ""
    var virginOnly = false

    static let colors = [
        "ALL",
        "Черный",
        "Красный",
        "Розовый",
        "Белый",
        "Синий",
        "Другой"
    ]

    static let sizes = [
        "ALL",
        "XS",
        "S",
        "M",
        "L",
        "XL"
    ]

    func apply(
        to items: [IOSAnnouncement],
        searchQuery: String
    ) -> [IOSAnnouncement] {
        let normalizedSearch = searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let priceFrom = Int(minPrice) ?? 0
        let priceTo = Int(maxPrice) ?? Int.max
        let ageFrom = Int(minAge) ?? 18
        let ageTo = Int(maxAge) ?? Int.max
        let selectedDays = Int(daysWorn)

        return items.filter { item in
            let searchMatches =
                normalizedSearch.isEmpty
                || item.title.lowercased().contains(normalizedSearch)
                || item.description.lowercased().contains(normalizedSearch)
                || item.type.lowercased().contains(normalizedSearch)
                || item.color.lowercased().contains(normalizedSearch)
                || item.size.lowercased().contains(normalizedSearch)

            return item.availabilityStatus == "AVAILABLE"
                && searchMatches
                && (filterColor == "ALL" || item.color == filterColor)
                && (filterSize == "ALL" || item.size == filterSize)
                && item.price >= priceFrom
                && item.price <= priceTo
                && item.age >= ageFrom
                && item.age <= ageTo
                && (selectedDays == nil || item.daysWorn == selectedDays)
                && (!virginOnly || item.isVirgin)
        }
    }

    mutating func reset() {
        filterColor = "ALL"
        filterSize = "ALL"
        minPrice = ""
        maxPrice = ""
        minAge = ""
        maxAge = ""
        daysWorn = ""
        virginOnly = false
    }

    var isActive: Bool {
        filterColor != "ALL"
            || filterSize != "ALL"
            || !minPrice.isEmpty
            || !maxPrice.isEmpty
            || !minAge.isEmpty
            || !maxAge.isEmpty
            || !daysWorn.isEmpty
            || virginOnly
    }
}

struct AnnouncementFiltersIOSView: View {
    @Binding var filters: IOSAnnouncementFilters

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Цвет") {
                    Picker("Цвет", selection: $filters.filterColor) {
                        ForEach(IOSAnnouncementFilters.colors, id: \.self) { color in
                            Text(color == "ALL" ? "Все" : color)
                                .tag(color)
                        }
                    }
                }

                Section("Размер") {
                    Picker("Размер", selection: $filters.filterSize) {
                        ForEach(IOSAnnouncementFilters.sizes, id: \.self) { size in
                            Text(size == "ALL" ? "Все" : size)
                                .tag(size)
                        }
                    }
                }

                Section("Цена, ₴") {
                    HStack {
                        numberField("От", text: $filters.minPrice)
                        numberField("До", text: $filters.maxPrice)
                    }
                }

                Section("Возраст модели") {
                    HStack {
                        numberField("От", text: $filters.minAge)
                        numberField("До", text: $filters.maxAge)
                    }
                }

                Section("Дополнительно") {
                    numberField(
                        "Количество дней носки",
                        text: $filters.daysWorn
                    )

                    Toggle(
                        "Только от девственниц",
                        isOn: $filters.virginOnly
                    )
                }

                Section {
                    Button(role: .destructive) {
                        filters.reset()
                    } label: {
                        Text("Сбросить фильтры")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func numberField(
        _ title: String,
        text: Binding<String>
    ) -> some View {
        TextField(title, text: text)
            .keyboardType(.numberPad)
            .onChange(of: text.wrappedValue) { value in
                let filtered = value.filter { $0.isNumber }
                if filtered != value {
                    text.wrappedValue = filtered
                }
            }
    }
}
