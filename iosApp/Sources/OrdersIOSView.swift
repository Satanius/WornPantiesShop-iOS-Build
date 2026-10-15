import SwiftUI
import UIKit
import PhotosUI
import ImageIO
import CryptoKit
import UniformTypeIdentifiers
import FirebaseAuth
import FirebaseFirestore

private let orderWorkerBaseURL = "https://telegram-photo-storage.sataniusdarkc.workers.dev"

struct IOSOrder: Identifiable {
    let id: String
    let announcementId: String
    let buyerId: String
    let sellerId: String
    let deliveryService: String
    let status: String
    let trackingNumber: String
    let trackingSource: String
    let packagingProofStatus: String
    let packagingProofPhotoFileId: String
    let createdAt: Int64
    let price: Int

    init(document: QueryDocumentSnapshot) {
        let data = document.data()

        id = document.documentID
        announcementId = data["announcementId"] as? String ?? ""
        buyerId = data["buyerId"] as? String ?? ""
        sellerId = data["sellerId"] as? String ?? ""
        deliveryService = data["deliveryService"] as? String ?? ""
        status = data["status"] as? String ?? ""
        trackingNumber = data["trackingNumber"] as? String ?? ""
        trackingSource = data["trackingSource"] as? String ?? ""
        packagingProofStatus = data["packagingProofStatus"] as? String ?? "NONE"
        packagingProofPhotoFileId =
            data["packagingProofPhotoFileId"] as? String ?? ""

        if let number = data["createdAt"] as? NSNumber {
            createdAt = number.int64Value
        } else {
            createdAt = 0
        }

        if let number = data["price"] as? NSNumber {
            price = number.intValue
        } else {
            price = 0
        }
    }
}

private struct IOSOrderAnnouncementInfo {
    let title: String
    let country: String
    let cameraFingerprint: String
}

private struct IOSDeliveryDetails {
    let deliveryService: String
    let recipientName: String
    let recipientPhone: String
    let recipientCity: String
    let recipientArea: String
    let recipientDepartment: String
    let recipientPostalCode: String

    init(json: [String: Any]) {
        deliveryService = json["deliveryService"] as? String ?? ""
        recipientName = json["recipientName"] as? String ?? ""
        recipientPhone = json["recipientPhone"] as? String ?? ""
        recipientCity = json["recipientCity"] as? String ?? ""
        recipientArea = json["recipientArea"] as? String ?? ""
        recipientDepartment = json["recipientDepartment"] as? String ?? ""
        recipientPostalCode = json["recipientPostalCode"] as? String ?? ""
    }
}

private enum IOSOrderWorker {
    static func post(
        path: String,
        body: [String: Any],
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            completion(
                .failure(
                    NSError(
                        domain: "Order",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: iosT(iosCurrentLanguage(), "PLEASE_SIGN_IN_FIRST")
                        ]
                    )
                )
            )
            return
        }

        user.getIDTokenForcingRefresh(false) { token, tokenError in
            if let tokenError {
                completion(.failure(tokenError))
                return
            }

            guard let token, !token.isEmpty else {
                completion(
                    .failure(
                        NSError(
                            domain: "Order",
                            code: 2,
                            userInfo: [
                                NSLocalizedDescriptionKey: iosT(iosCurrentLanguage(), "FAILED_TO_GET_FIREBASE_ID_TOKEN")
                            ]
                        )
                    )
                )
                return
            }

            guard
                let url = URL(string: orderWorkerBaseURL + path),
                let data = try? JSONSerialization.data(withJSONObject: body)
            else {
                completion(
                    .failure(
                        NSError(
                            domain: "Order",
                            code: 3,
                            userInfo: [
                                NSLocalizedDescriptionKey: iosT(iosCurrentLanguage(), "FAILED_TO_PREPARE_REQUEST")
                            ]
                        )
                    )
                )
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 45
            request.httpBody = data
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    completion(
                        .failure(
                            NSError(
                                domain: "Order",
                                code: 4,
                                userInfo: [
                                    NSLocalizedDescriptionKey: iosT(iosCurrentLanguage(), "SERVER_DID_NOT_RETURN_HTTP_RESPONSE")
                                ]
                            )
                        )
                    )
                    return
                }

                let json = data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
                } ?? [:]

                if !(200...299).contains(http.statusCode) {
                    let message = json["error"] as? String
                        ?? iosT(iosCurrentLanguage(), "SERVER_ERROR_HTTP", String(http.statusCode))

                    completion(
                        .failure(
                            NSError(
                                domain: "Order",
                                code: http.statusCode,
                                userInfo: [
                                    NSLocalizedDescriptionKey: message
                                ]
                            )
                        )
                    )
                    return
                }

                if let success = json["success"] as? Bool, !success {
                    let message = json["error"] as? String
                        ?? iosT(iosCurrentLanguage(), "OPERATION_FAILED")

                    completion(
                        .failure(
                            NSError(
                                domain: "Order",
                                code: 5,
                                userInfo: [
                                    NSLocalizedDescriptionKey: message
                                ]
                            )
                        )
                    )
                    return
                }

                completion(.success(json))
            }
            .resume()
        }
    }

    static func uploadPhoto(
        jpeg: Data,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard !jpeg.isEmpty, jpeg.count <= 400 * 1024 else {
            completion(
                .failure(
                    NSError(
                        domain: "Order",
                        code: 6,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                iosT(iosCurrentLanguage(), "PHOTO_MUST_BE_UNDER_400KB")
                        ]
                    )
                )
            )
            return
        }

        guard let user = Auth.auth().currentUser else {
            completion(
                .failure(
                    NSError(
                        domain: "Order",
                        code: 7,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                iosT(iosCurrentLanguage(), "PLEASE_SIGN_IN_FIRST")
                        ]
                    )
                )
            )
            return
        }

        user.getIDTokenForcingRefresh(false) { token, tokenError in
            if let tokenError {
                completion(.failure(tokenError))
                return
            }

            guard let token, !token.isEmpty else {
                completion(
                    .failure(
                        NSError(
                            domain: "Order",
                            code: 8,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    iosT(iosCurrentLanguage(), "FAILED_TO_GET_FIREBASE_ID_TOKEN")
                            ]
                        )
                    )
                )
                return
            }

            guard let url = URL(string: orderWorkerBaseURL + "/upload") else {
                completion(
                    .failure(
                        NSError(
                            domain: "Order",
                            code: 9,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    iosT(iosCurrentLanguage(), "INVALID_PHOTO_UPLOAD_URL")
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

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    completion(
                        .failure(
                            NSError(
                                domain: "Order",
                                code: 10,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        iosT(iosCurrentLanguage(), "SERVER_DID_NOT_RETURN_HTTP_RESPONSE")
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
                                domain: "Order",
                                code: http.statusCode,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        json["error"] as? String
                                        ?? iosT(iosCurrentLanguage(), "PHOTO_UPLOAD_HTTP_ERROR", String(http.statusCode))
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
                                domain: "Order",
                                code: 11,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        iosT(iosCurrentLanguage(), "WORKER_DID_NOT_RETURN_FILE_ID")
                                ]
                            )
                        )
                    )
                    return
                }

                completion(.success(fileId))
            }
            .resume()
        }
    }
}

@MainActor
private final class SellerOrdersIOSViewModel: ObservableObject {
    @Published var orders: [IOSOrder] = []
    @Published var announcementInfo: [String: IOSOrderAnnouncementInfo] = [:]
    @Published var deliveryDetails: [String: IOSDeliveryDetails] = [:]
    @Published var trackingInput: [String: String] = [:]
    @Published var actionOrderId: String?
    @Published var loadingDeliveryOrderId: String?
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    init() {
        start()
    }

    func start() {
        stop()

        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = iosT(iosCurrentLanguage(), "USER_NOT_AUTHORIZED")
            return
        }

        listener = Firestore.firestore()
            .collection("orders")
            .whereField("sellerId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }

                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.orders = snapshot?.documents.map {
                        IOSOrder(document: $0)
                    } ?? []
                    self.errorMessage = nil
                    self.loadAnnouncementInfo()
                }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func accept(_ order: IOSOrder) {
        perform(
            orderId: order.id,
            path: "/order/accept"
        )
    }

    func reject(_ order: IOSOrder) {
        perform(
            orderId: order.id,
            path: "/order/reject"
        )
    }

    func markSent(_ order: IOSOrder) {
        perform(
            orderId: order.id,
            path: "/order/mark-sent"
        )
    }

    func loadDelivery(_ order: IOSOrder) {
        guard loadingDeliveryOrderId == nil else {
            return
        }

        loadingDeliveryOrderId = order.id
        errorMessage = nil

        IOSOrderWorker.post(
            path: "/order/delivery-details",
            body: [
                "orderId": order.id
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                self.loadingDeliveryOrderId = nil

                switch result {
                case .success(let json):
                    let raw = (
                        json["com/example/wornpantiesshop/delivery"] as? [String: Any]
                    ) ?? (
                        json["delivery"] as? [String: Any]
                    )

                    guard let raw else {
                        self.errorMessage = iosT(iosCurrentLanguage(), "WORKER_DID_NOT_RETURN_DELIVERY_DATA")
                        return
                    }

                    self.deliveryDetails[order.id] = IOSDeliveryDetails(
                        json: raw
                    )

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func submitPackagingProof(
        order: IOSOrder,
        originalImageData: Data
    ) {
        guard actionOrderId == nil else {
            return
        }

        guard
            let info = announcementInfo[order.announcementId],
            !info.cameraFingerprint.isEmpty
        else {
            errorMessage =
                iosT(iosCurrentLanguage(), "LISTING_HAS_NO_CAMERA_DATA")
            return
        }

        guard let exif = packagingPhotoExif(originalImageData) else {
            errorMessage =
                iosT(iosCurrentLanguage(), "PHOTO_REJECTED_EXIF_AND_DATE_REQUIRED")
            return
        }

        guard exif.cameraFingerprint == info.cameraFingerprint else {
            errorMessage =
                iosT(iosCurrentLanguage(), "PHOTO_REJECTED_DIFFERENT_CAMERA")
            return
        }

        guard let jpeg = preparePackagingJPEG(originalImageData) else {
            errorMessage =
                iosT(iosCurrentLanguage(), "FAILED_TO_PREPARE_PHOTO_400KB")
            return
        }

        actionOrderId = order.id
        errorMessage = nil

        IOSOrderWorker.uploadPhoto(
            jpeg: jpeg
        ) { [weak self] uploadResult in
            switch uploadResult {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.actionOrderId = nil
                    self?.errorMessage = error.localizedDescription
                }

            case .success(let fileId):
                IOSOrderWorker.post(
                    path: "/order/packaging-proof",
                    body: [
                        "orderId": order.id,
                        "photoFileId": fileId,
                        "cameraFingerprint": exif.cameraFingerprint
                    ]
                ) { [weak self] proofResult in
                    DispatchQueue.main.async {
                        guard let self else {
                            return
                        }

                        self.actionOrderId = nil

                        if case .failure(let error) = proofResult {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    func saveTracking(_ order: IOSOrder) {
        let raw = trackingInput[order.id] ?? ""
        let clean = raw
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard trackingNumberValid(
            clean,
            service: order.deliveryService
        ) else {
            errorMessage = iosT(iosCurrentLanguage(), "CHECK_TRACKING_NUMBER")
            return
        }

        actionOrderId = order.id
        errorMessage = nil

        IOSOrderWorker.post(
            path: "/order/tracking-number",
            body: [
                "orderId": order.id,
                "trackingNumber": clean
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                self.actionOrderId = nil

                switch result {
                case .success:
                    self.trackingInput[order.id] = ""

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func trackingNumberValid(
        _ raw: String,
        service: String
    ) -> Bool {
        let clean = raw
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch service {
        case "NovaPoshta":
            return (10...30).contains(clean.count)
                && clean.allSatisfy { $0.isNumber }

        case "Ukrposhta":
            return clean.count == 13
                && clean.allSatisfy { $0.isNumber }

        case "Meest":
            return (5...50).contains(clean.count)
                && clean.allSatisfy { $0.isLetter || $0.isNumber }

        default:
            return false
        }
    }

    private func perform(
        orderId: String,
        path: String
    ) {
        guard actionOrderId == nil else {
            return
        }

        actionOrderId = orderId
        errorMessage = nil

        IOSOrderWorker.post(
            path: path,
            body: [
                "orderId": orderId
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                self.actionOrderId = nil

                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadAnnouncementInfo() {
        let ids = Set(
            orders
                .map { $0.announcementId }
                .filter { !$0.isEmpty }
        )

        for id in ids where announcementInfo[id] == nil {
            Firestore.firestore()
                .collection("announcements")
                .document(id)
                .getDocument { [weak self] document, _ in
                    DispatchQueue.main.async {
                        guard let self else {
                            return
                        }

                        let data = document?.data()
                        let title = (data?["title"] as? String)
                            ?? (data?["titleKey"] as? String)
                            ?? iosT(iosCurrentLanguage(), "LISTING_2")

                        let country = data?["country"] as? String
                            ?? "UA"

                        let cameraFingerprint =
                            data?["cameraFingerprint"] as? String
                            ?? ""

                        self.announcementInfo[id] = IOSOrderAnnouncementInfo(
                            title: title,
                            country: country,
                            cameraFingerprint: cameraFingerprint
                        )
                    }
                }
        }
    }
}

@MainActor
private final class BuyerOrdersIOSViewModel: ObservableObject {
    @Published var orders: [IOSOrder] = []
    @Published var announcementInfo: [String: IOSOrderAnnouncementInfo] = [:]
    @Published var actionOrderId: String?
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    init() {
        start()
    }

    func start() {
        stop()

        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = iosT(iosCurrentLanguage(), "USER_NOT_AUTHORIZED")
            return
        }

        listener = Firestore.firestore()
            .collection("orders")
            .whereField("buyerId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }

                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.orders = snapshot?.documents.map {
                        IOSOrder(document: $0)
                    } ?? []
                    self.errorMessage = nil
                    self.loadAnnouncementInfo()
                }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func confirmPackaging(_ order: IOSOrder) {
        guard actionOrderId == nil else {
            return
        }

        actionOrderId = order.id
        errorMessage = nil

        IOSOrderWorker.post(
            path: "/order/confirm-packaging",
            body: [
                "orderId": order.id
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                self.actionOrderId = nil

                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func confirmReceived(_ order: IOSOrder) {
        guard actionOrderId == nil else {
            return
        }

        actionOrderId = order.id
        errorMessage = nil

        IOSOrderWorker.post(
            path: "/order/confirm-received",
            body: [
                "orderId": order.id
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                self.actionOrderId = nil

                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadAnnouncementInfo() {
        let ids = Set(
            orders
                .map { $0.announcementId }
                .filter { !$0.isEmpty }
        )

        for id in ids where announcementInfo[id] == nil {
            Firestore.firestore()
                .collection("announcements")
                .document(id)
                .getDocument { [weak self] document, _ in
                    DispatchQueue.main.async {
                        guard let self else {
                            return
                        }

                        let data = document?.data()
                        let title = (data?["title"] as? String)
                            ?? (data?["titleKey"] as? String)
                            ?? iosT(iosCurrentLanguage(), "LISTING_2")

                        let country = data?["country"] as? String
                            ?? "UA"

                        let cameraFingerprint =
                            data?["cameraFingerprint"] as? String
                            ?? ""

                        self.announcementInfo[id] = IOSOrderAnnouncementInfo(
                            title: title,
                            country: country,
                            cameraFingerprint: cameraFingerprint
                        )
                    }
                }
        }
    }
}

struct SellerOrdersIOSView: View {
    @StateObject private var viewModel = SellerOrdersIOSViewModel()
    @State private var packagingOrderForPicker: IOSOrder?
    @AppStorage("appLanguage") private var languageRaw = "RU"
    @Environment(\.dismiss) private var dismiss

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.orders.isEmpty {
                    emptyState(
                        text: iosT(language, "NO_ORDERS_YET")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.orders) { order in
                                SellerOrderCardIOS(
                                    order: order,
                                    info: viewModel.announcementInfo[
                                        order.announcementId
                                    ],
                                    delivery: viewModel.deliveryDetails[
                                        order.id
                                    ],
                                    trackingInput: Binding(
                                        get: {
                                            viewModel.trackingInput[
                                                order.id
                                            ] ?? ""
                                        },
                                        set: {
                                            viewModel.trackingInput[
                                                order.id
                                            ] = $0
                                        }
                                    ),
                                    actionLoading:
                                        viewModel.actionOrderId == order.id,
                                    deliveryLoading:
                                        viewModel.loadingDeliveryOrderId == order.id,
                                    trackingValid:
                                        viewModel.trackingNumberValid(
                                            viewModel.trackingInput[
                                                order.id
                                            ] ?? "",
                                            service: order.deliveryService
                                        ),
                                    onAccept: {
                                        viewModel.accept(order)
                                    },
                                    onReject: {
                                        viewModel.reject(order)
                                    },
                                    onLoadDelivery: {
                                        viewModel.loadDelivery(order)
                                    },
                                    onSaveTracking: {
                                        viewModel.saveTracking(order)
                                    },
                                    onMarkSent: {
                                        viewModel.markSent(order)
                                    },
                                    onSubmitPackagingProof: {
                                        packagingOrderForPicker = order
                                    }
                                )
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .navigationTitle(iosT(language, "MY_ORDERS"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(iosT(language, "CLOSE")) {
                        dismiss()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding()
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(item: $packagingOrderForPicker) { order in
            PackagingPhotoPicker { data in
                packagingOrderForPicker = nil
                viewModel.submitPackagingProof(
                    order: order,
                    originalImageData: data
                )
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    @ViewBuilder
    private func emptyState(text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)

            Text(text)
                .foregroundStyle(.secondary)
        }
    }
}

struct BuyerOrdersIOSView: View {
    @StateObject private var viewModel = BuyerOrdersIOSViewModel()
    @AppStorage("appLanguage") private var languageRaw = "RU"
    @Environment(\.dismiss) private var dismiss

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.orders.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bag")
                            .font(.system(size: 42))
                            .foregroundStyle(.secondary)

                        Text(iosT(language, "YOU_DON_T_HAVE_ANY_PURCHASES_YET"))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.orders) { order in
                                BuyerOrderCardIOS(
                                    order: order,
                                    info: viewModel.announcementInfo[
                                        order.announcementId
                                    ],
                                    isLoading:
                                        viewModel.actionOrderId == order.id,
                                    onConfirmReceived: {
                                        viewModel.confirmReceived(order)
                                    },
                                    onConfirmPackaging: {
                                        viewModel.confirmPackaging(order)
                                    }
                                )
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .navigationTitle(iosT(language, "MY_PURCHASES"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(iosT(language, "CLOSE")) {
                        dismiss()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding()
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
}

private struct SellerOrderCardIOS: View {
    let order: IOSOrder
    @AppStorage("appLanguage") private var languageRaw = "RU"

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }
    let info: IOSOrderAnnouncementInfo?
    let delivery: IOSDeliveryDetails?
    @Binding var trackingInput: String
    let actionLoading: Bool
    let deliveryLoading: Bool
    let trackingValid: Bool
    let onAccept: () -> Void
    let onReject: () -> Void
    let onLoadDelivery: () -> Void
    let onSaveTracking: () -> Void
    let onMarkSent: () -> Void
    let onSubmitPackagingProof: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(info?.title ?? iosT(iosCurrentLanguage(), "LISTING_2"))
                .font(.headline)
                .foregroundStyle(.white)

            Text(
                iosT(language, "CASH_ON_DELIVERY") + " "
                    + formatPrice(
                        order.price,
                        country: info?.country ?? "UA"
                    )
            )
            .fontWeight(.bold)
            .foregroundStyle(.green)

            Text(iosT(language, "DELIVERY") + " " + deliveryServiceName(order.deliveryService))
                .foregroundStyle(.secondary)

            Text(iosT(language, "STATUS") + " " + orderStatusText(order.status))
                .fontWeight(.bold)
                .foregroundStyle(orderStatusColor(order.status))

            if !order.trackingNumber.isEmpty {
                Text(iosT(language, "TRACKING_NUMBER_3") + ": " + order.trackingNumber)
                    .fontWeight(.bold)
                    .foregroundStyle(.pink)
            }

            if
                order.status == "AWAITING_TTN"
                    || order.status == "CREATED"
            {
                if order.packagingProofStatus == "WAITING_BUYER" {
                    Text(
                        iosT(language, "PACKAGING_PHOTO_SENT_WAITING_FOR_BUYER_CONFIRMATION")
                    )
                    .font(.footnote)
                    .foregroundStyle(.yellow)
                } else if order.packagingProofStatus == "CONFIRMED" {
                    Text(iosT(language, "BUYER_CONFIRMED_THE_PACKAGING"))
                        .font(.footnote)
                        .foregroundStyle(.green)
                } else {
                    Button {
                        onSubmitPackagingProof()
                    } label: {
                        if actionLoading {
                            ProgressView()
                        } else {
                            Label(
                                iosT(language, "SEND_PACKAGING_CONFIRMATION"),
                                systemImage: "camera"
                            )
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(actionLoading)

                    Text(
                        "Фото должно содержать EXIF камеры и быть сделано той же камерой, что использовалась для объявления."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            if order.status == "PENDING_SELLER" {
                HStack(spacing: 10) {
                    Button(iosT(language, "REJECT")) {
                        onReject()
                    }
                    .buttonStyle(.bordered)
                    .disabled(actionLoading)

                    Button(iosT(language, "ACCEPT")) {
                        onAccept()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(actionLoading)
                }
            }

            if order.status == "AWAITING_TTN" {
                if let delivery {
                    Divider()

                    Text(iosT(language, "RECIPIENT"))
                        .font(.headline)

                    orderDetail(iosT(language, "FULL_NAME"), delivery.recipientName)
                    orderDetail(iosT(language, "PHONE"), delivery.recipientPhone)
                    orderDetail(iosT(language, "CITY"), delivery.recipientCity)

                    if !delivery.recipientArea.isEmpty {
                        orderDetail(iosT(language, "AREA"), delivery.recipientArea)
                    }

                    if !delivery.recipientPostalCode.isEmpty {
                        orderDetail(iosT(language, "INDEX"), delivery.recipientPostalCode)
                    }

                    orderDetail(iosT(language, "BRANCH"), delivery.recipientDepartment)

                    TextField(
                        trackingPlaceholder(order.deliveryService),
                        text: $trackingInput
                    )
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(
                        order.deliveryService == "Meest"
                            ? .asciiCapable
                            : .numberPad
                    )

                    Button(iosT(language, "SAVE_SHIPMENT_NUMBER")) {
                        onSaveTracking()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        actionLoading
                            || !trackingValid
                            || (
                                order.deliveryService == "Ukrposhta"
                                && order.packagingProofStatus != "CONFIRMED"
                            )
                    )
                } else {
                    Button {
                        onLoadDelivery()
                    } label: {
                        if deliveryLoading {
                            ProgressView()
                        } else {
                            Text(iosT(language, "SHOW_RECIPIENT_DETAILS"))
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(deliveryLoading)
                }
            }

            if
                order.status == "CREATED",
                order.trackingSource == "MANUAL"
            {
                Button(iosT(language, "PARCEL_SHIPPED")) {
                    onMarkSent()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    actionLoading
                        || order.packagingProofStatus != "CONFIRMED"
                )

                if order.packagingProofStatus != "CONFIRMED" {
                    Text(iosT(language, "BUYER_MUST_CONFIRM_PACKAGING_FIRST"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.055))
        )
    }
}

private struct BuyerOrderCardIOS: View {
    let order: IOSOrder
    @AppStorage("appLanguage") private var languageRaw = "RU"

    private var language: IOSAppLanguage {
        iosLanguage(from: languageRaw)
    }
    let info: IOSOrderAnnouncementInfo?
    let isLoading: Bool
    let onConfirmReceived: () -> Void
    let onConfirmPackaging: () -> Void

    private var canConfirmReceived: Bool {
        !order.trackingNumber.isEmpty
            && (
                order.status == "ARRIVED"
                || (
                    order.trackingSource == "MANUAL"
                    && order.status == "SENT"
                )
            )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(info?.title ?? iosT(iosCurrentLanguage(), "LISTING_2"))
                .font(.headline)
                .foregroundStyle(.white)

            Text(iosT(language, "DELIVERY") + " " + deliveryServiceName(order.deliveryService))
                .foregroundStyle(.secondary)

            Text(iosT(language, "STATUS") + " " + orderStatusText(order.status))
                .fontWeight(.bold)
                .foregroundStyle(orderStatusColor(order.status))

            if !order.trackingNumber.isEmpty {
                Text(iosT(language, "TRACKING_NUMBER_3") + ": " + order.trackingNumber)
                    .fontWeight(.bold)
                    .foregroundStyle(.pink)
            } else {
                Text(iosT(language, "TRACKING_NUMBER_HAS_NOT_BEEN_ASSIGNED_YET"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if
                order.packagingProofStatus == "WAITING_BUYER",
                !order.packagingProofPhotoFileId.isEmpty
            {
                Divider()

                Text(iosT(language, "CHECK_THE_PACKAGING_PHOTO"))
                    .font(.headline)

                WorkerPhotoView(
                    fileId: order.packagingProofPhotoFileId,
                    cornerRadius: 10
                )
                .frame(maxWidth: .infinity)
                .frame(height: 220)

                Button {
                    onConfirmPackaging()
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(iosT(language, "CONFIRM_PACKAGING"))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isLoading)
            } else if order.packagingProofStatus == "CONFIRMED" {
                Text(iosT(language, "PACKAGING_CONFIRMED_CHECKMARK"))
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }

            if order.status == "ARRIVED" {
                Text(iosT(language, "PARCEL_ALREADY_AT_BRANCH"))
                    .font(.footnote)
                    .foregroundStyle(.yellow)
            }

            if order.status == "RETURNING" {
                Text(iosT(language, "PARCEL_RETURNING_TO_SELLER"))
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if canConfirmReceived {
                Button {
                    onConfirmReceived()
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(iosT(language, "CONFIRM_RECEIPT"))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isLoading)
            } else if order.status == "RECEIVED" {
                Text(iosT(language, "RECEIVED_CHECKMARK"))
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.055))
        )
    }
}

@ViewBuilder
private func orderDetail(
    _ label: String,
    _ value: String
) -> some View {
    HStack(alignment: .top) {
        Text(label + ":")
            .foregroundStyle(.secondary)

        Spacer()

        Text(value.isEmpty ? "—" : value)
            .multilineTextAlignment(.trailing)
    }
}

private func deliveryServiceName(_ service: String) -> String {
    switch service {
    case "NovaPoshta":
        return iosT(iosCurrentLanguage(), "NOVA_POSHTA_RU_NAME")
    case "Ukrposhta":
        return iosT(iosCurrentLanguage(), "UKRPOSHTA")
    case "Meest":
        return "Meest"
    default:
        return service.isEmpty ? "—" : service
    }
}

private func orderStatusText(_ status: String) -> String {
    switch status {
    case "PENDING_SELLER":
        return iosT(iosCurrentLanguage(), "AWAITING_SELLER")
    case "AWAITING_TTN":
        return iosT(iosCurrentLanguage(), "AWAITING_SHIPMENT_NUMBER")
    case "CREATED":
        return iosT(iosCurrentLanguage(), "SHIPMENT_CREATED")
    case "SENT":
        return iosT(iosCurrentLanguage(), "SHIPPED")
    case "IN_TRANSIT":
        return iosT(iosCurrentLanguage(), "IN_TRANSIT")
    case "ARRIVED":
        return iosT(iosCurrentLanguage(), "ARRIVED_AT_THE_PICKUP_POINT")
    case "RECEIVED":
        return iosT(iosCurrentLanguage(), "RECEIVED")
    case "REJECTED":
        return iosT(iosCurrentLanguage(), "REJECTED")
    case "RETURNING":
        return iosT(iosCurrentLanguage(), "RETURNING")
    case "RETURNED":
        return iosT(iosCurrentLanguage(), "RETURNED")
    case "CANCELLED":
        return iosT(iosCurrentLanguage(), "CANCELLED")
    default:
        return status.isEmpty ? "—" : status
    }
}

private func orderStatusColor(_ status: String) -> Color {
    switch status {
    case "PENDING_SELLER", "ARRIVED":
        return .orange
    case "AWAITING_TTN":
        return .blue
    case "CREATED":
        return .purple
    case "SENT", "IN_TRANSIT":
        return .pink
    case "RECEIVED":
        return .green
    case "REJECTED", "RETURNING", "RETURNED", "CANCELLED":
        return .red
    default:
        return .secondary
    }
}

private func formatPrice(
    _ price: Int,
    country: String
) -> String {
    country == "RU"
        ? "\(price) ₽"
        : "\(price) ₴"
}

private func trackingPlaceholder(_ service: String) -> String {
    switch service {
    case "NovaPoshta":
        return iosT(iosCurrentLanguage(), "TRACKING_NUMBER")
    case "Ukrposhta":
        return iosT(iosCurrentLanguage(), "UKRPOSHTA_TRACKING_NUMBER")
    case "Meest":
        return iosT(iosCurrentLanguage(), "MEEST_SHIPMENT_NUMBER")
    default:
        return iosT(iosCurrentLanguage(), "GENERIC_SHIPMENT_NUMBER")
    }
}


private struct PackagingPhotoExif {
    let cameraFingerprint: String
    let dateTimeOriginal: String
}

private func packagingPhotoExif(
    _ data: Data
) -> PackagingPhotoExif? {
    guard
        let source = CGImageSourceCreateWithData(
            data as CFData,
            nil
        ),
        let properties =
            CGImageSourceCopyPropertiesAtIndex(
                source,
                0,
                nil
            ) as? [CFString: Any],
        let tiff =
            properties[kCGImagePropertyTIFFDictionary]
                as? [CFString: Any],
        let exif =
            properties[kCGImagePropertyExifDictionary]
                as? [CFString: Any],
        let make =
            (tiff[kCGImagePropertyTIFFMake] as? String)?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
        let model =
            (tiff[kCGImagePropertyTIFFModel] as? String)?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
        let dateTimeOriginal =
            (exif[kCGImagePropertyExifDateTimeOriginal] as? String)?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
        !make.isEmpty,
        !model.isEmpty,
        !dateTimeOriginal.isEmpty
    else {
        return nil
    }

    let normalized =
        make.lowercased()
        + "|"
        + model.lowercased()

    let digest = SHA256.hash(
        data: Data(
            normalized.utf8
        )
    )

    let fingerprint = digest
        .map {
            String(
                format: "%02x",
                $0
            )
        }
        .joined()

    return PackagingPhotoExif(
        cameraFingerprint: fingerprint,
        dateTimeOriginal: dateTimeOriginal
    )
}

private func preparePackagingJPEG(
    _ originalData: Data
) -> Data? {
    guard let source = UIImage(data: originalData) else {
        return nil
    }

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

private struct PackagingPhotoPicker: UIViewControllerRepresentable {
    let onPhotoPicked: (Data) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onPhotoPicked: onPhotoPicked
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

    final class Coordinator:
        NSObject,
        PHPickerViewControllerDelegate
    {
        let onPhotoPicked: (Data) -> Void

        init(
            onPhotoPicked: @escaping (Data) -> Void
        ) {
            self.onPhotoPicked = onPhotoPicked
        }

        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            guard
                let provider = results.first?.itemProvider
            else {
                picker.dismiss(
                    animated: true
                )
                return
            }

            let typeIdentifier =
                provider.registeredTypeIdentifiers
                    .first {
                        UTType($0)?.conforms(
                            to: .image
                        ) == true
                    }
                ?? UTType.image.identifier

            provider.loadDataRepresentation(
                forTypeIdentifier: typeIdentifier
            ) { [weak self] data, _ in
                guard let data else {
                    DispatchQueue.main.async {
                        picker.dismiss(
                            animated: true
                        )
                    }
                    return
                }

                DispatchQueue.main.async {
                    picker.dismiss(
                        animated: true
                    )
                    self?.onPhotoPicked(
                        data
                    )
                }
            }
        }
    }
}
