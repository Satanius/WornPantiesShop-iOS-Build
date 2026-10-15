import SwiftUI
import FirebaseAuth

private let iosBoostWorkerURL =
    "https://telegram-photo-storage.sataniusdarkc.workers.dev"

private struct IOSBoostPlan: Identifiable {
    let days: Int
    let price: Int
    let label: String

    var id: Int {
        days
    }
}

@MainActor
private final class IOSBoostModel: ObservableObject {
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var paymentURL: URL?

    func createPayment(
        announcementId: String,
        days: Int
    ) {
        guard !loading else { return }

        guard [1, 3, 7].contains(days) else {
            errorMessage = iosT(iosCurrentLanguage(), "INVALID_BOOST_PERIOD")
            return
        }

        guard let user = Auth.auth().currentUser else {
            errorMessage = iosT(iosCurrentLanguage(), "USER_NOT_AUTHORIZED")
            return
        }

        loading = true
        errorMessage = nil
        paymentURL = nil

        user.getIDTokenForcingRefresh(false) { [weak self] token, error in
            if let error {
                DispatchQueue.main.async {
                    self?.loading = false
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            guard
                let token,
                let url = URL(
                    string: iosBoostWorkerURL + "/create-boost-payment"
                )
            else {
                DispatchQueue.main.async {
                    self?.loading = false
                    self?.errorMessage = iosT(iosCurrentLanguage(), "FAILED_TO_PREPARE_PAYMENT")
                }
                return
            }

            let body = try? JSONSerialization.data(
                withJSONObject: [
                    "announcementId": announcementId,
                    "days": days
                ]
            )

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.httpBody = body
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )

            URLSession.shared
                .dataTask(with: request) { data, response, networkError in
                    let http = response as? HTTPURLResponse
                    let json = data.flatMap {
                        try? JSONSerialization.jsonObject(with: $0)
                            as? [String: Any]
                    } ?? [:]

                    let paymentString =
                        json["payment_url"] as? String
                    let paymentURL = paymentString.flatMap(URL.init)

                    let success =
                        networkError == nil
                        && (200...299).contains(http?.statusCode ?? 0)
                        && (json["success"] as? Bool) == true
                        && paymentURL != nil

                    let message =
                        networkError?.localizedDescription
                        ?? (json["error"] as? String)
                        ?? iosT(iosCurrentLanguage(), "FAILED_TO_CREATE_PAYMENT")

                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.loading = false

                        if success {
                            self.paymentURL = paymentURL
                            self.errorMessage = nil
                        } else {
                            self.errorMessage = message
                        }
                    }
                }
                .resume()
        }
    }
}

struct IOSBoostView: View {
    let announcement: IOSAnnouncement

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.openURL)
    private var openURL

    @StateObject
    private var model = IOSBoostModel()

    @State
    private var selectedDays = 3

    @AppStorage("appLanguage")
    private var languageRaw = "RU"

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }

    private var plans: [IOSBoostPlan] {
        [
            IOSBoostPlan(
                days: 1,
                price: 100,
                label: iosT(language, "TEXT_1_DAY")
            ),
            IOSBoostPlan(
                days: 3,
                price: 200,
                label: iosT(language, "TEXT_3_DAYS_BEST_VALUE")
            ),
            IOSBoostPlan(
                days: 7,
                price: 350,
                label: iosT(language, "TEXT_7_DAYS_MAXIMUM")
            )
        ]
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                Text(iosT(language, "BOOST_LISTING"))
                    .font(.title2.bold())

                Text(
                    announcement.title.isEmpty
                        ? iosT(language, "UNTITLED")
                        : announcement.title
                )
                .foregroundStyle(.secondary)

                if announcement.boostedUntil > currentMilliseconds {
                    Text(
                        iosT(language, "ACTIVE_UNTIL") + " "
                        + boostDate(
                            announcement.boostedUntil
                        )
                    )
                    .font(.footnote)
                    .foregroundStyle(.green)
                }

                VStack(spacing: 10) {
                    ForEach(plans) { plan in
                        Button {
                            selectedDays = plan.days
                        } label: {
                            HStack {
                                Image(
                                    systemName:
                                        selectedDays == plan.days
                                        ? "largecircle.fill.circle"
                                        : "circle"
                                )
                                .foregroundStyle(.pink)

                                Text(plan.label)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text("\(plan.price) ₴")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            }
                            .padding(14)
                            .background(
                                selectedDays == plan.days
                                    ? Color.pink.opacity(0.12)
                                    : Color.secondary.opacity(0.08)
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button {
                    model.createPayment(
                        announcementId: announcement.id,
                        days: selectedDays
                    )
                } label: {
                    HStack {
                        if model.loading {
                            ProgressView()
                        }

                        Text(iosT(language, "GO_TO_PAYMENT"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .disabled(model.loading)

                Spacer()
            }
            .padding()
            .navigationTitle(iosT(language, "PROMOTION"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(iosT(language, "CLOSE")) {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: model.paymentURL) { url in
            guard let url else { return }
            openURL(url)
        }
    }

    private var currentMilliseconds: Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func boostDate(
        _ milliseconds: Int64
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(
            identifier:
                language == .ru
                    ? "ru_RU"
                    : language == .ua
                        ? "uk_UA"
                        : "en_US"
        )
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return formatter.string(
            from: Date(
                timeIntervalSince1970:
                    TimeInterval(milliseconds) / 1000
            )
        )
    }
}
