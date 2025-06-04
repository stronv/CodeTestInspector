//
//  UserPresenter.swift
//  CodeTestInspector
//
//  Created by Artyom Tabachenko on 02.06.2025.
//

import Foundation

class UserPresenter {
    private let model: UserModel
    private weak var view: UsersViewProtocol?

    init(model: UserModel, view: UsersViewProtocol) {
        self.model = model
        self.view = view
    }

    // Основная «бизнес-логика» с несколькими ветвлениями
    func loadUser() {
        // Если имя пустое — ошибка
        if model.name.isEmpty {
            view?.displayError(message: "Name is empty")
            return
        }

        // Если возраст меньше 0 или больше 150 — ошибка «нереальный возраст»
        if model.age < 0 {
            view?.displayError(message: "Age cannot be negative")
            return
        } else if model.age > 150 {
            view?.displayError(message: "Age is too large")
            return
        }

        // Если всё в порядке, показываем данные
        view?.displayUser(name: model.name, age: model.age)
    }
}
