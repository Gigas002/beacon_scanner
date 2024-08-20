#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint beacon_scanner_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'beacon_scanner_ios'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin for scanning iBeacon.'
  s.description      = <<-DESC
A Flutter plugin for making the underlying platform (Android or iOS) scan for iBeacons.
                       DESC
  s.homepage         = 'https://github.com/Gigas002/beacon_scanner/tree/main/beacon_scanner_ios'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Lukangi' => 'lukanga.games@gmail.com' }
  s.source           = { :http => 'https://github.com/Gigas002/beacon_scanner/tree/main/beacon_scanner_ios' }
  s.documentation_url = 'https://pub.dev/packages/beacon_scanner_ios'
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  # s.swift_version = '5.0'
end