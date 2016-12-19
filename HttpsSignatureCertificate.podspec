Pod::Spec.new do |s|
    s.name         = 'HttpsSignatureCertificate'
    s.version      = '1.0'
    s.license       = 'MIT'
    s.summary      = 'An easy way use AFNetworking to authenticate a https signature for iOS.'
    s.homepage     = 'https://github.com/AustinKuture/HttpsSignatureCertificate'
    s.authors      = {'AustinKuture' => 'austinkuture@126.com'}
    s.platform     = :ios, '8.0'
    s.source       = {:git => 'https://github.com/AustinKuture/HttpsSignatureCertificate.git', :tag => '1.0'}
    s.source_files = 'HttpsSignatureCertificate/    AKNetPackegeAFN.{h,m}'
    s.dependency "AFNetworking", "~> 3.0"
    s.requires_arc = true
end

