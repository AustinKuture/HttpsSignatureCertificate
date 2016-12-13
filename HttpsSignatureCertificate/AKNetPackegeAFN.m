//
//  AKNetPackegeAFN.m
//  AKPackageAFN
//
//  Created by 李亚坤 on 2016/11/20.
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

- (void)netWorkType:(AKNetWorkType)netWorkType Signature:(NSString *)signature API:(NSString *)api Parameters:(NSDictionary *)parameters Success:(HttpSuccess)sucess Fail:(HttpErro)fail{
    
    //开启证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    
    //是否允许使用自签名证书
    signature == nil ? (void)(securityPolicy.allowInvalidCertificates = NO):(securityPolicy.allowInvalidCertificates = YES);
    
    //是否需要验证域名
    securityPolicy.validatesDomainName = NO;
    
    _manager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:api]];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    _manager.securityPolicy = securityPolicy;
    _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"application/xml",@"text/xml",@"text/json",@"text/plain",@"text/javascript",@"text/html", nil];
    
    if (signature != nil){
        
        __weak typeof(self) weakSelf = self;
        [_manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing *_credential) {
            
            //获取服务器的 trust object
            SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
            
            //导入自签名证书
            NSString *cerPath = [[NSBundle mainBundle] pathForResource:signature ofType:@"cer"];
            NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
            
            if (!cerData) {
                
                NSLog(@"==== .cer file is nil ====");
                
                return 0;
            }
            
            NSArray *cerArray = @[cerData];
            weakSelf.manager.securityPolicy.pinnedCertificates = cerArray;
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
        
        [_manager GET:api parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if (sucess){
                
                sucess(responseObject);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (fail){
                
                fail(error);
            }
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


@end
