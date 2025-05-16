Pod::Spec.new do |spec|
  spec.name         = 'DocereeAdSdk'
  spec.version      = '6.0.0'
  spec.license      = { :type => "MIT", :file => "MIT License" }
  spec.description  = <<-DESC
  Doceree iOS SDK for mobile ads is used by our publisher partners to show advertisements being run by our brand partners and record the corresponding actions and impressions being served.
                          DESC
  spec.homepage     = 'https://github.com/doceree/ios-sdk-new'
  spec.authors      = { 'Muqeem Ahmad' => 'muqeem.ahmad@doceree.com' }
  spec.summary      = 'Doceree iOS SDK for mobile ads.'
  spec.platform     = :ios, "15.0"
  spec.ios.deployment_target = "15.0"
  spec.source       = { :git => 'https://github.com/doceree/ios-sdk-new.git', :tag => spec.version }
  spec.source_files = "DocereeAdsSdk/**/*.{swift}"
  spec.resource_bundles = {
  	'DocereeAdsSdk' => [
    	'DocereeAdsSdk/**/*.{png,jpeg,jpg,storyboard,xib,xcassets,bundle,js}',
    	'DocereeAdsSdk/*.js'  # 👈 Explicitly match root-level js
  	]
	}
  spec.swift_version    = '5.0'

  # Properly include the OMSDK_Doceree.xcframework
  spec.vendored_frameworks = 'Frameworks/OMSDK_Doceree.xcframework'

  # Required system frameworks
  spec.frameworks = 'AdSupport', 'WebKit'
  
  # Link against required libraries (if needed)
  spec.libraries = 'z', 'sqlite3'

# Ensure the module is recognized
  spec.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-framework OMSDK_Doceree',
    'VALID_ARCHS' => 'arm64 x86_64'
  }

end
