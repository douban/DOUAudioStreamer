Pod::Spec.new do |s|
  s.name = "DOUAudioStreamer"
  s.version = "0.2.15"
  s.license = { :type => "BSD", :file => "LICENSE" }
  s.summary = "A Core Audio based streaming audio player for iOS/Mac."
  s.homepage = "https://github.com/douban/DOUAudioStreamer"
  s.author = { "Chongyu Zhu" => "i@lembacon.com" }
  s.source = { :git => "https://github.com/douban/DOUAudioStreamer.git", :tag => s.version.to_s }
  s.source_files = "src/*.{h,m}"
  s.requires_arc = true

  s.ios.deployment_target = "5.0"
  s.ios.frameworks = "Accelerate", "CFNetwork", "CoreAudio", "AudioToolbox", "AVFoundation", "MediaPlayer", "QuartzCore", "OpenGLES", "MobileCoreServices"

  s.osx.deployment_target = "10.7"
  s.osx.framework = "Accelerate", "CFNetwork", "CoreAudio", "AudioToolbox", "AudioUnit", "CoreServices"
end
