platform :ios, '10.0'
use_frameworks!

target 'rollcall' do
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'Firebase/RemoteConfig'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxOptional'
  pod 'RACameraHelper', :git => 'https://github.com/bobbyren/RACameraHelper', :tag => '0.1.5'
  pod 'RenderPay', :git => 'git@bitbucket.org:renderapps/renderpay.git'
  pod 'Balizinha', :git => 'https://bitbucket.org/renderapps/balizinha-pod'
  pod 'RenderCloud', :git => 'git@bitbucket.org:renderapps/RenderCloud.git'
  pod 'Stripe', '~>14.0.0'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  end
end

