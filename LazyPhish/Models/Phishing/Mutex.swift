//
//  Mutex.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 07.12.2024.
//


actor Mutex {
    let mainSemaphore = Semaphore(count: 1)
    
    func withLock(_ toExecute: @escaping () -> Void) async {
        await mainSemaphore.wait()
        toExecute()
        await mainSemaphore.signal()
    }
}