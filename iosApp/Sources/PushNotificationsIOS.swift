import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
@preconcurrency import FirebaseMessaging

extension Notification.Name {
    static let iosPushOpenChat = Notification.Name(
        "iosPushOpenChat"
    )

    static let iosPushOpenOrder = Notification.Name(
        "iosPushOpenOrder"
    )
}

final class IOSAppDelegate:
    NSObject,
    UIApplicationDelegate,
    @preconcurrency UNUserNotificationCenterDelegate,
    @preconcurrency MessagingDelegate
{
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken

        Task { @MainActor in
            IOSPushNotifications.syncCurrentToken()
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
    }

    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        guard
            let fcmToken,
            !fcmToken.isEmpty
        else {
            return
        }

        Task { @MainActor in
            IOSPushNotifications.save(
                token: fcmToken
            )
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(
            [
                .banner,
                .sound,
                .badge
            ]
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler:
            @escaping () -> Void
    ) {
        let userInfo =
            response.notification
                .request
                .content
                .userInfo

        let chatId =
            userInfo["chatId"] as? String

        let orderId =
            userInfo["orderId"] as? String

        DispatchQueue.main.async {
            IOSPushNotifications.handleOpen(
                chatId: chatId,
                orderId: orderId
            )
        }

        completionHandler()
    }
}

enum IOSPushNotifications {
    private static let pendingChatKey =
        "iosPendingPushChatId"

    private static let pendingOrderKey =
        "iosPendingPushOrderId"

    @MainActor
    static func requestPermissionAndSync() {
        UNUserNotificationCenter.current()
            .requestAuthorization(
                options: [
                    .alert,
                    .badge,
                    .sound
                ]
            ) { granted, _ in
                guard granted else {
                    return
                }

                DispatchQueue.main.async {
                    UIApplication.shared
                        .registerForRemoteNotifications()

                    syncCurrentToken()
                }
            }
    }

    @MainActor
    static func syncCurrentToken() {
        Messaging.messaging()
            .token { token, _ in
                guard
                    let token,
                    !token.isEmpty
                else {
                    return
                }

                Task { @MainActor in
                    save(
                        token: token
                    )
                }
            }
    }

    @MainActor
    static func save(
        token: String
    ) {
        guard
            !token.isEmpty,
            let uid =
                Auth.auth()
                    .currentUser?
                    .uid,
            !uid.isEmpty
        else {
            return
        }

        Firestore.firestore()
            .collection("userPrivate")
            .document(uid)
            .setData(
                [
                    "fcmToken": token
                ],
                merge: true
            )
    }

    @MainActor
    static func clearCurrentTokenForCurrentUser()
        async
    {
        guard
            let uid =
                Auth.auth()
                    .currentUser?
                    .uid,
            !uid.isEmpty
        else {
            return
        }

        do {
            let token =
                try await currentFCMToken()

            let document =
                Firestore.firestore()
                    .collection("userPrivate")
                    .document(uid)

            let snapshot =
                try await document
                    .getDocument()

            let storedToken =
                snapshot.get(
                    "fcmToken"
                ) as? String

            if
                let storedToken,
                !storedToken.isEmpty,
                storedToken == token
            {
                try await document
                    .updateData(
                        [
                            "fcmToken":
                                FieldValue.delete()
                        ]
                    )
            }
        } catch {
        }
    }

    @MainActor
    static func handleOpen(
        chatId: String?,
        orderId: String?
    ) {
        if
            let chatId,
            !chatId.isEmpty
        {
            UserDefaults.standard.set(
                chatId,
                forKey: pendingChatKey
            )

            NotificationCenter.default.post(
                name: .iosPushOpenChat,
                object: nil,
                userInfo: [
                    "chatId": chatId
                ]
            )

            return
        }

        if
            let orderId,
            !orderId.isEmpty
        {
            UserDefaults.standard.set(
                orderId,
                forKey: pendingOrderKey
            )

            NotificationCenter.default.post(
                name: .iosPushOpenOrder,
                object: nil,
                userInfo: [
                    "orderId": orderId
                ]
            )
        }
    }

    @MainActor
    static func consumePendingChatId()
        -> String?
    {
        let value =
            UserDefaults.standard
                .string(
                    forKey: pendingChatKey
                )

        UserDefaults.standard
            .removeObject(
                forKey: pendingChatKey
            )

        return value
    }

    @MainActor
    static func consumePendingOrderId()
        -> String?
    {
        let value =
            UserDefaults.standard
                .string(
                    forKey: pendingOrderKey
                )

        UserDefaults.standard
            .removeObject(
                forKey: pendingOrderKey
            )

        return value
    }

    @MainActor
    private static func currentFCMToken()
        async throws -> String
    {
        try await withCheckedThrowingContinuation {
            (
                continuation:
                    CheckedContinuation<
                        String,
                        Error
                    >
            ) in

            Messaging.messaging()
                .token { token, error in
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
                                        "Push",
                                    code: 1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "FCM token is empty."
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
    }
}
