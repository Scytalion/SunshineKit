Pod::Spec.new do |s|
  s.name             = "SunKit"
  s.summary          = "Framework that can calculation various Sun related data."
  s.version          = "1.0.0"
  s.homepage         = "https://github.com/scytalion/SunKit"
  s.license          = 'MIT'
  s.author           = { "Oleg Müller" => "mail@bitgrainedbytes.com" }
  s.source           = {
    :git => "https://github.com/scytalion/SunKit.git",
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.source_files = 'SunKit/Source/**/*.swift'

  s.ios.frameworks = 'Foundation', 'Accelerate', 'CoreLocation'

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
  s.documentation_url = 'http://cocoadocs.org/docsets/SunKit/'
end
