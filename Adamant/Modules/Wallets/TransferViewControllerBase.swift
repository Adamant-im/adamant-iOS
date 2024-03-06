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
import CommonKit
import Combine

// MARK: - Transfer Delegate Protocol

@MainActor
protocol TransferViewControllerDelegate: AnyObject {
    func transferViewController(_ viewController: TransferViewControllerBase, didFinishWithTransfer transfer: TransactionDetails?, detailsViewController: UIViewController?)
}

// MARK: - Localization
extension String.adamant {
    enum transfer {
        static var addressPlaceholder: String {
            String.localized("TransferScene.Recipient.Placeholder", comment: "Transfer: recipient address placeholder")
        }
        static var amountPlaceholder: String {
            String.localized("TransferScene.Amount.Placeholder", comment: "Transfer: transfer amount placeholder")
        }
        static var addressValidationError: String {
            String.localized("TransferScene.Error.InvalidAddress", comment: "Transfer: Address validation error")
        }
        static var amountZeroError: String {
            String.localized("TransferScene.Error.TooLittleMoney", comment: "Transfer: Amount is zero, or even negative notification")
        }
        static var notEnoughFeeError: String {
            String.localized("TransferScene.Error.TooLittleFee", comment: "Transfer: Not enough fee for send a transaction")
        }
        static var feeIsTooHigh: String {
            String.localized("TransferScene.Error.FeeIsTooHigh", comment: "Transfer: Fee is higher than usual")
        }
        static var amountTooHigh: String {
            String.localized("TransferScene.Error.notEnoughMoney", comment: "Transfer: Amount is hiegher that user's total money notification")
        }
        static var accountNotFound: String {
            String.localized("TransferScene.Error.AddressNotFound", comment: "Transfer: Address not found error")
        }
        static var transferProcessingMessage: String {
            String.localized("TransferScene.SendingFundsProgress", comment: "Transfer: Processing message")
        }
        static var transferSuccess: String {
            String.localized("TransferScene.TransferSuccessMessage", comment: "Transfer: Tokens transfered successfully message")
        }
        static var send: String {
            String.localized("TransferScene.Send", comment: "Transfer: Send button")
        }
        static var cantUndo: String {
            String.localized("TransferScene.CantUndo", comment: "Transfer: Send button")
        }
        static var useMaxToTransfer: String {
            String.localized("TransferScene.UseMaxToTransfer", comment: "Tranfser: Confirm using maximum available for transfer tokens as amount to transfer.")
        }
    }
}

fileprivate extension String.adamant.alert {
    static let confirmSendMessageFormat = String.localized("TransferScene.SendConfirmFormat", comment: "Transfer: Confirm transfer %1$@ tokens to %2$@ message. Note two variables: at runtime %1$@ will be amount (with ADM suffix), and %2$@ will be recipient address. You can use address before amount with this so called 'position tokens'.")
    static func confirmSendMessage(formattedAmount amount: String, recipient: String) -> String {
        return String.localizedStringWithFormat(String.adamant.alert.confirmSendMessageFormat, "\(amount)", recipient)
    }
    static let send = String.localized("TransferScene.Send", comment: "Transfer: Confirm transfer alert: Send tokens button")
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
        case increaseFee
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
            case .increaseFee: return "increaseFee"
            case .fee: return "fee"
            case .total: return "total"
            case .comments: return "comments"
            case .sendButton: return "send"
            }
        }
        
        var localized: String {
            switch self {
            case .balance: return .localized("TransferScene.Row.Balance", comment: "Transfer: logged user balance.")
            case .amount: return .localized("TransferScene.Row.Amount", comment: "Transfer: amount of adamant to transfer.")
            case .fiat: return .localized("TransferScene.Row.Fiat", comment: "Transfer: fiat value of crypto-amout")
            case .maxToTransfer: return .localized("TransferScene.Row.MaxToTransfer", comment: "Transfer: maximum amount to transfer: available account money substracting transfer fee")
            case .name: return .localized("TransferScene.Row.RecipientName", comment: "Transfer: recipient name")
            case .address: return .localized("TransferScene.Row.RecipientAddress", comment: "Transfer: recipient address")
            case .fee: return .localized("TransferScene.Row.TransactionFee", comment: "Transfer: transfer fee")
            case .total: return .localized("TransferScene.Row.Total", comment: "Transfer: total amount of transaction: money to transfer adding fee")
            case .comments: return .localized("TransferScene.Row.Comments", comment: "Transfer: transfer comment")
            case .sendButton: return String.adamant.transfer.send
            case .increaseFee: return .localized("TransferScene.Row.IncreaseFee", comment: "Transfer: transfer increase fee")
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
            case .wallet: return .localized("TransferScene.Section.YourWallet", comment: "Transfer: 'Your wallet' section")
            case .recipient: return .localized("TransferScene.Section.Recipient", comment: "Transfer: 'Recipient info' section")
            case .transferInfo: return .localized("TransferScene.Section.TransferInfo", comment: "Transfer: 'Transfer info' section")
            case .comments: return .localized("TransferScene.Row.Comments", comment: "Transfer: transfer comment")
            }
        }
    }
    
    // MARK: - Dependencies
    
    let accountService: AccountService
    let accountsProvider: AccountsProvider
    let dialogService: DialogService
    let screensFactory: ScreensFactory
    let currencyInfoService: CurrencyInfoService
    var increaseFeeService: IncreaseFeeService
    var chatsProvider: ChatsProvider
    let vibroService: VibroService
    let walletService: WalletService
    let walletCore: WalletCoreProtocol
    let reachabilityMonitor: ReachabilityMonitor
    let nodesStorage: NodesStorageProtocol
    
    // MARK: - Properties
    
    private var previousIsReadyToSend: Bool?
    private var subscriptions: Set<AnyCancellable> = []
    
    var commentsEnabled: Bool = false
    var rootCoinBalance: Decimal?
    var isNeedAddFee: Bool { true }
    var replyToMessageId: String?
    
    static let invalidCharacters: CharacterSet = {
        CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        ).inverted
    }()
    
    weak var delegate: TransferViewControllerDelegate?
    
    var addAdditionalFee = false {
        didSet {
            updateFeeCell()
        }
    }
    
    var transactionFee: Decimal {
        let baseFee = walletCore.transactionFee
        let additionalyFee = walletCore.additionalFee
        return addAdditionalFee
        ? baseFee + additionalyFee
        : baseFee
    }
    
    var recipientAddress: String? {
        set {
            if let row: RowOf<String> = form.rowBy(tag: BaseRows.address.tag) {
                row.value = newValue
                row.updateCell()
                validateForm()
            }
        }
        get {
            let row: RowOf<String>? = form.rowBy(tag: BaseRows.address.tag)
            return row?.value
        }
    }
    
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
            let balance = walletCore.wallet?.balance,
            balance > walletCore.minBalance
        else {
            return 0
        }
        
        let fee = isNeedAddFee
        ? transactionFee
        : 0
        
        let max = balance - fee - walletCore.minBalance
        
        return max >= 0 ? max : 0
    }
    
    var minToTransfer: Decimal {
        get async throws {
            return walletCore.minAmount
        }
    }
    
    override var customNavigationAccessoryView: (UIView & NavigationAccessory)? {
        let accessory = NavigationAccessoryView()
        accessory.tintColor = UIColor.adamant.primary
        return accessory
    }
    
    private let inactiveBaseColor = UIColor.gray.withAlphaComponent(0.5)
    private let activeBaseColor = UIColor.adamant.primary
    
    // MARK: - QR Reader
    
    lazy var qrReader: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr ], captureDevicePosition: .back)
            $0.cancelButtonTitle = String.adamant.alert.cancel
            $0.showSwitchCameraButton = false
        }
        
        let vc = QRCodeReaderViewController(builder: builder)
        vc.delegate = self
        return vc
    }()
    
    // MARK: - Alert
    var progressView: UIView?
    var alertView: UIView?
    
    // MARK: - Init
    
    init(
        chatsProvider: ChatsProvider,
        accountService: AccountService,
        accountsProvider: AccountsProvider,
        dialogService: DialogService,
        screensFactory: ScreensFactory,
        currencyInfoService: CurrencyInfoService,
        increaseFeeService: IncreaseFeeService,
        vibroService: VibroService,
        walletService: WalletService,
        reachabilityMonitor: ReachabilityMonitor,
        nodesStorage: NodesStorageProtocol
    ) {
        self.accountService = accountService
        self.accountsProvider = accountsProvider
        self.dialogService = dialogService
        self.screensFactory = screensFactory
        self.currencyInfoService = currencyInfoService
        self.increaseFeeService = increaseFeeService
        self.chatsProvider = chatsProvider
        self.vibroService = vibroService
        self.walletService = walletService
        self.walletCore = walletService.core
        self.reachabilityMonitor = reachabilityMonitor
        self.nodesStorage = nodesStorage
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
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
            Task { await self?.confirmSendFunds() }
        }
        
        // MARK: Notifications
        
        addObservers()
        
        setColors()
    }
    
    // MARK: - Other
    
    private func addObservers() {
        NotificationCenter.default
            .publisher(for: walletCore.transactionFeeUpdated)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.feeUpdated()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: walletCore.walletUpdatedNotification)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.reloadFormData()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantCurrencyInfoService.currencyRatesUpdated)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.currencyRateUpdated()
            }
            .store(in: &subscriptions)
    }
    
    private func feeUpdated() {
        if let row: DoubleDetailsRow = form.rowBy(tag: BaseRows.fee.tag) {
            row.value = getCellFeeValue()
            row.updateCell()
        }
        
        if let row: SafeDecimalRow = form.rowBy(tag: BaseRows.maxToTransfer.tag) {
            row.value = maxToTransfer.doubleValue
            row.updateCell()
        }
        
        validateForm()
    }
    
    private func currencyRateUpdated() {
        rate = currencyInfoService.getRate(for: currencyCode)
        
        if let row: SafeDecimalRow = form.rowBy(tag: BaseRows.fiat.tag) {
            if let formatter = row.formatter as? NumberFormatter {
                formatter.currencyCode = currencyInfoService.currentCurrency.rawValue
            }
            
            row.updateCell()
        }
    }
    
    private func isReadyToSend() -> Bool {
        validateAddress()
        guard recipientAddress != nil,
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
        guard isReadyToSend() else { return }
        Task { await confirmSendFunds() }
    }

    func updateToolbar(for row: BaseRow) {
        _ = inputAccessoryView(for: row)
    }
    
    override func inputAccessoryView(for row: BaseRow) -> UIView? {
        guard !isMacOS else { return nil }
        
        let view = super.inputAccessoryView(for: row)
        guard let view = view as? NavigationAccessoryView else { return view }
        
        view.doneClosure = { [weak self] in
            self?.navigationKeybordDone()
        }
        
        if let previousIsReadyToSend = previousIsReadyToSend,
           previousIsReadyToSend == isReadyToSend() {
            return view
        }
        previousIsReadyToSend = isReadyToSend()
        
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: view, action: view.doneButton.action)
        let sendBtn = UIBarButtonItem(title: String.adamant.transfer.send, style: .done, target: view, action: view.doneButton.action)
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
    
    private func updateFeeCell() {
        let row: DoubleDetailsRow? = form.rowBy(tag: BaseRows.fee.tag)
        row?.value = getCellFeeValue()
        row?.updateCell()
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
            var footer = HeaderFooterView<UIView>(.callback { [weak self] in
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
        
        if walletCore.isSupportIncreaseFee {
            section.append(defaultRowFor(baseRow: .increaseFee))
        }
        
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
        guard let recipientAddress = recipientAddress else {
            markAddres(isValid: false)
            return false
        }
        
        let isValid = validateRecipient(recipientAddress).isValid
        markAddres(isValid: isValid)
        return isValid
    }
    
    func validateForm(force: Bool = false) {
        guard let wallet = walletCore.wallet else {
            return
        }
        
        if let row: DoubleDetailsRow = form.rowBy(tag: BaseRows.fee.tag) {
            markRow(row, valid: isEnoughFee())
        }
        
        if let row: SafeDecimalRow = form.rowBy(tag: BaseRows.maxToTransfer.tag) {
            markRow(row, valid: wallet.balance > transactionFee)
        }
        
        if let row: SafeDecimalRow = form.rowBy(tag: BaseRows.amount.tag) {
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
        
        if let row: SafeDecimalRow = form.rowBy(tag: BaseRows.total.tag) {
            if let amount = amount {
                row.value = isNeedAddFee
                ? (amount + transactionFee).doubleValue
                : amount.doubleValue
                row.updateCell()
                markRow(row, valid: validateAmount(amount))
            } else {
                row.value = nil
                markRow(row, valid: true)
                row.updateCell()
            }
        }
        
        validateAddress()
    }
    
    func markRow(_ row: BaseRowType, valid: Bool) {
        row.baseCell.textLabel?.textColor = valid
        ? getBaseColor(for: row.tag)
        : UIColor.adamant.alert
    }
    
    func getBaseColor(for tag: String?) -> UIColor {
        guard let tag = tag,
              tag == BaseRows.fee.tag
        else { return activeBaseColor }
        
        return inactiveBaseColor
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
        
        if let row: SafeDecimalRow = form.rowBy(tag: BaseRows.maxToTransfer.tag) {
            row.updateCell()
        }
        
        if let row: SafeDecimalRow = form.rowBy(tag: BaseRows.balance.tag) {
            if let wallet = walletCore.wallet {
                row.value = wallet.balance.doubleValue
            } else {
                row.value = 0
            }
            
            row.updateCell()
        }
        
        validateForm()
    }
    
    // MARK: - Send Actions
    
    @MainActor
    private func confirmSendFunds() async {
        dialogService.showProgress(withMessage: nil, userInteractionEnable: true)
        validateAddress()
        validateForm(force: true)
        
        guard let recipientAddress = recipientAddress else {
            dialogService.showWarning(withMessage: .adamant.transfer.addressValidationError)
            return
        }
        
        let validationResult = validateRecipient(recipientAddress)
        guard validationResult.isValid else {
            dialogService.showWarning(
                withMessage: validationResult.errorDescription
                    ?? .adamant.transfer.addressValidationError
            )
            return
        }
        
        guard let amount = amount,
              amount > 0
        else {
            dialogService.showWarning(withMessage: String.adamant.transfer.amountZeroError)
            return
        }
        
        guard amount <= maxToTransfer else {
            dialogService.showWarning(withMessage: String.adamant.transfer.amountTooHigh)
            return
        }
        
        do {
            guard try await amount >= minToTransfer else {
                dialogService.showWarning(withMessage: .adamant.transfer.amountZeroError)
                return
            }
        } catch {
            dialogService.showWarning(withMessage: error.localizedDescription)
            return
        }
        
        guard isEnoughFee() else {
            dialogService.showWarning(withMessage: String.adamant.transfer.notEnoughFeeError)
            return
        }
        
        guard walletCore.isTransactionFeeValid else {
            return
        }
        
        if admReportRecipient != nil, let account = accountService.account, account.balance < 0.001 {
            dialogService.showWarning(withMessage: "Not enought money to send report")
            return
        }
        
        guard reachabilityMonitor.connection else {
            dialogService.showWarning(withMessage: .adamant.alert.noInternetTransferBody)
            return
        }
        
        if admReportRecipient != nil,
           !nodesStorage.haveActiveNode(in: .adm) {
            dialogService.showWarning(
                withMessage: ApiServiceError.noEndpointsAvailable(
                    coin: NodeGroup.adm.name
                ).localizedDescription
            )
            return
        }
        
        let groupsWithoutActiveNode = walletCore.nodeGroups.filter {
            !nodesStorage.haveActiveNode(in: $0)
        }

        if let group = groupsWithoutActiveNode.first {
            dialogService.showWarning(
                withMessage: ApiServiceError.noEndpointsAvailable(
                    coin: group.name
                ).localizedDescription
            )
            return
        }
        
        let recipient: String
        if let recipientName = recipientName {
            recipient = "\(recipientName) \(recipientAddress)"
        } else {
            recipient = recipientAddress
        }
        
        let formattedAmount = balanceFormatter.string(from: amount as NSDecimalNumber)!
        let title = String.adamant.alert.confirmSendMessage(formattedAmount: formattedAmount, recipient: recipient)
        
        let alert = UIAlertController(title: title, message: String.adamant.transfer.cantUndo, preferredStyleSafe: .alert, source: nil)
        let cancelAction = UIAlertAction(title: String.adamant.alert.cancel , style: .cancel, handler: nil)
        let sendAction = UIAlertAction(title: String.adamant.alert.send, style: .default) { [weak self] _ in
            self?.sendFunds()
        }
        
        dialogService.dismissProgress()
        alert.addAction(cancelAction)
        alert.addAction(sendAction)
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - 'Virtual' methods with basic implementation
    
    /// Currency code, used to get fiat rates
    /// Default implementation tries to get currency symbol from service. If no service present - its fails
    var currencyCode: String {
        walletCore.tokenSymbol
    }
    
    /// Override this to provide custom balance formatter
    var balanceFormatter: NumberFormatter {
        AdamantBalanceFormat.currencyFormatter(
            for: .custom(walletCore.transferDecimals),
            currencySymbol: walletCore.tokenSymbol
        )
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
        
        guard let balance = walletCore.wallet?.balance else {
            return false
        }
        
        let minAmount = walletCore.minAmount
        
        guard minAmount <= amount else {
            return false
        }
        
        let total = withFee ? amount + transactionFee : amount
        
        return balance >= total
    }
    
    func formIsValid() -> Bool {
        guard
            let wallet = walletCore.wallet,
            wallet.balance > transactionFee
        else {
            return false
        }

        guard
            let recipient = recipientAddress, validateRecipient(recipient).isValid,
            let amount = amount, validateAmount(amount),
            walletCore.isTransactionFeeValid,
            isEnoughFee()
        else {
            return false
        }

        return true
    }
    
    func isEnoughFee() -> Bool {
        guard let wallet = walletCore.wallet,
              wallet.balance > transactionFee,
              walletCore.isTransactionFeeValid
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
    
    /// User loaded address from QR (camera or library)
    ///
    /// - Parameter address: raw readed address
    /// - Returns: string was successfully handled
    func handleRawAddress(_ address: String) -> Bool {
        let parsedAddress = AdamantCoinTools.decode(
            uri: address,
            qqPrefix: walletCore.qqPrefix
        )
        
        guard let parsedAddress = parsedAddress,
              case .valid = walletCore.validate(address: parsedAddress.address)
        else { return false }
        
        recipientAddress = parsedAddress.address
        
        parsedAddress.params?.forEach { param in
            switch param {
            case .amount(let amount):
                let row: SafeDecimalRow? = form.rowBy(tag: BaseRows.amount.tag)
                row?.value  = Double(amount)
                row?.updateCell()
            }
        }
        
        return true
	}

    /// Report transfer
    func reportTransferTo(
        admAddress: String,
        amount: Decimal,
        comments: String,
        hash: String
    ) async throws {
        let richMessageType = walletCore.dynamicRichMessageType
        
        let message: AdamantMessage
        
        if let replyToMessageId = replyToMessageId {
            let payload = RichTransferReply(
                replyto_id: replyToMessageId,
                type: richMessageType,
                amount: amount,
                hash: hash,
                comments: comments
            )
            message = AdamantMessage.richMessage(payload: payload)
        } else {
            let payload = RichMessageTransfer(
                type: richMessageType,
                amount: amount,
                hash: hash,
                comments: comments
            )
            message = AdamantMessage.richMessage(payload: payload)
        }
        
        chatsProvider.removeChatPositon(for: admAddress)
        _ = try await chatsProvider.sendMessage(message, recipientId: admAddress)
    }
    
    // MARK: - Abstract
    
    /// Send funds to recipient after validations
    /// You must override this method
    /// Don't forget to call delegate.transferViewControllerDidFinishTransfer(self) after successfull transfer
    func sendFunds() {
        fatalError("You must implement sending logic")
    }
    
    /// Build recipient address row
    /// You must override this method
    func recipientRow() -> BaseRow {
        fatalError("You must implement recipient row")
    }
    
    /// Validate recipient's address
    func validateRecipient(_ address: String) -> AddressValidationResult {
        walletCore.validate(address: address)
    }
    
    func checkForAdditionalFee() { }
}

// MARK: - Default rows
extension TransferViewControllerBase {
    func defaultRowFor(baseRow: BaseRows) -> BaseRow {
        switch baseRow {
        case .balance:
            return SafeDecimalRow { [weak self] in
                $0.title = BaseRows.balance.localized
                $0.tag = BaseRows.balance.tag
                $0.disabled = true
                $0.formatter = self?.balanceFormatter
                
                if let wallet = self?.walletCore.wallet {
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
            let row = SafeDecimalRow { [weak self] in
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
                
                let alert = UIAlertController(title: String.adamant.transfer.useMaxToTransfer, message: nil, preferredStyleSafe: .alert, source: nil)
                let cancelAction = UIAlertAction(title: String.adamant.alert.cancel , style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: String.adamant.alert.ok, style: .default) { [weak self] _ in
                    guard let amountRow: SafeDecimalRow = self?.form.rowBy(tag: BaseRows.amount.tag) else {
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
            return SafeDecimalRow { [weak self] row in
                row.title = BaseRows.amount.localized
                row.placeholder = String.adamant.transfer.amountPlaceholder
                row.tag = BaseRows.amount.tag
                row.formatter = self?.balanceFormatter
                
                if let amount = self?.amount {
                    row.value = amount.doubleValue
                }
            }.onChange { [weak self] (row) in
                if let rate = self?.rate, let fiatRow: SafeDecimalRow = self?.form.rowBy(tag: BaseRows.fiat.tag) {
                    if let value = row.value {
                        fiatRow.value = value * rate.doubleValue
                    } else {
                        fiatRow.value = nil
                    }
                    
                    fiatRow.updateCell()
                }
                
                self?.validateForm()
                self?.updateToolbar(for: row)
            }
            
        case .fiat:
            return SafeDecimalRow { [weak self] in
                $0.title = BaseRows.fiat.localized
                $0.tag = BaseRows.fiat.tag
                $0.disabled = true
                
                $0.formatter = self?.fiatFormatter
                
                if let rate = self?.rate, let amount = self?.amount {
                    $0.value = amount.doubleValue * rate.doubleValue
                }
                
                $0.hidden = Condition.function([]) { [weak self] _ -> Bool in
                    return self?.rate == nil
                }
            }
        case .increaseFee:
            return SwitchRow { [weak self] in
                $0.tag = BaseRows.increaseFee.tag
                $0.title = BaseRows.increaseFee.localized
                $0.value = self?.walletCore.isIncreaseFeeEnabled ?? false
            }.cellUpdate { [weak self] (cell, row) in
                cell.switchControl.onTintColor = UIColor.adamant.active
                cell.textLabel?.textColor = row.value == true
                ? self?.activeBaseColor
                : self?.inactiveBaseColor
            }.onChange { [weak self] row in
                guard let id = self?.walletCore.tokenUnicID,
                      let value = row.value
                else {
                    return
                }
                
                row.cell.textLabel?.textColor = value
                ? self?.activeBaseColor
                : self?.inactiveBaseColor
                
                self?.increaseFeeService.setIncreaseFeeEnabled(for: id, value: value)
                self?.walletCore.update()
            }
        case .fee:
            return DoubleDetailsRow { [weak self] in
                let estimateSymbol = self?.walletCore.isDynamicFee == true 
                ? " ~"
                : .empty
                
                $0.tag = BaseRows.fee.tag
                $0.cell.titleLabel.text = ""
                $0.disabled = true
                $0.title = BaseRows.fee.localized + estimateSymbol
                $0.cell.titleLabel.textColor = .adamant.active
                $0.cell.secondDetailsLabel.textColor = .adamant.alert
                $0.value = self?.getCellFeeValue()
            }
            
        case .total:
            return SafeDecimalRow { [weak self] in
                $0.tag = BaseRows.total.tag
                $0.title = BaseRows.total.localized
                $0.value = nil
                $0.disabled = true
                $0.formatter = self?.balanceFormatter
                
                if let balance = self?.walletCore.wallet?.balance {
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
                Task { await self?.confirmSendFunds() }
            }
        }
    }
    
    private func getCellFeeValue() -> DoubleDetail {
        let fee = transactionFee
        let isWarningGasPrice = walletCore.isWarningGasPrice
        
        var fiat: Double = 0.0
        
        let rate = currencyInfoService.getRate(for: walletCore.blockchainSymbol)
        if let rate = rate {
            fiat = fee.doubleValue * rate.doubleValue
        }
        
        let feeRaw = fee.doubleValue.format(with: feeBalanceFormatter)
        let fiatRaw = fiat.format(with: fiatFormatter)
        
        return DoubleDetail(
            first: "\(feeRaw) ~\(fiatRaw)",
            second: isWarningGasPrice
            ? String.adamant.transfer.feeIsTooHigh
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
    
    func readyToSendFunds() async -> Bool {
        var history = walletCore.getLocalTransactionHistory()
        
        if history.isEmpty {
            history = (try? await walletCore.getTransactionsHistory(
                offset: .zero,
                limit: 2)
            ) ?? []
        }
        
        let havePending = history.contains {
            $0.transactionStatus == .pending || $0.transactionStatus == .registered || $0.transactionStatus == .notInitiated
        }
        
        return !havePending
    }
    
    func readyToSendFunds(with nonce: String) async -> Bool {
        var history = walletCore.getLocalTransactionHistory()
        
        if history.isEmpty {
            history = (try? await walletCore.getTransactionsHistory(
                offset: .zero,
                limit: 2)
            ) ?? []
        }
        
        let nonces = history.compactMap { $0.nonceRaw }
        
        return !nonces.contains(nonce)
    }
}
