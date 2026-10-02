//
//  ViewState.swift
//  Discount
//
//  Created by Malik Alijanov on 30.09.26.
//

enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
}
