#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'Flutter'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter podspec.'
  s.description      = <<-DESC
A Flutter podspec.
                       DESC
  s.homepage         = 'https://flutter.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files      = 'Flutter.podspec'
  s.ios.deployment_target = '12.0'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
end
