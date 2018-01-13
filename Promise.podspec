Pod::Spec.new do |s|
  s.name         = "Promise"
  s.version      = "0.1.0"
  s.summary      = "Promise for Swift."
  s.homepage     = "https://github.com/wegie/Promise"
  s.license      = "MIT"
  s.author       = "wegie"
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/wegie/Promise.git", :tag => s.version.to_s }
  s.source_files = "Promise/**/*.swift"
  s.requires_arc = true
end
