import SwiftUI
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
            errorMessage = iosT(iosCurrentLanguage(), "FAILED_TO_SEND_REPORT")
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
                        iosT(iosCurrentLanguage(), "REPORT_SENT_FOR_REVIEW")
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
                iosT(iosCurrentLanguage(), "FAILED_TO_BLOCK_USER")
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
                            iosT(iosCurrentLanguage(), "USER_BLOCKED")
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
                iosT(iosCurrentLanguage(), "USER_NOT_AUTHORIZED")
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
                iosT(iosCurrentLanguage(), "USER_NOT_AUTHORIZED")
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
    @AppStorage("appLanguage") private var languageRaw = "RU"

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }

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
                        iosT(language, "LOADING_PROGRESS")
                    )
                } else if let error =
                    viewModel.errorMessage
                {
                    VStack(
                        spacing: 14
                    ) {
                        Text(
                            iosT(language, "FAILED_TO_LOAD_LIST")
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
                            iosT(language, "RETRY")
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
                            iosT(language, "NO_BLOCKED_USERS")
                        )
                        .font(.headline)

                        Text(
                            iosT(language, "BLOCKED_USERS_APPEAR_HERE")
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
                                    iosT(language, "USER")
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
                                    iosT(language, "UNBLOCK")
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
                iosT(language, "BLOCKED_USERS")
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
                        iosT(language, "READY")
                    ) {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .confirmationDialog(
            iosT(language, "UNBLOCK_USER_QUESTION"),
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
                iosT(language, "UNBLOCK")
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
                iosT(language, "CANCEL"),
                role: .cancel
            ) {
                pendingUnblock = nil
            }
        } message: {
            Text(
                iosT(language, "UNBLOCKED_CONTENT_VISIBLE")
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


struct IOSSubmittedReport: Identifiable {
    let id: String
    let reportedUserId: String
    let announcementId: String
    let chatId: String
    let reason: String
    let status: String
    let source: String
    let createdAt: Int64

    init(
        document: QueryDocumentSnapshot
    ) {
        let data = document.data()

        id = document.documentID
        reportedUserId =
            data["reportedUserId"]
                as? String
                ?? ""
        announcementId =
            data["announcementId"]
                as? String
                ?? ""
        chatId =
            data["chatId"]
                as? String
                ?? ""
        reason =
            data["reason"]
                as? String
                ?? "OTHER"
        status =
            data["status"]
                as? String
                ?? "OPEN"
        source =
            data["source"]
                as? String
                ?? ""

        if let number =
            data["createdAt"]
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
final class IOSSubmittedReportsViewModel:
    ObservableObject
{
    @Published var reports:
        [IOSSubmittedReport] = []
    @Published var loading = true
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
                iosT(iosCurrentLanguage(), "USER_NOT_AUTHORIZED")
            return
        }

        loading = true
        errorMessage = nil

        listener =
            Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("reports")
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

                        self.reports =
                            (snapshot?.documents ?? [])
                                .map {
                                    IOSSubmittedReport(
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
}

struct SubmittedReportsIOSView: View {
    @StateObject private var viewModel =
        IOSSubmittedReportsViewModel()
    @AppStorage("appLanguage") private var languageRaw = "RU"

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }

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
                        iosT(language, "LOADING")
                    )
                } else if let error =
                    viewModel.errorMessage
                {
                    VStack(
                        spacing: 14
                    ) {
                        Text(
                            iosT(language, "FAILED_TO_LOAD_REPORTS")
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
                            iosT(language, "RETRY")
                        ) {
                            viewModel.start()
                        }
                        .buttonStyle(
                            .borderedProminent
                        )
                        .tint(accentPink)
                    }
                    .padding(24)
                } else if
                    viewModel.reports.isEmpty
                {
                    VStack(
                        spacing: 12
                    ) {
                        Image(
                            systemName:
                                "exclamationmark.bubble"
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
                            iosT(language, "NO_REPORTS_YET")
                        )
                        .font(.headline)

                        Text(
                            iosT(language, "SUBMITTED_REPORTS_APPEAR_HERE")
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
                        viewModel.reports
                    ) { report in
                        VStack(
                            alignment:
                                .leading,
                            spacing: 8
                        ) {
                            HStack {
                                Text(
                                    reasonTitle(
                                        report.reason
                                    )
                                )
                                .font(.headline)

                                Spacer()

                                Text(
                                    statusTitle(
                                        report.status
                                    )
                                )
                                .font(
                                    .caption.bold()
                                )
                                .foregroundStyle(
                                    statusColor(
                                        report.status
                                    )
                                )
                            }

                            if
                                report.createdAt
                                    > 0
                            {
                                Text(
                                    formattedDate(
                                        report.createdAt
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            if
                                !report
                                    .announcementId
                                    .isEmpty
                            {
                                Label(
                                    iosT(
                                        language,
                                        "LISTING_ID_LABEL",
                                        shortId(report.announcementId)
                                    ),
                                    systemImage:
                                        "rectangle.stack"
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            if
                                !report
                                    .chatId
                                    .isEmpty
                            {
                                Label(
                                    iosT(
                                        language,
                                        "CHAT_ID_LABEL",
                                        shortId(report.chatId)
                                    ),
                                    systemImage:
                                        "bubble.left.and.bubble.right"
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            if
                                !report
                                    .reportedUserId
                                    .isEmpty
                            {
                                Label(
                                    iosT(
                                        language,
                                        "USER_ID_LABEL",
                                        shortId(report.reportedUserId)
                                    ),
                                    systemImage:
                                        "person"
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }
                        .padding(
                            .vertical,
                            5
                        )
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(
                iosT(language, "MY_REPORTS")
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
                        iosT(language, "READY")
                    ) {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private func reasonTitle(
        _ reason: String
    ) -> String {
        switch reason.uppercased() {
        case "PROHIBITED_CONTENT":
            return iosT(language, "PROHIBITED_CONTENT")
        case "FRAUD":
            return iosT(language, "FRAUD")
        case "HARASSMENT":
            return iosT(language, "HARASSMENT_OR_THREATS")
        case "SPAM":
            return iosT(language, "SPAM")
        default:
            return iosT(language, "OTHER")
        }
    }

    private func statusTitle(
        _ status: String
    ) -> String {
        switch status.uppercased() {
        case "OPEN":
            return iosT(language, "REPORT_STATUS_OPEN")
        case "REVIEWING":
            return iosT(language, "REPORT_STATUS_REVIEWING")
        case "RESOLVED":
            return iosT(language, "REPORT_STATUS_RESOLVED")
        case "REJECTED":
            return iosT(language, "REPORT_STATUS_REJECTED")
        case "CLOSED":
            return iosT(language, "REPORT_STATUS_CLOSED")
        default:
            return status
        }
    }

    private func statusColor(
        _ status: String
    ) -> Color {
        switch status.uppercased() {
        case "RESOLVED",
             "CLOSED":
            return .green
        case "REJECTED":
            return .red
        case "REVIEWING":
            return .blue
        default:
            return .orange
        }
    }

    private func formattedDate(
        _ millis: Int64
    ) -> String {
        let date = Date(
            timeIntervalSince1970:
                Double(millis)
                / 1000.0
        )

        let formatter =
            DateFormatter()
        formatter.locale =
            Locale(
                identifier:
                    language == .ru
                        ? "ru_RU"
                        : language == .ua
                            ? "uk_UA"
                            : "en_US"
            )
        formatter.dateStyle =
            .medium
        formatter.timeStyle =
            .short

        return formatter.string(
            from: date
        )
    }

    private func shortId(
        _ id: String
    ) -> String {
        guard id.count > 16 else {
            return id
        }

        let prefix =
            id.prefix(7)
        let suffix =
            id.suffix(7)

        return "\(prefix)…\(suffix)"
    }
}
