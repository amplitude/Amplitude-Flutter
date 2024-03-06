#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

amplitude_version = "4.0.0-beta.0" # Version is managed automatically by semantic-release, please don't change it manually

Pod::Spec.new do |s|
  s.name             = 'amplitude_flutter'
  s.version          = amplitude_version
  s.summary          = 'A new flutter plugin project.'
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Amplitude' => 'sdk.dev@amplitude.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'AmplitudeSwift', '~> 1.0.0'

  s.ios.deployment_target = '13.0'
end

