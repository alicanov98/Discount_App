//
//  NetworkingDebugView.swift
//  Discount
//
//  Created by Malik Alijanov on 26.09.26.
//

import SwiftUI

struct NetworkingDebugView: View {
    var body: some View {
        List {
            #if DEBUG
                NavigationLink {
                    NetworkLogsView()
                } label: {
                    Label(
                        "Network Logs",
                        systemImage: "network"
                    )
                }
            #endif
        }
        .navigationTitle("Network Debug")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NetworkingDebugView()
}
