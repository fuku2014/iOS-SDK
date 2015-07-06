#
# Be sure to run `pod lib lint MODE-iOSSDK.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MODE-iOSSDK"
  s.version          = "0.1.5"
  s.summary          = "iOS API libraries to access MODE cloud."
  s.description      = <<-DESC
                       This is iOS API library to access MODE cloud.
                       DESC
  s.homepage         = "https://github.com/moderepo/iOS-SDK"
  s.license          = 'MIT'
  s.author           = { "Naoki Takano" => "honten@tinkermode.com" }
  s.source           = { :git => "https://github.com/moderepo/iOS-SDK.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/tinkermode'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Mode/*'

  s.dependency 'Mantle'
  s.dependency 'SocketRocket'
end
