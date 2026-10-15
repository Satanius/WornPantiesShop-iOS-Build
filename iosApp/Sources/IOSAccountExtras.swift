import SwiftUI
import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

private let iosAccountWorkerURL =
    "https://telegram-photo-storage.sataniusdarkc.workers.dev"

// MARK: - Rules / disclaimer

@MainActor
final class IOSDisclaimerGateModel: ObservableObject {
    @Published var checked = false
    @Published var accepted = false
    @Published var saving = false
    @Published var errorMessage: String?

    func load(userId: String) {
        checked = false
        accepted = false
        errorMessage = nil

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .getDocument { [weak self] snapshot, error in
                let accepted =
                    (snapshot?.data()?["disclaimerAccepted"] as? Bool) == true
                let message = error?.localizedDescription

                DispatchQueue.main.async {
                    guard let self else { return }
                    self.accepted = accepted
                    self.errorMessage = message
                    self.checked = true
                }
            }
    }

    func accept(userId: String) {
        guard !saving else { return }

        saving = true
        errorMessage = nil

        Firestore.firestore()
            .collection("users")
            .document(userId)
            .setData(
                [
                    "disclaimerAccepted": true,
                    "disclaimerAcceptedAt": Int64(
                        Date().timeIntervalSince1970 * 1000
                    )
                ],
                merge: true
            ) { [weak self] error in
                let message = error?.localizedDescription

                DispatchQueue.main.async {
                    guard let self else { return }
                    self.saving = false

                    if let message {
                        self.errorMessage = message
                    } else {
                        self.accepted = true
                    }
                }
            }
    }
}

struct IOSDisclaimerGate<Content: View>: View {
    let userId: String
    let content: () -> Content

    @StateObject
    private var model = IOSDisclaimerGateModel()

    var body: some View {
        Group {
            if !model.checked {
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    ProgressView()
                }
            } else if !model.accepted {
                IOSDisclaimerRulesView(
                    requireAcceptance: true,
                    saving: model.saving,
                    errorMessage: model.errorMessage,
                    onAccept: {
                        model.accept(userId: userId)
                    },
                    onClose: nil
                )
            } else {
                content()
            }
        }
        .onAppear {
            model.load(userId: userId)
        }
    }
}

struct IOSDisclaimerRulesView: View {
    let requireAcceptance: Bool
    let saving: Bool
    let errorMessage: String?
    let onAccept: (() -> Void)?
    let onClose: (() -> Void)?

    @State
    private var accepted = false

    @AppStorage("appLanguage")
    private var languageRaw = "RU"

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }

    private var sections: [(String, String, Bool)] {
        [
            (
                iosT(language, "TEXT_1_ABOUT_THE_SERVICE"),
                iosT(language, "RULES_PLATFORM_DISCLAIMER"),
                false
            ),
            (
                iosT(language, "TEXT_2_AGE_RESTRICTIONS"),
                iosT(language, "RULES_AGE_RESTRICTION"),
                false
            ),
            (
                iosT(language, "TEXT_3_PURCHASES_AND_DELIVERY"),
                iosT(language, "RULES_PAYMENTS_AND_DELIVERY"),
                false
            ),
            (
                iosT(language, "TEXT_4_PHOTO_VERIFICATION_AND_PACKAGING_CONFIRMATION"),
                iosT(language, "RULES_PHOTO_METADATA_POLICY"),
                false
            ),
            (
                iosT(language, "TEXT_5_PROHIBITED"),
                iosT(language, "RULES_PROHIBITED_CONTENT"),
                true
            ),
            (
                iosT(language, "TEXT_6_RESPONSIBILITY"),
                iosT(language, "RULES_USER_RESPONSIBILITY"),
                false
            )
        ]
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.0)
                                .font(.headline)
                                .foregroundStyle(
                                    section.2 ? Color.red : Color.pink
                                )

                            Text(section.1)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            section.2
                                ? Color.red.opacity(0.10)
                                : Color.secondary.opacity(0.10)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                    }

                    if requireAcceptance {
                        Toggle(
                            iosT(language, "I_HAVE_READ_AND_ACCEPT_THE_RULES"),
                            isOn: $accepted
                        )
                        .padding(.top, 4)

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.footnote)
                        }

                        Button {
                            onAccept?()
                        } label: {
                            HStack {
                                if saving {
                                    ProgressView()
                                }

                                Text(iosT(language, "ACCEPT_AND_CONTINUE"))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                        .disabled(!accepted || saving)
                    }
                }
                .padding()
            }
            .navigationTitle(iosT(language, "SERVICE_RULES"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let onClose {
                        Button(iosT(language, "READY")) {
                            onClose()
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Feedback

@MainActor
final class IOSFeedbackModel: ObservableObject {
    @Published var sending = false
    @Published var sent = false
    @Published var errorMessage: String?

    func send(text: String) {
        let cleanText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanText.count >= 5 else {
            errorMessage = iosT(iosCurrentLanguage(), "MESSAGE_TOO_SHORT")
            return
        }

        guard cleanText.count <= 2000 else {
            errorMessage = iosT(iosCurrentLanguage(), "MESSAGE_TOO_LONG")
            return
        }

        guard let user = Auth.auth().currentUser else {
            errorMessage = iosT(iosCurrentLanguage(), "USER_NOT_AUTHORIZED")
            return
        }

        sending = true
        sent = false
        errorMessage = nil

        user.getIDTokenForcingRefresh(false) { [weak self] token, error in
            if let error {
                DispatchQueue.main.async {
                    self?.sending = false
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            guard
                let token,
                let url = URL(string: iosAccountWorkerURL + "/feedback")
            else {
                DispatchQueue.main.async {
                    self?.sending = false
                    self?.errorMessage = iosT(iosCurrentLanguage(), "FAILED_TO_PREPARE_REQUEST")
                }
                return
            }

            let body = try? JSONSerialization.data(
                withJSONObject: ["text": cleanText]
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

                    let success =
                        networkError == nil
                        && (200...299).contains(http?.statusCode ?? 0)
                        && (json["success"] as? Bool) == true

                    let message =
                        networkError?.localizedDescription
                        ?? (json["error"] as? String)
                        ?? iosT(iosCurrentLanguage(), "FAILED_TO_SEND_MESSAGE")

                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.sending = false

                        if success {
                            self.sent = true
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

struct IOSFeedbackView: View {
    @Environment(\.dismiss)
    private var dismiss

    @StateObject
    private var model = IOSFeedbackModel()

    @State
    private var text = ""

    @AppStorage("appLanguage")
    private var languageRaw = "RU"

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 14) {
                Text(
                    iosT(language, "FEEDBACK_PROMPT")
                )
                .foregroundStyle(.secondary)

                TextEditor(text: $text)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(Color.secondary.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("\(text.count)/2000")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                if model.sent {
                    Text(iosT(language, "THANK_YOU_YOUR_MESSAGE_HAS_BEEN_SENT"))
                        .foregroundStyle(.green)
                }

                Button {
                    model.send(text: text)
                } label: {
                    HStack {
                        if model.sending {
                            ProgressView()
                        }

                        Text(iosT(language, "SEND"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .disabled(
                    model.sending
                    || text.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).count < 5
                )

                Spacer()
            }
            .padding()
            .navigationTitle(iosT(language, "FEEDBACK_TITLE"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(iosT(language, "READY")) {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Profile avatar

struct IOSProfilePhotoPicker: UIViewControllerRepresentable {
    let onPicked: (Data) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    func makeUIViewController(
        context: Context
    ) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(
            configuration: configuration
        )
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: PHPickerViewController,
        context: Context
    ) {
    }

    final class Coordinator:
        NSObject,
        PHPickerViewControllerDelegate
    {
        let onPicked: (Data) -> Void

        init(onPicked: @escaping (Data) -> Void) {
            self.onPicked = onPicked
        }

        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            picker.dismiss(animated: true)

            guard
                let provider = results.first?.itemProvider,
                provider.canLoadObject(ofClass: UIImage.self)
            else {
                return
            }

            provider.loadObject(
                ofClass: UIImage.self
            ) { object, _ in
                guard
                    let image = object as? UIImage,
                    let data = makeIOSAvatarJPEG(image)
                else {
                    return
                }

                DispatchQueue.main.async {
                    self.onPicked(data)
                }
            }
        }
    }
}

private func makeIOSAvatarJPEG(
    _ image: UIImage
) -> Data? {
    let maxSide: CGFloat = 1200
    let side = max(image.size.width, image.size.height)
    let scale = min(1, maxSide / max(1, side))

    let targetSize = CGSize(
        width: max(1, image.size.width * scale),
        height: max(1, image.size.height * scale)
    )

    let rendered = UIGraphicsImageRenderer(
        size: targetSize
    ).image { _ in
        image.draw(
            in: CGRect(
                origin: .zero,
                size: targetSize
            )
        )
    }

    for quality: CGFloat in [
        0.82,
        0.72,
        0.62,
        0.52,
        0.42,
        0.32
    ] {
        if let data = rendered.jpegData(
            compressionQuality: quality
        ),
           data.count <= 400 * 1024
        {
            return data
        }
    }

    return rendered.jpegData(
        compressionQuality: 0.28
    )
}

func uploadIOSProfileAvatar(
    _ jpeg: Data,
    completion: @escaping (Result<String, Error>) -> Void
) {
    guard let user = Auth.auth().currentUser else {
        completion(
            .failure(
                NSError(
                    domain: "ProfileAvatar",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            iosT(iosCurrentLanguage(), "USER_NOT_AUTHORIZED")
                    ]
                )
            )
        )
        return
    }

    user.getIDTokenForcingRefresh(false) { token, error in
        if let error {
            completion(.failure(error))
            return
        }

        guard
            let token,
            let url = URL(
                string: iosAccountWorkerURL + "/upload"
            )
        else {
            completion(
                .failure(
                    NSError(
                        domain: "ProfileAvatar",
                        code: 2,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                iosT(iosCurrentLanguage(), "FAILED_TO_PREPARE_PHOTO_UPLOAD")
                        ]
                    )
                )
            )
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.httpBody = jpeg
        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            "image/jpeg",
            forHTTPHeaderField: "Content-Type"
        )

        URLSession.shared
            .dataTask(with: request) { data, response, networkError in
                if let networkError {
                    completion(.failure(networkError))
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    completion(
                        .failure(
                            NSError(
                                domain: "ProfileAvatar",
                                code: 3,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        iosT(iosCurrentLanguage(), "SERVER_DID_NOT_RETURN_HTTP_RESPONSE")
                                ]
                            )
                        )
                    )
                    return
                }

                let json = data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0)
                        as? [String: Any]
                } ?? [:]

                guard (200...299).contains(http.statusCode) else {
                    completion(
                        .failure(
                            NSError(
                                domain: "ProfileAvatar",
                                code: http.statusCode,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        json["error"] as? String
                                        ?? iosT(iosCurrentLanguage(), "PHOTO_UPLOAD_FAILED")
                                ]
                            )
                        )
                    )
                    return
                }

                guard
                    let fileId = json["fileId"] as? String,
                    !fileId.isEmpty
                else {
                    completion(
                        .failure(
                            NSError(
                                domain: "ProfileAvatar",
                                code: 4,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        iosT(iosCurrentLanguage(), "WORKER_DID_NOT_RETURN_FILE_ID")
                                ]
                            )
                        )
                    )
                    return
                }

                Firestore.firestore()
                    .collection("users")
                    .document(user.uid)
                    .setData(
                        ["avatarFileId": fileId],
                        merge: true
                    ) { error in
                        if let error {
                            completion(.failure(error))
                        } else {
                            completion(.success(fileId))
                        }
                    }
            }
            .resume()
    }
}
