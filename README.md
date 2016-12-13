# HttpsSignatureCertificate
##iOS 使用AFN对自签名证书进行验证的封装

##摘要##
在WWDC 2016开发者大会上，苹果宣布了一个最后期限：到2017年1月1日 App Store中的所有应用都必须启用 App Transport Security安全功能。**App Transport Security（ATS）**是苹果在iOS 9中引入的一项隐私保护功能，屏蔽明文HTTP资源加载，连接必须经过更安全的HTTPS。苹果目前允许开发者暂时关闭ATS，可以继续使用HTTP连接，但到年底所有官方商店的应用都必须强制性使用ATS。 

项目中使用的框架是AFNetworking 3.0及以上版本，由于ATS的原因，iOS只允许使用Https开头的链接，在2016年12月30日以前苹果允许绕开ATS，如下图所示：
![MacDown](https://static.oschina.net/uploads/space/2016/1212/145057_MOH4_2728740.png)

但是从2017年1月1日开始将不再接受使用http加载资源的应用，因此本篇文章主要讲解如何使用AFN进行自签名证书的通过认证（注：对于使用CA机构认证的证书不需要进行认证，直接使用Https开头的链接进行数据访问和加载页面即可）

###1 建立一个根类 此处命名为AKNetPackegeAFN

 * 1>  .h文件 ,创建所需要的Get 与 Post 方法
     
     ```
     #import <Foundation/Foundation.h>
     
     typedef void (^HttpSuccess)(id json);
     typedef void (^HttpErro)(NSError* error);
	  @interface AKNetPackegeAFN : NSObject
	  
     +(instancetype)shareHttpManager;
     - (void)postWith:(NSString *)api Parameters:(NSDictionary *)parameters Success:(HttpSuccess)sucess Fail:(HttpErro)fail;
     - (void)getWith:(NSString *)api Parameters:(NSDictionary *)parameters Success:(HttpSuccess)sucess Fail:(HttpErro)fail;
     @end
     
     
     
* 2> .m文件，导入头文件AFNetworking.h 新建Manager 属性并实现shareHttpManager类方法

   ```
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


###2 Get 与Post 方法的实现
* 1> Post 方法，使用时将后台所给的证书转换为 .cer格式 拖入项目根目录中，在方法中进行绑定即可例如后台给的证书名为：Kuture.crt  收到证书后双击进行安装，然后打开钥匙串，将名为Kuture的证书右击导出，选择后缀为.cer 然后确定即可 如下图所示：

  ![MacDown one](https://static.oschina.net/uploads/space/2016/1212/150519_EWHB_2728740.png) --> ![MacDown two](https://static.oschina.net/uploads/space/2016/1212/150736_GvZ4_2728740.png) -->  ![MacDown three](https://static.oschina.net/uploads/space/2016/1212/150817_zVDP_2728740.png) --> ![MacDown four] (https://static.oschina.net/uploads/space/2016/1212/150837_EZdf_2728740.png) 
  
  ```
  - (void)postWith:(NSString *)api Parameters:(NSDictionary *)parameters Success:(HttpSuccess)sucess Fail:(HttpErro)fail{
    
    //开启证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    
    //是否允许使用自签名证书
    securityPolicy.allowInvalidCertificates = YES;
    
    //是否需要验证域名
    securityPolicy.validatesDomainName = NO;
    
    _manager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:api]];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    _manager.securityPolicy = securityPolicy;
    _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"application/xml",@"text/xml",@"text/json",@"text/plain",@"text/javascript",@"text/html", nil];
    
    __weak typeof(self) weakSelf = self;
    [_manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing *_credential) {
        
        //获取服务器的 trust object
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        
        //导入自签名证书
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"你的证书名字" ofType:@"cer"];
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

* 2> Get 方法的实现方式与Post 方法雷同，代码如下

  ```
  - (void)getWith:(NSString *)api Parameters:(NSDictionary *)parameters Success:(HttpSuccess)sucess Fail:(HttpErro)fail{
    
    //开启证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    
    //是否允许使用自签名证书
    securityPolicy.allowInvalidCertificates = YES;
    
    //是否需要验证域名
    securityPolicy.validatesDomainName = NO;
    
    _manager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:api]];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    _manager.securityPolicy = securityPolicy;
    _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"application/xml",@"text/xml",@"text/json",@"text/plain",@"text/javascript",@"text/html", nil];
    
    __weak typeof(self) weakSelf = self;
    [_manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing *_credential) {
        
        //获取服务器的 trust object
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        
        //导入自签名证书
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"你的证书名字" ofType:@"cer"];
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
}

### 3 使用方法，在需要进行数据获取或传递的类里面，直接导入头文件 AKNetPackegeAFN.h ，并实现方法即可，如下所示：

  ```
  AKNetPackegeAFN *netPack = [AKNetPackegeAFN shareHttpManager];
    [netPack postWith:_singleBaseUrl Parameters:nil Success:^(id json) {
        
       NSLog(@"Json:%@",json);//此处便是从服务端获取的数据，方法中已经进行过序列化了，此时的json里是一个数组格式
        
    } Fail:^(NSError *error) {
        
        NSLog(@"Error:%@",error);
    }];

























