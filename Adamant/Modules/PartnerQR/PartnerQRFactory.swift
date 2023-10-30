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

struct PartnerQRFactory {
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = .init([PartnerQRAssembly()], parent: parent)
    }
    
    @MainActor
    func makeViewController(partner: CoreDataAccount) -> UIViewController {
        let viewModel = assembler.resolve(PartnerQRViewModel.self)!
        viewModel.setup(partner: partner)
        
        let view = PartnerQRView(
            viewModel: viewModel
        )
        
        return UIHostingController(
            rootView: view
        )
    }
}

private struct PartnerQRAssembly: Assembly {
    func assemble(container: Container) {
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
                partnerQRService: $0.resolve(PartnerQRService.self)!
            )
        }.inObjectScope(.weak)
    }
}
