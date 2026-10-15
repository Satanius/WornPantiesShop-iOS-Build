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
