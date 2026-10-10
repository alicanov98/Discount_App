//
//  SettingsView.swift
//  Discount
//
//  Created by Malik Alijanov on 09.10.26.
//

import SwiftUI

struct SettingsView: View {
    let viewModel: ProfileViewModel
    @AppStorage("app.language") private var language: AppLanguage = .azerbaijani
    @AppStorage("app.appearance") private var appearance: AppAppearance = .system
    @State private var showsNotifications = false
    @State private var showsDeleteConfirmation = false

    var body: some View {
        ScrollView {
            section {
                HStack(spacing: 14) {
                    icon("globe")
                    Text("Dil")
                        .font(AppTypography.body)
                        .fixedSize()
                    Spacer(minLength: 8)
                    Menu {
                        Picker("Dil", selection: $language) {
                            ForEach(AppLanguage.allCases) { option in
                                Text(verbatim: option.title).tag(option)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(verbatim: language.title)
                                .font(AppTypography.body)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(AppTypography.font(size: 12, weight: .semiBold))
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(Color.appPrimary)
                        .frame(minHeight: 44)
                    }
                    .layoutPriority(1)
                    .accessibilityLabel("Dil")
                    .accessibilityValue(Text(verbatim: language.title))
                    .accessibilityIdentifier("settings-language")
                }

                Divider().overlay(Color.appBorder)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        icon("circle.lefthalf.filled")
                        Text("Görünüş")
                            .font(AppTypography.body)
                    }

                    Picker("Görünüş", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(LocalizedStringKey(option.title)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .font(AppTypography.caption)
                    .accessibilityIdentifier("settings-appearance")

                    Text("Sistem seçimi cihazın görünüş ayarına uyğunlaşır.")
                        .font(AppTypography.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Divider().overlay(Color.appBorder)

                Button {
                    showsNotifications = true
                } label: {
                    HStack(spacing: 14) {
                        icon("bell.badge")
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Bildiriş idarəsi")
                                .font(AppTypography.body)
                                .foregroundStyle(Color.appTextPrimary)
                            Text("Yaxınlıq, maraqlar və seçilmişlər")
                                .font(AppTypography.caption)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(AppTypography.caption)
                            .foregroundStyle(Color.appPrimary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasLoaded || viewModel.isBusy)
                .accessibilityIdentifier("settings-notifications")

                Divider().overlay(Color.appBorder)

                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    HStack(spacing: 14) {
                        icon("trash", tint: .appDanger, background: .appDangerBackground)
                        Text("Hesabı sil")
                            .font(AppTypography.body)
                        Spacer(minLength: 8)
                        if viewModel.operation == .deleting {
                            AppLoadingView(placement: .inline)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(AppTypography.caption)
                        }
                    }
                    .foregroundStyle(Color.appDanger)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasLoaded || viewModel.isBusy)
                .accessibilityIdentifier("settings-delete-account")

                Text("Hesabın və ona bağlı məlumatlar birdəfəlik silinəcək.")
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .foregroundStyle(Color.appTextPrimary)
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Ayarlar")
                    .font(AppTypography.sectionTitle)
            }
        }
        .tint(Color.appPrimary)
        .navigationDestination(isPresented: $showsNotifications) {
            ProfileEditorView(viewModel: viewModel, section: .notifications)
        }
        .task { await viewModel.load() }
        .alert("Hesabını silmək istəyirsən?", isPresented: $showsDeleteConfirmation) {
            Button("Hesabı saxla", role: .cancel) {}
            Button("Hesabı sil", role: .destructive) {
                Task { await viewModel.deleteAccount() }
            }
        } message: {
            if viewModel.isBusiness {
                Text("Biznesin, kampaniyaların və onların statistikası birdəfəlik silinəcək. Bu əməliyyatı geri qaytarmaq mümkün deyil.")
            } else {
                Text("Profilin, seçilmişlərin və şəxsi seçimlərin birdəfəlik silinəcək. Bu əməliyyatı geri qaytarmaq mümkün deyil.")
            }
        }
        .alert("Xəta baş verdi", isPresented: Binding(
            get: { viewModel.isShowingError && !showsNotifications },
            set: { if !$0 { viewModel.isShowingError = false } }
        )) {
            Button("Bağla", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(LocalizedStringKey(viewModel.errorMessage ?? "Əməliyyatı tamamlamaq mümkün olmadı."))
        }
    }

    private func icon(
        _ symbol: String,
        tint: Color = .appPrimary,
        background: Color = .appPrimarySoft
    ) -> some View {
        Image(systemName: symbol)
            .font(AppTypography.font(size: 20, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(background, in: Circle())
            .accessibilityHidden(true)
    }

    private func section<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22).stroke(Color.appBorder, lineWidth: 1)
        }
    }
}
