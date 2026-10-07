//
//  WebImage+Loading.swift
//  Discount
//
//  Created by Malik Alijanov on 07.10.26.
//

import SDWebImageSwiftUI

extension WebImage {
    func stableLoading() -> WebImage {
        retryOnAppear(false)
            .cancelOnDisappear(false)
    }
}
