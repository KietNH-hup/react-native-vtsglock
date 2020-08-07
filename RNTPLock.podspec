require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "RNTPLock"
  s.version      = package['version']
  s.summary      = "React Native TTLock"
  s.license      = "MIT"

  s.authors      = "Ahmad Dehnavi"
  s.homepage     = "https://gitlab.com/yooki/yooki-mobile/react-native-tipilock.git"
  s.platform     = :ios, "11.0"
  s.ios.deployment_target = '11.0'

  s.source       = { :git => "https://gitlab.com/yooki/yooki-mobile/react-native-tipilock.git", :tag => "v#{s.version}" }
  s.source_files  = "ios/TtLockModule/**/*.{h,m}"

  s.dependency 'React'
end
