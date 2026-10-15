import SwiftUI
import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct IOSChatSummary: Identifiable {
    let id: String
    let buyerId: String
    let sellerId: String
    let announcementId: String
    let announcementTitle: String
    let lastMessage: String
    let lastSenderId: String
    let updatedAt: Int64
    let unreadCount: Int

    init(document: QueryDocumentSnapshot, currentUid: String) {
        let data = document.data()

        id = document.documentID
        buyerId = data["buyerId"] as? String ?? ""
        sellerId = data["sellerId"] as? String ?? ""
        announcementId = data["announcementId"] as? String ?? ""
        announcementTitle = data["announcementTitle"] as? String ?? ""
        lastMessage = data["lastMessage"] as? String ?? ""
        lastSenderId = data["lastSenderId"] as? String ?? ""

        if let number = data["updatedAt"] as? NSNumber {
            updatedAt = number.int64Value
        } else {
            updatedAt = 0
        }

        if let number = data["unreadCount_\(currentUid)"] as? NSNumber {
            unreadCount = number.intValue
        } else {
            unreadCount = 0
        }
    }

    init(
        id: String,
        buyerId: String,
        sellerId: String,
        announcementId: String,
        announcementTitle: String,
        lastMessage: String = "",
        lastSenderId: String = "",
        updatedAt: Int64 = 0,
        unreadCount: Int = 0
    ) {
        self.id = id
        self.buyerId = buyerId
        self.sellerId = sellerId
        self.announcementId = announcementId
        self.announcementTitle = announcementTitle
        self.lastMessage = lastMessage
        self.lastSenderId = lastSenderId
        self.updatedAt = updatedAt
        self.unreadCount = unreadCount
    }
}

private struct IOSChatMessage: Identifiable {
    let id: String
    let senderId: String
    let text: String
    let sentAt: Int64
    let photoFileId: String
    let messageType: String
    let photoVerified: Bool

    init(document: QueryDocumentSnapshot) {
        let data = document.data()

        id = document.documentID
        senderId = data["senderId"] as? String ?? ""
        text = data["text"] as? String ?? ""
        photoFileId = data["photoFileId"] as? String ?? ""
        messageType = data["messageType"] as? String ?? "NORMAL"
        photoVerified = data["photoVerified"] as? Bool ?? false

        if let number = data["sentAt"] as? NSNumber {
            sentAt = number.int64Value
        } else {
            sentAt = 0
        }
    }
}

@MainActor
private final class ChatsIOSViewModel: ObservableObject {
    @Published var chats: [IOSChatSummary] = []
    @Published var errorMessage: String?
    @Published var deletingId: String?

    private var buyerChats: [String: IOSChatSummary] = [:]
    private var sellerChats: [String: IOSChatSummary] = [:]
    private var blockedUserIds: Set<String> = []
    private var currentUid = ""
    private var buyerListener: ListenerRegistration?
    private var sellerListener: ListenerRegistration?
    private var blockedUsersListener: ListenerRegistration?

    init() {
        start()
    }

    func start() {
        stop()

        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            chats = []
            errorMessage = "Пользователь не авторизован."
            return
        }

        currentUid = uid

        blockedUsersListener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("blockedUsers")
            .addSnapshotListener { [weak self] snapshot, _ in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }

                    self.blockedUserIds = Set(
                        snapshot?.documents.map { $0.documentID } ?? []
                    )
                    self.publish()
                }
            }

        let collection = Firestore.firestore().collection("chats")

        buyerListener = collection
            .whereField("buyerId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }

                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.buyerChats = Dictionary(
                        uniqueKeysWithValues: (snapshot?.documents ?? []).map {
                            let chat = IOSChatSummary(
                                document: $0,
                                currentUid: uid
                            )
                            return (chat.id, chat)
                        }
                    )

                    self.publish()
                }
            }

        sellerListener = collection
            .whereField("sellerId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }

                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.sellerChats = Dictionary(
                        uniqueKeysWithValues: (snapshot?.documents ?? []).map {
                            let chat = IOSChatSummary(
                                document: $0,
                                currentUid: uid
                            )
                            return (chat.id, chat)
                        }
                    )

                    self.publish()
                }
            }
    }

    func stop() {
        buyerListener?.remove()
        sellerListener?.remove()
        blockedUsersListener?.remove()
        buyerListener = nil
        sellerListener = nil
        blockedUsersListener = nil
    }

    func deleteChat(_ chat: IOSChatSummary) {
        guard deletingId == nil else {
            return
        }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "Пользователь не авторизован."
            return
        }

        deletingId = chat.id
        errorMessage = nil

        user.getIDTokenForcingRefresh(false) { [weak self] token, error in
            if let error {
                DispatchQueue.main.async {
                    self?.deletingId = nil
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            guard
                let token,
                let url = URL(
                    string:
                        "https://telegram-photo-storage.sataniusdarkc.workers.dev/chat/delete"
                )
            else {
                DispatchQueue.main.async {
                    self?.deletingId = nil
                    self?.errorMessage = "Не удалось подготовить удаление чата."
                }
                return
            }

            let body = try? JSONSerialization.data(
                withJSONObject: [
                    "chatId": chat.id
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

                    let success =
                        networkError == nil
                        && (200...299).contains(http?.statusCode ?? 0)
                        && (json["success"] as? Bool) != false

                    let message =
                        networkError?.localizedDescription
                        ?? (json["error"] as? String)
                        ?? "Не удалось удалить чат."

                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.deletingId = nil

                        if success {
                            self.buyerChats.removeValue(
                                forKey: chat.id
                            )
                            self.sellerChats.removeValue(
                                forKey: chat.id
                            )
                            self.publish()
                        } else {
                            self.errorMessage = message
                        }
                    }
                }
                .resume()
        }
    }

    private func publish() {
        var merged = buyerChats

        for (key, value) in sellerChats {
            merged[key] = value
        }

        chats = merged.values
            .filter { chat in
                let otherUserId =
                    chat.buyerId == currentUid
                        ? chat.sellerId
                        : chat.buyerId

                return !blockedUserIds.contains(
                    otherUserId
                )
            }
            .sorted {
                $0.updatedAt > $1.updatedAt
            }

        errorMessage = nil
    }
}

struct ChatsIOSView: View {
    let pendingChatId: String?
    let onPendingChatConsumed: () -> Void

    @StateObject private var viewModel = ChatsIOSViewModel()
    @State private var selectedChat: IOSChatSummary?
    @State private var deletingChat: IOSChatSummary?

    init(
        pendingChatId: String? = nil,
        onPendingChatConsumed: @escaping () -> Void = {}
    ) {
        self.pendingChatId = pendingChatId
        self.onPendingChatConsumed = onPendingChatConsumed
    }

    private let accentPink = Color(
        red: 233.0 / 255.0,
        green: 30.0 / 255.0,
        blue: 99.0 / 255.0
    )

    var body: some View {
        NavigationView {
            Group {
                if let error = viewModel.errorMessage {
                    VStack(spacing: 14) {
                        Text("Не удалось загрузить чаты")
                            .font(.headline)

                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Повторить") {
                            viewModel.start()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(accentPink)
                    }
                    .padding(24)
                } else if viewModel.chats.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text("Пока нет чатов")
                            .font(.headline)
                    }
                } else {
                    List(viewModel.chats) { chat in
                        Button {
                            selectedChat = chat
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(accentPink)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(
                                        chat.announcementTitle.isEmpty
                                            ? "Объявление"
                                            : chat.announcementTitle
                                    )
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                    Text(
                                        chat.lastMessage.isEmpty
                                            ? "Нет сообщений"
                                            : chat.lastMessage
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                }

                                Spacer()

                                if chat.unreadCount > 0 {
                                    Text(String(chat.unreadCount))
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                        .frame(minWidth: 22, minHeight: 22)
                                        .background(Circle().fill(accentPink))
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deletingChat = chat
                            } label: {
                                Label(
                                    "Удалить чат",
                                    systemImage: "trash"
                                )
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deletingChat = chat
                            } label: {
                                Label(
                                    "Удалить",
                                    systemImage: "trash"
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Чаты")
        }
        .navigationViewStyle(.stack)
        .onAppear {
            viewModel.start()
            openPendingChatIfAvailable()
        }
        .onChange(of: viewModel.chats.map(\.id)) { _ in
            openPendingChatIfAvailable()
        }
        .onChange(of: pendingChatId) { _ in
            openPendingChatIfAvailable()
        }
        .onDisappear {
            viewModel.stop()
        }
        .sheet(item: $selectedChat) { chat in
            ChatConversationIOSView(chat: chat)
        }
        .alert(item: $deletingChat) { chat in
            Alert(
                title: Text("Удалить чат?"),
                message: Text(
                    "Чат и все сообщения будут удалены безвозвратно."
                ),
                primaryButton: .destructive(
                    Text("Удалить")
                ) {
                    viewModel.deleteChat(chat)
                },
                secondaryButton: .cancel(
                    Text("Отмена")
                )
            )
        }
    }

    private func openPendingChatIfAvailable() {
        guard
            let pendingChatId,
            !pendingChatId.isEmpty,
            selectedChat?.id != pendingChatId,
            let chat = viewModel.chats.first(
                where: { $0.id == pendingChatId }
            )
        else {
            return
        }

        selectedChat = chat
        onPendingChatConsumed()
    }
}

@MainActor
private final class ChatConversationIOSViewModel: ObservableObject {
    @Published var messages: [IOSChatMessage] = []
    @Published var text = ""
    @Published var sending = false
    @Published var uploadingPhoto = false
    @Published var errorMessage: String?

    private let chat: IOSChatSummary
    private var listener: ListenerRegistration?

    init(chat: IOSChatSummary) {
        self.chat = chat
        start()
    }

    func start() {
        stop()

        listener = Firestore.firestore()
            .collection("chats")
            .document(chat.id)
            .collection("messages")
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }

                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.messages = snapshot?.documents.map {
                        IOSChatMessage(document: $0)
                    } ?? []

                    self.errorMessage = nil
                    self.markRead()
                }
            }

        markRead()
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func send() {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !clean.isEmpty, !sending, !uploadingPhoto else {
            return
        }

        sendMessage(
            cleanText: clean,
            photoFileId: ""
        )
    }

    func sendPhoto(_ image: UIImage) {
        guard !uploadingPhoto, !sending else {
            return
        }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "Пользователь не авторизован."
            return
        }

        guard let jpeg = prepareJPEG(image) else {
            errorMessage = "Не удалось сжать фото до 400 КБ."
            return
        }

        uploadingPhoto = true
        errorMessage = nil

        user.getIDTokenForcingRefresh(false) { [weak self] token, tokenError in
            guard let self else {
                return
            }

            if let tokenError {
                DispatchQueue.main.async {
                    self.uploadingPhoto = false
                    self.errorMessage = tokenError.localizedDescription
                }
                return
            }

            guard let token, !token.isEmpty else {
                DispatchQueue.main.async {
                    self.uploadingPhoto = false
                    self.errorMessage = "Не удалось получить Firebase ID Token."
                }
                return
            }

            guard let url = URL(
                string: "https://telegram-photo-storage.sataniusdarkc.workers.dev/upload"
            ) else {
                DispatchQueue.main.async {
                    self.uploadingPhoto = false
                    self.errorMessage = "Некорректный адрес загрузки фото."
                }
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

            URLSession.shared.dataTask(with: request) { [weak self] data, response, networkError in
                guard let self else {
                    return
                }

                if let networkError {
                    DispatchQueue.main.async {
                        self.uploadingPhoto = false
                        self.errorMessage = networkError.localizedDescription
                    }
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        self.uploadingPhoto = false
                        self.errorMessage = "Сервер не вернул HTTP-ответ."
                    }
                    return
                }

                let json = data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
                }

                guard (200...299).contains(http.statusCode) else {
                    let message = json?["error"] as? String
                        ?? "Ошибка загрузки фото \(http.statusCode)"

                    DispatchQueue.main.async {
                        self.uploadingPhoto = false
                        self.errorMessage = message
                    }
                    return
                }

                guard
                    let fileId = json?["fileId"] as? String,
                    !fileId.isEmpty
                else {
                    DispatchQueue.main.async {
                        self.uploadingPhoto = false
                        self.errorMessage = "Worker не вернул fileId."
                    }
                    return
                }

                DispatchQueue.main.async {
                    let cleanText = self.text
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    self.sendMessage(
                        cleanText: cleanText,
                        photoFileId: fileId
                    )
                }
            }
            .resume()
        }
    }

    private func sendMessage(
        cleanText: String,
        photoFileId: String
    ) {
        guard !cleanText.isEmpty || !photoFileId.isEmpty else {
            uploadingPhoto = false
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            sending = false
            uploadingPhoto = false
            errorMessage = "Пользователь не авторизован."
            return
        }

        let receiverId = uid == chat.buyerId
            ? chat.sellerId
            : chat.buyerId

        let firestore = Firestore.firestore()
        let chatDocument = firestore.collection("chats").document(chat.id)
        let messageDocument = chatDocument.collection("messages").document()
        let now = Int64(Date().timeIntervalSince1970 * 1000.0)

        let lastMessage = photoFileId.isEmpty
            ? cleanText
            : "📷 Фото"

        let chatData: [String: Any] = [
            "buyerId": chat.buyerId,
            "sellerId": chat.sellerId,
            "announcementId": chat.announcementId,
            "announcementTitle": chat.announcementTitle,
            "lastMessage": lastMessage,
            "lastSenderId": uid,
            "updatedAt": now,
            "unreadCount_\(receiverId)": FieldValue.increment(Int64(1))
        ]

        var messageData: [String: Any] = [
            "senderId": uid,
            "text": cleanText,
            "sentAt": now,
            "messageType": "NORMAL",
            "photoVerified": false
        ]

        if !photoFileId.isEmpty {
            messageData["photoFileId"] = photoFileId
        }

        let batch = firestore.batch()

        batch.setData(
            chatData,
            forDocument: chatDocument,
            merge: true
        )

        batch.setData(
            messageData,
            forDocument: messageDocument
        )

        if photoFileId.isEmpty {
            sending = true
        }

        errorMessage = nil

        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                self.sending = false
                self.uploadingPhoto = false

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                self.text = ""
                self.sendPush(
                    messageId: messageDocument.documentID
                )
            }
        }
    }

    private func prepareJPEG(_ source: UIImage) -> Data? {
        let maxSide: CGFloat = 900
        let width = source.size.width
        let height = source.size.height
        let longest = max(width, height)

        let targetSize: CGSize

        if longest > maxSide {
            let scale = maxSide / longest
            targetSize = CGSize(
                width: max(1, width * scale),
                height: max(1, height * scale)
            )
        } else {
            targetSize = source.size
        }

        let renderer = UIGraphicsImageRenderer(
            size: targetSize
        )

        let prepared = renderer.image { _ in
            source.draw(
                in: CGRect(
                    origin: .zero,
                    size: targetSize
                )
            )
        }

        let qualities: [CGFloat] = [
            0.80,
            0.70,
            0.60,
            0.50,
            0.40,
            0.30
        ]

        for quality in qualities {
            if
                let data = prepared.jpegData(
                    compressionQuality: quality
                ),
                data.count <= 400 * 1024
            {
                return data
            }
        }

        return nil
    }

    private func markRead() {
        guard let user = Auth.auth().currentUser else {
            return
        }

        user.getIDTokenForcingRefresh(false) { token, _ in
            guard let token, !token.isEmpty else {
                return
            }

            guard let url = URL(
                string: "https://telegram-photo-storage.sataniusdarkc.workers.dev/chat/read"
            ) else {
                return
            }

            let body: [String: Any] = [
                "chatId": self.chat.id
            ]

            guard let data = try? JSONSerialization.data(withJSONObject: body) else {
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.httpBody = data
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request).resume()
        }
    }

    private func sendPush(messageId: String) {
        guard let user = Auth.auth().currentUser else {
            return
        }

        user.getIDTokenForcingRefresh(false) { token, _ in
            guard let token, !token.isEmpty else {
                return
            }

            guard let url = URL(
                string: "https://telegram-photo-storage.sataniusdarkc.workers.dev/notify"
            ) else {
                return
            }

            let body: [String: Any] = [
                "chatId": self.chat.id,
                "messageId": messageId
            ]

            guard let data = try? JSONSerialization.data(withJSONObject: body) else {
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.httpBody = data
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request).resume()
        }
    }
}

struct ChatConversationIOSView: View {
    let chat: IOSChatSummary

    @StateObject private var viewModel: ChatConversationIOSViewModel
    @StateObject private var moderation = IOSModerationViewModel()
    @State private var showPhotoPicker = false
    @State private var showReportReasons = false
    @State private var showBlockConfirmation = false
    @Environment(\.dismiss) private var dismiss

    private let accentPink = Color(
        red: 233.0 / 255.0,
        green: 30.0 / 255.0,
        blue: 99.0 / 255.0
    )

    private var otherUserId: String {
        guard
            let uid =
                Auth.auth()
                    .currentUser?
                    .uid,
            !uid.isEmpty
        else {
            return ""
        }

        return uid == chat.buyerId
            ? chat.sellerId
            : chat.buyerId
    }

    init(chat: IOSChatSummary) {
        self.chat = chat
        _viewModel = StateObject(
            wrappedValue: ChatConversationIOSViewModel(chat: chat)
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(10)
                }

                if let message = moderation.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                }

                if let error = moderation.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.messages) { message in
                                ChatMessageBubbleIOSView(
                                    message: message,
                                    isMine: message.senderId == Auth.auth().currentUser?.uid
                                )
                                .id(message.id)
                            }
                        }
                        .padding(12)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let last = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                HStack(alignment: .bottom, spacing: 8) {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        if viewModel.uploadingPhoto {
                            ProgressView()
                                .tint(accentPink)
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(accentPink)
                        }
                    }
                    .disabled(
                        viewModel.uploadingPhoto
                            || viewModel.sending
                    )

                    TextField(
                        "Сообщение",
                        text: $viewModel.text
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.08))
                    )

                    Button {
                        viewModel.send()
                    } label: {
                        if viewModel.sending {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 34, height: 34)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(accentPink)
                        }
                    }
                    .disabled(
                        viewModel.sending
                            || viewModel.uploadingPhoto
                            || viewModel.text
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                    )
                }
                .padding(10)
            }
            .navigationTitle(
                chat.announcementTitle.isEmpty
                    ? "Чат"
                    : chat.announcementTitle
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showReportReasons = true
                        } label: {
                            Label(
                                "Пожаловаться",
                                systemImage: "exclamationmark.triangle"
                            )
                        }

                        Button(role: .destructive) {
                            showBlockConfirmation = true
                        } label: {
                            Label(
                                "Заблокировать пользователя",
                                systemImage: "person.crop.circle.badge.xmark"
                            )
                        }
                    } label: {
                        Image(
                            systemName: "ellipsis.circle"
                        )
                    }
                    .disabled(
                        moderation.isWorking
                            || otherUserId.isEmpty
                    )
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showPhotoPicker) {
            ChatPhotoPicker { image in
                showPhotoPicker = false
                viewModel.sendPhoto(image)
            }
        }
        .confirmationDialog(
            "Причина жалобы",
            isPresented: $showReportReasons,
            titleVisibility: .visible
        ) {
            Button("Запрещённый контент") {
                submitChatReport(
                    reason: "PROHIBITED_CONTENT"
                )
            }

            Button("Мошенничество") {
                submitChatReport(
                    reason: "FRAUD"
                )
            }

            Button("Оскорбления или угрозы") {
                submitChatReport(
                    reason: "HARASSMENT"
                )
            }

            Button("Спам") {
                submitChatReport(
                    reason: "SPAM"
                )
            }

            Button("Другое") {
                submitChatReport(
                    reason: "OTHER"
                )
            }

            Button(
                "Отмена",
                role: .cancel
            ) {
            }
        }
        .confirmationDialog(
            "Заблокировать пользователя?",
            isPresented: $showBlockConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Заблокировать",
                role: .destructive
            ) {
                moderation.block(
                    userId: otherUserId
                )
            }

            Button(
                "Отмена",
                role: .cancel
            ) {
            }
        } message: {
            Text(
                "Чаты и объявления этого пользователя будут скрыты."
            )
        }
        .onChange(of: moderation.message) { message in
            if message == "Пользователь заблокирован." {
                dismiss()
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private func submitChatReport(
        reason: String
    ) {
        moderation.report(
            reportedUserId: otherUserId,
            announcementId: chat.announcementId,
            chatId: chat.id,
            reason: reason
        )
    }
}

private struct ChatMessageBubbleIOSView: View {
    let message: IOSChatMessage
    let isMine: Bool

    private let accentPink = Color(
        red: 233.0 / 255.0,
        green: 30.0 / 255.0,
        blue: 99.0 / 255.0
    )

    var body: some View {
        HStack {
            if isMine {
                Spacer(minLength: 45)
            }

            VStack(alignment: .leading, spacing: 6) {
                if message.messageType == "PACKAGING_PROOF" && message.photoVerified {
                    Text("✅ Подтверждение упаковки")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }

                if !message.photoFileId.isEmpty {
                    WorkerPhotoView(
                        fileId: message.photoFileId,
                        cornerRadius: 9
                    )
                    .frame(width: 210, height: 210)
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .foregroundStyle(.white)
                }

                if message.sentAt > 0 {
                    Text(formattedDate(message.sentAt))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(isMine ? accentPink : Color.gray.opacity(0.38))
            )

            if !isMine {
                Spacer(minLength: 45)
            }
        }
    }

    private func formattedDate(_ milliseconds: Int64) -> String {
        let date = Date(
            timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM HH:mm"
        return formatter.string(from: date)
    }
}


private struct ChatPhotoPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onImagePicked: onImagePicked
        )
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

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(
            onImagePicked: @escaping (UIImage) -> Void
        ) {
            self.onImagePicked = onImagePicked
        }

        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            picker.dismiss(
                animated: true
            )

            guard
                let provider = results.first?.itemProvider,
                provider.canLoadObject(ofClass: UIImage.self)
            else {
                return
            }

            provider.loadObject(
                ofClass: UIImage.self
            ) { [weak self] object, _ in
                guard let image = object as? UIImage else {
                    return
                }

                DispatchQueue.main.async {
                    self?.onImagePicked(
                        image
                    )
                }
            }
        }
    }
}
