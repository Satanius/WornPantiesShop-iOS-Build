import SwiftUI
import UIKit
import PhotosUI
import ImageIO
import CryptoKit
import UniformTypeIdentifiers
import FirebaseAuth
import FirebaseFirestore

private let listingWorkerURL = "https://telegram-photo-storage.sataniusdarkc.workers.dev"
private let listingTypes = ["Шортики", "Стринги", "Танга", "Бикини", "Слипы", "Бразилиана", "Кружевные", "Другое"]
private let listingSizes = ["XS", "S", "M", "L", "XL"]
private let listingColors = ["Черный", "Красный", "Розовый", "Белый", "Синий", "Другой"]
private let listingDeliveryServices = ["NovaPoshta", "Ukrposhta", "Meest"]

private struct ListingPhoto: Identifiable {
    let id = UUID()
    let data: Data
    let image: UIImage
}

@MainActor
private final class ListingEditorModel: ObservableObject {
    @Published var title: String
    @Published var description: String
    @Published var price: String
    @Published var age: String
    @Published var daysWorn: String
    @Published var isVirgin: Bool
    @Published var type: String
    @Published var size: String
    @Published var color: String
    @Published var deliveryServices: Set<String>
    @Published var photos: [ListingPhoto] = []
    @Published var saving = false
    @Published var saved = false
    @Published var errorMessage: String?

    let announcementId: String?

    init(announcement: IOSAnnouncement? = nil) {
        announcementId = announcement?.id
        title = announcement?.title ?? ""
        description = announcement?.description ?? ""
        price = announcement.map { String($0.price) } ?? ""
        age = announcement.map { String($0.age) } ?? "18"
        daysWorn = announcement.map { String($0.daysWorn) } ?? "1"
        isVirgin = announcement?.isVirgin ?? false
        type = listingTypes.contains(announcement?.type ?? "") ? announcement!.type : listingTypes[0]
        size = listingSizes.contains(announcement?.size ?? "") ? announcement!.size : "M"
        color = listingColors.contains(announcement?.color ?? "") ? announcement!.color : listingColors[0]
        deliveryServices = Set(announcement?.deliveryServices ?? listingDeliveryServices)
    }

    var isEditing: Bool {
        announcementId != nil
    }

    func addPhotos(_ items: [Data]) {
        guard !saving else { return }
        let available = max(0, 5 - photos.count)
        guard available > 0 else {
            errorMessage = "Можно добавить максимум 5 фото."
            return
        }

        let newPhotos = items.prefix(available).compactMap { data -> ListingPhoto? in
            guard let image = UIImage(data: data) else { return nil }
            return ListingPhoto(data: data, image: image)
        }

        photos.append(contentsOf: newPhotos)
        errorMessage = items.count > available ? "Максимум — 5 фото." : nil
    }

    func removePhoto(_ id: UUID) {
        photos.removeAll { $0.id == id }
    }

    func save(country: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty else {
            errorMessage = "Введите название."
            return
        }
        guard let parsedPrice = Int(price), parsedPrice > 0 else {
            errorMessage = "Введите корректную цену."
            return
        }
        guard let parsedAge = Int(age), parsedAge >= 18 else {
            errorMessage = "Возраст должен быть не меньше 18 лет."
            return
        }
        guard let parsedDays = Int(daysWorn), parsedDays >= 0 else {
            errorMessage = "Введите корректное количество дней."
            return
        }
        guard !deliveryServices.isEmpty else {
            errorMessage = "Выберите хотя бы одну службу доставки."
            return
        }

        let orderedServices = listingDeliveryServices.filter { deliveryServices.contains($0) }
        let editableData: [String: Any] = [
            "title": cleanTitle,
            "description": cleanDescription,
            "type": type,
            "size": size,
            "age": parsedAge,
            "daysWorn": parsedDays,
            "isVirgin": isVirgin,
            "color": color,
            "price": parsedPrice,
            "deliveryServices": orderedServices
        ]

        if let announcementId {
            saving = true
            errorMessage = nil
            Firestore.firestore().collection("announcements").document(announcementId).updateData(editableData) { [weak self] error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.saving = false
                    if let error {
                        self.errorMessage = error.localizedDescription
                    } else {
                        self.saved = true
                    }
                }
            }
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Сначала войдите в аккаунт."
            return
        }
        guard (1...5).contains(photos.count) else {
            errorMessage = "Нужно добавить от 1 до 5 фото."
            return
        }

        let exif = photos.compactMap { listingExif($0.data) }
        guard exif.count == photos.count else {
            errorMessage = "Одно или несколько фото не содержат нужные EXIF-данные камеры."
            return
        }

        let fingerprints = Set(exif.map { $0 })
        guard fingerprints.count == 1, let fingerprint = fingerprints.first else {
            errorMessage = "Все фото должны быть сделаны одной камерой."
            return
        }

        let jpegData = photos.compactMap { listingJPEG($0.data) }
        guard jpegData.count == photos.count else {
            errorMessage = "Не удалось подготовить одно или несколько фото до 400 КБ."
            return
        }

        saving = true
        errorMessage = nil

        uploadListingPhotos(jpegData, index: 0, fileIds: []) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .failure(let error):
                    self.saving = false
                    self.errorMessage = error.localizedDescription

                case .success(let fileIds):
                    var data = editableData
                    data["authorId"] = uid
                    data["photoFileIds"] = fileIds
                    data["cameraFingerprint"] = fingerprint
                    data["country"] = country
                    data["sold"] = false
                    data["boostedUntil"] = Int64(0)
                    data["createdAt"] = Int64(Date().timeIntervalSince1970 * 1000.0)

                    Firestore.firestore().collection("announcements").addDocument(data: data) { [weak self] error in
                        DispatchQueue.main.async {
                            guard let self else { return }
                            self.saving = false
                            if let error {
                                self.errorMessage = error.localizedDescription
                            } else {
                                self.saved = true
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AddAnnouncementIOSView: View {
    let country: String
    let onSaved: () -> Void

    @StateObject private var model = ListingEditorModel()
    @State private var showPhotos = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ListingEditorForm(
            title: "Новое объявление",
            model: model,
            showPhotos: $showPhotos,
            onCancel: { dismiss() },
            onSave: {
                model.save(country: country)
            }
        )
        .onChange(of: model.saved) { saved in
            if saved {
                onSaved()
                dismiss()
            }
        }
        .sheet(isPresented: $showPhotos) {
            ListingPhotosPicker(selectionLimit: max(1, 5 - model.photos.count)) { items in
                showPhotos = false
                model.addPhotos(items)
            }
        }
    }
}

struct EditAnnouncementIOSView: View {
    let announcement: IOSAnnouncement
    let onSaved: () -> Void

    @StateObject private var model: ListingEditorModel
    @State private var unusedPhotoSheet = false
    @Environment(\.dismiss) private var dismiss

    init(announcement: IOSAnnouncement, onSaved: @escaping () -> Void) {
        self.announcement = announcement
        self.onSaved = onSaved
        _model = StateObject(wrappedValue: ListingEditorModel(announcement: announcement))
    }

    var body: some View {
        ListingEditorForm(
            title: "Редактирование",
            model: model,
            showPhotos: $unusedPhotoSheet,
            onCancel: { dismiss() },
            onSave: {
                model.save(country: announcement.country)
            }
        )
        .onChange(of: model.saved) { saved in
            if saved {
                onSaved()
                dismiss()
            }
        }
    }
}

private struct ListingEditorForm: View {
    let title: String
    @ObservedObject var model: ListingEditorModel
    @Binding var showPhotos: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ListingTextField(title: "Название", text: $model.title)
                    ListingTextField(title: "Описание", text: $model.description)
                    ListingTextField(title: "Цена", text: $model.price, number: true)
                    ListingTextField(title: "Возраст модели", text: $model.age, number: true)
                    ListingTextField(title: "Дней носили", text: $model.daysWorn, number: true)

                    ListingPicker(title: "Тип", value: $model.type, values: listingTypes)
                    ListingPicker(title: "Размер", value: $model.size, values: listingSizes)
                    ListingPicker(title: "Цвет", value: $model.color, values: listingColors)

                    Toggle("Девственница", isOn: $model.isVirgin)
                        .tint(.pink)

                    Text("Могу отправить через")
                        .font(.headline)
                        .foregroundStyle(.pink)

                    ForEach(listingDeliveryServices, id: \.self) { service in
                        Toggle(
                            deliveryName(service),
                            isOn: Binding(
                                get: { model.deliveryServices.contains(service) },
                                set: { enabled in
                                    if enabled {
                                        model.deliveryServices.insert(service)
                                    } else {
                                        model.deliveryServices.remove(service)
                                    }
                                }
                            )
                        )
                        .tint(.pink)
                    }

                    if model.isEditing {
                        Text("Фото при редактировании остаются прежними, как в Android-версии.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        HStack {
                            Text("Фото: \(model.photos.count) / 5")
                                .font(.headline)
                            Spacer()
                            Button("Добавить фото") {
                                showPhotos = true
                            }
                            .disabled(model.saving || model.photos.count >= 5)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(model.photos) { photo in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: photo.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 105, height: 105)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))

                                        Button {
                                            model.removePhoto(photo.id)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 23))
                                                .foregroundStyle(.white)
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                        }

                        Text("Нужно 1–5 фото. Все фото должны содержать EXIF и быть сделаны одной камерой.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let error = model.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button(action: onSave) {
                        ZStack {
                            if model.saving {
                                ProgressView().tint(.black)
                            } else {
                                Text(model.isEditing ? "Сохранить" : "Опубликовать")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.black)
                    .background(Color.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(model.saving)
                }
                .padding(18)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена", action: onCancel)
                        .disabled(model.saving)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct ListingTextField: View {
    let title: String
    @Binding var text: String
    var number = false

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(number ? .numberPad : .default)
            .padding(.horizontal, 12)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
            )
    }
}

private struct ListingPicker: View {
    let title: String
    @Binding var value: String
    let values: [String]

    var body: some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Picker(title, selection: $value) {
                ForEach(values, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.6), lineWidth: 1)
        )
    }
}

@MainActor
private final class MyListingsIOSViewModel: ObservableObject {
    @Published var items: [IOSAnnouncement] = []
    @Published var deletingId: String?
    @Published var errorMessage: String?
    private var listener: ListenerRegistration?

    init() {
        start()
    }

    func start() {
        stop()
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Пользователь не авторизован."
            return
        }

        listener = Firestore.firestore()
            .collection("announcements")
            .whereField("authorId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.items = (snapshot?.documents ?? [])
                        .map { IOSAnnouncement(document: $0) }
                        .sorted { $0.createdAt > $1.createdAt }
                    self.errorMessage = nil
                }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func delete(_ item: IOSAnnouncement) {
        guard deletingId == nil else {
            return
        }

        guard
            let uid = Auth.auth().currentUser?.uid,
            uid == item.authorId
        else {
            errorMessage = "Можно удалить только своё объявление."
            return
        }

        deletingId = item.id
        errorMessage = nil

        Firestore.firestore()
            .collection("announcements")
            .document(item.id)
            .delete { [weak self] error in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }

                    self.deletingId = nil

                    if let error {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
    }
}

struct MyListingsIOSView: View {
    @StateObject private var model = MyListingsIOSViewModel()
    @State private var editing: IOSAnnouncement?
    @State private var deleting: IOSAnnouncement?
    @State private var boosting: IOSAnnouncement?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if let error = model.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding()
                } else if model.items.isEmpty {
                    Text("У вас пока нет объявлений.")
                        .foregroundStyle(.secondary)
                } else {
                    List(model.items) { item in
                        HStack(spacing: 12) {
                            if let photo = item.photoFileIds.first {
                                WorkerPhotoView(fileId: photo, cornerRadius: 8)
                                    .frame(width: 62, height: 62)
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.title.isEmpty ? "Без названия" : item.title)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Text(item.country == "RU" ? "\(item.price) ₽" : "\(item.price) ₴")
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                editing = item
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(.pink)
                            }
                            .buttonStyle(.plain)
                            .disabled(model.deletingId != nil)

                            Button {
                                boosting = item
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundStyle(.pink)
                            }
                            .buttonStyle(.plain)
                            .disabled(model.deletingId != nil)

                            Button {
                                deleting = item
                            } label: {
                                if model.deletingId == item.id {
                                    ProgressView()
                                } else {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(model.deletingId != nil)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Мои объявления")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(item: $editing) { item in
            EditAnnouncementIOSView(announcement: item) {
                editing = nil
            }
        }
        .sheet(item: $boosting) { item in
            IOSBoostView(announcement: item)
        }
        .alert(item: $deleting) { item in
            Alert(
                title: Text("Удалить объявление?"),
                message: Text(
                    item.title.isEmpty
                        ? "Без названия"
                        : item.title
                ),
                primaryButton: .destructive(
                    Text("Удалить")
                ) {
                    model.delete(item)
                },
                secondaryButton: .cancel(
                    Text("Отмена")
                )
            )
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

private struct ListingPhotosPicker: UIViewControllerRepresentable {
    let selectionLimit: Int
    let onPicked: ([Data]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = selectionLimit
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPicked: ([Data]) -> Void
        private var values: [Int: Data] = [:]
        private var expected = 0

        init(onPicked: @escaping ([Data]) -> Void) {
            self.onPicked = onPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                picker.dismiss(animated: true)
                return
            }

            values = [:]
            expected = results.count

            for (index, result) in results.enumerated() {
                let provider = result.itemProvider
                let type = provider.registeredTypeIdentifiers.first {
                    UTType($0)?.conforms(to: .image) == true
                } ?? UTType.image.identifier

                provider.loadDataRepresentation(forTypeIdentifier: type) { [weak self] data, _ in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if let data {
                            self.values[index] = data
                        }
                        if self.values.count == self.expected {
                            let ordered = (0..<self.expected).compactMap { self.values[$0] }
                            picker.dismiss(animated: true)
                            self.onPicked(ordered)
                        }
                    }
                }
            }
        }
    }
}

private func listingExif(_ data: Data) -> String? {
    guard
        let source = CGImageSourceCreateWithData(data as CFData, nil),
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
        let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any],
        let make = (tiff[kCGImagePropertyTIFFMake] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
        let model = (tiff[kCGImagePropertyTIFFModel] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
        let date = (exif[kCGImagePropertyExifDateTimeOriginal] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
        !make.isEmpty,
        !model.isEmpty,
        !date.isEmpty
    else {
        return nil
    }

    let normalized = make.lowercased() + "|" + model.lowercased()
    return SHA256.hash(data: Data(normalized.utf8))
        .map { String(format: "%02x", $0) }
        .joined()
}

private func listingJPEG(_ data: Data) -> Data? {
    guard let image = UIImage(data: data) else { return nil }

    let longest = max(image.size.width, image.size.height)
    let scale = longest > 900 ? 900 / longest : 1
    let target = CGSize(
        width: max(1, image.size.width * scale),
        height: max(1, image.size.height * scale)
    )

    let rendered = UIGraphicsImageRenderer(size: target).image { _ in
        image.draw(in: CGRect(origin: .zero, size: target))
    }

    for quality: CGFloat in [0.80, 0.70, 0.60, 0.50, 0.40, 0.30] {
        if let result = rendered.jpegData(compressionQuality: quality),
           result.count <= 400 * 1024 {
            return result
        }
    }

    return nil
}

private func uploadListingPhotos(
    _ images: [Data],
    index: Int,
    fileIds: [String],
    completion: @escaping (Result<[String], Error>) -> Void
) {
    guard index < images.count else {
        completion(.success(fileIds))
        return
    }

    uploadListingPhoto(images[index]) { result in
        switch result {
        case .failure(let error):
            completion(.failure(error))
        case .success(let fileId):
            uploadListingPhotos(
                images,
                index: index + 1,
                fileIds: fileIds + [fileId],
                completion: completion
            )
        }
    }
}

private func uploadListingPhoto(
    _ jpeg: Data,
    completion: @escaping (Result<String, Error>) -> Void
) {
    guard let user = Auth.auth().currentUser else {
        completion(.failure(NSError(
            domain: "Listing",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Сначала войдите в аккаунт."]
        )))
        return
    }

    user.getIDTokenForcingRefresh(false) { token, error in
        if let error {
            completion(.failure(error))
            return
        }

        guard
            let token,
            let url = URL(string: listingWorkerURL + "/upload")
        else {
            completion(.failure(NSError(
                domain: "Listing",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Не удалось подготовить загрузку фото."]
            )))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.httpBody = jpeg
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, networkError in
            if let networkError {
                completion(.failure(networkError))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(NSError(
                    domain: "Listing",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Сервер не вернул HTTP-ответ."]
                )))
                return
            }

            let json = data.flatMap {
                try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
            } ?? [:]

            guard (200...299).contains(http.statusCode) else {
                completion(.failure(NSError(
                    domain: "Listing",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey:
                        json["error"] as? String ?? "Ошибка загрузки фото \(http.statusCode)"
                    ]
                )))
                return
            }

            guard let fileId = json["fileId"] as? String, !fileId.isEmpty else {
                completion(.failure(NSError(
                    domain: "Listing",
                    code: 4,
                    userInfo: [NSLocalizedDescriptionKey: "Worker не вернул fileId."]
                )))
                return
            }

            completion(.success(fileId))
        }
        .resume()
    }
}

private func deliveryName(_ value: String) -> String {
    switch value {
    case "NovaPoshta": return "Новая почта"
    case "Ukrposhta": return "Укрпочта"
    default: return value
    }
}
