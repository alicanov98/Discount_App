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
        self._text = text
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment:.leading) {
            Text(title)
    
        VStack(alignment: .leading, spacing: 6){
           
            HStack {
            inputField
            if type.isSecure {
                passwordVisibilityButton
            }
            }
        }
        .padding(.horizontal,16)
        .frame(height: 52)
        .background{
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.white))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(errorMessage == nil ?
                  Color.gray.opacity(0.5) :
                  Color.red, lineWidth: 1)
        }
        if let errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal,4)
        }
        }
    }
    
    @ViewBuilder
    private var inputField: some View {
        if type.isSecure && !isPasswordVisible {
            SecureField(placeholder,text:$text)
                .textContentType(type.contnetType)
        }else {
            TextField(placeholder,text:$text)
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
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
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
