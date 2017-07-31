//
//  AKNetPackegeAFN.m
//  AKPackageAFN
//
//  Created by 李亚坤 on 2016/10/20.
//  Copyright © 2016年 Kuture. All rights reserved.
//

#import "AKNetPackegeAFN.h"
#import "AFNetworking.h"

@interface AKNetPackegeAFN()

@property (nonatomic,strong) AFHTTPSessionManager *manager;

@end

@implementation AKNetPackegeAFN


+(instancetype)shareHttpManager{
    static dispatch_once_t onece = 0;
    static AKNetPackegeAFN *httpManager = nil;
    dispatch_once(&onece, ^(void){
        httpManager = [[self alloc]init];
    });
    return httpManager;
}

//自签名https请求Json数据
- (void)netWorkType:(AKNetWorkType)netWorkType
          Signature:(NSString *)signature
                API:(NSString *)api
         Parameters:(NSDictionary *)parameters
       RequestTimes:(float)requestTimes
            Success:(HttpSuccess)sucess
               Fail:(HttpErro)fail{
    
    /*
     * netWorkType:请求方式 GET 或 POST
     * signature:是否使用签名证书，是的话直接写入证书名字，否的话填nil
     * api:请求的URL接口
     * parameters:请求参数
     * sucess:请求成功时的返回值
     * fail:请求失败时的返回值
     */
    

    //是否允许使用自签名证书和证书验证模式
    AFSecurityPolicy *securityPolicy;
    
    signature == nil || [signature isEqualToString:@""] ? (void)(securityPolicy.allowInvalidCertificates = NO,securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone]):(securityPolicy.allowInvalidCertificates = YES,securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate]);
    
    //是否需要验证域名
    securityPolicy.validatesDomainName = NO;
    
    _manager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:api]];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    _manager.securityPolicy = securityPolicy;
    _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"application/xml",@"text/xml",@"text/json",@"text/plain",@"text/javascript",@"text/html", nil];
    
    
    [_manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    _manager.requestSerializer.timeoutInterval = requestTimes;
    [_manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    if (signature != nil){
        
        __weak typeof(self) weakSelf = self;
        [_manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing *_credential) {
            
            //获取服务器的 trust object
            SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
            
            //导入自签名证书
            NSString *cerPath = [[NSBundle mainBundle] pathForResource:signature ofType:@"cer"];
            NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
            
            if (!cerData) {
                
                NSLog(@"==== 证书为空 ====");
                
                return 0;
            }
            
            //NSArray *cerArray = @[cerData];
            NSSet *cerSetA = [[NSSet alloc]initWithArray:@[cerData]];
            weakSelf.manager.securityPolicy.pinnedCertificates = cerSetA;
            SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)cerData);
            NSCAssert(caRef != nil, @"caRef is nil");
            
            NSArray *caArray = @[(__bridge id)(caRef)];
            NSCAssert(caArray != nil, @"caArray is nil");
            
            //将读取到的证书设置为serverTrust的根证书
            OSStatus status = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)caArray);
            SecTrustSetAnchorCertificatesOnly(serverTrust, NO);
            NSCAssert(errSecSuccess == status, @"SectrustSetAnchorCertificates failed");
            
            //选择质询认证的处理方式
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            __autoreleasing NSURLCredential *credential = nil;
            
            //NSURLAuthenTicationMethodServerTrust质询认证方式
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                //基于客户端的安全策略来决定是否信任该服务器，不信任则不响应质询
                if ([weakSelf.manager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                    
                    //创建质询证书
                    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    
                    //确认质询方式
                    if (credential) {
                        disposition = NSURLSessionAuthChallengeUseCredential;
                        
                    } else {
                        
                        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                    }
                    
                } else {
                    
                    //取消挑战
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }
                
            } else {
                
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
            
            return disposition;
        }];
    }
    
    if (netWorkType == 0){
        
        [_manager GET:api parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if (sucess){
                
                sucess(responseObject);
            }else{
                
                NSLog(@"链接异常或网络不存在");
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            fail(error);
        }];
        
    }else if (netWorkType == 1){
        
        [_manager POST:api parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if (sucess){
                
                sucess(responseObject);
            }else{
                
                NSLog(@"链接异常或网络不存在");
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            fail(error);
        }];
        
    }
}

//单张或多张图片的上传
- (void)uploadPictureWithAPI:(NSString *)api
                   Signature:(NSString *)signature
                  Parameters:(NSDictionary *)parameters
                RequestTimes:(float)requestTimes
                      Images:(NSMutableArray *)images
          CompressionQuality:(float)compression
                    fileName:(NSString *)fileName
                   ImageName:(NSString *)imageName
                   ImageType:(NSString *)imageType
              UploadProgress:(HttpProgress)progress
                     Success:(HttpSuccess)success
                        Fail:(HttpErro)fail{
    
    
    /*
     * api:请求的URL接口
     * signature:是否使用签名证书，是的话直接写入证书名字，否的话填nil
     * parameters:请求参数
     * requestTimes:请求时间
     * images:要上传的图片数组
     * compression:图片压缩倍数(小于等于1)
     * fileName:上传文件名(多张上传时只有一个名字)
     * ImageName:图片名(多张上传时图片名字不相同)
     * imageType:图片的类型(例如.png格式为 : @"image/png")
     * progress:上传进程
     * sucess:请求成功时的返回值
     * fail:请求失败时的返回值
     */

    
    //是否允许使用自签名证书和证书验证模式
    AFSecurityPolicy *securityPolicy;
    
    signature == nil || [signature isEqualToString:@""] ? (void)(securityPolicy.allowInvalidCertificates = NO,securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone]):(securityPolicy.allowInvalidCertificates = YES,securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate]);
    
    //是否需要验证域名
    securityPolicy.validatesDomainName = NO;
    
    _manager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:api]];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    _manager.securityPolicy = securityPolicy;
    _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                          @"application/octet-stream",
                                                          @"application/xml",
                                                          @"text/xml",
                                                          @"text/json",
                                                          @"text/plain",
                                                          @"text/javascript",
                                                          @"text/html",
                                                          @"image/jpeg",
                                                          @"image/png",
                                                          nil];
    
    
    [_manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    _manager.requestSerializer.timeoutInterval = requestTimes;
    [_manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    if (signature != nil){
        
        __weak typeof(self) weakSelf = self;
        [_manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing *_credential) {
            
            //获取服务器的 trust object
            SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
            
            //导入自签名证书
            NSString *cerPath = [[NSBundle mainBundle] pathForResource:signature ofType:@"cer"];
            NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
            
            if (!cerData) {
                
                NSLog(@"==== 证书为空 ====");
                
                return 0;
            }
            
            //NSArray *cerArray = @[cerData];
            NSSet *cerSetA = [[NSSet alloc]initWithArray:@[cerData]];
            weakSelf.manager.securityPolicy.pinnedCertificates = cerSetA;
            SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)cerData);
            NSCAssert(caRef != nil, @"caRef is nil");
            
            NSArray *caArray = @[(__bridge id)(caRef)];
            NSCAssert(caArray != nil, @"caArray is nil");
            
            //将读取到的证书设置为serverTrust的根证书
            OSStatus status = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)caArray);
            SecTrustSetAnchorCertificatesOnly(serverTrust, NO);
            NSCAssert(errSecSuccess == status, @"SectrustSetAnchorCertificates failed");
            
            //选择质询认证的处理方式
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            __autoreleasing NSURLCredential *credential = nil;
            
            //NSURLAuthenTicationMethodServerTrust质询认证方式
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                //基于客户端的安全策略来决定是否信任该服务器，不信任则不响应质询
                if ([weakSelf.manager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                    
                    //创建质询证书
                    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    
                    //确认质询方式
                    if (credential) {
                        disposition = NSURLSessionAuthChallengeUseCredential;
                        
                    } else {
                        
                        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                    }
                    
                } else {
                    
                    //取消挑战
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }
                
            } else {
                
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
            
            return disposition;
        }];
    }
    

#pragma mark ***上传图片***  
    
    [_manager POST:api parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (int i = 0;i < images.count;i++){
            
            NSData *data = UIImageJPEGRepresentation(images[i], compression);
            
            [formData appendPartWithFileData:data name:fileName fileName:[NSString stringWithFormat:@"%@%d",imageName,i] mimeType:imageType];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progress){
            
            progress(uploadProgress);
        }else{
            
            NSLog(@"上传失败");
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        if (success){
            
            success(responseObject);
        }else{
            
            NSLog(@"链接异常或网络不存在");
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (fail){
            
            fail(error);
        }else{
            
             NSLog(@"上传失败,失败原因:%@",error);
        }
    }];
}































@end
