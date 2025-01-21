//
//  StreamSendableActor.swift
//  CommonKit
//
//  Created by Andrew G on 17.10.2024.
//

import Combine

public protocol StreamSendableActor: Actor {
    var streamSubscription: AnyCancellable? { get set }
    nonisolated var streamSender: AsyncStreamSender<@Sendable (isolated Self) -> Void> { get }
}

public extension StreamSendableActor {
    nonisolated func task(_ action: @escaping @Sendable (isolated Self) -> Void) {
        streamSender.send(action)
    }
    
    func configureStream() {
        streamSubscription = Task { [weak self, streamSender] in
            for await action in streamSender.stream {
                guard let self else { return }
                await action(self)
            }
        }.eraseToAnyCancellable()
    }
}
