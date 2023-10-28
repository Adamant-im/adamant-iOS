//
//  PartnerQRFactory.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject
import SwiftUI

struct PartnerQRFactory {
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = .init([ContributeAssembly()], parent: parent)
    }
    
    @MainActor
    func makeViewController(partner: CoreDataAccount) -> UIViewController {
        let view = PartnerQRView(
            viewModel: assembler.resolve(PartnerQRViewModel.self)!
        )
        view.viewModel.setup(partner: partner)
        
        return UIHostingController(
            rootView: view
        )
    }
}

private struct ContributeAssembly: Assembly {
    func assemble(container: Container) {
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
