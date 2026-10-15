import SwiftUI
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

struct AuthView: View {
    let onAuthSuccess: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var registration = false
    @State private var selectedCountry = "UA"
    @State private var loading = false
    @State private var errorMessage: String?

    private let accentPink = Color(red: 233.0 / 255.0, green: 30.0 / 255.0, blue: 99.0 / 255.0)

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Spacer(minLength: 70)

                Text("Worn panties shop")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(accentPink)
                    .multilineTextAlignment(.center)

                Text(registration ? "Регистрация" : "Вход")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)

                if registration {
                    Picker("Страна", selection: $selectedCountry) {
                        Text("Украина").tag("UA")
                        Text("Россия").tag("RU")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    )
                }

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .padding(.horizontal, 12)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    )
                    .onChange(of: email) { _ in
                        errorMessage = nil
                    }

                SecureField("Пароль", text: $password)
                    .textContentType(registration ? .newPassword : .password)
                    .padding(.horizontal, 12)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    )
                    .onChange(of: password) { _ in
                        errorMessage = nil
                    }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    submit()
                } label: {
                    ZStack {
                        if loading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(registration ? "Зарегистрироваться" : "Войти")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(accentPink)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(loading)
                .opacity(loading ? 0.7 : 1.0)

                Button(registration ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться") {
                    registration.toggle()
                    errorMessage = nil
                }
                .foregroundStyle(accentPink)
                .disabled(loading)

                Divider()
                    .background(Color.gray.opacity(0.5))

                Button {
                    signInWithGoogle()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))

                        Text("Войти через Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(loading)
                .opacity(loading ? 0.7 : 1.0)

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(red: 18.0 / 255.0, green: 18.0 / 255.0, blue: 18.0 / 255.0))
    }

    @MainActor
    private func signInWithGoogle() {
        loading = true
        errorMessage = nil

        guard
            let clientID =
                FirebaseApp.app()?
                    .options
                    .clientID,
            !clientID.isEmpty
        else {
            loading = false
            errorMessage =
                "Не удалось получить Google Client ID."
            return
        }

        guard
            let presenter =
                presentingViewController()
        else {
            loading = false
            errorMessage =
                "Не удалось открыть окно входа Google."
            return
        }

        GIDSignIn.sharedInstance.configuration =
            GIDConfiguration(
                clientID: clientID
            )

        GIDSignIn.sharedInstance
            .signIn(
                withPresenting: presenter
            ) { result, error in
                if let error {
                    loading = false
                    errorMessage =
                        error.localizedDescription
                    return
                }

                guard
                    let user = result?.user,
                    let idToken =
                        user.idToken?
                            .tokenString,
                    !idToken.isEmpty
                else {
                    loading = false
                    errorMessage =
                        "Google не вернул ID-токен."
                    return
                }

                let accessToken =
                    user.accessToken
                        .tokenString

                let credential =
                    GoogleAuthProvider
                        .credential(
                            withIDToken:
                                idToken,
                            accessToken:
                                accessToken
                        )

                Auth.auth()
                    .signIn(
                        with: credential
                    ) { result, error in
                        if let error {
                            loading = false
                            errorMessage =
                                error.localizedDescription
                            return
                        }

                        guard
                            let uid =
                                result?
                                    .user
                                    .uid,
                            !uid.isEmpty
                        else {
                            loading = false
                            errorMessage =
                                "Не удалось получить ID пользователя."
                            return
                        }

                        finishGoogleSignIn(
                            uid: uid
                        )
                    }
            }
    }

    @MainActor
    private func finishGoogleSignIn(
        uid: String
    ) {
        let document =
            Firestore.firestore()
                .collection("users")
                .document(uid)

        document.getDocument {
            snapshot,
            error in

            if let error {
                loading = false
                errorMessage =
                    error.localizedDescription
                return
            }

            let existingCountry =
                snapshot?
                    .data()?["country"]
                    as? String

            if
                let existingCountry,
                !existingCountry.isEmpty
            {
                loading = false
                onAuthSuccess()
                return
            }

            document.setData(
                [
                    "country":
                        selectedCountry
                ],
                merge: true
            ) { error in
                loading = false

                if let error {
                    errorMessage =
                        error.localizedDescription
                    return
                }

                onAuthSuccess()
            }
        }
    }

    @MainActor
    private func presentingViewController()
        -> UIViewController?
    {
        guard
            let scene =
                UIApplication.shared
                    .connectedScenes
                    .compactMap {
                        $0
                            as? UIWindowScene
                    }
                    .first(
                        where: {
                            $0.activationState
                                == .foregroundActive
                        }
                    ),
            let root =
                scene.windows
                    .first(
                        where: {
                            $0.isKeyWindow
                        }
                    )?
                    .rootViewController
        else {
            return nil
        }

        var presenter = root

        while
            let presented =
                presenter
                    .presentedViewController
        {
            presenter = presented
        }

        return presenter
    }

    private func submit() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(cleanEmail) else {
            errorMessage = "Введите корректный Email."
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Пароль должен содержать минимум 6 символов."
            return
        }

        loading = true
        errorMessage = nil

        if registration {
            Auth.auth().createUser(withEmail: cleanEmail, password: password) { result, error in
                if let error {
                    loading = false
                    errorMessage = error.localizedDescription
                    return
                }

                guard let uid = result?.user.uid else {
                    loading = false
                    errorMessage = "Не удалось получить ID пользователя."
                    return
                }

                Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .setData(["country": selectedCountry], merge: true) { error in
                        loading = false

                        if let error {
                            errorMessage = error.localizedDescription
                            return
                        }

                        onAuthSuccess()
                    }
            }
        } else {
            Auth.auth().signIn(withEmail: cleanEmail, password: password) { _, error in
                loading = false

                if let error {
                    errorMessage = error.localizedDescription
                    return
                }

                onAuthSuccess()
            }
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        let parts = value.split(separator: "@")
        guard parts.count == 2 else {
            return false
        }

        return parts[1].contains(".")
    }
}
