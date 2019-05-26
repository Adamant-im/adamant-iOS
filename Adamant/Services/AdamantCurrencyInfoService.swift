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


// MARK: - Service
class AdamantCurrencyInfoService: CurrencyInfoService {
    // MARK: - API
    private lazy var infoServiceUrl: URL = {
        return URL(string: AdamantResources.coinsInfoSrvice)!
    }()
    
    private enum InfoServiceApiCommands: String {
        case get = "/get"
        case history = "/getHistory"
    }
    
    private func url(for command: InfoServiceApiCommands, with queryItems: [URLQueryItem]? = nil) -> URL? {
        guard var components = URLComponents(url: infoServiceUrl, resolvingAgainstBaseURL: false) else {
            fatalError("Failed to build InfoService url")
        }
        
        components.path = command.rawValue
        components.queryItems = queryItems
        
        return try? components.asURL()
    }
    
    // MARK: - Properties
    private static let historyThreshold = Double(exactly: 60*60*24)!
    
    private var rateCoins: [String]? = nil
    private var rates = [String: Decimal]()
    
    private let defaultResponseDispatchQueue = DispatchQueue(label: "com.adamant.info-coins-response-queue", qos: .utility, attributes: [.concurrent])
    
    public var currentCurrency: Currency = Currency.default {
        didSet {
            securedStore?.set(currentCurrency.rawValue, for: StoreKey.CoinInfo.selectedCurrency)
            NotificationCenter.default.post(name: Notification.Name.AdamantCurrencyInfoService.currencyRatesUpdated, object: nil)
        }
    }
    
    // MARK: - Dependencies
    var accountService: AccountService! {
        didSet {
            if let accountService = accountService {
                rateCoins = accountService.wallets.map { s -> String in type(of: s).currencySymbol }
            } else {
                rateCoins = nil
            }
        }
    }
    
    var securedStore: SecuredStore? {
        didSet {
            if let securedStore = securedStore, let id = securedStore.get(StoreKey.CoinInfo.selectedCurrency), let currency = Currency(rawValue: id) {
                currentCurrency = currency
            } else {
                currentCurrency = Currency.default
            }
        }
    }
    
    // MARK: - Info service
    func update() {
        guard let coins = rateCoins else {
            return
        }
        
        loadRates(for: coins) { [weak self] result in
            switch result {
            case .success(let rates):
                self?.rates = rates
                NotificationCenter.default.post(name: Notification.Name.AdamantCurrencyInfoService.currencyRatesUpdated, object: nil)
                
            case .failure(let error):
                print("Fail to load rates from server with error: \(error.localizedDescription)")
            }
        }
    }
    
    func getRate(for coin: String) -> Decimal? {
        let currency = currentCurrency.rawValue
        let pair = "\(coin)/\(currency)"
        
        return rates[pair]
    }
    
    private func loadRates(for coins: [String], completion: @escaping (ApiServiceResult<[String: Decimal]>) -> Void) {
        guard let url = url(for: .get, with: [URLQueryItem(name: "coin", value: coins.joined(separator: ","))]) else {
            completion(.failure(.internalError(message: "Failed to build URL", error: nil)))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, headers: headers).responseData(queue: defaultResponseDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                do {
                    let model: CoinInfoServiceResponseGet = try JSONDecoder().decode(CoinInfoServiceResponseGet.self, from: data)
                    if let result = model.result {
                        completion(.success(result))
                    } else {
                        completion(.failure(.serverError(error: "Coin info API result: Parsing error")))
                    }
                } catch {
                    completion(.failure(.serverError(error: "Coin info API result: Parsing error")))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    func getHistory(for coin: String, timestamp: Date, completion: @escaping (ApiServiceResult<[String:Decimal]?>) -> Void) {
        guard let url = url(for: .history, with: [URLQueryItem(name: "timestamp", value: String(format: "%.0f", timestamp.timeIntervalSince1970)), URLQueryItem(name: "coin", value: coin)]) else {
            completion(.failure(.internalError(message: "Failed to build URL", error: nil)))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, headers: headers).responseData(queue: defaultResponseDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                do {
                    let model: CoinInfoServiceResponseHistory = try JSONDecoder().decode(CoinInfoServiceResponseHistory.self, from: data)
                    guard let result = model.result?.first, abs(timestamp.timeIntervalSince(result.date)) < AdamantCurrencyInfoService.historyThreshold else {   // Разница в датах не должна превышать суток
                        completion(.success(nil))
                        return
                    }
                    
                    completion(.success(result.tickers))
                } catch {
                    completion(.failure(.serverError(error: "Coin info API result: Parsing error")))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
}


// MARK: - Server responses
struct CoinInfoServiceResponseGet: Decodable {
    enum CodingKeys: String, CodingKey {
        case success
        case date
        case result
    }
    
    let success: Bool
    let date: Date
    let result: [String: Decimal]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.success = try container.decode(Bool.self, forKey: .success)
        self.result = try? container.decode([String: Decimal].self, forKey: .result)
        
        if let timeInterval = try? container.decode(TimeInterval.self, forKey: .date) {
            self.date = Date(timeIntervalSince1970: timeInterval)
        } else {
            self.date = Date()
        }
    }
}

struct CoinInfoServiceResponseHistory: Decodable {
    enum CodingKeys: String, CodingKey {
        case success
        case date
        case result
    }
    
    let success: Bool
    let date: Date
    let result: [CoinInfoServiceHistoryResult]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.success = try container.decode(Bool.self, forKey: .success)
        self.result = try? container.decode([CoinInfoServiceHistoryResult].self, forKey: .result)
        
        if let timeInterval = try? container.decode(TimeInterval.self, forKey: .date) {
            self.date = Date(timeIntervalSince1970: timeInterval)
        } else {
            self.date = Date()
        }
    }
}

struct CoinInfoServiceHistoryResult: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case date
        case tickers
    }
    
    let id: String
    let tickers: [String: Decimal]?
    let date: Date
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.tickers = try? container.decode([String: Decimal].self, forKey: .tickers)
        
        if let timeInterval = try? container.decode(TimeInterval.self, forKey: .date) {
            self.date = Date(timeIntervalSince1970: timeInterval / 1000) // ms, just because
        } else {
            self.date = Date()
        }
    }
}
