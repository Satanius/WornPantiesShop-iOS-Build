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

    @AppStorage("appLanguage")
    private var languageRaw = "RU"

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(iosT(language, "COLOR")) {
                    Picker(iosT(language, "COLOR"), selection: $filters.filterColor) {
                        ForEach(IOSAnnouncementFilters.colors, id: \.self) { color in
                            Text(color == "ALL" ? iosT(language, "ALL") : color)
                                .tag(color)
                        }
                    }
                }

                Section(iosT(language, "SIZE")) {
                    Picker(iosT(language, "SIZE"), selection: $filters.filterSize) {
                        ForEach(IOSAnnouncementFilters.sizes, id: \.self) { size in
                            Text(size == "ALL" ? iosT(language, "ALL") : size)
                                .tag(size)
                        }
                    }
                }

                Section(iosT(language, "PRICE_UAH")) {
                    HStack {
                        numberField(iosT(language, "FROM"), text: $filters.minPrice)
                        numberField(iosT(language, "TO"), text: $filters.maxPrice)
                    }
                }

                Section(iosT(language, "MODEL_AGE")) {
                    HStack {
                        numberField(iosT(language, "FROM"), text: $filters.minAge)
                        numberField(iosT(language, "TO"), text: $filters.maxAge)
                    }
                }

                Section {
                    numberField(
                        iosT(language, "DAYS_WORN"),
                        text: $filters.daysWorn
                    )

                    Toggle(
                        iosT(language, "VIRGIN_ONLY"),
                        isOn: $filters.virginOnly
                    )
                }

                Section {
                    Button(role: .destructive) {
                        filters.reset()
                    } label: {
                        Text(iosT(language, "RESET"))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(iosT(language, "FILTERS"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(iosT(language, "APPLY")) {
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
