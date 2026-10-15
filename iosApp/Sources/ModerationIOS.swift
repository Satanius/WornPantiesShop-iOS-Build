import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class IOSModerationViewModel: ObservableObject {
    @Published var isWorking = false
    @Published var message: String?
    @Published var errorMessage: String?

    func report(
        reportedUserId: String,
        announcementId: String = "",
        chatId: String = "",
        reason: String
    ) {
        guard !isWorking else {
            return
        }

        guard
            let reporterId =
                Auth.auth()
                    .currentUser?
                    .uid,
            !reporterId.isEmpty,
            !reportedUserId.isEmpty,
            reporterId != reportedUserId
        else {
            errorMessage = "Не удалось отправить жалобу."
            return
        }

        isWorking = true
        message = nil
        errorMessage = nil

        let reportDocument =
            Firestore.firestore()
                .collection("users")
                .document(reporterId)
                .collection("reports")
                .document()

        var data: [String: Any] = [
            "reporterId": reporterId,
            "reportedUserId": reportedUserId,
            "reason": reason,
            "status": "OPEN",
            "source": "IOS",
            "createdAt":
                Int64(
                    Date()
                        .timeIntervalSince1970
                        * 1000.0
                )
        ]

        if !announcementId.isEmpty {
            data["announcementId"] =
                announcementId
        }

        if !chatId.isEmpty {
            data["chatId"] =
                chatId
        }

        reportDocument.setData(
            data
        ) { [weak self] error in
            Task { @MainActor in
                guard let self else {
                    return
                }

                self.isWorking = false

                if let error {
                    self.errorMessage =
                        error.localizedDescription
                } else {
                    self.message =
                        "Жалоба отправлена на проверку."
                }
            }
        }
    }

    func block(
        userId: String
    ) {
        guard !isWorking else {
            return
        }

        guard
            let currentUid =
                Auth.auth()
                    .currentUser?
                    .uid,
            !currentUid.isEmpty,
            !userId.isEmpty,
            currentUid != userId
        else {
            errorMessage =
                "Не удалось заблокировать пользователя."
            return
        }

        isWorking = true
        message = nil
        errorMessage = nil

        Firestore.firestore()
            .collection("users")
            .document(currentUid)
            .collection("blockedUsers")
            .document(userId)
            .setData(
                [
                    "blockedUserId":
                        userId,
                    "createdAt":
                        Int64(
                            Date()
                                .timeIntervalSince1970
                                * 1000.0
                        )
                ]
            ) { [weak self] error in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    self.isWorking = false

                    if let error {
                        self.errorMessage =
                            error.localizedDescription
                    } else {
                        self.message =
                            "Пользователь заблокирован."
                    }
                }
            }
    }
}


struct IOSBlockedUser: Identifiable {
    let id: String
    let createdAt: Int64

    init(
        document: QueryDocumentSnapshot
    ) {
        id = document.documentID

        if let number =
            document.data()["createdAt"]
                as? NSNumber
        {
            createdAt =
                number.int64Value
        } else {
            createdAt = 0
        }
    }
}

@MainActor
final class IOSBlockedUsersViewModel:
    ObservableObject
{
    @Published var users: [IOSBlockedUser] = []
    @Published var loading = true
    @Published var unblockingId: String?
    @Published var errorMessage: String?

    private var listener:
        ListenerRegistration?

    init() {
        start()
    }

    func start() {
        stop()

        guard
            let uid =
                Auth.auth()
                    .currentUser?
                    .uid,
            !uid.isEmpty
        else {
            loading = false
            errorMessage =
                "Пользователь не авторизован."
            return
        }

        loading = true
        errorMessage = nil

        listener =
            Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("blockedUsers")
                .addSnapshotListener {
                    [weak self]
                    snapshot,
                    error in

                    Task { @MainActor in
                        guard let self else {
                            return
                        }

                        self.loading = false

                        if let error {
                            self.errorMessage =
                                error.localizedDescription
                            return
                        }

                        self.users =
                            (snapshot?.documents ?? [])
                                .map {
                                    IOSBlockedUser(
                                        document: $0
                                    )
                                }
                                .sorted {
                                    $0.createdAt
                                        > $1.createdAt
                                }

                        self.errorMessage = nil
                    }
                }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func unblock(
        _ user: IOSBlockedUser
    ) {
        guard unblockingId == nil else {
            return
        }

        guard
            let uid =
                Auth.auth()
                    .currentUser?
                    .uid,
            !uid.isEmpty
        else {
            errorMessage =
                "Пользователь не авторизован."
            return
        }

        unblockingId = user.id
        errorMessage = nil

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("blockedUsers")
            .document(user.id)
            .delete {
                [weak self] error in

                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    self.unblockingId = nil

                    if let error {
                        self.errorMessage =
                            error.localizedDescription
                    }
                }
            }
    }
}

struct BlockedUsersIOSView: View {
    @StateObject private var viewModel =
        IOSBlockedUsersViewModel()

    @State private var pendingUnblock:
        IOSBlockedUser?

    @Environment(\.dismiss)
    private var dismiss

    private let accentPink = Color(
        red: 233.0 / 255.0,
        green: 30.0 / 255.0,
        blue: 99.0 / 255.0
    )

    var body: some View {
        NavigationView {
            Group {
                if viewModel.loading {
                    ProgressView(
                        "Загрузка…"
                    )
                } else if let error =
                    viewModel.errorMessage
                {
                    VStack(
                        spacing: 14
                    ) {
                        Text(
                            "Не удалось загрузить список"
                        )
                        .font(.headline)

                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(
                                .secondary
                            )
                            .multilineTextAlignment(
                                .center
                            )

                        Button(
                            "Повторить"
                        ) {
                            viewModel.start()
                        }
                        .buttonStyle(
                            .borderedProminent
                        )
                        .tint(accentPink)
                    }
                    .padding(24)
                } else if viewModel.users.isEmpty {
                    VStack(
                        spacing: 12
                    ) {
                        Image(
                            systemName:
                                "person.crop.circle.badge.checkmark"
                        )
                        .font(
                            .system(
                                size: 44
                            )
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        Text(
                            "Нет заблокированных пользователей"
                        )
                        .font(.headline)

                        Text(
                            "Заблокированные пользователи появятся здесь."
                        )
                        .font(.footnote)
                        .foregroundStyle(
                            .secondary
                        )
                        .multilineTextAlignment(
                            .center
                        )
                    }
                    .padding(24)
                } else {
                    List(
                        viewModel.users
                    ) { user in
                        HStack(
                            spacing: 12
                        ) {
                            Image(
                                systemName:
                                    "person.crop.circle.badge.xmark"
                            )
                            .font(
                                .system(
                                    size: 30
                                )
                            )
                            .foregroundStyle(
                                .secondary
                            )

                            VStack(
                                alignment:
                                    .leading,
                                spacing: 4
                            ) {
                                Text(
                                    "Пользователь"
                                )
                                .font(.headline)

                                Text(
                                    shortId(
                                        user.id
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            Spacer()

                            if
                                viewModel
                                    .unblockingId
                                    == user.id
                            {
                                ProgressView()
                            } else {
                                Button(
                                    "Разблокировать"
                                ) {
                                    pendingUnblock =
                                        user
                                }
                                .buttonStyle(
                                    .bordered
                                )
                                .tint(
                                    accentPink
                                )
                            }
                        }
                        .padding(
                            .vertical,
                            4
                        )
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(
                "Заблокированные"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .navigationBarTrailing
                ) {
                    Button(
                        "Готово"
                    ) {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .confirmationDialog(
            "Разблокировать пользователя?",
            isPresented: Binding(
                get: {
                    pendingUnblock != nil
                },
                set: { value in
                    if !value {
                        pendingUnblock = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(
                "Разблокировать"
            ) {
                guard
                    let user =
                        pendingUnblock
                else {
                    return
                }

                pendingUnblock = nil
                viewModel.unblock(
                    user
                )
            }

            Button(
                "Отмена",
                role: .cancel
            ) {
                pendingUnblock = nil
            }
        } message: {
            Text(
                "Его объявления и чаты снова будут видны."
            )
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private func shortId(
        _ id: String
    ) -> String {
        guard id.count > 12 else {
            return id
        }

        let prefix =
            id.prefix(6)
        let suffix =
            id.suffix(6)

        return "\(prefix)…\(suffix)"
    }
}
