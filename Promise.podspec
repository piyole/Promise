Pod::Spec.new do |s|
  s.name         = "Promise"
  s.version      = "0.0.1"
  s.summary      = "Promise for Swift."
  s.homepage     = "https://github.com/wegie/Promise"
  s.license      = "MIT"
  s.author       = "wegie"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/wegie/Promise.git", :tag => "0.0.1" }
  s.source_files  = "Promise/**/*"
  s.requires_arc = true
end
