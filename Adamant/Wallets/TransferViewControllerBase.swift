//
//  TransferViewControllerBase.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import QRCodeReader

// MARK: - Transfer Delegate Protocol

@MainActor
protocol TransferViewControllerDelegate: AnyObject {
    func transferViewController(_ viewController: TransferViewControllerBase, didFinishWithTransfer transfer: TransactionDetails?, detailsViewController: UIViewController?)
}

// MARK: - Localization
extension String.adamantLocalized {
    struct transfer {
        static let addressPlaceholder = NSLocalizedString("TransferScene.Recipient.Placeholder", comment: "Transfer: recipient address placeholder")
        static let amountPlaceholder = NSLocalizedString("TransferScene.Amount.Placeholder", comment: "Transfer: transfer amount placeholder")
        
        static let addressValidationError = NSLocalizedString("TransferScene.Error.InvalidAddress", comment: "Transfer: Address validation error")
        static let amountZeroError = NSLocalizedString("TransferScene.Error.TooLittleMoney", comment: "Transfer: Amount is zero, or even negative notification")
        static let notEnoughFeeError = NSLocalizedString("TransferScene.Error.TooLittleFee", comment: "Transfer: Not enough fee for send a transaction")
        static let feeIsTooHigh = NSLocalizedString("TransferScene.Error.FeeIsTooHigh", comment: "Transfer: Fee is higher than usual")
        static let amountTooHigh = NSLocalizedString("TransferScene.Error.notEnoughMoney", comment: "Transfer: Amount is hiegher that user's total money notification")
        static let accountNotFound = NSLocalizedString("TransferScene.Error.AddressNotFound", comment: "Transfer: Address not found error")
        
        static let transferProcessingMessage = NSLocalizedString("TransferScene.SendingFundsProgress", comment: "Transfer: Processing message")
        static let transferSuccess = NSLocalizedString("TransferScene.TransferSuccessMessage", comment: "Transfer: Tokens transfered successfully message")
        
        static let send = NSLocalizedString("TransferScene.Send", comment: "Transfer: Send button")
        
        static let cantUndo = NSLocalizedString("TransferScene.CantUndo", comment: "Transfer: Send button")
        
        static let useMaxToTransfer = NSLocalizedString("TransferScene.UseMaxToTransfer", comment: "Tranfser: Confirm using maximum available for transfer tokens as amount to transfer.")
        
        private init() { }
    }
}

fileprivate extension String.adamantLocalized.alert {
    static let confirmSendMessageFormat = NSLocalizedString("TransferScene.SendConfirmFormat", comment: "Transfer: Confirm transfer %1$@ tokens to %2$@ message. Note two variables: at runtime %1$@ will be amount (with ADM suffix), and %2$@ will be recipient address. You can use address before amount with this so called 'position tokens'.")
    static func confirmSendMessage(formattedAmount amount: String, recipient: String) -> String {
        return String.localizedStringWithFormat(String.adamantLocalized.alert.confirmSendMessageFormat, "\(amount)", recipient)
    }
    static let send = NSLocalizedString("TransferScene.Send", comment: "Transfer: Confirm transfer alert: Send tokens button")
}

// MARK: -
class TransferViewControllerBase: FormViewController {
    
    // MARK: - Rows
    
    enum BaseRows {
        case balance
        case amount
        case fiat
        case maxToTransfer
        case name
        case address
        case fee
        case total
        case comments
        case sendButton
        
        var tag: String {
            switch self {
            case .balance: return "balance"
            case .amount: return "amount"
            case .fiat: return "fiat"
            case .maxToTransfer: return "max"
            case .name: return "name"
            case .address: return "recipient"
            case .fee: return "fee"
            case .total: return "total"
            case .comments: return "comments"
            case .sendButton: return "send"
            }
        }
        
        var localized: String {
            switch self {
            case .balance: return NSLocalizedString("TransferScene.Row.Balance", comment: "Transfer: logged user balance.")
            case .amount: return NSLocalizedString("TransferScene.Row.Amount", comment: "Transfer: amount of adamant to transfer.")
            case .fiat: return NSLocalizedString("TransferScene.Row.Fiat", comment: "Transfer: fiat value of crypto-amout")
            case .maxToTransfer: return NSLocalizedString("TransferScene.Row.MaxToTransfer", comment: "Transfer: maximum amount to transfer: available account money substracting transfer fee")
            case .name: return NSLocalizedString("TransferScene.Row.RecipientName", comment: "Transfer: recipient name")
            case .address: return NSLocalizedString("TransferScene.Row.RecipientAddress", comment: "Transfer: recipient address")
            case .fee: return NSLocalizedString("TransferScene.Row.TransactionFee", comment: "Transfer: transfer fee")
            case .total: return NSLocalizedString("TransferScene.Row.Total", comment: "Transfer: total amount of transaction: money to transfer adding fee")
            case .comments: return NSLocalizedString("TransferScene.Row.Comments", comment: "Transfer: transfer comment")
            case .sendButton: return String.adamantLocalized.transfer.send
            }
        }
    }
    
    enum Sections {
        case wallet
        case recipient
        case transferInfo
        case comments
        
        var tag: String {
            switch self {
            case .wallet: return "wlt"
            case .recipient: return "rcp"
            case .transferInfo: return "trsfr"
            case .comments: return "cmmnt"
            }
        }
        
        var localized: String {
            switch self {
            case .wallet: return NSLocalizedString("TransferScene.Section.YourWallet", comment: "Transfer: 'Your wallet' section")
            case .recipient: return NSLocalizedString("TransferScene.Section.Recipient", comment: "Transfer: 'Recipient info' section")
            case .transferInfo: return NSLocalizedString("TransferScene.Section.TransferInfo", comment: "Transfer: 'Transfer info' section")
            case .comments: return NSLocalizedString("TransferScene.Row.Comments", comment: "Transfer: transfer comment")
            }
        }
    }
    
    // MARK: - Dependencies
    
    let accountService: AccountService
    let accountsProvider: AccountsProvider
    let dialogService: DialogService
    let router: Router
    let currencyInfoService: CurrencyInfoService
    
    // MARK: - Properties
    
    private var previousIsReadyToSend: Bool?
    
    var commentsEnabled: Bool = false
    var rootCoinBalance: Decimal?
    
    var service: WalletServiceWithSend? {
        didSet {
            if let prev = oldValue {
                NotificationCenter.default.removeObserver(self, name: prev.transactionFeeUpdated, object: prev)
                NotificationCenter.default.removeObserver(self, name: prev.walletUpdatedNotification, object: prev)
            }
            
            if let new = service {
                NotificationCenter.default.addObserver(forName: new.transactionFeeUpdated, object: new, queue: OperationQueue.main) { [weak self] _ in
                    guard let form = self?.form
                    else {
                        return
                    }
                    
                    if let row: DoubleDetailsRow = form.rowBy(tag: BaseRows.fee.tag) {
                        row.value = self?.getCellFeeValue()
                        row.updateCell()
                    }
                    
                    if let row: DecimalRow = form.rowBy(tag: BaseRows.maxToTransfer.tag) {
                        row.updateCell()
                    }
                    
                    self?.validateForm()
                }
                
                NotificationCenter.default.addObserver(forName: new.walletUpdatedNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
                    self?.reloadFormData()
                }
            }
        }
    }
    
    weak var delegate: TransferViewControllerDelegate?
    
    var recipientAddress: String? {
        didSet {
            if let row: RowOf<String> = form.rowBy(tag: BaseRows.address.tag) {
                row.value = recipientAddress
                row.updateCell()
                validateForm()
            }
        }
    }
    
    private var recipientAddressIsValid = false
    
    var recipientName: String? {
        didSet {
            guard let row: RowOf<String> = form.rowBy(tag: BaseRows.name.tag) else {
                return
            }
            
            row.value = recipientName
            row.updateCell()
            row.evaluateHidden()
        }
    }
    
    var admReportRecipient: String?
    var amount: Decimal?
    
    var recipientIsReadonly = false
    
    var rate: Decimal?
    
    var maxToTransfer: Decimal {
        guard
            let service = service,
            let balance = service.wallet?.balance,
            balance > service.minBalance else {
            return 0
        }
        
        let max = balance - service.transactionFee - service.minBalance
        
        return max >= 0 ? max : 0
    }
    
    var minToTransfer: Decimal {
        guard
            let service = service else {
            return 0
        }
        
        return service.minAmount
    }
    
    override var customNavigationAccessoryView: (UIView & NavigationAccessory)? {
        let accessory = NavigationAccessoryView()
        accessory.tintColor = UIColor.adamant.primary
        return accessory
    }
    
    // MARK: - QR Reader
    
    lazy var qrReader: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr ], captureDevicePosition: .back)
            $0.cancelButtonTitle = String.adamantLocalized.alert.cancel
            $0.showSwitchCameraButton = false
        }
        
        let vc = QRCodeReaderViewController(builder: builder)
        vc.delegate = self
        return vc
    }()
    
    // MARK: - Alert
    var progressView: UIView?
    var alertView: UIView?
    
    // MARK: - Lifecycle
    
    init(
        accountService: AccountService,
        accountsProvider: AccountsProvider,
        dialogService: DialogService,
        router: Router,
        currencyInfoService: CurrencyInfoService
    ) {
        self.accountService = accountService
        self.accountsProvider = accountsProvider
        self.dialogService = dialogService
        self.router = router
        self.currencyInfoService = currencyInfoService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Fiat rate
        rate = currencyInfoService.getRate(for: currencyCode)
        
        // MARK: UI
        navigationItem.title = defaultSceneTitle()
        
        // MARK: Sections
        form.append(walletSection())
        form.append(recipientSection())
        form.append(transactionInfoSection())
        
        if commentsEnabled {
            form.append(commentsSection())
        }
        
        // MARK: Button section
        form +++ Section()
        <<< ButtonRow {
            $0.title = BaseRows.sendButton.localized
            $0.tag = BaseRows.sendButton.tag
        }.onCellSelection { [weak self] (_, _) in
            self?.confirmSendFunds()
        }
        
        // MARK: Notifications
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantCurrencyInfoService.currencyRatesUpdated,
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: { [weak self] _ in
                                                guard let vc = self else {
                                                    return
                                                }
                                                
                                                vc.rate = vc.currencyInfoService.getRate(for: vc.currencyCode)
                                                
                                                if let row: DecimalRow = vc.form.rowBy(tag: BaseRows.fiat.tag) {
                                                    if let formatter = row.formatter as? NumberFormatter {
                                                        formatter.currencyCode = vc.currencyInfoService.currentCurrency.rawValue
                                                    }
                                                    
                                                    row.updateCell()
                                                }
        })
        
        setColors()
    }
    
    // MARK: - Other
    
    private func isReadyToSend() -> Bool {
        validateAddress()
        guard recipientAddress != nil,
              recipientAddressIsValid,
              amount != nil
        else {
            return false
        }
        if commentsEnabled {
            if let row: TextAreaRow = form.rowBy(tag: BaseRows.comments.tag) {
                return !(row.value?.isEmpty ?? true)
            }
            return false
        }
        return true
    }
    
    private func navigationKeybordDone() {
        tableView?.endEditing(true)
        if isReadyToSend() {
            confirmSendFunds()
        }
    }

    func updateToolbar(for row: BaseRow) {
        _ = inputAccessoryView(for: row)
    }
    
    override func inputAccessoryView(for row: BaseRow) -> UIView? {
        let view = super.inputAccessoryView(for: row)
        guard var view = view as? NavigationAccessoryView else { return view }
        
        view.doneClosure = { [weak self] in
            self?.navigationKeybordDone()
        }
        
        if let previousIsReadyToSend = previousIsReadyToSend,
           previousIsReadyToSend == isReadyToSend() {
            return view
        }
        previousIsReadyToSend = isReadyToSend()
        
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: view, action: view.doneButton.action)
        let sendBtn = UIBarButtonItem(title: String.adamantLocalized.transfer.send, style: .done, target: view, action: view.doneButton.action)
        view.doneButton = isReadyToSend() ? sendBtn : doneBtn
        if (view.items?.count ?? 0) > 4 {
            view.items?.remove(at: 4)
            view.items?.append(view.doneButton)
        }
        return view
    }
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
    }
    
    // MARK: - Form constructors
    
    func walletSection() -> Section {
        let section = Section(Sections.wallet.localized) {
            $0.tag = Sections.wallet.tag
        }
        
        section.append(defaultRowFor(baseRow: BaseRows.balance))
        section.append(defaultRowFor(baseRow: BaseRows.maxToTransfer))
        
        return section
    }
    
    func recipientSection() -> Section {
        let section = Section(Sections.recipient.localized) {
            $0.tag = Sections.recipient.tag
        }
        
        section.header = {
            var header = HeaderFooterView<UILabel>(.callback({
                let font = UIFont.preferredFont(forTextStyle: .footnote)
                let label = UILabel()
                label.text = "    \(Sections.recipient.localized.uppercased())"
                label.font = font
                label.textColor = .adamant.primary
                return label
            }))
            
            header.height = {
                33
            }
            return header
        }()
        
        // Address row
        section.append(defaultRowFor(baseRow: BaseRows.address))
        
        if !recipientIsReadonly, let stripe = recipientStripe() {
            var footer = HeaderFooterView<UIView>(.callback {
                let view = ButtonsStripeView.adamantConfigured()
                view.stripe = stripe
                view.delegate = self
                return view
            })
                
            footer.height = { ButtonsStripeView.adamantDefaultHeight }
            
            section.footer = footer
        }
        
        return section
    }
    
    func transactionInfoSection() -> Section {
        let section = Section(Sections.transferInfo.localized) {
            $0.tag = Sections.transferInfo.tag
        }
        
        section.append(defaultRowFor(baseRow: .amount))
        section.append(defaultRowFor(baseRow: .fiat))
        section.append(defaultRowFor(baseRow: .fee))
        section.append(defaultRowFor(baseRow: .total))
        
        return section
    }
    
    func commentsSection() -> Section {
        let section = Section(Sections.comments.localized) {
            $0.tag = Sections.comments.tag
        }
        
        section.append(defaultRowFor(baseRow: .comments))
        
        return section
    }

    // MARK: - Tools

    @discardableResult
    func validateAddress() -> Bool {
        guard let row: RowOf<String> = form.rowBy(tag: BaseRows.address.tag) else {
            recipientAddress = nil
            recipientAddressIsValid = false
            return false
        }

        if let address = row.value, validateRecipient(address) {
            recipientAddress = address
            markAddres(isValid: true)
            recipientAddressIsValid = true
            return true
        } else {
            markAddres(isValid: false)
            recipientAddressIsValid = false
            return false
        }
    }
    
    func validateForm(force: Bool = false) {
        guard let service = service, let wallet = service.wallet else {
            return
        }
        
        if let row: DoubleDetailsRow = form.rowBy(tag: BaseRows.fee.tag) {
            markRow(row, valid: isEnoughFee())
        }
        
        if let row: DecimalRow = form.rowBy(tag: BaseRows.maxToTransfer.tag) {
            markRow(row, valid: wallet.balance > service.transactionFee)
        }
        
        if let row: DecimalRow = form.rowBy(tag: BaseRows.amount.tag) {
            // Eureka looses decimal precision when deserializing numbers by itself.
            // Try to get raw value and deserialize it
            if let input = row.cell.textInput as? UITextField, let raw = input.text {
                if raw.isEmpty && force {
                    markRow(row, valid: false)
                    return
                }
                // NumberFormatter.number(from: string).decimalValue loses precision.
                // Creating decimal with Decimal(string: "") drops decimal part, if wrong locale used
                var gotValue = false
                if let localeSeparator = Locale.current.decimalSeparator {
                    let replacingSeparator = localeSeparator == "." ? "," : "."
                    let fixed = raw.replacingOccurrences(of: replacingSeparator, with: localeSeparator)
                    
                    if let amount = Decimal(string: fixed, locale: Locale.current) {
                        self.amount = amount
                        markRow(row, valid: validateAmount(amount))
                        gotValue = true
                    }
                }
                
                if !gotValue {
                    if let raw = row.value {
                        let amount = Decimal(raw)
                        self.amount = amount
                        markRow(row, valid: validateAmount(amount))
                    } else {
                        self.amount = nil
                        markRow(row, valid: true)
                    }
                }
            } else if let raw = row.value { // We can't get raw value, let's try to get a value from row
                let amount = Decimal(raw)
                self.amount = amount
                
                markRow(row, valid: validateAmount(amount))
            } else { // No value at all
                amount = nil
                markRow(row, valid: true)
            }
        } else {
            amount = nil
        }
        
        if let row: DecimalRow = form.rowBy(tag: BaseRows.total.tag) {
            if let amount = amount {
                row.value = (amount + service.transactionFee).doubleValue
                row.updateCell()
                markRow(row, valid: validateAmount(amount))
            } else {
                row.value = nil
                markRow(row, valid: true)
                row.updateCell()
            }
        }
    }
    
    func markRow(_ row: BaseRowType, valid: Bool) {
        row.baseCell.textLabel?.textColor = valid ? UIColor.adamant.primary : UIColor.adamant.alert
    }

    func markAddres(isValid: Bool) {
        guard
            let recipientRow: TextRow = form.rowBy(tag: BaseRows.address.tag),
            let recipientSection = form.sectionBy(tag: Sections.recipient.tag),
            !recipientIsReadonly
        else {
            return
        }
        
        if let label = recipientSection.header?.viewForSection(recipientSection, type: .header), let label = label as? UILabel {
            label.textColor = isValid ? UIColor.adamant.primary : UIColor.adamant.alert
        }
        
        recipientRow.cell.textField.textColor = isValid ? UIColor.adamant.primary : UIColor.adamant.alert
        recipientRow.cell.textField.leftView?.subviews.forEach { view in
            guard let label = view as? UILabel else { return }
            label.textColor = isValid ? UIColor.adamant.primary : UIColor.adamant.alert
        }
    }

    func reloadFormData() {
        if let row: DoubleDetailsRow = form.rowBy(tag: BaseRows.fee.tag) {
            row.value = getCellFeeValue()
            row.updateCell()
        }
        
        if let row: DecimalRow = form.rowBy(tag: BaseRows.maxToTransfer.tag) {
            row.updateCell()
        }
        
        if let row: DecimalRow = form.rowBy(tag: BaseRows.balance.tag) {
            if let wallet = service?.wallet {
                row.value = wallet.balance.doubleValue
            } else {
                row.value = 0
            }
            
            row.updateCell()
        }
        
        validateForm()
    }
    
    // MARK: - Send Actions
    
    private func confirmSendFunds() {
        validateAddress()
        validateForm(force: true)

        guard
            let recipientAddress = recipientAddress,
            recipientAddressIsValid,
            let amount = amount
        else {
            return
        }
        
        guard validateRecipient(recipientAddress) else {
            dialogService.showWarning(withMessage: String.adamantLocalized.transfer.addressValidationError)
            return
        }
        
        guard amount > 0 else {
            dialogService.showWarning(withMessage: String.adamantLocalized.transfer.amountZeroError)
            return
        }
        
        guard amount <= maxToTransfer else {
            dialogService.showWarning(withMessage: String.adamantLocalized.transfer.amountTooHigh)
            return
        }

        guard amount >= minToTransfer else {
            dialogService.showWarning(withMessage: String.adamantLocalized.transfer.amountZeroError)
            return
        }
        
        guard isEnoughFee() else {
            dialogService.showWarning(withMessage: String.adamantLocalized.transfer.notEnoughFeeError)
            return
        }
        
        guard service?.isTransactionFeeValid ?? true else {
            return
        }
        
        if admReportRecipient != nil, let account = accountService.account, account.balance < 0.001 {
            dialogService.showWarning(withMessage: "Not enought money to send report")
            return
        }
        
        let recipient: String
        if let recipientName = recipientName {
            recipient = "\(recipientName) \(recipientAddress)"
        } else {
            recipient = recipientAddress
        }
        
        let formattedAmount = balanceFormatter.string(from: amount as NSDecimalNumber)!
        let title = String.adamantLocalized.alert.confirmSendMessage(formattedAmount: formattedAmount, recipient: recipient)
        
        let alert = UIAlertController(title: title, message: String.adamantLocalized.transfer.cantUndo, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String.adamantLocalized.alert.cancel , style: .cancel, handler: nil)
        let sendAction = UIAlertAction(title: String.adamantLocalized.alert.send, style: .default) { [weak self] _ in
            self?.sendFunds()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(sendAction)
        alert.modalPresentationStyle = .overFullScreen
        
        DispatchQueue.onMainAsync {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - 'Virtual' methods with basic implementation
    
    /// Currency code, used to get fiat rates
    /// Default implementation tries to get currency symbol from service. If no service present - its fails
    var currencyCode: String {
        if let service = service {
            return service.tokenSymbol
        } else {
            return ""
        }
    }
    
    /// Override this to provide custom balance formatter
    var balanceFormatter: NumberFormatter {
        if let service = service {
            return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: service.tokenSymbol)
        } else {
            return AdamantBalanceFormat.full.defaultFormatter
        }
    }

    var feeBalanceFormatter: NumberFormatter {
        return balanceFormatter
    }
    
    var fiatFormatter: NumberFormatter {
        return AdamantBalanceFormat.fiatFormatter(for: currencyInfoService.currentCurrency)
    }
    
    /// Override this to provide custom validation logic
    /// Default - positive number, amount + fee less than or equal to wallet balance
    func validateAmount(_ amount: Decimal, withFee: Bool = true) -> Bool {
        guard amount > 0 else {
            return false
        }
        
        guard let service = service,
              let balance = service.wallet?.balance
        else {
            return false
        }
        
        let minAmount = service.minAmount
        
        guard minAmount <= amount else {
            return false
        }
        
        let total = withFee ? amount + service.transactionFee : amount
        
        return balance >= total
    }
    
    func formIsValid() -> Bool {
        guard
            let service = service,
            let wallet = service.wallet,
            wallet.balance > service.transactionFee
        else {
            return false
        }

        guard
            let recipient = recipientAddress, validateRecipient(recipient),
            let amount = amount, validateAmount(amount),
            recipientAddressIsValid,
            service.isTransactionFeeValid,
            isEnoughFee()
        else {
            return false
        }

        return true
    }
    
    func isEnoughFee() -> Bool {
        guard let service = service,
              let wallet = service.wallet,
              wallet.balance > service.transactionFee,
              service.isTransactionFeeValid
        else {
            return false
        }
        return true
    }
    
    /// Recipient section footer. You can override this to provide custom set of elements.
    /// You can also override ButtonsStripeViewDelegate implementation
    /// nil for no stripe
    func recipientStripe() -> Stripe? {
        return [.qrCameraReader, .qrPhotoReader]
    }
    
    func defaultSceneTitle() -> String? {
        return WalletViewControllerBase.BaseRows.send.localized
    }
    
    // MARK: - Abstract
    
    /// Send funds to recipient after validations
    /// You must override this method
    /// Don't forget to call delegate.transferViewControllerDidFinishTransfer(self) after successfull transfer
    func sendFunds() {
        fatalError("You must implement sending logic")
    }
    
    /// User loaded address from QR (camera or library)
    /// You must override this method
    ///
    /// - Parameter address: raw readed address
    /// - Returns: string was successfully handled
    func handleRawAddress(_ address: String) -> Bool {
        fatalError("You must implement raw address handling")
    }
    
    /// Build recipient address row
    /// You must override this method
    func recipientRow() -> BaseRow {
        fatalError("You must implement recipient row")
    }
    
    /// Validate recipient's address
    /// You must override this method
    func validateRecipient(_ address: String) -> Bool {
        fatalError("You must implement recipient addres validation logic")
    }
}

// MARK: - Default rows
extension TransferViewControllerBase {
    func defaultRowFor(baseRow: BaseRows) -> BaseRow {
        switch baseRow {
        case .balance:
            return DecimalRow { [weak self] in
                $0.title = BaseRows.balance.localized
                $0.tag = BaseRows.balance.tag
                $0.disabled = true
                $0.formatter = self?.balanceFormatter
                
                if let wallet = self?.service?.wallet {
                    $0.value = wallet.balance.doubleValue
                } else {
                    $0.value = 0
                }
            }
            
        case .name:
            let row = LabelRow { [weak self] in
                $0.title = BaseRows.name.localized
                $0.tag = BaseRows.name.tag
                $0.value = self?.recipientName
                $0.hidden = Condition.function([], { form in
                    if let row: RowOf<String> = form.rowBy(tag: BaseRows.name.tag), row.value != nil {
                        return false
                    } else {
                        return true
                    }
                })
            }
            
            return row
            
        case .address:
            return recipientRow()
            
        case .maxToTransfer:
            let row = DecimalRow { [weak self] in
                $0.title = BaseRows.maxToTransfer.localized
                $0.tag = BaseRows.maxToTransfer.tag
                $0.disabled = true
                $0.formatter = self?.balanceFormatter
                $0.cell.selectionStyle = .gray
                
                if let maxToTransfer = self?.maxToTransfer {
                    $0.value = maxToTransfer.doubleValue
                }
            }.onCellSelection { [weak self] (_, row) in
                guard let value = row.value, value > 0, let presenter = self else {
                    row.deselect(animated: true)
                    return
                }
                
                let alert = UIAlertController(title: String.adamantLocalized.transfer.useMaxToTransfer, message: nil, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: String.adamantLocalized.alert.cancel , style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: String.adamantLocalized.alert.ok, style: .default) { [weak self] _ in
                    guard let amountRow: DecimalRow = self?.form.rowBy(tag: BaseRows.amount.tag) else {
                        return
                    }
                    amountRow.value = value
                    amountRow.updateCell()
                    self?.validateForm()
                }
                
                alert.addAction(cancelAction)
                alert.addAction(confirmAction)
                alert.modalPresentationStyle = .overFullScreen
                presenter.present(alert, animated: true) {
                    row.deselect(animated: true)
                }
            }
            
            return row
            
        case .amount:
            return DecimalRow { [weak self] row in
                row.title = BaseRows.amount.localized
                row.placeholder = String.adamantLocalized.transfer.amountPlaceholder
                row.tag = BaseRows.amount.tag
                row.formatter = self?.balanceFormatter
                
                if let amount = self?.amount {
                    row.value = amount.doubleValue
                }
            }.onChange { [weak self] (row) in
                if let rate = self?.rate, let fiatRow: DecimalRow = self?.form.rowBy(tag: BaseRows.fiat.tag) {
                    if let value = row.value {
                        fiatRow.value = value * rate.doubleValue
                    } else {
                        fiatRow.value = nil
                    }
                    
                    fiatRow.updateCell()
                }
                
                self?.validateForm()
                self?.updateToolbar(for: row)
            }.cellUpdate { [weak self] _, _ in
                self?.validateForm()
            }
            
        case .fiat:
            return DecimalRow { [weak self] in
                $0.title = BaseRows.fiat.localized
                $0.tag = BaseRows.fiat.tag
                $0.disabled = true
                
                $0.formatter = fiatFormatter
                
                if let rate = self?.rate, let amount = self?.amount {
                    $0.value = amount.doubleValue * rate.doubleValue
                }
                
                $0.hidden = Condition.function([]) { [weak self] _ -> Bool in
                    return self?.rate == nil
                }
            }
        
        case .fee:
            return DoubleDetailsRow { [weak self] in
                let estimateSymbol = service?.isDynamicFee == true ? " ~" : ""
                
                $0.tag = BaseRows.fee.tag
                $0.cell.titleLabel.text = ""
                $0.disabled = true
                $0.title = BaseRows.fee.localized + estimateSymbol
                $0.cell.titleLabel.textColor = .adamant.active
                $0.cell.secondDetailsLabel.textColor = .adamant.alert
                $0.value = self?.getCellFeeValue()
            }
            
        case .total:
            return DecimalRow { [weak self] in
                $0.tag = BaseRows.total.tag
                $0.title = BaseRows.total.localized
                $0.value = nil
                $0.disabled = true
                $0.formatter = self?.balanceFormatter
                
                if let balance = self?.service?.wallet?.balance {
                    $0.add(rule: RuleSmallerOrEqualThan<Double>(max: balance.doubleValue))
                }
            }
        
        case .comments:
            let row = TextAreaRow {
                $0.tag = BaseRows.comments.tag
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
            }.onChange { [weak self] row in
                self?.updateToolbar(for: row)
            }.cellUpdate { (cell, _) in
                cell.textView?.backgroundColor = UIColor.clear
            }
            
            return row
            
        case .sendButton:
            return ButtonRow {
                $0.title = BaseRows.sendButton.localized
                $0.tag = BaseRows.sendButton.tag
            }.onCellSelection { [weak self] (_, _) in
                self?.confirmSendFunds()
            }
        }
    }
    
    private func getCellFeeValue() -> DoubleDetail {
        guard let service = service else {
            return DoubleDetail(first: "0", second: nil)
        }
        
        let fee = service.diplayTransactionFee
        let isWarningGasPrice = service.isWarningGasPrice
        
        var fiat: Double = 0.0
        
        let rate = currencyInfoService.getRate(for: service.blockchainSymbol)
        if let rate = rate {
            fiat = fee.doubleValue * rate.doubleValue
        }
        
        let feeRaw = fee.doubleValue.format(with: feeBalanceFormatter)
        let fiatRaw = fiat.format(with: fiatFormatter)
        
        return DoubleDetail(
            first: "\(feeRaw) ~\(fiatRaw)",
            second: isWarningGasPrice
            ? String.adamantLocalized.transfer.feeIsTooHigh
            : nil
        )
    }
    
    // MARK: - Tools
    
    func shareValue(_ value: String?, from: UIView) {
        guard
            let value = value,
            !value.isEmpty,
            recipientIsReadonly
        else {
            return
        }

        dialogService.presentShareAlertFor(string: value, types: [.copyToPasteboard, .share], excludedActivityTypes: nil, animated: true, from: from) { [weak self] in
            guard let tableView = self?.tableView else { return }
            
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}
