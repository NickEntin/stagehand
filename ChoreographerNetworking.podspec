Pod::Spec.new do |s|
  s.name             = 'ChoreographerNetworking'
  s.version          = '1.0.0'
  s.summary          = 'Modern, type-safe API for building animations on iOS'
  s.homepage         = 'https://github.com/CashApp/Stagehand'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = 'Square'
  s.source           = { :git => 'https://github.com/CashApp/Stagehand.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.osx.deployment_target = '11.0'

  s.swift_version = '5.0.1'

  s.dependency 'Memo'

  s.source_files = 'Sources/ChoreographerNetworking/**/*'
end