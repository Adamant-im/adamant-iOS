import SwiftUI
import CommonKit

struct AddSecretWalletView: View {
    private var viewModel: SecretWalletsMenuViewModel
    @Binding private var password: String
    
    var body: some View {
        VStack {
            
        }
        .background(Color(.adamant.secondBackgroundColor))
        .navigationTitle(String.adamant.AddSecretWallet.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    init(viewModel: SecretWalletsMenuViewModel) {
        self.viewModel = viewModel
        self._password = Binding.constant("")
    }
}

private extension AddSecretWalletView {
    var inputSection: some View {
        Section {
            Group {
                Text(String.adamant.AddSecretWallet.description)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 5)
                
                AdamantSecureField(
                    placeholder: .adamant.AddSecretWallet.passwordPlaceholder,
                    text: $password
                )
                
                Button(action: { viewModel.createSecretWallet(password: password) }) {
                    Text(String.adamant.pkGenerator.generateButton)
                        .foregroundStyle(Color(uiColor: .adamant.primary))
                        .padding(.horizontal, 30)
                        .expanded(axes: .horizontal)
                }
            }.listRowBackground(Color(uiColor: .adamant.cellColor))
        }
    }
}
