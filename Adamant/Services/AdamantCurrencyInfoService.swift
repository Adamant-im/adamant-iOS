//
//  AdamantCurrencyInfoService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 23/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import Alamofire

extension StoreKey {
    struct CoinInfo {
        static let selectedCurrency = "coinInfo.selectedCurrency"
    }
}

enum Currency: String {
    case RUB = "RUB"
    case USD = "USD"
    case EUR = "EUR"
    case CNY = "CNY"
    case JPY = "JPY"
    
    var symbol: String {
        switch self {
        case .RUB: return "₽"
        case .USD: return "$"
        case .EUR: return "€"
        case .CNY: return "¥"
        case .JPY: return "¥"
        }
    }
}

class CoinInfoServerResponse: Decodable {
    struct CodingKeys: CodingKey {
        var intValue: Int?
        var stringValue: String
        
        init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
        init?(stringValue: String) { self.stringValue = stringValue }
        
        static let success = CodingKeys(stringValue: "success")!
        static let date = CodingKeys(stringValue: "date")!
    }
    
    let success: Bool
    let date: TimeInterval
    let result: [String: Double]
    
    init(success: Bool, date: TimeInterval, result: [String: Double]) {
        self.success = success
        self.date = date
        self.result = result
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.success = try container.decode(Bool.self, forKey: CodingKeys.success)
        self.date = try container.decode(TimeInterval.self, forKey: CodingKeys.date)
        
        self.result = try container.decode([String: Double].self, forKey: CodingKeys(stringValue: "result")!)
    }
}

class AdamantCurrencyInfoService: CurrencyInfoService {
    // MARK: - Properties
    private var rates = [String: Double]()
    private let defaultResponseDispatchQueue = DispatchQueue(label: "com.adamant.info-coins-response-queue", qos: .utility, attributes: [.concurrent])
    public var currentCurrency: Currency = Currency.USD {
        didSet {
            securedStore?.set(currentCurrency.rawValue, for: StoreKey.CoinInfo.selectedCurrency)
            NotificationCenter.default.post(name: Notification.Name.WalletViewController.balanceUpdated, object: nil)
        }
    }
    
    // MARK: - Dependencies
    var securedStore: SecuredStore? {
        didSet {
            if let securedStore = securedStore, let id = securedStore.get(StoreKey.CoinInfo.selectedCurrency), let currency = Currency(rawValue: id) {
                currentCurrency = currency
            }
        }
    }
    
    func loadUpdate(for coins: [String]) {
        self.loadRates(for: coins) { [weak self] result in
            switch result {
            case .success(let rates):
                print("rates: \(rates)")
                self?.rates = rates
                break
            case .failure(let error):
                print("Fail to load rates from server with error: \(error.localizedDescription)")
            }
        }
    }
    
    func getRate(for coin: String) -> Double {
        let currency = self.currentCurrency.rawValue
        let pair = "\(coin)/\(currency)"
        let rate = self.rates[pair]
        return rate ?? 0
    }
    
    private func loadRates(for coins: [String], completion: @escaping (ApiServiceResult<[String: Double]>) -> Void) {
        let parameters = [
            "coin": coins.joined(separator: ",")
        ]
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(AdamantResources.coinsInfoSrvice, method: .get, parameters: parameters, headers: headers).responseData(queue: defaultResponseDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                do {
                    let model: CoinInfoServerResponse = try JSONDecoder().decode(CoinInfoServerResponse.self, from: data)
                    completion(.success(model.result))
                } catch {
                    completion(.failure(.serverError(error: "Coin info API result: Parsing error")))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
}
