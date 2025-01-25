//
//  Semaphore.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 25.09.2024.
//

actor Semaphore {
    var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(count: Int = 0) {
        self.count = count
    }

    func wait() async {
        count -= 1
        if count >= 0 { return }
        await withCheckedContinuation {
            waiters.append($0)
        }
    }

    func signal(count: Int = 1) {
        assert(count >= 1)
        self.count += count
        for _ in 0..<count {
            if waiters.isEmpty { return }
            waiters.removeFirst().resume()
        }
    }
}
