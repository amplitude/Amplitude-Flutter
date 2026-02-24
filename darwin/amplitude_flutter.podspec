#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint amplitude_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'amplitude_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Official Amplitude Flutter SDK for analytics tracking.'
  s.description      = <<-DESC
The official Amplitude Flutter SDK for tracking analytics events in your Flutter applications.
                       DESC
  s.homepage         = 'https://github.com/amplitude/Amplitude-Flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Amplitude' => 'sdk@amplitude.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'amplitude_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'

    s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym'
  }
  s.swift_version = '5.9'
  s.dependency 'AmplitudeSwift', '1.17.3'
end
