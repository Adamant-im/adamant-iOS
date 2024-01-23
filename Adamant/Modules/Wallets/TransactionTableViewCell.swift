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
    
    let topImageView = UIImageView(image: UIImage(named: "transfer-in_top"))
    let bottomImageView = UIImageView(image: UIImage(named: "transfer-in_bot"))
    
    lazy var accountLabel: UILabel = {
        let text = UILabel()
        text.font = .systemFont(ofSize: 17)
        text.translatesAutoresizingMaskIntoConstraints = false
        text.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        return text
    }()
    
    lazy var addressLabel: UILabel = {
        let text = UILabel()
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        text.font = font.withSize(17)
        text.textColor = .lightGray
        return text
    }()
    
    lazy var contactInfoView: UIView = {
        let view = UIView()
        view.addSubview(accountLabel)
        view.addSubview(addressLabel)
        
        accountLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.trailing.equalTo(addressLabel.snp.leading).offset(-5)
        }
        
        addressLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(80)
        }
        
        view.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
        return view
    }()

    lazy var ammountLabel: UILabel = {
        let text = UILabel()
        return text
    }()
    
    lazy var dateLabel: UILabel = {
        let text = UILabel()
        return text
    }()
    
    lazy var informationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 3
        
        stackView.addArrangedSubview(contactInfoView)
        stackView.addArrangedSubview(ammountLabel)
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
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        transactionType = .income
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
        ammountLabel.tintColor = UIColor.adamant.primary
        
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
            addressLabel.lineBreakMode = .byTruncatingMiddle
            
            if addressLabel.isHidden {
                addressLabel.isHidden = false
            }
            addressLabel.snp.updateConstraints { make in
                make.width.greaterThanOrEqualTo(80)
            }
        } else {
            accountLabel.text = partnerId
            
            if !addressLabel.isHidden {
                addressLabel.isHidden = true
            }
            addressLabel.snp.updateConstraints { make in
                make.width.greaterThanOrEqualTo(0)
            }
        }
        
        let amount = transaction.amountValue ?? .zero
        ammountLabel.text = AdamantBalanceFormat.full.format(amount, withCurrencySymbol: currencySymbol)
    }
}

// MARK: - TransactionStatus UI
private extension TransactionStatus {
    var color: UIColor {
        switch self {
        case .failed:
            return .adamant.danger
        case .pending, .registered:
            return .adamant.alert
        default:
            return .adamant.secondary
        }
    }
}
