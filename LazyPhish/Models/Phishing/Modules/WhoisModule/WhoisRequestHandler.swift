//
//  WhoisRequestHandler.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 08.12.2024.
//

import Foundation
import NIO
import OSLog

final class WhoisRequestHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    
    var promise: EventLoopPromise<String>
    var finished: Bool = false
    
    init(promise: EventLoopPromise<String>) {
        self.promise = promise
        Task {
            do {
                try await Task.sleep(for: .seconds(3))
            }
            if !finished {
                eventTimeout()
            }
        }
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let dataBuffer = self.unwrapInboundIn(data)
        if let returnedString = dataBuffer.getString(at: 0, length: dataBuffer.readableBytes) {
            promise.succeed(returnedString)
        } else {
            promise.fail(WhoisModuleError.emptyData)
            Logger.whoisRequestLogger.info("Request string is null. Check WhoisRequestHandler")
        }
        finished = true
        context.close(promise: nil)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        finished = true
        promise.fail(WhoisModuleError.NIOInternal(error))
        context.close(promise: nil)
    }
    
    func eventTimeout() {
        promise.fail(WhoisModuleError.timeout)
    }
    
    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        if event is IdleStateHandler.IdleStateEvent {
            promise.fail(WhoisModuleError.timeout)
            context.close(promise: nil)
        }
    }
}
