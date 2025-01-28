//
//  PartnerQRFactory.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject
import SwiftUI
import CommonKit

@MainActor
struct PartnerQRFactory {
    private let parent: Assembler
    private let assemblies = [PartnerQRAssembly()]
    init(parent: Assembler) {
        self.parent = parent
    }
    
    @MainActor
    func makeViewController(partner: CoreDataAccount, screenFactory: ScreensFactory) -> UIViewController {
        let assembler = Assembler(assemblies, parent: parent)
        
        let viewModel = {
            let viewModel = assembler.resolver.resolve(PartnerQRViewModel.self)!
            viewModel.setup(partner: partner)
            return viewModel
        }
        
        return UIHostingController(rootView: PartnerQRView(viewModel: viewModel, screenFactory: screenFactory))
    }
}

private struct PartnerQRAssembly: MainThreadAssembly {
    func assembleOnMainThread(container: Container) {
        container.register(PartnerQRService.self) { r in
            AdamantPartnerQRService(
                securedStore: r.resolve(SecuredStore.self)!
            )
        }.inObjectScope(.container)
        
        container.register(PartnerQRViewModel.self) {
            PartnerQRViewModel(
                dialogService: $0.resolve(DialogService.self)!,
                addressBookService: $0.resolve(AddressBookService.self)!,
                avatarService: $0.resolve(AvatarService.self)!,
                partnerQRService: $0.resolve(PartnerQRService.self)!,
                accountService: $0.resolve(AccountService.self)!
            )
        }.inObjectScope(.transient)
    }
}
