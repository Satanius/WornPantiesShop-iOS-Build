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

    private let sections: [(String, String, Bool)] = [
        (
            "1. О сервисе",
            "«Worn panties shop» является информационной площадкой для размещения объявлений. Администрация не является стороной сделок между пользователями, не хранит и не обрабатывает денежные средства, не осуществляет доставку товаров и не несёт ответственности за содержание объявлений.",
            false
        ),
        (
            "2. Возрастные ограничения",
            "Сервис предназначен исключительно для лиц старше 18 лет. Регистрируясь, вы подтверждаете, что достигли совершеннолетия. Размещение контента с участием несовершеннолетних строго запрещено и будет немедленно удалено.",
            false
        ),
        (
            "3. Покупки и доставка",
            "• Все расчёты между пользователями происходят напрямую (наложенный платёж, перевод на карту).\n• Почта/курьерская служба не позволяет вскрыть посылку до оплаты — вы принимаете этот риск.\n• Фото упаковки с номером накладной обязательно. Продавец должен отправить подтверждение упаковки покупателю до отправки заказа.\n• Предоплата за доставку (200–300 грн) — стандартная практика защиты от отказов.",
            false
        ),
        (
            "4. Проверка фотографий и подтверждение упаковки",
            "• Фотографии объявления должны содержать исходные EXIF-метаданные камеры.\n• Фотографии без обязательных EXIF-метаданных не допускаются к публикации.\n• Фото одного объявления должны иметь одинаковый отпечаток устройства.\n• Геолокационные данные из EXIF не используются и не сохраняются сервисом.\n• Фото подтверждения упаковки должно быть сделано тем же устройством.\n• Запрещено удалять, изменять, подделывать или обходить проверку метаданных и отпечатка устройства.",
            false
        ),
        (
            "5. Запрещено",
            "• Контент с участием лиц младше 18 лет\n• Мошенничество, обман, фишинг\n• Продажа запрещённых веществ и предметов\n• Разглашение персональных данных третьих лиц\n\nНарушение ведёт к блокировке аккаунта.",
            true
        ),
        (
            "6. Ответственность",
            "Используя сервис, вы принимаете на себя ответственность за свои действия, размещаемые материалы и достоверность информации. Проверка EXIF и отпечатка устройства является дополнительной мерой защиты и не гарантирует отсутствие мошенничества. Пользователь самостоятельно оценивает риски сделки.",
            false
        )
    ]

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
                            "Я ознакомился(ась) и принимаю правила",
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

                                Text("Принять и продолжить")
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
            .navigationTitle("Правила сервиса")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onClose {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Готово") {
                            onClose()
                        }
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
            errorMessage = "Сообщение слишком короткое."
            return
        }

        guard cleanText.count <= 2000 else {
            errorMessage = "Сообщение слишком длинное."
            return
        }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "Пользователь не авторизован."
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
                    self?.errorMessage = "Не удалось подготовить запрос."
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
                        ?? "Не удалось отправить сообщение."

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

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 14) {
                Text(
                    "Напишите предложение, сообщите об ошибке или оставьте отзыв о сервисе."
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
                    Text("Спасибо! Сообщение отправлено.")
                        .foregroundStyle(.green)
                }

                Button {
                    model.send(text: text)
                } label: {
                    HStack {
                        if model.sending {
                            ProgressView()
                        }

                        Text("Отправить")
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
            .navigationTitle("Предложения и обратная связь")
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
                            "Пользователь не авторизован."
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
                                "Не удалось подготовить загрузку."
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
                                        "Сервер не вернул HTTP-ответ."
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
                                        ?? "Ошибка загрузки фото."
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
                                        "Worker не вернул fileId."
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
