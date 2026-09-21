//
//  OnboardingView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct OnboardingView: View {
    
    let onCompleted: () -> Void
    
    var body: some View {
        VStack {
            Text("OnboardingView")
            Button("Basla"){
                onCompleted()
            }
        }
    }
}

//#Preview {
//    OnboardingView(onCompleted:(){
//    })
//}
