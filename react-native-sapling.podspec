require 'json'
package_json = JSON.parse(File.read('package.json'))

Pod::Spec.new do |s|

  s.name           = "react-native-sapling"
  s.version        = package_json["version"]
  s.summary        = package_json["description"]
  s.homepage       = "https://github.com/madfish-solutions/react-native-sapling"
  s.license        = package_json["license"]
  s.author         = { package_json["author"] => package_json["author"] }
  s.platform       = :ios, "13.0"
  s.source         = { :git => "#{package_json["repository"]["url"]}" }
  s.source_files   = '*.{h,m,swift}'
  s.swift_version  = '5.0'

  s.dependency 'React-Core'

  # SaplingFFI.xcframework is downloaded by the npm postinstall script
  # (scripts/download-xcframework.js). It contains the prebuilt Rust/C static
  # library that provides the Zcash Sapling cryptographic primitives.
  s.vendored_frameworks = 'SaplingFFI.xcframework'

  # The postinstall script patches the xcframework headers in-place to use
  # angle-bracket system includes (<stdlib.h> instead of "stdlib.h") so the
  # module builds cleanly without picking up Folly's Stdlib.h.
  #
  # Explicit LIBRARY_SEARCH_PATHS + linker flag as a fallback for CocoaPods
  # versions that don't fully wire up static-library xcframeworks.
  # The upstream xcframework ships ios-arm64 (device) and
  # ios-x86_64-simulator but NOT ios-arm64-simulator.  On Apple Silicon Macs
  # Xcode defaults to arm64 for the simulator; excluding it forces x86_64
  # via Rosetta so the existing slice is used.
  xcf = '$(PODS_TARGET_SRCROOT)/SaplingFFI.xcframework'
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]'       => 'arm64',
    'LIBRARY_SEARCH_PATHS[sdk=iphoneos*]'        => "$(inherited) #{xcf}/ios-arm64",
    'LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*]'  => "$(inherited) #{xcf}/ios-x86_64-simulator",
    'OTHER_LDFLAGS'                               => '$(inherited) -lairgap_sapling',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]'       => 'arm64'
  }

end
