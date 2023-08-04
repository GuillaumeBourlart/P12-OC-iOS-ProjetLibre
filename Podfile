# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

target 'Quiz' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Quiz
  pod 'Alamofire', '5.7.1'

  pod 'Firebase', '10.13.0'
  pod 'Firebase/Firestore', '10.13.0'
  pod 'Firebase/Messaging', '10.13.0'
  pod 'Firebase/Auth', '10.13.0'
  pod 'Firebase/Analytics', '10.13.0'
  pod 'Firebase/Performance', '10.13.0'
  pod 'Firebase/Storage', '10.13.0'

  pod 'SDWebImage', '5.17.0'
  pod 'SDWebImageFLPlugin', '0.6.0'

  target 'QuizTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end