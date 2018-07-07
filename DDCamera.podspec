#
# Be sure to run `pod lib lint iOS-Camera.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "DDCamera"
  s.version          = "0.1.0"
  s.summary          = "iOS Camera"
  s.description      = <<-DESC
                       An optional longer description of iOS Camera
                       DESC
  s.homepage         = "https://github.com/dougdiego/iOS-Camera"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "dougdiego" => "dougdiego@gmail.com" }
  s.source           = { :git => "https://github.com/dougdiego/iOS-camera.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/dougdiego'

  s.platforms	 = { :ios => "10.0" }
  
  s.ios.deployment_target = '10.0'
  s.requires_arc = true

  s.source_files = 'Camera/**/*.{swift}'
  
  s.resource_bundles = {
     'iOS-Camera' => ['Camera/**/*.{lproj,storyboard,xib,xcassets,json,imageset,png,strings}']
  }
  
  #s.ios.frameworks = 'MobileCoreServices'
end
