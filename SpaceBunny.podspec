Pod::Spec.new do |s|
  s.name         = "SpaceBunny"
  s.version      = "0.1.2"
  s.summary      = "Official Swift SDK for SpaceBunny (http://spacebunny.io)"
  s.description  = <<-DESC
                    Official SpaceBunny's SDK for iOS. Used to connect and communicate with the platform. 
                    The library offers a client that allows to send messages and subscribe to the device inbox.
                   DESC
  s.homepage     = "https://github.com/space-bunny/Swift-sdk"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Fancy Pixel" => "andrea@fancypixel.it" }
  s.source       = { :git => "https://github.com/space-bunny/swift-sdk.git", :tag => s.version }
  s.platform     = :ios, '8.0'
  s.source_files = 'Source', '*.{swift}'
  s.requires_arc = true
  s.dependency 'ObjectMapper', '~> 1.2'
  s.dependency 'CocoaMQTT', '~> 1.0.7'
  s.social_media_url = 'https://twitter.com/spacebunny_iot'
end
