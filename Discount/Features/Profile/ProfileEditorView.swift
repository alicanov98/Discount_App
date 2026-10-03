Məntiqi dəyişmədən formatladım, artıq boşluqları və Markdown simvollarını təmizlədim:

```swift
//
//  ProfileEditorView.swift
//  Discount
//
//  Created by Malik Alijanov on 03.10.26.
//

import SwiftUI
import UIKit

struct ProfileEditorView: View {
    let viewModel: ProfileViewModel
    let section: ProfileSection

    @State private var draft: ProfileDraft
    @State private var savedDraft: ProfileDraft
    @State private var selectedInterests: Set<String>
    @State private var savedInterests: Set<String>
    @State private var saveMessage: String?

    init(
        viewModel: ProfileViewModel,
        section: ProfileSection
    ) {
        self.viewModel = viewModel
        self.section = section

        _draft = State(initialValue: viewModel.draft)
        _savedDraft = State(initialValue: viewModel.draft)

        let interests = Set(viewModel.user?.interests ?? [])

        _selectedInterests = State(initialValue: interests)
        _savedInterests = State(initialValue: interests)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let saveMessage {
                    Label(
                        saveMessage,
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appSuccess)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        Color.appSuccessBackground,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .accessibilityIdentifier("profile-save-success")
                }

                sectionFields
                    .disabled(viewModel.isBusy)

                PrimaryButton(
                    title: "Dəyişiklikləri saxla",
                    backgroundColor: Color.appPrimary,
                    textColor: Color.appOnPrimary,
                    isLoading: viewModel.operation == .savingProfile
                        || viewModel.operation == .savingInterests,
                    isDisable: viewModel.isBusy
                        || !hasChanges
                        || (section == .interests && viewModel.categories.isEmpty)
                ) {
                    Task {
                        await save()
                    }
                }
                .accessibilityIdentifier("profile-save")
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground)
        .navigationTitle(section.title(isBusiness: viewModel.isBusiness))
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.appPrimary)
        .alert(
            "Xəta baş verdi",
            isPresented: Binding(
                get: {
                    viewModel.isShowingError
                },
                set: {
                    viewModel.isShowingError = $0
                }
            )
        ) {
            Button("Bağla", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(
                viewModel.errorMessage
                    ?? "Dəyişiklikləri saxlamaq mümkün olmadı."
            )
        }
    }

    private var hasChanges: Bool {
        section == .interests
            ? selectedInterests != savedInterests
            : draft != savedDraft
    }

    private func save() async {
        saveMessage = nil

        if section == .interests {
            if await viewModel.saveInterests(selectedInterests) {
                selectedInterests = Set(viewModel.user?.interests ?? [])
                savedInterests = selectedInterests
                saveMessage = "Maraqların yeniləndi."
            }
        } else if await viewModel.saveProfile(
            section: section,
            editedDraft: draft
        ) {
            draft = viewModel.draft
            savedDraft = draft
            saveMessage = "Dəyişikliklər saxlanıldı."
        }
    }

    @ViewBuilder
    private var sectionFields: some View {
        switch section {
        case .identity:
            card(
                title: section.title(isBusiness: viewModel.isBusiness),
                symbol: section.symbol
            ) {
                input(
                    viewModel.isBusiness ? "Biznes adı" : "Ad və soyad",
                    text: $draft.name
                )

                input(
                    "E-poçt",
                    text: $draft.email,
                    keyboard: .emailAddress,
                    capitalization: .never
                )
                .accessibilityIdentifier("profile-email")

                if viewModel.isBusiness {
                    businessFields
                }
            }

        case .location:
            card(title: "Məkan", symbol: section.symbol) {
                Text(
                    viewModel.isBusiness
                        ? "Müştərilərinin səni tapa biləcəyi məkanı qeyd et."
                        : "Yaxın təkliflər üçün məkanını qeyd et."
                )
                .font(AppTypography.caption)
                .foregroundStyle(Color.appTextSecondary)

                input(
                    "Enlik",
                    text: $draft.latitude,
                    keyboard: .numbersAndPunctuation,
                    capitalization: .never,
                    placeholder: "40.4093"
                )

                input(
                    "Uzunluq",
                    text: $draft.longitude,
                    keyboard: .numbersAndPunctuation,
                    capitalization: .never,
                    placeholder: "49.8671"
                )

                Text("Məkanı silmək üçün hər iki koordinatı boş saxla.")
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.appTextMuted)
            }

        case .notifications:
            card(
                title: "Bildiriş seçimləri",
                symbol: section.symbol
            ) {
                notificationToggle(
                    "Yaxınlıqdakı kampaniyalar",
                    description: "Saxlanmış məkanına yaxın yeni təkliflər.",
                    value: $draft.notifyNearby
                )

                Divider()

                notificationToggle(
                    "Maraqlarıma uyğun təkliflər",
                    description: "Seçdiyin kateqoriyalarda yeni kampaniyalar.",
                    value: $draft.notifyInterests
                )

                Divider()

                notificationToggle(
                    "Seçilmişlərdə yeniliklər",
                    description: "Yenilənən və bitmək üzrə olan seçilmiş təkliflər.",
                    value: $draft.notifyFavorites
                )

                input(
                    "Yaxınlıq radiusu (km)",
                    text: $draft.notificationRadius,
                    keyboard: .decimalPad,
                    capitalization: .never
                )
            }

        case .interests:
            interests
        }
    }

    private var interests: some View {
        card(title: "Maraqlarım", symbol: "sparkles") {
            Text("Sənə uyğun təklifləri seçməyimiz üçün maraq kateqoriyalarını qeyd et.")
                .font(AppTypography.caption)
                .foregroundStyle(Color.appTextSecondary)

            categoryError

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 138), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(viewModel.categories) { category in
                    let selected = selectedInterests.contains(category.slug)

                    Button {
                        if selected {
                            selectedInterests.remove(category.slug)
                        } else {
                            selectedInterests.insert(category.slug)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(
                                systemName: selected
                                    ? "checkmark.circle.fill"
                                    : category.symbol
                            )

                            Text(category.displayName)
                                .multilineTextAlignment(.leading)
                        }
                        .font(AppTypography.caption)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 34,
                            alignment: .leading
                        )
                        .padding(10)
                        .foregroundStyle(
                            selected
                                ? Color.appOnPrimary
                                : Color.appTextPrimary
                        )
                        .background(
                            selected
                                ? Color.appPrimary
                                : Color.appBackground,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(
                        selected ? "Seçilib" : "Seçilməyib"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var categoryError: some View {
        if let error = viewModel.categoryError {
            CampaignErrorView(message: error) {
                Task {
                    await viewModel.loadCategories()
                }
            }
        }
    }

    private var businessFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Kateqoriya", selection: $draft.categoryID) {
                Text("Seçilməyib")
                    .tag(nil as Int?)

                if let selected = draft.categoryID,
                   !viewModel.categories.contains(where: { $0.id == selected })
                {
                    Text("Seçilmiş kateqoriya")
                        .tag(Optional(selected))
                }

                ForEach(viewModel.categories) { category in
                    Text(category.displayName)
                        .tag(Optional(category.id))
                }
            }
            .pickerStyle(.menu)

            categoryError

            input(
                "Telefon",
                text: $draft.phone,
                keyboard: .phonePad,
                capitalization: .never,
                placeholder: "+994 50 000 00 00"
            )

            input(
                "Ünvan",
                text: $draft.address,
                placeholder: "Küçə və bina"
            )

            input(
                "Loqo linki",
                text: $draft.logoURL,
                keyboard: .URL,
                capitalization: .never,
                placeholder: "https://…/logo.png"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Biznes haqqında")
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.appTextSecondary)

                TextField(
                    "Biznesini qısaca tanıt",
                    text: $draft.description,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .font(AppTypography.body)
                .padding(12)
                .background(
                    Color.appBackground,
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
        }
    }

    private func notificationToggle(
        _ title: String,
        description: String,
        value: Binding<Bool>
    ) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appTextPrimary)

                Text(description)
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    private func input(
        _ label: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        capitalization: TextInputAutocapitalization = .words,
        placeholder: String = ""
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(Color.appTextSecondary)

            TextField(
                placeholder.isEmpty ? label : placeholder,
                text: text
            )
            .font(AppTypography.body)
            .keyboardType(keyboard)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled()
            .padding(12)
            .background(
                Color.appBackground,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appBorder)
            )
            .accessibilityLabel(label)
        }
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
```