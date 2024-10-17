//
//  TransactionTableViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CommonKit

final class TransactionTableViewCell: UITableViewCell {
    enum TransactionType {
        case income, outcome, myself
        
        var imageTop: UIImage {
            switch self {
            case .income: return .asset(named: "transfer-in_top") ?? .init()
            case .outcome: return .asset(named: "transfer-out_top") ?? .init()
            case .myself: return .asset(named: "transfer-in_top")?.withTintColor(.lightGray) ?? .init()
            }
        }
        
        var imageBottom: UIImage {
            switch self {
            case .income: return .asset(named: "transfer-in_bot") ?? .init()
            case .outcome: return .asset(named: "transfer-out_bot") ?? .init()
            case .myself: return .asset(named: "transfer-self_bot") ?? .init()
            }
        }
        
        var bottomTintColor: UIColor {
            switch self {
            case .income: return UIColor.adamant.transferIncomeIconBackground
            case .outcome: return UIColor.adamant.transferOutcomeIconBackground
            case .myself: return UIColor.adamant.transferIncomeIconBackground
            }
        }
    }
    
    // MARK: - Constants
    
    static let cellHeightCompact: CGFloat = 90.0
    static let cellFooterLoadingCompact: CGFloat = 30.0
    static let cellHeightFull: CGFloat = 100.0
    
    // MARK: - IBOutlets
    
    private let topImageView = UIImageView(image: UIImage(named: "transfer-in_top"))
    private let bottomImageView = UIImageView(image: UIImage(named: "transfer-in_bot"))
    private lazy var amountLabel = UILabel()
    private lazy var dateLabel = UILabel()
    
    private lazy var accountLabel: UILabel = {
        let text = UILabel()
        text.font = .systemFont(ofSize: 17)
        return text
    }()
    
    private lazy var addressLabel: UILabel = {
        let text = UILabel()
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        text.font = font.withSize(17)
        text.textColor = .lightGray
        return text
    }()
    
    private lazy var contactInfoView: UIView = {
        let view = UIView()
        view.addSubview(accountLabel)
        view.addSubview(addressLabel)
        
        accountLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.trailing.equalTo(addressLabel.snp.leading).offset(-5)
        }
        accountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        addressLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(80)
        }
        addressLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        view.snp.makeConstraints { make in
            make.height.equalTo(26)
        }
        return view
    }()
    
    private lazy var informationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 3
        
        stackView.addArrangedSubview(contactInfoView)
        stackView.addArrangedSubview(amountLabel)
        stackView.addArrangedSubview(dateLabel)
        
        return stackView
    }()
    
    // MARK: - Properties
    
    var transactionType: TransactionType = .income {
        didSet {
            topImageView.image = transactionType.imageTop
            bottomImageView.image = transactionType.imageBottom
            bottomImageView.tintColor = transactionType.bottomTintColor
        }
    }
    
    var currencySymbol: String?
    
    var transaction: SimpleTransactionDetails? {
        didSet {
            updateUI()
        }
    }
    
    // MARK: - Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func awakeFromNib() {
        Task { @MainActor in
            transactionType = .income
        }
    }
    
    private func setupView() {
        addSubview(informationStackView)
        addSubview(bottomImageView)
        addSubview(topImageView)
        
        bottomImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(37)
        }
        
        topImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(37)
        }
        
        informationStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(70)
            make.trailing.equalToSuperview().offset(-30)
        }
    }
    
    func updateUI() {
        guard let transaction = transaction else { return }
        
        let partnerId = transaction.isOutgoing
        ? transaction.recipientAddress
        : transaction.senderAddress
        
        let transactionType: TransactionTableViewCell.TransactionType
        if transaction.recipientAddress == transaction.senderAddress {
            transactionType = .myself
        } else if transaction.isOutgoing {
            transactionType = .outcome
        } else {
            transactionType = .income
        }
        
        self.transactionType = transactionType
        
        backgroundColor = .clear
        accountLabel.tintColor = UIColor.adamant.primary
        amountLabel.tintColor = UIColor.adamant.primary
        
        dateLabel.textColor = transaction.transactionStatus?.color ?? .adamant.secondary
        
        switch transaction.transactionStatus {
        case .success, .inconsistent:
            if let date = transaction.dateValue {
                dateLabel.text = date.humanizedDateTime()
            } else {
                dateLabel.text = nil
            }
        case .notInitiated:
            dateLabel.text = TransactionDetailsViewControllerBase.awaitingValueString
        case .failed:
            dateLabel.text = TransactionStatus.failed.localized
        case .pending, .registered:
            dateLabel.text = TransactionStatus.pending.localized
        default:
            dateLabel.text = TransactionDetailsViewControllerBase.awaitingValueString
        }
        
        if let partnerName = transaction.partnerName {
            accountLabel.text = partnerName
            addressLabel.text = partnerId
            accountLabel.lineBreakMode = .byTruncatingTail
            addressLabel.lineBreakMode = .byTruncatingMiddle
            
            if addressLabel.isHidden {
                addressLabel.isHidden = false
            }
            addressLabel.snp.remakeConstraints { make in
                make.trailing.centerY.equalToSuperview()
                make.width.greaterThanOrEqualTo(80)
            }
        } else {
            accountLabel.text = partnerId
            accountLabel.lineBreakMode = .byTruncatingMiddle
            
            if !addressLabel.isHidden {
                addressLabel.isHidden = true
            }
            addressLabel.snp.remakeConstraints { make in
                make.trailing.centerY.equalToSuperview()
                make.width.equalTo(0)
            }
        }
        
        let amount = transaction.amountValue ?? .zero
        amountLabel.text = AdamantBalanceFormat.full.format(amount, withCurrencySymbol: currencySymbol)
    }
}

// MARK: - TransactionStatus UI
private extension TransactionStatus {
    var color: UIColor {
        switch self {
        case .failed:
            return .adamant.warning
        case .pending, .registered:
            return .adamant.attention
        default:
            return .adamant.secondary
        }
    }
}
