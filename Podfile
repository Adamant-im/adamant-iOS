
platform :ios, '10.0'

 # ADAMANT Messenger iOS app
target 'Adamant' do
  use_frameworks!
  
  # UI
  pod 'FreakingSimpleRoundImageView' # Round avatars
  pod 'MessageKit', '2.0.0' # Chat UI
  pod 'MyLittlePinpad' # Pinpad
  pod 'PMAlertController' # Custom alert controller
  pod 'SwiftLint'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'MessageKit'
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.2'
      end
    end
  end
end
