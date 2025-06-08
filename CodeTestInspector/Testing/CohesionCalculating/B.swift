protocol BProtocol {
    func bar()
}

class B: BProtocol {
    func bar() {
        let a = A()
        a.foo()
    }
}
