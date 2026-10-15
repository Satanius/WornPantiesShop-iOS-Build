import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

private let workerBaseURL = "https://telegram-photo-storage.sataniusdarkc.workers.dev"

struct IOSAnnouncement: Identifiable {
    let id: String
    let title: String
    let description: String
    let type: String
    let size: String
    let age: Int
    let daysWorn: Int
    let isVirgin: Bool
    let color: String
    let price: Int
    let authorId: String
    let country: String
    let photoFileIds: [String]
    let deliveryServices: [String]
    let createdAt: Int64
    let boostedUntil: Int64
    let availabilityStatus: String

    init(document: QueryDocumentSnapshot) {
        let data = document.data()

        id = document.documentID
        title = (data["title"] as? String)
            ?? (data["titleKey"] as? String)
            ?? ""
        description = (data["description"] as? String)
            ?? (data["descKey"] as? String)
            ?? ""
        type = (data["type"] as? String)
            ?? (data["typeKey"] as? String)
            ?? ""
        size = (data["size"] as? String) ?? "M"
        age = IOSAnnouncement.intValue(data["age"])
        daysWorn = IOSAnnouncement.intValue(data["daysWorn"])
        isVirgin = (data["isVirgin"] as? Bool) ?? false
        color = (data["color"] as? String)
            ?? (data["colorKey"] as? String)
            ?? ""
        price = IOSAnnouncement.intValue(data["price"])
        authorId = (data["authorId"] as? String) ?? ""
        country = (data["country"] as? String) ?? "UA"

        let multiple = (data["photoFileIds"] as? [Any])?
            .compactMap { $0 as? String }
            .filter { !$0.isEmpty }
            ?? []

        if !multiple.isEmpty {
            photoFileIds = Array(multiple.prefix(5))
        } else if let oldPhoto = data["photoFileId"] as? String, !oldPhoto.isEmpty {
            photoFileIds = [oldPhoto]
        } else {
            photoFileIds = []
        }

        if let rawDeliveryServices = data["deliveryServices"] as? [Any] {
            deliveryServices = rawDeliveryServices
                .compactMap { $0 as? String }
                .filter { !$0.isEmpty }
        } else {
            deliveryServices = ["NovaPoshta", "Ukrposhta", "Meest"]
        }

        createdAt = IOSAnnouncement.int64Value(data["createdAt"])
        boostedUntil = IOSAnnouncement.int64Value(data["boostedUntil"])

        if (data["sold"] as? Bool) == true {
            availabilityStatus = "SOLD"
        } else {
            availabilityStatus = (data["availabilityStatus"] as? String) ?? "AVAILABLE"
        }
    }

    private static func intValue(_ value: Any?) -> Int {
        if let number = value as? NSNumber {
            return number.intValue
        }

        return 0
    }

    private static func int64Value(_ value: Any?) -> Int64 {
        if let number = value as? NSNumber {
            return number.int64Value
        }

        return 0
    }
}

@MainActor
final class MainIOSViewModel: ObservableObject {
    @Published var country: String?
    @Published var avatarFileId: String?
    @Published var announcements: [IOSAnnouncement] = []
    @Published var favoriteIds: Set<String> = []
    @Published var blockedUserIds: Set<String> = []
    @Published var loading = true
    @Published var errorMessage: String?
    @Published var favoritesError: String?

    private var listener: ListenerRegistration?
    private var favoritesListener: ListenerRegistration?
    private var blockedUsersListener: ListenerRegistration?

    init() {
        loadProfile()
    }

    func stop() {
        listener?.remove()
        favoritesListener?.remove()
        blockedUsersListener?.remove()
        listener = nil
        favoritesListener = nil
        blockedUsersListener = nil
    }

    func reload() {
        listener?.remove()
        listener = nil
        announcements = []
        loading = true
        errorMessage = nil
        loadProfile()
    }

    private func loadProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            loading = false
            errorMessage = "Пользователь не авторизован."
            return
        }

        listenFavorites(uid: uid)
        listenBlockedUsers(uid: uid)

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { [weak self] document, error in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    if let error {
                        self.loading = false
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    let data = document?.data()
                    let loadedCountry = (data?["country"] as? String) ?? "UA"

                    self.country = loadedCountry
                    self.avatarFileId = data?["avatarFileId"] as? String
                    self.listenAnnouncements(country: loadedCountry)
                }
            }
    }

    func toggleFavorite(announcementId: String) {
        guard
            let uid = Auth.auth().currentUser?.uid,
            !uid.isEmpty,
            !announcementId.isEmpty
        else {
            return
        }

        let document = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("favorites")
            .document(announcementId)

        favoritesError = nil

        if favoriteIds.contains(announcementId) {
            document.delete { [weak self] error in
                Task { @MainActor in
                    if let error {
                        self?.favoritesError = error.localizedDescription
                    }
                }
            }
        } else {
            document.setData(
                [
                    "announcementId": announcementId,
                    "createdAt": Int64(Date().timeIntervalSince1970 * 1000.0)
                ]
            ) { [weak self] error in
                Task { @MainActor in
                    if let error {
                        self?.favoritesError = error.localizedDescription
                    }
                }
            }
        }
    }

    private func listenFavorites(uid: String) {
        favoritesListener?.remove()

        favoritesListener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("favorites")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    if let error {
                        self.favoritesError = error.localizedDescription
                        return
                    }

                    self.favoriteIds = Set(
                        snapshot?.documents.map { $0.documentID } ?? []
                    )
                    self.favoritesError = nil
                }
            }
    }

    private func listenBlockedUsers(uid: String) {
        blockedUsersListener?.remove()

        blockedUsersListener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("blockedUsers")
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    self.blockedUserIds = Set(
                        snapshot?.documents.map { $0.documentID } ?? []
                    )
                }
            }
    }

    private func listenAnnouncements(country: String) {
        listener?.remove()

        listener = Firestore.firestore()
            .collection("announcements")
            .whereField("sold", isEqualTo: false)
            .whereField("country", isEqualTo: country)
            .order(by: "boostedUntil", descending: true)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    self.loading = false

                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.errorMessage = nil
                    self.announcements = snapshot?.documents.map {
                        IOSAnnouncement(document: $0)
                    } ?? []
                }
            }
    }
}

struct MainIOSView: View {
    let onLogout: () -> Void

    @StateObject private var viewModel = MainIOSViewModel()
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var showAddAnnouncement = false
    @State private var showFilters = false
    @State private var searchQuery = ""
    @State private var filters = IOSAnnouncementFilters()
    @State private var selectedAnnouncement: IOSAnnouncement?

    private let accentPink = Color(
        red: 233.0 / 255.0,
        green: 30.0 / 255.0,
        blue: 99.0 / 255.0
    )

    private var visibleAnnouncements: [IOSAnnouncement] {
        viewModel.announcements.filter {
            !viewModel.blockedUserIds.contains($0.authorId)
        }
    }

    private var filteredAnnouncements: [IOSAnnouncement] {
        filters.apply(
            to: visibleAnnouncements,
            searchQuery: searchQuery
        )
    }

    private var favoriteAnnouncements: [IOSAnnouncement] {
        visibleAnnouncements.filter {
            viewModel.favoriteIds.contains($0.id)
                && $0.availabilityStatus == "AVAILABLE"
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                announcementsContent(
                    items: filteredAnnouncements,
                    emptyTitle: searchQuery.isEmpty && !filters.isActive
                        ? "Пока нет объявлений"
                        : "Ничего не найдено",
                    emptyIcon: "shippingbox"
                )
                .navigationTitle("Worn panties shop")
                .searchable(
                    text: $searchQuery,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Поиск объявлений"
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showFilters = true
                        } label: {
                            Image(
                                systemName: filters.isActive
                                    ? "line.3.horizontal.decrease.circle.fill"
                                    : "line.3.horizontal.decrease.circle"
                            )
                            .font(.system(size: 23))
                            .foregroundStyle(accentPink)
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddAnnouncement = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 25))
                                .foregroundStyle(accentPink)
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showProfile = true
                        } label: {
                            if let avatarFileId = viewModel.avatarFileId {
                                WorkerPhotoView(
                                    fileId: avatarFileId,
                                    cornerRadius: 18
                                )
                                .frame(width: 36, height: 36)
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 28))
                                    .foregroundStyle(accentPink)
                            }
                        }
                    }
                }
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Объявления", systemImage: "house")
            }
            .tag(0)

            NavigationView {
                announcementsContent(
                    items: favoriteAnnouncements,
                    emptyTitle: "Нет избранных объявлений",
                    emptyIcon: "heart"
                )
                .navigationTitle("Избранное")
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Избранное", systemImage: "heart.fill")
            }
            .tag(1)

            ChatsIOSView()
                .tabItem {
                    Label("Чаты", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(2)
        }
        .tint(accentPink)
        .onAppear {
            IOSPushNotifications
                .requestPermissionAndSync()

            if
                IOSPushNotifications
                    .consumePendingChatId() != nil
            {
                selectedTab = 2
            } else if
                IOSPushNotifications
                    .consumePendingOrderId() != nil
            {
                showProfile = true
            }
        }
        .onReceive(
            NotificationCenter.default
                .publisher(
                    for: .iosPushOpenChat
                )
        ) { _ in
            selectedTab = 2
        }
        .onReceive(
            NotificationCenter.default
                .publisher(
                    for: .iosPushOpenOrder
                )
        ) { _ in
            showProfile = true
        }
        .onDisappear {
            viewModel.stop()
        }
        .sheet(isPresented: $showAddAnnouncement) {
            AddAnnouncementIOSView(country: viewModel.country ?? "UA") {
                showAddAnnouncement = false
            }
        }
        .sheet(isPresented: $showFilters) {
            AnnouncementFiltersIOSView(filters: $filters)
        }
        .sheet(isPresented: $showProfile) {
            ProfileIOSView(
                country: viewModel.country ?? "UA",
                avatarFileId: viewModel.avatarFileId,
                onLogout: {
                    showProfile = false
                    onLogout()
                }
            )
        }
        .sheet(item: $selectedAnnouncement) { item in
            AnnouncementDetailsIOSView(item: item)
        }
    }

    @ViewBuilder
    private func announcementsContent(
        items: [IOSAnnouncement],
        emptyTitle: String,
        emptyIcon: String
    ) -> some View {
        Group {
            if viewModel.loading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Загрузка объявлений…")
                        .foregroundStyle(.secondary)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 14) {
                    Text("Не удалось загрузить данные")
                        .font(.headline)

                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Повторить") {
                        viewModel.reload()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentPink)
                }
                .padding(24)
            } else if items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: emptyIcon)
                        .font(.system(size: 38))
                        .foregroundStyle(.secondary)

                    Text(emptyTitle)
                        .font(.headline)

                    if let country = viewModel.country {
                        Text("Страна: \(country)")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(items) { item in
                            AnnouncementRow(
                                item: item,
                                isFavorite: viewModel.favoriteIds.contains(item.id),
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(
                                        announcementId: item.id
                                    )
                                },
                                onOpen: {
                                    selectedAnnouncement = item
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .refreshable {
                    viewModel.reload()
                }
            }

            if let favoritesError = viewModel.favoritesError {
                VStack {
                    Spacer()

                    Text(favoritesError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(10)
                }
                .allowsHitTesting(false)
            }
        }
    }
}

private struct AnnouncementRow: View {
    let item: IOSAnnouncement
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onOpen: () -> Void

    private let accentPink = Color(
        red: 233.0 / 255.0,
        green: 30.0 / 255.0,
        blue: 99.0 / 255.0
    )

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 12) {
                if let fileId = item.photoFileIds.first {
                    WorkerPhotoView(
                        fileId: fileId,
                        cornerRadius: 12
                    )
                    .frame(width: 112, height: 112)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))

                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 112, height: 112)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(item.title.isEmpty ? "Без названия" : item.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(.trailing, 32)

                    if !item.type.isEmpty {
                        Text(item.type)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text("Размер: \(item.size)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 2)

                    Text(
                        item.country == "RU"
                            ? "\(item.price) ₽"
                            : "\(item.price) ₴"
                    )
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accentPink)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onOpen()
            }

            Button {
                onFavoriteToggle()
            } label: {
                Image(
                    systemName: isFavorite
                        ? "heart.fill"
                        : "heart"
                )
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    isFavorite
                        ? accentPink
                        : Color.white
                )
                .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .padding(4)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.055))
        )
    }
}

private struct ProfileIOSView: View {
    let country: String
    let avatarFileId: String?
    let onLogout: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showSellerOrders = false
    @State private var showBuyerOrders = false
    @State private var showMyListings = false
    @State private var showBlockedUsers = false
    @State private var showSubmittedReports = false

    private let accentPink = Color(
        red: 233.0 / 255.0,
        green: 30.0 / 255.0,
        blue: 99.0 / 255.0
    )

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                if let avatarFileId {
                    WorkerPhotoView(
                        fileId: avatarFileId,
                        cornerRadius: 48
                    )
                    .frame(width: 96, height: 96)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 92))
                        .foregroundStyle(.secondary)
                }

                Text(Auth.auth().currentUser?.email ?? "Пользователь")
                    .font(.headline)

                Text(country == "UA" ? "Украина" : country)
                    .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    Button {
                        showMyListings = true
                    } label: {
                        Label("Мои объявления", systemImage: "rectangle.stack")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(accentPink)

                    Button {
                        showSellerOrders = true
                    } label: {
                        Label(
                            "Мои заказы",
                            systemImage: "shippingbox"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(accentPink)

                    Button {
                        showBuyerOrders = true
                    } label: {
                        Label(
                            "Мои покупки",
                            systemImage: "bag"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(accentPink)

                    Button {
                        showBlockedUsers = true
                    } label: {
                        Label(
                            "Заблокированные",
                            systemImage: "person.crop.circle.badge.xmark"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(accentPink)

                    Button {
                        showSubmittedReports = true
                    } label: {
                        Label(
                            "Мои жалобы",
                            systemImage: "exclamationmark.bubble"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(accentPink)
                }

                Spacer()

                Button(role: .destructive) {
                    onLogout()
                } label: {
                    Text("Выйти из аккаунта")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(accentPink)
            }
            .padding(24)
            .navigationTitle("Профиль")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showMyListings) {
            MyListingsIOSView()
        }
        .sheet(isPresented: $showSellerOrders) {
            SellerOrdersIOSView()
        }
        .sheet(isPresented: $showBuyerOrders) {
            BuyerOrdersIOSView()
        }
        .sheet(isPresented: $showBlockedUsers) {
            BlockedUsersIOSView()
        }
        .sheet(isPresented: $showSubmittedReports) {
            SubmittedReportsIOSView()
        }
    }
}

@MainActor
final class WorkerPhotoLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var failed = false

    private var loadedFileId: String?

    func load(fileId: String) {
        if loadedFileId == fileId, image != nil {
            return
        }

        loadedFileId = fileId
        failed = false

        guard let user = Auth.auth().currentUser else {
            failed = true
            return
        }

        user.getIDTokenForcingRefresh(false) { [weak self] token, error in
            guard error == nil, let token, !token.isEmpty else {
                Task { @MainActor in
                    self?.failed = true
                }
                return
            }

            var components = URLComponents(string: workerBaseURL + "/photo")
            components?.queryItems = [
                URLQueryItem(name: "fileId", value: fileId)
            ]

            guard let url = components?.url else {
                Task { @MainActor in
                    self?.failed = true
                }
                return
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 45
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )

            URLSession.shared.dataTask(with: request) { data, response, error in
                let http = response as? HTTPURLResponse

                guard
                    error == nil,
                    let data,
                    http?.statusCode == 200,
                    let loadedImage = UIImage(data: data)
                else {
                    Task { @MainActor in
                        self?.failed = true
                    }
                    return
                }

                Task { @MainActor in
                    self?.image = loadedImage
                    self?.failed = false
                }
            }
            .resume()
        }
    }
}

struct WorkerPhotoView: View {
    let fileId: String
    let cornerRadius: CGFloat

    @StateObject private var loader = WorkerPhotoLoader()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.06))

            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if loader.failed {
                Image(systemName: "photo.badge.exclamationmark")
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: fileId) {
            loader.load(fileId: fileId)
        }
    }
}
