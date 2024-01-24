#!/usr/bin/ruby
#encoding: utf-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "json"

class Coins
    
    def createSwiftVariable(name, value, type, isStatic)
        prefix = isStatic ? "static " : ""
        text = "    #{prefix}var #{name}: #{type} {
        #{value}
    }
        "
        return text
    end
    
    # Get Health Check file
    def get_health_check_params_from(json)
        symbol = json["symbol"]
        
        # node_additional_info
        node_additional_info = json["nodes"]["healthCheck"]
        services = json["services"]
        
        if !services.nil?
            service_additional_info = services["healthCheck"]
        end
        
        normal_update_interval = nil
        crucial_update_interval = nil
        on_screen_update_interval = nil
        threshold = nil
        normal_service_update_interval = nil
        crucial_service_update_interval = nil
        on_screen_service_update_interval = nil
        
        if !service_additional_info.nil?
            normal_service_update_interval = service_additional_info["normalUpdateInterval"]
            crucial_service_update_interval = service_additional_info["crucialUpdateInterval"]
            on_screen_service_update_interval = service_additional_info["onScreenUpdateInterval"]
        end
        
        if !node_additional_info.nil?
            normal_update_interval = node_additional_info["normalUpdateInterval"]
            crucial_update_interval = node_additional_info["crucialUpdateInterval"]
            on_screen_update_interval = node_additional_info["onScreenUpdateInterval"]
            threshold = node_additional_info["threshold"]
            
            if normal_service_update_interval.nil?
                normal_service_update_interval = normal_update_interval
            end
            if crucial_service_update_interval.nil?
                crucial_service_update_interval = crucial_update_interval
            end
            if on_screen_service_update_interval.nil?
                on_screen_service_update_interval = on_screen_update_interval
            end
            
            text = "static let healthCheckParameters = CoinHealthCheckParameters(
        normalUpdateInterval: #{normal_update_interval / 1000},
        crucialUpdateInterval: #{crucial_update_interval / 1000},
        onScreenUpdateInterval: #{on_screen_update_interval / 1000},
        threshold: #{threshold},
        normalServiceUpdateInterval: #{normal_service_update_interval / 1000},
        crucialServiceUpdateInterval: #{crucial_service_update_interval / 1000},
        onScreenServiceUpdateInterval: #{on_screen_service_update_interval / 1000}
    )"
            return text
        end
        
        return nil
    end
    
    # Update a swift file
    def writeToSwiftFile(name, json)
        
        # Read data from json
        
        fullName = json["name"]
        symbol = json["symbol"]
        decimals = json["decimals"]
        explorerTx = json["explorerTx"]
        cryptoTransferDecimals = json["cryptoTransferDecimals"]
        nodes = ""
        nodesArray = json["nodes"]["list"]
        if nodesArray != nil
            nodesArray.each do |node|
                url = node["url"]
                altUrl = node["alt_ip"]
                if altUrl == nil
                    nodes += "Node(url: URL(string: \"#{url}\")!),\n"
                else
                    nodes += "Node(url: URL(string: \"#{url}\")!, altUrl: URL(string: \"#{altUrl}\")),\n"
                end
            end
        end
        
        serviceNodes = ""
        servicesInfo = json["services"]
        if servicesInfo != nil
            services = servicesInfo["list"]
            if services != nil
                serviceNodesArray = (symbol == "ADM") ? services["infoService"] : services["#{symbol.downcase}Service"]
                if serviceNodesArray != nil
                    serviceNodesArray.each do |node|
                        url = node["url"]
                        serviceNodes += "Node(url: URL(string: \"#{url}\")!),\n"
                    end
                end
            end
        end
        
        fixedFee = json["fixedFee"]
        if fixedFee == nil
            fixedFee = json["defaultFee"]
        end
        if fixedFee == nil
            fixedFee = 0.0
        end
        
        consistencyMaxTime = json["txConsistencyMaxTime"]
        if consistencyMaxTime == nil
            consistencyMaxTime = 0
            else
            consistencyMaxTime = consistencyMaxTime / 1000
        end
        minBalance = json["minBalance"]
        if minBalance == nil
            minBalance = 0
        end
        minAmount = json["minTransferAmount"]
        if minAmount == nil
            minAmount = 0
        end
        qqPrefix = json["qqPrefix"]
        
        defaultVisibility = json["defaultVisibility"]
        if defaultVisibility == nil
            defaultVisibility = false
        end
        
        defaultOrdinalLevel = json["defaultOrdinalLevel"]
        
        nodesInfo = json["nodes"]
        minNodeVersion = "nil"
        
        if nodesInfo != nil
            minNodeVersion = nodesInfo["minVersion"]
        end
        
        if minNodeVersion == nil
            minNodeVersion = "nil"
        else
            minNodeVersion = "\"#{minNodeVersion}\""
        end
        
        # txFetchInfo
        txFetchInfo = json["txFetchInfo"]
        
        newPendingInterval = nil
        oldPendingInterval = nil
        registeredInterval = nil
        newPendingAttempts = nil
        oldPendingAttempts = nil
        
        if !txFetchInfo.nil?
        newPendingInterval = txFetchInfo["newPendingInterval"]
        oldPendingInterval = txFetchInfo["oldPendingInterval"]
        registeredInterval = txFetchInfo["registeredInterval"]
        newPendingAttempts = txFetchInfo["newPendingAttempts"]
        oldPendingAttempts = txFetchInfo["oldPendingAttempts"]
        end

        # Gas for eth
        reliabilityGasPricePercent = json["reliabilityGasPricePercent"]
        reliabilityGasLimitPercent = json["reliabilityGasLimitPercent"]
        defaultGasPriceGwei = json["defaultGasPriceGwei"]
        defaultGasLimit = json["defaultGasLimit"]
        warningGasPriceGwei = json["warningGasPriceGwei"]
        
        health_check_params = get_health_check_params_from(json)
        
        emptyText = ""
        
        # Create swift file
        
        text = "import Foundation
import BigInt
import CommonKit
    
extension #{symbol.capitalize}WalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = #{fixedFee}
    static let currencySymbol = \"#{symbol}\"
    static let currencyExponent: Int = -#{decimals}
    static let qqPrefix: String = \"#{qqPrefix}\"
    static let cryptoTransferDecimals: Int = #{cryptoTransferDecimals}
    #{health_check_params ?
    health_check_params :
    emptyText
    }
        
#{newPendingInterval ?
    createSwiftVariable("newPendingInterval", newPendingInterval, "Int", true) :
    emptyText
    }

#{oldPendingInterval ?
    createSwiftVariable("oldPendingInterval", oldPendingInterval, "Int", true) :
    emptyText
    }

#{registeredInterval ?
    createSwiftVariable("registeredInterval", registeredInterval, "Int", true) :
    emptyText
    }

#{newPendingAttempts ?
    createSwiftVariable("newPendingAttempts", newPendingAttempts, "Int", true) :
    emptyText
    }

#{oldPendingAttempts ?
    createSwiftVariable("oldPendingAttempts", oldPendingAttempts, "Int", true) :
    emptyText
    }

#{reliabilityGasPricePercent ?
    createSwiftVariable("reliabilityGasPricePercent", reliabilityGasPricePercent, "BigUInt", false) :
    emptyText
    }

#{reliabilityGasLimitPercent ?
    createSwiftVariable("reliabilityGasLimitPercent", reliabilityGasLimitPercent, "BigUInt", false) :
    emptyText
    }

#{defaultGasPriceGwei ?
    createSwiftVariable("defaultGasPriceGwei", defaultGasPriceGwei, "BigUInt", false) :
    emptyText
    }

#{defaultGasLimit ?
    createSwiftVariable("defaultGasLimit", defaultGasLimit, "BigUInt", false) :
    emptyText
    }

#{warningGasPriceGwei ?
    createSwiftVariable("warningGasPriceGwei", warningGasPriceGwei, "BigUInt", false) :
    emptyText
    }

    var tokenName: String {
        \"#{fullName}\"
    }
    
    var consistencyMaxTime: Double {
        #{consistencyMaxTime}
    }
    
    var minBalance: Decimal {
        #{minBalance}
    }
    
    var minAmount: Decimal {
        #{minAmount}
    }
    
    var defaultVisibility: Bool {
        #{defaultVisibility}
    }
    
    var defaultOrdinalLevel: Int? {
        #{defaultOrdinalLevel}
    }
    
    var minNodeVersion: String? {
        #{minNodeVersion}
    }
    
    static let explorerAddress = \"#{explorerTx.sub! '${ID}', ''}\"
    
    static var nodes: [Node] {
        [
            #{nodes}
        ]
    }
    
    static var serviceNodes: [Node] {
        [
            #{serviceNodes}
        ]
    }
}
"
        # remove empty lines
        text = text.gsub!(/\n+/, "\n")
        
        # If is ADM write to share file
        if symbol == "ADM"
           textResources = "import Foundation

public extension AdamantResources {
    // MARK: Nodes
    static var nodes: [Node] {
        [
            #{nodes}
        ]
    }
}"
            File.open(Dir.pwd + "/CommonKit/Sources/CommonKit/AdamantDynamicResources.swift", 'w') { |file| file.write(textResources) }
            File.open(Dir.pwd + "/Adamant/Modules/Wallets/#{name}/#{symbol}WalletService+DynamicConstants.swift", 'w') { |file| file.write(text) }
        else
            File.open(Dir.pwd + "/Adamant/Modules/Wallets/#{name}/#{symbol}WalletService+DynamicConstants.swift", 'w') { |file| file.write(text) }
        end
    end
    
    # Read JSON from a file
    def readJson(folder)
        file = open(folder + "/info.json")
        walletName = folder.split('/').last
        json = file.read
        parsed = JSON.parse(json)
        createCoin = parsed["createCoin"]
        if createCoin == true
            writeToSwiftFile(walletName.capitalize, parsed)
        end
    end
    
    # Go over all wallets
    def startUnpack(branch)
        wallets = Dir[Dir.pwd + "/scripts/wallets/adamant-wallets-#{branch}/assets/general/*"]
        wallets.each do |wallet|
            readJson(wallet)
        end
    end
    
end

Coins.new.startUnpack("dev") #master #dev
