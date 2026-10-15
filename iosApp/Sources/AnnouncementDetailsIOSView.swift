import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AnnouncementDetailsIOSView: View {
    let item: IOSAnnouncement

    @Environment(\.dismiss) private var dismiss
    @State private var photoIndex = 0
    @State private var showCheckout = false
    @State private var orderPlaced = false
    @State private var openingChat = false
    @State private var chatError: String?
    @State private var openedChat: IOSChatSummary?

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
                    Text(item.title.isEmpty ? "Без названия" : item.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text(formattedPrice)
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(priceGreen)

                    photoGallery

                    Divider()

                    Text("Информация об объявлении")
                        .font(.headline)
                        .foregroundStyle(accentPink)

                    DetailLine(label: "Тип", value: item.type)
                    DetailLine(label: "Размер", value: item.size)
                    DetailLine(label: "Цвет", value: item.color)
                    DetailLine(label: "Возраст модели", value: String(item.age))
                    DetailLine(label: "Дней носили", value: String(item.daysWorn))
                    DetailLine(label: "Девственница", value: item.isVirgin ? "Да" : "Нет")

                    if item.createdAt > 0 {
                        DetailLine(
                            label: "Дата публикации",
                            value: formattedDate(item.createdAt)
                        )
                    }

                    if !item.deliveryServices.isEmpty {
                        Divider()

                        Text("Доставка")
                            .font(.headline)
                            .foregroundStyle(accentPink)

                        Text(deliveryText)
                            .foregroundStyle(.white)
                    }

                    if !item.description.isEmpty {
                        Divider()

                        Text("Описание")
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
                                Text(isOwnAnnouncement ? "Это ваше объявление" : "Написать продавцу")
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
                        Text(isOwnAnnouncement ? "Это ваше объявление" : "Купить")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isOwnAnnouncement ? Color.secondary : accentPink)
                    .background(isOwnAnnouncement ? Color.white.opacity(0.08) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isOwnAnnouncement)

                    if item.country != "UA" {
                        Text("Автоматическое оформление доставки пока доступно только для Украины.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
            .background(Color(red: 18.0 / 255.0, green: 18.0 / 255.0, blue: 18.0 / 255.0))
            .navigationTitle("Объявление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showCheckout) {
            CheckoutIOSView(item: item) {
                showCheckout = false
                orderPlaced = true
            }
        }
        .sheet(item: $openedChat) { chat in
            ChatConversationIOSView(chat: chat)
        }
        .alert("Заказ оформлен", isPresented: $orderPlaced) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Заказ создан и отправлен продавцу.")
        }
    }


    private func openSellerChat() {
        guard let buyerId = Auth.auth().currentUser?.uid else {
            chatError = "Сначала войдите в аккаунт."
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
                    return "Новая почта"
                case "Ukrposhta":
                    return "Укрпочта"
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
            initialValue: item.deliveryServices.first ?? ""
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(item.title.isEmpty ? "Товар" : item.title)
                        .font(.headline)

                    Text("Наложенный платёж: " + formattedPrice)
                        .font(.headline)
                        .foregroundStyle(.green)

                    if item.country != "UA" {
                        Text("Автоматическая доставка для этой страны пока недоступна.")
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
                                Text("Оформить заказ")
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
            .navigationTitle("Оформление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
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
        Text("Служба доставки")
            .font(.headline)
            .foregroundStyle(accentPink)

        Picker("Служба доставки", selection: $selectedDeliveryService) {
            ForEach(item.deliveryServices, id: \.self) { service in
                Text(deliveryName(service)).tag(service)
            }
        }
        .pickerStyle(.menu)

        TextField("ФИО получателя", text: $recipientName)
            .textContentType(.name)
            .iosField()

        TextField("Телефон, например +380...", text: $recipientPhone)
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
            .iosField()

        TextField("Город / населённый пункт", text: $recipientCity)
            .iosField()

        TextField("Область (необязательно)", text: $recipientArea)
            .iosField()

        if selectedDeliveryService == "Ukrposhta" {
            TextField("Почтовый индекс", text: $recipientPostalCode)
                .keyboardType(.numberPad)
                .iosField()
        }

        TextField(
            selectedDeliveryService == "Meest"
                ? "Номер отделения Meest"
                : selectedDeliveryService == "Ukrposhta"
                    ? "Отделение Укрпочты"
                    : "Отделение / почтомат Новой почты",
            text: $recipientDepartment
        )
        .iosField()

        Toggle(
            "Я проверил данные получателя и принимаю правила оформления заказа",
            isOn: $rulesAccepted
        )
        .tint(accentPink)
    }

    private var canSubmit: Bool {
        item.country == "UA"
            && !submitting
            && rulesAccepted
            && !selectedDeliveryService.isEmpty
            && item.deliveryServices.contains(selectedDeliveryService)
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
            return "Новая почта"
        case "Ukrposhta":
            return "Укрпочта"
        default:
            return service
        }
    }

    private func submit() {
        guard canSubmit else {
            return
        }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "Сначала войдите в аккаунт."
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
                finishWithError("Не удалось получить Firebase ID Token.")
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
                finishWithError("Не удалось подготовить запрос.")
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
                    finishWithError("Сервер не вернул HTTP-ответ.")
                    return
                }

                let json = data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
                }

                if !(200...299).contains(http.statusCode) {
                    let message = json?["error"] as? String
                        ?? "Ошибка сервера \(http.statusCode)"
                    finishWithError(message)
                    return
                }

                guard (json?["success"] as? Bool) == true else {
                    let message = json?["error"] as? String
                        ?? "Не удалось оформить заказ."
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
