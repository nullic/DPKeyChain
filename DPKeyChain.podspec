Pod::Spec.new do |s|

  s.name         = "DPKeyChain"
  s.version      = "1.0"
  s.summary      = "Provides way to use iOS keycahin"
  s.homepage     = "https://github.com/nullic/DPKeyChain"
  s.license      = "MIT"
  s.author       = { "Dmitriy Petrusevich" => "nullic@gmail.com" }
  s.platforms    = { :ios => "9.0" }
  
  s.source       = { :git => "https://github.com/nullic/DPKeyChain", :tag => "1.0" }
  s.source_files = "DPKeyChain", "DPKeyChain/*.{h,m}"
  s.requires_arc = true

end
