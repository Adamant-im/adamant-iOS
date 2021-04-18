
platform :ios, '10.0'

# Keychain secured store pods
def keychain_pods
  pod 'RNCryptor' # Cryptor
  pod 'KeychainAccess' # Keychain
end

# NativeCore pods
def core_pods
  pod 'ByteBackpacker' # Utility to pack value types into a Byte array
#  pod 'CryptoSwift', '1.0.0' # MD5 hash
#  pod 'libsodium' # Sodium crypto library
#  pod 'GRKOpenSSLFramework', '1.0.2.18'
end

# Markdown parser, forked with fixed whitespaces. '5 * 5 * 6'
def markdown_pods
  pod 'MarkdownKit'#, :git => 'https://github.com/RealBonus/MarkdownKit'
end

 # ADAMANT Messenger iOS app
target 'Adamant' do
  use_frameworks!

  pod 'Alamofire' # Network
  pod 'Swinject' # Dependency Injection
  pod 'ReachabilitySwift' # Network status
  pod 'DateToolsSwift' # Date formatter tools
  pod 'ProcedureKit' # Async programming tools
  
  # UI
  pod 'FreakingSimpleRoundImageView' # Round avatars
  pod 'FTIndicator' # Notifications and activity indicator
  pod 'Eureka', '5.3.0'#, :git => 'https://github.com/boyarkin-anton/Eureka.git', :branch => 'develop' # Forms
  pod 'MessageKit', '2.0.0' # Chat UI
  pod 'MyLittlePinpad' # Pinpad
  pod 'PMAlertController' # Custom alert controller
  pod 'Parchment' # Paging menu
#  pod 'SwiftyOnboard', :git => 'https://github.com/RealBonus/SwiftyOnboard', :branch => 'feature/customStyle' # wellcome screen

  # QR
  pod 'EFQRCode' # QR generator
  pod 'QRCodeReader.swift' # QR reader
  
  # Crypto
  pod 'web3.swift.pod', '~> 2.2.0' # ETH Web3 Swift Port
#  pod 'Lisk', :git => 'https://github.com/adamant-im/lisk-swift.git' # LSK
#  pod 'BitcoinKit', :git => 'https://github.com/boyarkin-anton/BitcoinKit.git', :branch => 'dev' # BTC

  # Shared
  keychain_pods
  core_pods
  markdown_pods
end

target 'AdamantTests' do
  use_frameworks!
  pod 'GRDB.swift'
end

# Adamant NotificationServiceExtension - real notifications
target 'NotificationServiceExtension' do
  use_frameworks!
  keychain_pods
  core_pods
  markdown_pods
end

# Adamant TransferNotificationContentExtension - Notification Content Extension for transfers
target 'TransferNotificationContentExtension' do
  use_frameworks!
  keychain_pods
  core_pods
  markdown_pods
  pod 'DateToolsSwift' # Date formatter tools
end

# Adamant MessageNotificationContentExtension - Notification Content Extension for messages
target 'MessageNotificationContentExtension' do
  use_frameworks!
  keychain_pods
  core_pods
  markdown_pods
  pod 'DateToolsSwift' # Date formatter tools
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'ByteBackpacker'
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '5.0'
      end
    end
    if target.name == 'MessageKit'
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.2'
      end
    end
    if target.name == 'GRDB.swift'
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.2'
      end
    end
    if target.name == 'GRDBCipher'
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.2'
      end
    end
  end
end
