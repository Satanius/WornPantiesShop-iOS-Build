import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AnnouncementDetailsIOSView: View {
    let item: IOSAnnouncement

    @Environment(\.dismiss) private var dismiss
    @State private var photoIndex = 0
    @State private var showCheckout = false
    @State private var openingChat = false
    @State private var chatError: String?
    @State private var openedChat: IOSChatSummary?
    @StateObject private var moderation = IOSModerationViewModel()
    @State private var showReportReasons = false
    @State private var showBlockConfirmation = false
    @AppStorage("appLanguage") private var languageRaw = "RU"

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }

    private let accentPink = Color(
        red: 233.0 / 255.0,
        green: 30.0 / 255.0,
        blue: 99.0 / 255.0
    )

    private let priceGreen = Color(
        red: 76.0 / 255.0,
        green: 175.0 / 255.0,
        blue: 80.0 / 255.0
    )

    private var isOwnAnnouncement: Bool {
        Auth.auth().currentUser?.uid == item.authorId
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(item.title.isEmpty ? iosT(language, "UNTITLED") : item.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text(formattedPrice)
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(priceGreen)

                    photoGallery

                    Divider()

                    Text(iosT(language, "LISTING_INFORMATION"))
                        .font(.headline)
                        .foregroundStyle(accentPink)

                    DetailLine(label: iosT(language, "TYPE"), value: item.type)
                    DetailLine(label: iosT(language, "SIZE"), value: item.size)
                    DetailLine(label: iosT(language, "COLOR"), value: item.color)
                    DetailLine(label: iosT(language, "MODEL_AGE"), value: String(item.age))
                    DetailLine(label: iosT(language, "DAYS_WORN"), value: String(item.daysWorn))
                    DetailLine(label: iosT(language, "VIRGIN"), value: item.isVirgin ? iosT(language, "YES") : iosT(language, "NO"))

                    if item.createdAt > 0 {
                        DetailLine(
                            label: iosT(language, "PUBLICATION_DATE"),
                            value: formattedDate(item.createdAt)
                        )
                    }

                    if !item.deliveryServices.isEmpty {
                        Divider()

                        Text(iosT(language, "DELIVERY_2"))
                            .font(.headline)
                            .foregroundStyle(accentPink)

                        Text(deliveryText)
                            .foregroundStyle(.white)
                    }

                    if !item.description.isEmpty {
                        Divider()

                        Text(iosT(language, "DESCRIPTION"))
                            .font(.headline)
                            .foregroundStyle(accentPink)

                        Text(item.description)
                            .foregroundStyle(.white)
                    }

                    Divider()

                    Button {
                        openSellerChat()
                    } label: {
                        ZStack {
                            if openingChat {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isOwnAnnouncement ? iosT(language, "THIS_IS_YOUR_LISTING") : iosT(language, "MESSAGE_SELLER"))
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(accentPink)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isOwnAnnouncement || openingChat)

                    if let chatError {
                        Text(chatError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        showCheckout = true
                    } label: {
                        Text(isOwnAnnouncement ? iosT(language, "THIS_IS_YOUR_LISTING") : iosT(language, "BUY"))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isOwnAnnouncement ? Color.secondary : accentPink)
                    .background(isOwnAnnouncement ? Color.white.opacity(0.08) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isOwnAnnouncement)

                    if !["UA", "RU"].contains(item.country) {
                        Text(iosT(language, "AUTO_DELIVERY_ONLY_UKRAINE"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if !isOwnAnnouncement {
                        Divider()

                        HStack(spacing: 12) {
                            Button {
                                showReportReasons = true
                            } label: {
                                Label(
                                    iosT(language, "REPORT"),
                                    systemImage: "exclamationmark.triangle"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .disabled(moderation.isWorking)

                            Button(role: .destructive) {
                                showBlockConfirmation = true
                            } label: {
                                Label(
                                    iosT(language, "BLOCK"),
                                    systemImage: "person.crop.circle.badge.xmark"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(moderation.isWorking)
                        }

                        if moderation.isWorking {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }

                        if let message = moderation.message {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.green)
                        }

                        if let error = moderation.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(red: 18.0 / 255.0, green: 18.0 / 255.0, blue: 18.0 / 255.0))
            .navigationTitle(iosT(language, "LISTING_2"))
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
        .sheet(isPresented: $showCheckout) {
            CheckoutIOSView(item: item) {
                showCheckout = false
                finishOrderAndOpenChat()
            }
        }
        .sheet(item: $openedChat) { chat in
            ChatConversationIOSView(chat: chat)
        }
        .confirmationDialog(
            iosT(language, "REPORT_REASON"),
            isPresented: $showReportReasons,
            titleVisibility: .visible
        ) {
            Button(iosT(language, "PROHIBITED_CONTENT")) {
                submitReport(
                    reason: "PROHIBITED_CONTENT"
                )
            }

            Button(iosT(language, "FRAUD")) {
                submitReport(
                    reason: "FRAUD"
                )
            }

            Button(iosT(language, "HARASSMENT_OR_THREATS")) {
                submitReport(
                    reason: "HARASSMENT"
                )
            }

            Button(iosT(language, "SPAM")) {
                submitReport(
                    reason: "SPAM"
                )
            }

            Button(iosT(language, "OTHER")) {
                submitReport(
                    reason: "OTHER"
                )
            }

            Button(
                iosT(language, "CANCEL"),
                role: .cancel
            ) {
            }
        }
        .confirmationDialog(
            iosT(language, "BLOCK_SELLER_QUESTION"),
            isPresented: $showBlockConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                iosT(language, "BLOCK"),
                role: .destructive
            ) {
                moderation.block(
                    userId: item.authorId
                )
            }

            Button(
                iosT(language, "CANCEL"),
                role: .cancel
            ) {
            }
        } message: {
            Text(
                iosT(language, "SELLER_CONTENT_WILL_BE_HIDDEN")
            )
        }
    }


    private func submitReport(
        reason: String
    ) {
        moderation.report(
            reportedUserId: item.authorId,
            announcementId: item.id,
            reason: reason
        )
    }

    private func finishOrderAndOpenChat() {
        guard
            let buyerId =
                Auth.auth()
                    .currentUser?
                    .uid,
            !buyerId.isEmpty
        else {
            chatError =
                iosT(
                    language,
                    "ORDER_PLACED_CHAT_USER_NOT_AUTHORIZED"
                )
            return
        }

        let sellerId =
            item.authorId

        guard
            !sellerId.isEmpty,
            buyerId != sellerId
        else {
            chatError =
                iosT(
                    language,
                    "ORDER_PLACED_CHAT_OPEN_FAILED"
                )
            return
        }

        let users =
            [buyerId, sellerId]
                .sorted()

        let chatId =
            users[0]
                + "_"
                + users[1]
                + "_"
                + item.id

        openingChat = true
        chatError = nil

        let firestore =
            Firestore.firestore()

        let chatDocument =
            firestore
                .collection("chats")
                .document(chatId)

        let chatBaseData:
            [String: Any] = [
                "buyerId": buyerId,
                "sellerId": sellerId,
                "announcementId": item.id,
                "announcementTitle": item.title
            ]

        chatDocument.setData(
            chatBaseData,
            merge: true
        ) { error in
            if let error {
                DispatchQueue.main.async {
                    openingChat = false
                    chatError =
                        iosT(
                            language,
                            "ORDER_PLACED_CHAT_ERROR",
                            error.localizedDescription
                        )
                }
                return
            }

            chatDocument
                .collection("messages")
                .limit(to: 1)
                .getDocuments {
                    snapshot,
                    error in

                    if let error {
                        DispatchQueue.main.async {
                            openingChat = false
                            chatError =
                                iosT(
                                    language,
                                    "ORDER_PLACED_CHAT_ERROR",
                                    error.localizedDescription
                                )
                        }
                        return
                    }

                    if
                        let snapshot,
                        !snapshot.documents.isEmpty
                    {
                        DispatchQueue.main.async {
                            openingChat = false
                            openedChat =
                                IOSChatSummary(
                                    id: chatId,
                                    buyerId: buyerId,
                                    sellerId: sellerId,
                                    announcementId:
                                        item.id,
                                    announcementTitle:
                                        item.title
                                )
                        }
                        return
                    }

                    DispatchQueue.main.async {
                        createInitialBuyMessage(
                            chatId:
                                chatId,
                            buyerId:
                                buyerId,
                            sellerId:
                                sellerId
                        )
                    }
                }
        }
    }

    private func createInitialBuyMessage(
        chatId: String,
        buyerId: String,
        sellerId: String
    ) {
        let firestore =
            Firestore.firestore()

        let chatDocument =
            firestore
                .collection("chats")
                .document(chatId)

        let text =
            iosT(
                language,
                "HELLO_I_D_LIKE_TO_BUY_THIS"
            )

        let now =
            Int64(
                Date()
                    .timeIntervalSince1970
                    * 1000.0
            )

        let messageDocument =
            chatDocument
                .collection("messages")
                .document()

        let chatData:
            [String: Any] = [
                "buyerId": buyerId,
                "sellerId": sellerId,
                "announcementId": item.id,
                "announcementTitle": item.title,
                "lastMessage": text,
                "lastSenderId": buyerId,
                "updatedAt": now,
                "unreadCount_\(sellerId)":
                    FieldValue.increment(
                        Int64(1)
                    )
            ]

        let messageData:
            [String: Any] = [
                "senderId": buyerId,
                "text": text,
                "sentAt": now,
                "messageType": "NORMAL",
                "photoVerified": false
            ]

        let batch =
            firestore.batch()

        batch.setData(
            chatData,
            forDocument:
                chatDocument,
            merge: true
        )

        batch.setData(
            messageData,
            forDocument:
                messageDocument
        )

        let messageId =
            messageDocument.documentID

        let announcementId =
            item.id

        let announcementTitle =
            item.title

        batch.commit { error in
            DispatchQueue.main.async {
                openingChat = false

                if let error {
                    chatError =
                        iosT(
                            language,
                            "ORDER_PLACED_FIRST_MESSAGE_FAILED",
                            error.localizedDescription
                        )
                    return
                }

                sendInitialBuyPush(
                    chatId: chatId,
                    messageId:
                        messageId
                )

                openedChat =
                    IOSChatSummary(
                        id: chatId,
                        buyerId: buyerId,
                        sellerId: sellerId,
                        announcementId:
                            announcementId,
                        announcementTitle:
                            announcementTitle,
                        lastMessage: text,
                        lastSenderId:
                            buyerId,
                        updatedAt: now,
                        unreadCount: 0
                    )
            }
        }
    }

    private func sendInitialBuyPush(
        chatId: String,
        messageId: String
    ) {
        guard
            let user =
                Auth.auth()
                    .currentUser
        else {
            return
        }

        user.getIDTokenForcingRefresh(
            false
        ) { token, _ in
            guard
                let token,
                !token.isEmpty
            else {
                return
            }

            guard
                let url =
                    URL(
                        string:
                            "https://telegram-photo-storage.sataniusdarkc.workers.dev/notify"
                    )
            else {
                return
            }

            let body:
                [String: Any] = [
                    "chatId": chatId,
                    "messageId": messageId
                ]

            guard
                let data =
                    try? JSONSerialization
                        .data(
                            withJSONObject:
                                body
                        )
            else {
                return
            }

            var request =
                URLRequest(
                    url: url
                )

            request.httpMethod =
                "POST"
            request.timeoutInterval =
                30
            request.httpBody =
                data

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

            URLSession.shared
                .dataTask(
                    with: request
                )
                .resume()
        }
    }

    private func openSellerChat() {
        guard let buyerId = Auth.auth().currentUser?.uid else {
            chatError =
            iosT(
                language,
                "PLEASE_SIGN_IN_FIRST"
            )
            return
        }

        let sellerId = item.authorId

        guard !sellerId.isEmpty, buyerId != sellerId else {
            return
        }

        let users = [buyerId, sellerId].sorted()
        let chatId = users[0] + "_" + users[1] + "_" + item.id

        openingChat = true
        chatError = nil

        let data: [String: Any] = [
            "buyerId": buyerId,
            "sellerId": sellerId,
            "announcementId": item.id,
            "announcementTitle": item.title
        ]

        Firestore.firestore()
            .collection("chats")
            .document(chatId)
            .setData(data, merge: true) { error in
                DispatchQueue.main.async {
                    openingChat = false

                    if let error {
                        chatError = error.localizedDescription
                        return
                    }

                    openedChat = IOSChatSummary(
                        id: chatId,
                        buyerId: buyerId,
                        sellerId: sellerId,
                        announcementId: item.id,
                        announcementTitle: item.title
                    )
                }
            }
    }

    @ViewBuilder
    private var photoGallery: some View {
        if item.photoFileIds.isEmpty {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))

                Image(systemName: "photo")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 300)
        } else {
            VStack(spacing: 8) {
                TabView(selection: $photoIndex) {
                    ForEach(Array(item.photoFileIds.enumerated()), id: \.offset) { index, fileId in
                        WorkerPhotoView(
                            fileId: fileId,
                            cornerRadius: 14
                        )
                        .tag(index)
                        .padding(.horizontal, 1)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 320)

                Text("\(photoIndex + 1) / \(item.photoFileIds.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var formattedPrice: String {
        item.country == "RU"
            ? "\(item.price) ₽"
            : "\(item.price) ₴"
    }

    private var deliveryText: String {
        item.deliveryServices
            .map { service in
                switch service {
                case "NovaPoshta":
                    return iosT(language, "NOVA_POSHTA_RU_NAME")
                case "Ukrposhta":
                    return iosT(language, "UKRPOSHTA")
                default:
                    return service
                }
            }
            .joined(separator: ", ")
    }

    private func formattedDate(_ milliseconds: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
}

private struct DetailLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label + ":")
                .foregroundStyle(.secondary)

            Spacer()

            Text(value.isEmpty ? "—" : value)
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct CheckoutIOSView: View {
    let item: IOSAnnouncement
    let onOrderPlaced: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedDeliveryService: String
    @State private var recipientName = ""
    @State private var recipientPhone = ""
    @State private var recipientCity = ""
    @State private var recipientArea = ""
    @State private var recipientDepartment = ""
    @State private var recipientPostalCode = ""
    @State private var rulesAccepted = false
    @State private var submitting = false
    @State private var errorMessage: String?
    @AppStorage("appLanguage") private var checkoutLanguageRaw = "RU"

    private var checkoutLanguage: IOSAppLanguage {
        iosLanguage(from: checkoutLanguageRaw)
    }

    private let workerURL = "https://telegram-photo-storage.sataniusdarkc.workers.dev"

    private let accentPink = Color(
        red: 233.0 / 255.0,
        green: 30.0 / 255.0,
        blue: 99.0 / 255.0
    )

    init(
        item: IOSAnnouncement,
        onOrderPlaced: @escaping () -> Void
    ) {
        self.item = item
        self.onOrderPlaced = onOrderPlaced

        _selectedDeliveryService = State(
            initialValue:
                item.country == "RU"
                    ? "CDEK"
                    : item.deliveryServices.first ?? ""
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(item.title.isEmpty ? iosT(checkoutLanguage, "UNKNOWN_ITEM") : item.title)
                        .font(.headline)

                    Text(iosT(checkoutLanguage, "CASH_ON_DELIVERY") + " " + formattedPrice)
                        .font(.headline)
                        .foregroundStyle(.green)

                    if !["UA", "RU"].contains(item.country) {
                        Text(iosT(checkoutLanguage, "AUTOMATIC_SHIPPING_IS_NOT_YET_AVAILABLE_FOR"))
                            .foregroundStyle(.red)
                    } else {
                        deliveryForm
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        submit()
                    } label: {
                        ZStack {
                            if submitting {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text(iosT(checkoutLanguage, "PLACE_ORDER"))
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.black)
                    .background(accentPink)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1.0 : 0.45)
                }
                .padding(20)
            }
            .background(Color(red: 18.0 / 255.0, green: 18.0 / 255.0, blue: 18.0 / 255.0))
            .navigationTitle(iosT(checkoutLanguage, "CHECKOUT_SHORT"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(iosT(checkoutLanguage, "CANCEL")) {
                        dismiss()
                    }
                    .disabled(submitting)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var deliveryForm: some View {
        Text(iosT(checkoutLanguage, "DELIVERY_SERVICE"))
            .font(.headline)
            .foregroundStyle(accentPink)

        Picker(iosT(checkoutLanguage, "DELIVERY_SERVICE"), selection: $selectedDeliveryService) {
            ForEach(availableDeliveryServices, id: \.self) { service in
                Text(deliveryName(service)).tag(service)
            }
        }
        .pickerStyle(.menu)

        TextField(iosT(checkoutLanguage, "RECIPIENTS_FULL_NAME"), text: $recipientName)
            .textContentType(.name)
            .iosField()

        TextField(
            item.country == "RU"
                ? iosT(checkoutLanguage, "PHONE") + " +7..."
                : iosT(checkoutLanguage, "PHONE_EXAMPLE"),
            text: $recipientPhone
        )
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
            .iosField()

        if selectedDeliveryService == "Ukrposhta" {
            Text(
                iosT(
                    checkoutLanguage,
                    "THE_UKRPOSHTA_DIRECTORY_IS_UNAVAILABLE_ENTER_THE"
                )
            )
            .font(.footnote)
            .foregroundStyle(.orange)
        }

        TextField(iosT(checkoutLanguage, "CITY_LOCALITY"), text: $recipientCity)
            .iosField()

        TextField(iosT(checkoutLanguage, "AREA_OPTIONAL"), text: $recipientArea)
            .iosField()

        if selectedDeliveryService == "Ukrposhta" {
            TextField(iosT(checkoutLanguage, "POSTAL_CODE"), text: $recipientPostalCode)
                .keyboardType(.numberPad)
                .iosField()
        }

        TextField(
            selectedDeliveryService == "Meest"
                ? iosT(checkoutLanguage, "MEEST_BRANCH_NUMBER_LONG")
                : selectedDeliveryService == "Ukrposhta"
                    ? iosT(checkoutLanguage, "UKRPOSHTA_BRANCH")
                    : selectedDeliveryService == "CDEK"
                        ? iosT(checkoutLanguage, "BRANCH") + " CDEK"
                        : iosT(checkoutLanguage, "NOVA_POSHTA_BRANCH_PARCEL_LOCKER"),
            text: $recipientDepartment
        )
        .iosField()

        Toggle(
            iosT(checkoutLanguage, "CHECKED_RECIPIENT_DATA_ACCEPT_RULES"),
            isOn: $rulesAccepted
        )
        .tint(accentPink)
    }

    private var availableDeliveryServices: [String] {
        let countryServices =
            item.country == "RU"
                ? ["CDEK"]
                : ["NovaPoshta", "Ukrposhta", "Meest"]

        let selected =
            item.deliveryServices.filter {
                countryServices.contains($0)
            }

        return selected.isEmpty
            ? countryServices
            : selected
    }

    private var canSubmit: Bool {
        ["UA", "RU"].contains(item.country)
            && !submitting
            && rulesAccepted
            && !selectedDeliveryService.isEmpty
            && availableDeliveryServices.contains(selectedDeliveryService)
            && !recipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !recipientPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !recipientCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !recipientDepartment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (
                selectedDeliveryService != "Ukrposhta"
                || recipientPostalCode.filter { $0.isNumber }.count == 5
            )
    }

    private var formattedPrice: String {
        item.country == "RU"
            ? "\(item.price) ₽"
            : "\(item.price) ₴"
    }

    private func deliveryName(_ service: String) -> String {
        switch service {
        case "NovaPoshta":
            return iosT(checkoutLanguage, "NOVA_POSHTA_RU_NAME")
        case "Ukrposhta":
            return iosT(checkoutLanguage, "UKRPOSHTA")
        default:
            return service
        }
    }

    private func submit() {
        guard canSubmit else {
            return
        }

        guard let user = Auth.auth().currentUser else {
            errorMessage = iosT(checkoutLanguage, "PLEASE_SIGN_IN_FIRST")
            return
        }

        submitting = true
        errorMessage = nil

        user.getIDTokenForcingRefresh(false) { token, tokenError in
            if let tokenError {
                finishWithError(tokenError.localizedDescription)
                return
            }

            guard let token, !token.isEmpty else {
                finishWithError(iosT(checkoutLanguage, "FAILED_TO_GET_FIREBASE_ID_TOKEN"))
                return
            }

            let delivery: [String: Any] = [
                "deliveryService": selectedDeliveryService,
                "recipientName": recipientName.trimmingCharacters(in: .whitespacesAndNewlines),
                "recipientPhone": recipientPhone.trimmingCharacters(in: .whitespacesAndNewlines),
                "recipientCity": recipientCity.trimmingCharacters(in: .whitespacesAndNewlines),
                "recipientCityRef": "",
                "recipientArea": recipientArea.trimmingCharacters(in: .whitespacesAndNewlines),
                "recipientSettlementType": "",
                "recipientDepartment": recipientDepartment.trimmingCharacters(in: .whitespacesAndNewlines),
                "recipientDepartmentRef": "",
                "recipientPostalCode": recipientPostalCode.filter { $0.isNumber },
                "recipientAddress": ""
            ]

            let body: [String: Any] = [
                "announcementId": item.id,
                "com/example/wornpantiesshop/delivery": delivery
            ]

            guard
                let url = URL(string: workerURL + "/create-order"),
                let data = try? JSONSerialization.data(withJSONObject: body)
            else {
                finishWithError(iosT(checkoutLanguage, "FAILED_TO_PREPARE_REQUEST"))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 45
            request.httpBody = data
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request) { data, response, networkError in
                if let networkError {
                    finishWithError(networkError.localizedDescription)
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    finishWithError(iosT(checkoutLanguage, "SERVER_DID_NOT_RETURN_HTTP_RESPONSE"))
                    return
                }

                let json = data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
                }

                if !(200...299).contains(http.statusCode) {
                    let message = json?["error"] as? String
                        ?? iosT(checkoutLanguage, "SERVER_ERROR_HTTP", String(http.statusCode))
                    finishWithError(message)
                    return
                }

                guard (json?["success"] as? Bool) == true else {
                    let message = json?["error"] as? String
                        ?? iosT(checkoutLanguage, "FAILED_TO_PLACE_ORDER")
                    finishWithError(message)
                    return
                }

                DispatchQueue.main.async {
                    submitting = false
                    onOrderPlaced()
                }
            }
            .resume()
        }
    }

    private func finishWithError(_ message: String) {
        DispatchQueue.main.async {
            submitting = false
            errorMessage = message
        }
    }
}

private extension View {
    func iosField() -> some View {
        self
            .padding(.horizontal, 12)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
            )
    }
}
