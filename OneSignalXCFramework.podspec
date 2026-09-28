Pod::Spec.new do |s|
    s.name             = "OneSignalXCFramework"
    s.version          = "5.7.0"
    s.summary          = "OneSignal push notification library for mobile apps."
    s.homepage         = "https://onesignal.com"
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { "Joseph Kalash" => "joseph@onesignal.com", "Josh Kasten" => "josh@onesignal.com" , "Brad Hesse" => "brad@onesignal.com"}
    
    # Fork: the OneSignal subspec (OneSignalFramework) is compiled from source; every other
    # module is the upstream, OneSignal-signed 5.7.0 binary. See the OneSignal subspec.
    s.source           = { :git => "https://github.com/kaiquegazola/OneSignal-iOS-SDK.git", :tag => "5.7.0-noautoinit.2" }
    s.module_name      = "OneSignalFramework"
    s.swift_version    = "5.0"
    s.platform         = :ios, '15.0'
    s.pod_target_xcconfig = {
      'IPHONEOS_DEPLOYMENT_TARGET[sdk=macosx*]' => '14.0',
      # Source/ uses UIApplication.shared. CocoaPods forces YES when an app extension (NSE, widget)
      # links the pod; the upstream prebuilt OneSignalFramework was not extension-only either.
      'APPLICATION_EXTENSION_API_ONLY' => 'NO',
      # Source/ quote-includes headers of the other modules; CocoaPodsSourceHeaders forwards them
      # to the prebuilt frameworks (see that folder).
      'USER_HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/iOS_SDK/OneSignalSDK/CocoaPodsSourceHeaders"'
    }
    s.requires_arc     = true
    s.default_subspec = "OneSignalComplete"

    s.subspec 'OneSignalCore' do |ss|
      ss.vendored_frameworks = 'iOS_SDK/OneSignalSDK/OneSignal_Core/OneSignalCore.xcframework'
    end

    s.subspec 'OneSignalOSCore' do |ss|
      ss.dependency 'OneSignalXCFramework/OneSignalCore'
      ss.vendored_frameworks = 'iOS_SDK/OneSignalSDK/OneSignal_OSCore/OneSignalOSCore.xcframework'
    end

    s.subspec 'OneSignalOutcomes' do |ss|
      ss.dependency 'OneSignalXCFramework/OneSignalCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOSCore'
      ss.vendored_frameworks = 'iOS_SDK/OneSignalSDK/OneSignal_Outcomes/OneSignalOutcomes.xcframework'
    end

    s.subspec 'OneSignalExtension' do |ss|
      ss.dependency 'OneSignalXCFramework/OneSignalCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOSCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOutcomes'
      ss.vendored_frameworks = 'iOS_SDK/OneSignalSDK/OneSignal_Extension/OneSignalExtension.xcframework'
    end

    s.subspec 'OneSignalNotifications' do |ss|
      ss.dependency 'OneSignalXCFramework/OneSignalCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOSCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOutcomes'
      ss.dependency 'OneSignalXCFramework/OneSignalExtension'
      ss.vendored_frameworks = 'iOS_SDK/OneSignalSDK/OneSignal_Notifications/OneSignalNotifications.xcframework'
    end

    s.subspec 'OneSignalUser' do |ss|
      ss.dependency 'OneSignalXCFramework/OneSignalCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOSCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOutcomes'
      ss.dependency 'OneSignalXCFramework/OneSignalNotifications'
      ss.vendored_frameworks = 'iOS_SDK/OneSignalSDK/OneSignal_User/OneSignalUser.xcframework'
    end

    s.subspec 'OneSignalLiveActivities' do |ss|
      ss.dependency 'OneSignalXCFramework/OneSignalCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOSCore'
      ss.dependency 'OneSignalXCFramework/OneSignalUser'
      ss.vendored_frameworks = 'iOS_SDK/OneSignalSDK/OneSignal_LiveActivities/OneSignalLiveActivities.xcframework'
    end

    s.subspec 'OneSignalLocation' do |ss|
      ss.dependency 'OneSignalXCFramework/OneSignalCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOSCore'
      ss.dependency 'OneSignalXCFramework/OneSignalNotifications'
      ss.dependency 'OneSignalXCFramework/OneSignalUser'
      ss.vendored_frameworks = 'iOS_SDK/OneSignalSDK/OneSignal_Location/OneSignalLocation.xcframework'
    end

    s.subspec 'OneSignalInAppMessages' do |ss|
      ss.dependency 'OneSignalXCFramework/OneSignalCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOSCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOutcomes'
      ss.dependency 'OneSignalXCFramework/OneSignalNotifications'
      ss.dependency 'OneSignalXCFramework/OneSignalUser'
      ss.vendored_frameworks = 'iOS_SDK/OneSignalSDK/OneSignal_InAppMessages/OneSignalInAppMessages.xcframework'
    end

    s.subspec 'OneSignal' do |ss|
      ss.dependency 'OneSignalXCFramework/OneSignalCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOSCore'
      ss.dependency 'OneSignalXCFramework/OneSignalOutcomes'
      ss.dependency 'OneSignalXCFramework/OneSignalExtension'
      ss.dependency 'OneSignalXCFramework/OneSignalNotifications'
      ss.dependency 'OneSignalXCFramework/OneSignalUser'
      ss.dependency 'OneSignalXCFramework/OneSignalLiveActivities'
      # Fork: built from source (module OneSignalFramework) instead of the prebuilt xcframework.
      # Only this module can be: CocoaPods compiles all of a pod's sources into ONE framework, and
      # the other upstream binaries link @rpath/<Module>.framework of their dependencies.
      ss.source_files = 'iOS_SDK/OneSignalSDK/Source/**/*.{h,m,swift}'
      ss.public_header_files = 'iOS_SDK/OneSignalSDK/Source/OneSignalFramework.h'
      # Fork: no resource_bundles for the privacy manifest. A resource bundle makes CocoaPods add a
      # "[CP] Copy Pods Resources" script phase to every consuming target, which fails under
      # ENABLE_USER_SCRIPT_SANDBOXING (e.g. notification service extensions). Apple's signature and
      # privacy-manifest requirements for commonly used SDKs apply to prebuilt binaries; the upstream
      # binaries (Core, OSCore, Outcomes, Extension, ...) keep their embedded manifests. This module is
      # compiled into the host app, so the app's own PrivacyInfo.xcprivacy must declare the entries of
      # iOS_SDK/OneSignalSDK/Source/PrivacyInfo.xcprivacy.
      # Header-only inputs of the source build; CocoaPods deletes unreferenced files of :git pods.
      ss.preserve_paths = ['iOS_SDK/OneSignalSDK/CocoaPodsSourceHeaders/*.h', 'iOS_SDK/OneSignalSDK/OneSignalCore/Source/OSMacros.h']
    end

    s.subspec 'OneSignalComplete' do |ss|
      ss.dependency 'OneSignalXCFramework/OneSignal'
      ss.dependency 'OneSignalXCFramework/OneSignalLocation'
      ss.dependency 'OneSignalXCFramework/OneSignalInAppMessages'
    end
end
