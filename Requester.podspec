Pod::Spec.new do |s|
  s.name             = 'Requester'
  s.version          = '1.0.22'
  s.summary          = 'A lightweight async/await and Combine based networking library.'
  s.homepage         = 'https://github.com/Kevinvandenhoek/Requester.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Kevin van den Hoek' => 'kevinvandenhoek@gmail.com' }
  s.source           = { :git => 'https://github.com/Kevinvandenhoek/Requester.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/Requester/**/*'
end
