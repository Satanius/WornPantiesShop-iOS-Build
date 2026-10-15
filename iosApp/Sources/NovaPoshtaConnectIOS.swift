import SwiftUI
import FirebaseAuth

private let iosNovaPoshtaWorkerURL =
    "https://telegram-photo-storage.sataniusdarkc.workers.dev"

private struct IOSNovaPoshtaSenderOption: Identifiable {
    let senderRef: String
    let senderName: String
    let cityRef: String
    let cityName: String
    let contactSenderRef: String
    let contactName: String
    let phone: String

    var id: String {
        senderRef + "|" + contactSenderRef
    }

    var displayName: String {
        [senderName, cityName, contactName]
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }
}

private struct IOSNovaPoshtaWarehouseOption: Identifiable {
    let ref: String
    let number: String
    let description: String
    let shortAddress: String

    var id: String {
        ref
    }

    var displayName: String {
        description.isEmpty ? shortAddress : description
    }
}

@MainActor
private final class IOSNovaPoshtaConnectModel: ObservableObject {
    @Published var apiKey = ""
    @Published var senders: [IOSNovaPoshtaSenderOption] = []
    @Published var warehouses: [IOSNovaPoshtaWarehouseOption] = []
    @Published var selectedSenderIndex = -1
    @Published var selectedWarehouseIndex = -1
    @Published var loading = false
    @Published var connected = false
    @Published var errorMessage: String?

    func apiKeyChanged() {
        senders = []
        warehouses = []
        selectedSenderIndex = -1
        selectedWarehouseIndex = -1
        connected = false
        errorMessage = nil
    }

    func verifyKey() {
        let cleanKey =
            apiKey.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard
            !loading,
            cleanKey.count >= 10
        else {
            return
        }

        loading = true
        connected = false
        errorMessage = nil
        senders = []
        warehouses = []
        selectedSenderIndex = -1
        selectedWarehouseIndex = -1

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let json =
                    try await self.post(
                        path:
                            "/delivery-profile/novaposhta/options",
                        payload: [
                            "apiKey": cleanKey
                        ]
                    )

                let rawOptions =
                    json["options"]
                        as? [[String: Any]]
                        ?? []

                self.senders =
                    rawOptions.map {
                        IOSNovaPoshtaSenderOption(
                            senderRef:
                                $0["senderRef"]
                                    as? String
                                    ?? "",
                            senderName:
                                $0["senderName"]
                                    as? String
                                    ?? "",
                            cityRef:
                                $0["cityRef"]
                                    as? String
                                    ?? "",
                            cityName:
                                $0["cityName"]
                                    as? String
                                    ?? "",
                            contactSenderRef:
                                $0["contactSenderRef"]
                                    as? String
                                    ?? "",
                            contactName:
                                $0["contactName"]
                                    as? String
                                    ?? "",
                            phone:
                                $0["phone"]
                                    as? String
                                    ?? ""
                        )
                    }

                self.loading = false

                if self.senders.isEmpty {
                    self.errorMessage =
                        iosT(
                            iosCurrentLanguage(),
                            "FAILED_TO_VERIFY_API_KEY"
                        )
                } else if self.senders.count == 1 {
                    self.selectedSenderIndex = 0
                    self.loadWarehousesForSelectedSender()
                }
            } catch {
                self.loading = false
                self.errorMessage =
                    error.localizedDescription.isEmpty
                    ? iosT(
                        iosCurrentLanguage(),
                        "FAILED_TO_VERIFY_API_KEY"
                    )
                    : error.localizedDescription
            }
        }
    }

    func selectSender(
        _ index: Int
    ) {
        selectedSenderIndex = index
        warehouses = []
        selectedWarehouseIndex = -1
        errorMessage = nil

        guard
            senders.indices.contains(index)
        else {
            return
        }

        loadWarehousesForSelectedSender()
    }

    func connect() {
        guard
            !loading,
            senders.indices.contains(
                selectedSenderIndex
            ),
            warehouses.indices.contains(
                selectedWarehouseIndex
            )
        else {
            return
        }

        let sender =
            senders[selectedSenderIndex]
        let warehouse =
            warehouses[selectedWarehouseIndex]
        let cleanKey =
            apiKey.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        loading = true
        connected = false
        errorMessage = nil

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                _ =
                    try await self.post(
                        path:
                            "/delivery-profile/novaposhta",
                        payload: [
                            "apiKey": cleanKey,
                            "senderCityRef":
                                sender.cityRef,
                            "senderRef":
                                sender.senderRef,
                            "senderAddressRef":
                                warehouse.ref,
                            "contactSenderRef":
                                sender.contactSenderRef,
                            "senderPhone":
                                sender.phone
                        ]
                    )

                self.loading = false
                self.errorMessage = nil
                self.connected = true
            } catch {
                self.loading = false
                self.connected = false
                self.errorMessage =
                    error.localizedDescription.isEmpty
                    ? iosT(
                        iosCurrentLanguage(),
                        "FAILED_TO_CONNECT_NOVA_POSHTA"
                    )
                    : error.localizedDescription
            }
        }
    }

    private func loadWarehousesForSelectedSender() {
        guard
            senders.indices.contains(
                selectedSenderIndex
            )
        else {
            return
        }

        let sender =
            senders[selectedSenderIndex]

        guard !sender.cityRef.isEmpty else {
            errorMessage =
                iosT(
                    iosCurrentLanguage(),
                    "NOVA_POSHTA_DID_NOT_RETURN_THE_SENDERS"
                )
            return
        }

        let cleanKey =
            apiKey.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        loading = true
        errorMessage = nil
        warehouses = []
        selectedWarehouseIndex = -1

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let json =
                    try await self.post(
                        path:
                            "/delivery-profile/novaposhta/warehouses",
                        payload: [
                            "apiKey": cleanKey,
                            "cityRef": sender.cityRef
                        ]
                    )

                let rawWarehouses =
                    json["warehouses"]
                        as? [[String: Any]]
                        ?? []

                self.warehouses =
                    rawWarehouses.map {
                        IOSNovaPoshtaWarehouseOption(
                            ref:
                                $0["ref"]
                                    as? String
                                    ?? "",
                            number:
                                $0["number"]
                                    as? String
                                    ?? "",
                            description:
                                $0["description"]
                                    as? String
                                    ?? "",
                            shortAddress:
                                $0["shortAddress"]
                                    as? String
                                    ?? ""
                        )
                    }

                self.loading = false

                if self.warehouses.count == 1 {
                    self.selectedWarehouseIndex = 0
                }
            } catch {
                self.loading = false
                self.errorMessage =
                    error.localizedDescription.isEmpty
                    ? iosT(
                        iosCurrentLanguage(),
                        "FAILED_TO_LOAD_BRANCHES"
                    )
                    : error.localizedDescription
            }
        }
    }

    private func post(
        path: String,
        payload: [String: Any]
    ) async throws -> [String: Any] {
        guard
            let user =
                Auth.auth()
                    .currentUser
        else {
            throw NSError(
                domain: "NovaPoshta",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        iosT(
                            iosCurrentLanguage(),
                            "USER_NOT_AUTHORIZED"
                        )
                ]
            )
        }

        let token =
            try await withCheckedThrowingContinuation {
                (
                    continuation:
                        CheckedContinuation<
                            String,
                            Error
                        >
                ) in

                user.getIDTokenForcingRefresh(
                    false
                ) {
                    token,
                    error in

                    if let error {
                        continuation.resume(
                            throwing: error
                        )
                        return
                    }

                    guard
                        let token,
                        !token.isEmpty
                    else {
                        continuation.resume(
                            throwing:
                                NSError(
                                    domain:
                                        "NovaPoshta",
                                    code: 2,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            iosT(
                                                iosCurrentLanguage(),
                                                "FAILED_TO_GET_FIREBASE_ID_TOKEN"
                                            )
                                    ]
                                )
                        )
                        return
                    }

                    continuation.resume(
                        returning: token
                    )
                }
            }

        guard
            let url =
                URL(
                    string:
                        iosNovaPoshtaWorkerURL
                        + path
                ),
            let body =
                try? JSONSerialization.data(
                    withJSONObject: payload
                )
        else {
            throw NSError(
                domain: "NovaPoshta",
                code: 3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        iosT(
                            iosCurrentLanguage(),
                            "FAILED_TO_PREPARE_REQUEST"
                        )
                ]
            )
        }

        var request =
            URLRequest(
                url: url
            )

        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.httpBody = body

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField:
                "Authorization"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Accept"
        )

        let (
            data,
            response
        ) =
            try await URLSession.shared.data(
                for: request
            )

        guard
            let http =
                response
                    as? HTTPURLResponse
        else {
            throw NSError(
                domain: "NovaPoshta",
                code: 4,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        iosT(
                            iosCurrentLanguage(),
                            "SERVER_DID_NOT_RETURN_HTTP_RESPONSE"
                        )
                ]
            )
        }

        let json =
            (
                try? JSONSerialization
                    .jsonObject(
                        with: data
                    )
            ) as? [String: Any]
            ?? [:]

        let success =
            (200...299)
                .contains(
                    http.statusCode
                )
            && (
                json["success"]
                    as? Bool
                    ?? false
            )

        guard success else {
            let message =
                json["error"]
                    as? String
                ?? iosT(
                    iosCurrentLanguage(),
                    "SERVER_ERROR_HTTP",
                    String(
                        http.statusCode
                    )
                )

            throw NSError(
                domain: "NovaPoshta",
                code: http.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        message
                ]
            )
        }

        return json
    }
}

struct IOSNovaPoshtaConnectView: View {
    let onConnected: () -> Void

    @StateObject
    private var model = IOSNovaPoshtaConnectModel()

    @AppStorage("appLanguage")
    private var languageRaw = "RU"

    @Environment(\.dismiss)
    private var dismiss

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(
                        iosT(
                            language,
                            "ENTER_THE_API_KEY_FROM_YOUR_NOVA"
                        )
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    SecureField(
                        "Nova Poshta API Key",
                        text: $model.apiKey
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .frame(minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                Color.gray.opacity(0.6),
                                lineWidth: 1
                            )
                    )
                    .onChange(of: model.apiKey) { _ in
                        model.apiKeyChanged()
                    }

                    Button {
                        model.verifyKey()
                    } label: {
                        HStack {
                            if
                                model.loading
                                && model.senders.isEmpty
                            {
                                ProgressView()
                            }

                            Text(
                                iosT(
                                    language,
                                    "VERIFY_KEY"
                                )
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .disabled(
                        model.loading
                        || model.apiKey
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .count < 10
                    )

                    if !model.senders.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                iosT(
                                    language,
                                    "SENDER"
                                )
                            )
                            .font(.headline)

                            Picker(
                                iosT(
                                    language,
                                    "SELECT_SENDER"
                                ),
                                selection: $model.selectedSenderIndex
                            ) {
                                Text(
                                    iosT(
                                        language,
                                        "SELECT_SENDER"
                                    )
                                )
                                .tag(-1)

                                ForEach(
                                    model.senders.indices,
                                    id: \.self
                                ) { index in
                                    Text(
                                        model.senders[index]
                                            .displayName
                                    )
                                    .tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(
                                of: model.selectedSenderIndex
                            ) { index in
                                model.selectSender(index)
                            }
                        }
                    }

                    if !model.warehouses.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                iosT(
                                    language,
                                    "SHIPPING_BRANCH"
                                )
                            )
                            .font(.headline)

                            Picker(
                                iosT(
                                    language,
                                    "SELECT_BRANCH"
                                ),
                                selection:
                                    $model.selectedWarehouseIndex
                            ) {
                                Text(
                                    iosT(
                                        language,
                                        "SELECT_BRANCH"
                                    )
                                )
                                .tag(-1)

                                ForEach(
                                    model.warehouses.indices,
                                    id: \.self
                                ) { index in
                                    Text(
                                        model.warehouses[index]
                                            .displayName
                                    )
                                    .tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        model.connect()
                    } label: {
                        HStack {
                            if
                                model.loading
                                && !model.senders.isEmpty
                            {
                                ProgressView()
                            }

                            Text(
                                iosT(
                                    language,
                                    "CONNECT"
                                )
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .disabled(
                        model.loading
                        || !model.senders.indices.contains(
                            model.selectedSenderIndex
                        )
                        || !model.warehouses.indices.contains(
                            model.selectedWarehouseIndex
                        )
                    )
                }
                .padding(20)
            }
            .navigationTitle(
                iosT(
                    language,
                    "CONNECT_NOVA_POSHTA"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .navigationBarTrailing
                ) {
                    Button(
                        iosT(
                            language,
                            "CANCEL"
                        )
                    ) {
                        dismiss()
                    }
                    .disabled(model.loading)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onChange(
            of: model.connected
        ) { connected in
            guard connected else {
                return
            }

            onConnected()
            dismiss()
        }
    }
}
