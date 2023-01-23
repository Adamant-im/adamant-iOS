#!/usr/bin/ruby
#encoding: utf-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "json"

class Coins
    
    # Update a swift file
    def writeToSwiftFile(name, json)
        nodes = ""
        nodesArray = json["nodes"]
        if nodesArray != nil
            nodesArray.each do |node|
                url = node["url"]
                nodes += "Node(url: URL(string: \"#{url}\")!),\n"
            end
        end
        
        serviceNodes = ""
        serviceNodesArray = json["serviceNodes"]
        if serviceNodesArray != nil
            serviceNodesArray.each do |node|
                url = node["url"]
                serviceNodes += "Node(url: URL(string: \"#{url}\")!),\n"
            end
        end
        
        fixedFee = json["fixedFee"]
        if fixedFee == nil
            fixedFee = json["defaultFee"]
        end
        if fixedFee == nil
            fixedFee = 0.0
        end
        
        fullName = json["name"]
        symbol = json["symbol"]
        decimals = json["decimals"]
        explorerTx = json["explorerTx"]
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
        
        text = "import Foundation

extension #{symbol.capitalize}WalletService {
    // MARK: - Constants
    static let fixedFee: Decimal = #{fixedFee}
    static let currencySymbol = \"#{symbol}\"
    static let currencyExponent: Int = -#{decimals}
    static let qqPrefix: String = \"#{qqPrefix}\"
    
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
        
        # If is ADM write to share file
        if symbol == "ADM"
           textResources = "import Foundation

extension AdamantResources {
    // MARK: Nodes
    static var nodes: [Node] {
        [
            #{nodes}
        ]
    }
}"
            File.open(Dir.pwd + "/AdamantShared/AdamantDynamicResources.swift", 'w') { |file| file.write(textResources) }
            File.open(Dir.pwd + "/Adamant/Wallets/#{name}/#{symbol}WalletService+DynamicConstants.swift", 'w') { |file| file.write(text) }
        else
            File.open(Dir.pwd + "/Adamant/Wallets/#{name}/#{symbol}WalletService+DynamicConstants.swift", 'w') { |file| file.write(text) }
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
    def startUnpack
        wallets = Dir[Dir.pwd + "/scripts/wallets/adamant-wallets-master/assets/general/*"]
        wallets.each do |wallet|
            readJson(wallet)
        end
    end
    
end

Coins.new.startUnpack
