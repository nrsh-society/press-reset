use_frameworks!

target 'Lumos Mind' do
  platform :ios, '17.0'
  use_frameworks!
  pod 'PromiseKit'
  pod 'Parse'
  pod 'Charts', :git => 'https://github.com/danielgindi/Charts.git', :branch => 'master'
  pod 'NVActivityIndicatorView'
  pod 'Hero'
  pod 'SwiftyJSON'
  pod 'lottie-ios'
  pod 'Cache'
  pod 'SDWebImage'
  pod 'Smooth', :path => '~/src/cancelself/Smooth.swift'
end

target 'Lumos Mind WatchKit Extension' do
  platform :watchos, '10.0'
  use_frameworks!
  pod 'Smooth' , :path => '~/src/cancelself/Smooth.swift'
  pod 'Parse'
end

#post_install do |installer|
#    installer.pods_project.targets.each do |target|
#        target.build_configurations.each do |config|
#                config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
#        end
#    end
#end
