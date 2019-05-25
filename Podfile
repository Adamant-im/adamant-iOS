
platform :ios, '10.0'

# Keychain secured store pods
def keychain_pods
  pod 'RNCryptor' # Cryptor
  pod 'KeychainAccess' # Keychain
end

# NativeCore pods
def core_pods
  pod 'CryptoSwift' # MD5 hash
  pod 'ByteBackpacker' # Utility to pack value types into a Byte array
  pod 'libsodium' # Sodium crypto library
end

 # ADAMANT Messenger iOS app
target 'Adamant' do
  use_frameworks!

  pod 'Alamofire' # Network
  pod 'Swinject' # Dependency Injection
  pod 'ReachabilitySwift' # Network status
  pod 'MarkdownKit', :git => 'https://github.com/RealBonus/MarkdownKit' # Markdown parser, forked fixing whitespaces '5 * 5 * 6'
  pod 'DateToolsSwift' # Date formatter tools
  pod 'ProcedureKit' # Async programming tools
  
  # UI
  pod 'FreakingSimpleRoundImageView' # Round avatars
  pod 'FTIndicator' # Notifications and activity indicator
  pod 'Eureka' # Forms
  pod 'MessageKit' # Chat UI
  pod 'MyLittlePinpad' # Pinpad
  pod 'PMAlertController' # Custom alert controller
  pod 'Parchment' # Paging menu
  pod 'SwiftyOnboard', :git => 'https://github.com/RealBonus/SwiftyOnboard', :branch => 'feature/customStyle' # wellcome screen

  # QR
  pod 'EFQRCode' # QR generator
  pod 'QRCodeReader.swift' # QR reader
  
  # Crypto
  pod 'web3swift' # ETH Web3 Swift Port
  pod 'Lisk', :git => 'https://github.com/adamant-im/lisk-swift.git' # LSK
  pod 'BitcoinKit', :git => 'https://github.com/boyarkin-anton/BitcoinKit.git', :branch => 'dev' # BTC

  # Shared
  keychain_pods
  core_pods

end

# Adamant NotificationServiceExtension - readable notifications
target 'NotificationServiceExtension' do
  use_frameworks!
  keychain_pods
  core_pods
end