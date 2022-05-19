Pod::Spec.new do |spec|
  spec.name         = 'DocereeAdsSdk'
  spec.version      = '1.1.2'
  spec.license      = { :type => "MIT", :file => "MIT License" }
  spec.description  = <<-DESC
  Doceree iOS SDK for mobile ads is used by our publisher partners to show advertisements being run by our brand partners and record the corresponding actions and impressions being served.
  						DESC
  spec.homepage     = 'https://github.com/doceree/ios-sdk'
  spec.authors      = { 'Muqeem Ahmad' => 'muqeem.ahmad@doceree.com' }
  spec.summary      = 'Doceree iOS SDK for mobile ads.'
  spec.platform 	= :ios, "9.0"
  spec.ios.deployment_target = "9.0"
  spec.source       = { :git => 'https://github.com/doceree/ios-sdk.git', :tag => spec.version }
  spec.source_files = "DocereeAdsSdk/**/*.{swift}", "DocereeAdsSdk/Utillities/APICall.swift 
"
  spec.resources = "DocereeAdsSdk/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"
  spec.swift_version    = '5.0'
end
