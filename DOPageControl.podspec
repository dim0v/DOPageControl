#
# Be sure to run `pod lib lint DOPageControl.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "DOPageControl"
  s.version          = "1.0.1"
  s.summary          = "Replacement for UIPageControl. Written in Swift"
  s.description      = <<-DESC
                       Provides functionality similar to UIPageControl.
                       Has slightly different visual appearence and allows to customize page indicators size, color and spacing

                       DESC
  s.homepage         = "https://github.com/dim0v/DOPageControl"
  s.screenshots      = "https://raw.githubusercontent.com/dim0v/DOPageControl/master/Screenshots/Screenshot0.png"
  s.license          = 'MIT'
  s.author           = { "Dmytro Ovcharenko" => "dmyt.ov@gmail.com" }
  s.source           = { :git => "https://github.com/dim0v/DOPageControl.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'DOPageControl' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
