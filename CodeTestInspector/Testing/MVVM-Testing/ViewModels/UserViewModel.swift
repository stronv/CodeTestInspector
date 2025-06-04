//
//  UserViewModel.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 25.05.2025.
//

import Foundation

class UserViewModel {
    var user: User
    init(user: User) {
        self.user = user
    }
    func test() {
        let view = UserView()
        print(view)
    }
}
