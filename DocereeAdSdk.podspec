Pod::Spec.new do |spec|
  spec.name             = 'DocereeAdSdk'
  spec.version          = '6.0.0'
  spec.summary          = 'Doceree iOS SDK for mobile ads.'
  spec.description      = <<-DESC
  Doceree iOS SDK for mobile ads is used by our publisher partners to show advertisements being run by our brand partners and record corresponding actions and impressions.
  DESC
  spec.homepage         = 'https://github.com/doceree/ios-sdk-new'
  spec.license          = { :type => 'MIT', :file => 'MIT License' }
  spec.authors          = { 'Muqeem Ahmad' => 'muqeem.ahmad@doceree.com' }
  spec.platform         = :ios, '15.0'
  spec.source           = { :git => 'https://github.com/doceree/ios-sdk-new.git', :tag => spec.version }
  spec.source_files     = 'DocereeAdsSdk/**/*.{swift}'
  spec.resource_bundles = {
    'DocereeAdsSdk' => ['DocereeAdsSdk/**/*.{png,jpeg,jpg,storyboard,xib,xcassets,bundle,js}', 'DocereeAdsSdk/*.js']
  }
  spec.swift_version    = '5.0'

  # Vendored xcframework with only iOS slices (no tvOS)
  spec.vendored_frameworks = 'Frameworks/OMSDK_Doceree.xcframework'

  # Required system frameworks and libraries
  spec.frameworks = 'AdSupport', 'WebKit'
  spec.libraries = 'z', 'sqlite3'

  spec.requires_arc = true
end
