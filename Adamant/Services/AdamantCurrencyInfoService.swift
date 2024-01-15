//
//  AdamantCurrencyInfoService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 23/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import Alamofire
import UIKit
import CommonKit

extension StoreKey {
    struct CoinInfo {
        static let selectedCurrency = "coinInfo.selectedCurrency"
    }
}

// MARK: - Service
final class AdamantCurrencyInfoService: CurrencyInfoService {
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
    
    private var rateCoins: [String]?
    private var rates = [String: Decimal]()
    
    private let defaultResponseDispatchQueue = DispatchQueue(label: "com.adamant.info-coins-response-queue", qos: .utility, attributes: [.concurrent])
    
    public var currentCurrency: Currency = Currency.default {
        didSet {
            securedStore.set(currentCurrency.rawValue, for: StoreKey.CoinInfo.selectedCurrency)
            NotificationCenter.default.post(name: Notification.Name.AdamantCurrencyInfoService.currencyRatesUpdated, object: nil)
        }
    }
    
    private var observerActive: NSObjectProtocol?
    
    // MARK: - Dependencies
    private let securedStore: SecuredStore
    
    weak var accountService: AccountService? {
        didSet {
            if let accountService = accountService {
                rateCoins = accountService.wallets.map { s -> String in s.tokenSymbol }
            } else {
                rateCoins = nil
            }
        }
    }
    
    // MARK: - Init
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
        addObservers()
        setupSecuredStore()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - Observers
    func addObservers() {
        observerActive = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.update()
        }
    }
    
    func removeObservers() {
        if let observerActive = observerActive {
            NotificationCenter.default.removeObserver(observerActive)
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
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(url, method: .get, headers: headers).responseData(queue: defaultResponseDispatchQueue) { response in
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
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(url, method: .get, headers: headers).responseData(queue: defaultResponseDispatchQueue) { response in
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
    
    func getHistory(
        for coin: String,
        timestamp: Date
    ) async throws -> [String: Decimal] {
        try await withUnsafeThrowingContinuation { continuation in
            getHistory(
                for: coin,
                timestamp: timestamp) { completion in
                    switch completion {
                    case .success(let result):
                        continuation.resume(returning: result ?? [:])
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    private func setupSecuredStore() {
        if
            let id: String = securedStore.get(StoreKey.CoinInfo.selectedCurrency),
            let currency = Currency(rawValue: id)
        {
            currentCurrency = currency
        } else {
            currentCurrency = Currency.default
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
