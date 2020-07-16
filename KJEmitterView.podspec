Pod::Spec.new do |s|
  s.name     = "KJEmitterView"
  s.version  = "5.0.0"
  s.summary  = "77 Tools"
  s.homepage = "https://github.com/yangKJ/KJEmitterView"
  s.license  = "MIT"
  s.license  = {:type => "MIT", :file => "LICENSE"}
  s.license  = "Copyright (c) 2018 yangkejun"
  s.author   = { "77" => "393103982@qq.com" }
  s.platform = :ios
  s.source   = {:git => "https://github.com/yangKJ/KJEmitterView.git",:tag => "#{s.version}"}
  s.social_media_url = 'https://www.jianshu.com/u/c84c00476ab6'
  s.requires_arc = true

  s.default_subspec = 'Kit'
  s.ios.source_files = 'KJEmitterView/KJEmitterHeader.h' 

  s.subspec 'Kit' do |y|
    y.source_files = "KJEmitterView/Kit/**/*.{h,m}" 
    y.public_header_files = 'KJEmitterView/Kit/*.h',"KJEmitterView/Kit/**/*.h" 
    y.frameworks = 'Foundation','UIKit','Accelerate'
  end

  s.subspec 'Control' do |a|
    a.source_files = "KJEmitterView/Control/**/*.{h,m}"
    a.public_header_files = "KJEmitterView/Control/**/*.h",'KJEmitterView/Control/*.h'
    a.dependency 'KJEmitterView/Kit'
    a.frameworks = 'QuartzCore'
  end

  s.subspec 'Classes' do |ss|
    ss.source_files = "KJEmitterView/Classes/**/*.{h,m}"
    ss.public_header_files = "KJEmitterView/Classes/**/*.h",'KJEmitterView/Classes/*.h'
    ss.resources = "KJEmitterView/Classes/**/*.{bundle}" 
    ss.dependency 'KJEmitterView/Kit'
  end

  s.subspec 'Function' do |fun|
    fun.source_files = "KJEmitterView/Foundation/**/*.{h,m}"
    fun.public_header_files = 'KJEmitterView/Foundation/*.h',"KJEmitterView/Foundation/**/*.h"
    fun.dependency 'KJEmitterView/Kit'
  end
  
end


