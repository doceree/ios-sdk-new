platform :ios, '15.0'

target 'DocereeAdsSdk' do
  use_frameworks!

  project 'DocereeAdsSdk.xcodeproj'
  pod 'DocereeAdSdk', :path => '.'

  # Satisfies CocoaPods host-target check for framework development; tests load the SDK at runtime.
  target 'DocereeAdsSdkTests' do
    inherit! :search_paths
  end
end

# CocoaPods injects Pods_* umbrella frameworks during *integration*. Linking those umbrellas breaks
# when building from the root app workspace (single Pods graph). Real libs stay in Pods-DocereeAdsSdk*
# and Pods-DocereeAdsSdkTests *.xcconfig (OTHER_LDFLAGS, FRAMEWORK_SEARCH_PATHS).
post_integrate do |_installer|
  sdk_project_path = File.expand_path('DocereeAdsSdk.xcodeproj', __dir__)
  project = Xcodeproj::Project.open(sdk_project_path)
  project.targets.each do |target|
    next unless %w[DocereeAdsSdk DocereeAdsSdkTests].include?(target.name)

    target.frameworks_build_phase.files.to_a.each do |build_file|
      path = build_file.file_ref&.path.to_s
      next unless path.include?('Pods_DocereeAdsSdk')

      target.frameworks_build_phase.files.delete(build_file)
      build_file.remove_from_project
    end
  end

  %w[Pods_DocereeAdsSdk.framework Pods_DocereeAdsSdkTests.framework].each do |umbrella_name|
    project.files.each do |ref|
      next unless ref.path == umbrella_name

      ref.remove_from_project
    end
  end

  project.save
end
