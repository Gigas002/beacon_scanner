#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint beacon_scanner.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'beacon_scanner'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin for scanning iBeacon.'
  s.description      = <<-DESC
A Flutter plugin for making the underlying platform (Android or iOS) scan for iBeacons.
                       DESC
  s.homepage         = 'https://github.com/Gigas002/beacon_scanner'
  s.license          = { :type => 'MIT' }
  s.author           = { 'gigas002' => 'example@gmail.com' }
  s.source           = { :git => 'https://github.com/Gigas002/beacon_scanner.git' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '17.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

end
