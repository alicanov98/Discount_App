//
//  InputField.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI


struct InputField: View {
    let title:String
    let placeholder:String
    let type: InputFieldType
    let icon: String?

    @Binding var text: String
    var errorMessage: String?
    @State private var isPasswordVisible = false

    init(title: String,placeholder: String, type: InputFieldType = .text, icon: String? = nil, text: Binding<String>, errorMessage: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self.type = type
        self.icon = icon
        _text = text
        self.errorMessage = errorMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(LocalizedStringKey(title))
                .font(AppTypography.body)
            VStack(alignment: .leading, spacing: AppSpacing.sm){
                HStack(spacing: AppSpacing.sm) {
                    if let icon {
                        Image(systemName: icon)
                            .foregroundStyle(Color.appTextSecondary)
                            .accessibilityHidden(true)
                    }
                    inputField
                        .foregroundStyle(Color.appTextPrimary)
                        .font(AppTypography.body)
                        .accessibilityLabel(Text(LocalizedStringKey(title)))
                        .frame(maxWidth: .infinity)
                    if type.isSecure {
                        passwordVisibilityButton
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.controlVertical)
            .frame(minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.control)
                    .fill(Color.appCardBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.control)
                    .stroke(errorMessage == nil ?
                        Color.appBorder :
                        Color.appDanger, lineWidth: 1)
            }
            if let errorMessage {
                Text(LocalizedStringKey(errorMessage))
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.appDanger)
                    .padding(.horizontal, AppSpacing.xs)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var inputField: some View {
        if type.isSecure && !isPasswordVisible {
            SecureField(LocalizedStringKey(placeholder),text:$text)
                .textContentType(type.contnetType)
        }else {
            TextField(LocalizedStringKey(placeholder),text:$text)
                .textContentType(type.contnetType)
                .keyboardType(type.keyboardType)
                .textInputAutocapitalization(
                    type == .text ? .words : .never
                )
                .autocorrectionDisabled(type != .text)
        }
    }
    
    private var passwordVisibilityButton: some View {
        Button {
            isPasswordVisible.toggle()
        }label: {
            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                .foregroundStyle(Color.appTextSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPasswordVisible ? "Şifrəni gizlət" : "Şifrəni göstər")
    }
}



#Preview {
    @Previewable @State var name = ""

    InputField(
        title: "Ad1",
        placeholder: "Ad",
        type: .password,
        icon: "mail",
        text: $name,
        errorMessage: "Salam"
    )
    .padding()
}
