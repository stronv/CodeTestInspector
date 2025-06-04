//
//  UsersView.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 02.06.2025.
//

import Foundation

protocol UsersViewProtocol: AnyObject {
    func displayUser(name: String, age: Int)
    func displayError(message: String)
}

class UserViews: UsersViewProtocol {
    // Ссылка на презентер
    var presenter: UserPresenter?

    func displayUser(name: String, age: Int) {
        print("User: \(name), Age: \(age)")
    }

    func displayError(message: String) {
        print("Error: \(message)")
    }

    // Вызов, например, при загрузке экрана
    func onViewDidLoad() {
        presenter?.loadUser()
    }
}
