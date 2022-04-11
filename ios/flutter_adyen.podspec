#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_adyen'
  s.version          = '4.7.1'
  s.summary          = 'Flutter plugin to integrate with the Android and iOS libraries of Adyen.'
  s.description      = <<-DESC
Flutter plugin to integrate with the Android and iOS libraries of Adyen.
                       DESC
  s.homepage         = 'https://github.com/skiprco/flutter-adyen/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { '' => 'developers@skipr.co' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Adyen', '~> 4.7.1'
  s.dependency 'Adyen3DS2', '~> 2.2.4'

  s.ios.deployment_target = '11.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end

