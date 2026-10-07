//
//  ProfileView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SDWebImageSwiftUI
import SwiftUI

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    @State private var selectedSection: ProfileSection?
    @State private var showsDeleteConfirmation = false
    @State private var showsLogoutConfirmation = false

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                identity

                if let message = viewModel.successMessage {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .font(AppTypography.body)
                        .foregroundStyle(Color.appSuccess)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            Color.appSuccessBackground,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }

                if viewModel.hasLoaded {
                    sectionMenu
                    accountActions
                } else if viewModel.operation == .loading {
                    ProgressView("Profil yüklənir…")
                        .frame(maxWidth: .infinity)
                        .padding(30)
                } else {
                    CampaignErrorView(
                        message: viewModel.errorMessage
                            ?? "Profil məlumatlarını yükləmək mümkün olmadı."
                    ) {
                        Task {
                            await viewModel.load()
                        }
                    }

                    logoutButton
                }
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle(viewModel.isBusiness ? "Biznes profili" : "Profilim")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.appPrimary)
        .task {
            await viewModel.load()
        }
        .navigationDestination(item: $selectedSection) { section in
            ProfileEditorView(
                viewModel: viewModel,
                section: section
            )
        }
        .alert(
            "Xəta baş verdi",
            isPresented: Binding(
                get: {
                    viewModel.isShowingError && selectedSection == nil
                },
                set: {
                    if !$0 {
                        viewModel.isShowingError = false
                    }
                }
            )
        ) {
            Button("Bağla", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(
                viewModel.errorMessage
                    ?? "Əməliyyatı tamamlamaq mümkün olmadı."
            )
        }
        .alert(
            "Hesabdan çıxmaq istəyirsən?",
            isPresented: $showsLogoutConfirmation
        ) {
            Button("Hesabdan çıx", role: .destructive) {
                Task {
                    await viewModel.logout()
                }
            }

            Button("Ləğv et", role: .cancel) {}
        }
        .alert(
            "Hesabını silmək istəyirsən?",
            isPresented: $showsDeleteConfirmation
        ) {
            Button("Hesabı saxla", role: .cancel) {}

            Button("Hesabı sil", role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                }
            }
        } message: {
            Text(
                viewModel.isBusiness
                    ? "Biznesin, kampaniyaların və onların statistikası birdəfəlik silinəcək. Bu əməliyyatı geri qaytarmaq mümkün deyil."
                    : "Profilin, seçilmişlərin və şəxsi seçimlərin birdəfəlik silinəcək. Bu əməliyyatı geri qaytarmaq mümkün deyil."
            )
        }
    }

    private var sectionMenu: some View {
        card(
            title: "Profil məlumatları",
            symbol: "slider.horizontal.3"
        ) {
            ForEach(sections) { section in
                Button {
                    selectedSection = section
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: section.symbol)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .foregroundStyle(Color.appPrimary)
                            .background(
                                Color.appPrimarySoft,
                                in: RoundedRectangle(cornerRadius: 13)
                            )

                        VStack(alignment: .leading, spacing: 5) {
                            Text(section.title(isBusiness: viewModel.isBusiness))
                                .font(AppTypography.body)
                                .foregroundStyle(Color.appTextPrimary)

                            Text(section.subtitle)
                                .font(AppTypography.caption)
                                .foregroundStyle(Color.appTextSecondary)
                        }

                        Spacer(minLength: 4)

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(Color.appTextMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isBusy)
                .accessibilityIdentifier("profile-section-\(section.rawValue)")

                if section != sections.last {
                    Divider()
                }
            }
        }
    }

    private var sections: [ProfileSection] {
        viewModel.isBusiness
            ? [.identity]
            : [.identity, .notifications, .interests]
    }

    private var identity: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appPrimarySoft)

                Text(viewModel.initials.isEmpty ? "?" : viewModel.initials)
                    .font(AppTypography.title)
                    .foregroundStyle(Color.appPrimary)

                AppImage(source: viewModel.business?.logoURL) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    case .empty:
                        Color.appPrimarySoft.overlay { ProgressView() }
                    case .failure:
                        Color.appTransparent
                    }
                }
            }
            .frame(width: 76, height: 76)
            .clipShape(Circle())
            .contentShape(Circle())

            Text(viewModel.business?.name ?? viewModel.user?.name ?? "Hesabım")
                .font(AppTypography.title)
                .multilineTextAlignment(.center)

            Text(viewModel.user?.email ?? "")
                .font(AppTypography.body)
                .foregroundStyle(Color.appTextSecondary)

            Label(
                viewModel.isBusiness ? "Biznes hesabı" : "Şəxsi hesab",
                systemImage: viewModel.isBusiness
                    ? "storefront"
                    : "person.crop.circle"
            )
            .font(AppTypography.caption)
            .foregroundStyle(Color.appPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.appPrimarySoft, in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            Color.appCardBackground,
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.appBorder)
        )
    }

    private var accountActions: some View {
        card(title: "Hesab", symbol: "person.crop.circle") {
            logoutButton

            Divider()

            Button(role: .destructive) {
                showsDeleteConfirmation = true
            } label: {
                Label("Hesabı sil", systemImage: "trash")
                    .font(AppTypography.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            .foregroundStyle(Color.appDanger)
            .disabled(viewModel.isBusy)

            Text("Hesabın və ona bağlı məlumatlar birdəfəlik silinəcək.")
                .font(AppTypography.caption)
                .foregroundStyle(Color.appTextMuted)
        }
    }

    private var logoutButton: some View {
        Button {
            showsLogoutConfirmation = true
        } label: {
            HStack(spacing: 10) {
                if viewModel.operation == .loggingOut {
                    ProgressView()
                } else {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }

                Text("Hesabdan çıx")
            }
            .font(AppTypography.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
        .foregroundStyle(Color.appTextPrimary)
        .disabled(viewModel.isBusy)
    }

    private func card<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: symbol)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(Color.appTextPrimary)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            Color.appCardBackground,
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.appBorder)
        )
    }
}
