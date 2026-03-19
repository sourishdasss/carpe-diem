import SwiftUI

struct AuthScreen: View {
    @EnvironmentObject var auth: AuthStore

    @State private var started = false
    @State private var mode: Mode = .signIn
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    enum Mode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Create Account"
    }

    var body: some View {
        ZStack {
            Color.sonderBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    if !started {
                        landingHeader
                        flowDiagram
                        VStack(spacing: 10) {
                            getStartedButton
                            signInLinkButton
                        }
                        footerCopy
                    } else {
                        backToLandingButton
                        brandHeader

                        authCard

                        if auth.isLoading {
                            ProgressView()
                                .tint(Color.sonderAccent)
                        }

                        if let msg = auth.errorMessage, !msg.isEmpty {
                            Text(msg)
                                .font(.georgia(13))
                                .foregroundStyle(Color.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 40)
                .padding(.bottom, 24)
            }
        }
    }

    private var brandHeader: some View {
        VStack(spacing: 6) {
            Text("Sonder")
                .font(.georgiaBold(44))
                .foregroundStyle(Color.sonderAccent)

            Text("Travel that fits you.")
                .font(.georgiaItalic(16))
                .foregroundStyle(Color.sonderTextSecond)
        }
        .padding(.top, 10)
    }

    // MARK: - Landing (pre-auth)

    private var landingHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(Color.sonderAccent)
                .padding(.bottom, 6)

            Text("Find your Sonder.")
                .font(.georgiaBold(30))
                .foregroundStyle(Color.sonderTextPrimary)
                .multilineTextAlignment(.center)

            Text("Rate a few city vibes and get a travel personality + recommendations that actually match you.")
                .font(.georgia(14))
                .foregroundStyle(Color.sonderTextSecond)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 10)
    }

    private var flowDiagram: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                stepPill(number: "1", title: "Rate cities")
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.sonderDivider)
                stepPill(number: "2", title: "Get your profile")
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.sonderDivider)
                stepPill(number: "3", title: "Discover matches")
            }
        }
        .padding(16)
        .background(Color.sonderSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private func stepPill(number: String, title: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.sonderAccent.opacity(0.14))
                    .frame(width: 34, height: 34)
                Text(number)
                    .font(.georgiaBold(14))
                    .foregroundStyle(Color.sonderAccent)
            }
            Text(title)
                .font(.georgiaBold(13))
                .foregroundStyle(Color.sonderTextPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 110)
    }

    private var getStartedButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                started = true
                mode = .signUp
            }
        } label: {
            Text("Get Started")
                .font(.georgiaBold(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.sonderAccent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private var signInLinkButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                started = true
                mode = .signIn
            }
        } label: {
            Text("Sign in")
                .font(.georgiaBold(15))
                .foregroundStyle(Color.sonderAccent)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var backToLandingButton: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    started = false
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.sonderAccent)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var footerCopy: some View {
        Text("No credit card. Just better trips.")
            .font(.georgia(13))
            .foregroundStyle(Color.sonderTextSecond)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }

    private var authCard: some View {
        VStack(spacing: 14) {
            if mode == .signUp {
                TextField("First name", text: $firstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)
                    .font(.georgia(15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.sonderSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                TextField("Last name", text: $lastName)
                    .textContentType(.familyName)
                    .autocapitalization(.words)
                    .font(.georgia(15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.sonderSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .font(.georgia(15))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.sonderSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            SecureField("Password", text: $password)
                .font(.georgia(15))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.sonderSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                if mode == .signIn {
                    Task { await auth.signIn(email: email, password: password) }
                } else {
                    Task { await auth.signUp(firstName: firstName, lastName: lastName, email: email, password: password) }
                }
            } label: {
                Text(mode == .signIn ? "Sign In" : "Create Account")
                    .font(.georgiaBold(15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.sonderAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(
                auth.isLoading
                || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || password.isEmpty
                || (mode == .signUp && (firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            )
        }
    }
}

