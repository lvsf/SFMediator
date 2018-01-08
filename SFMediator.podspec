Pod::Spec.new do |s|
    s.name         = 'SFMediator'
    s.version      = '0.0.1'
    s.summary      = '简易的组件中间件'
    s.homepage     = 'https://github.com/lvsf/SFMediator'
    s.license      = 'MIT'
    s.authors      = {'lvsf' => 'lvsf1992@163.com'}
    s.platform     = :ios, '7.0'
    s.source       = {:git => 'https://github.com/lvsf/SFMediator.git', :tag => s.version}
    s.source_files = 'SFMediator/Class/**/*'
    s.requires_arc = true
end