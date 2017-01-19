//
//  AKNetPackegeAFN.h
//  AKPackageAFN
//
//  Created by 李亚坤 on 2016/11/20.
//  Copyright © 2016年 Kuture. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    
    AKNetWorkGET ,   /**< GET请求 */
    AKNetWorkPOST = 1 /**< POST请求 */
}AKNetWorkType;
typedef void (^HttpSuccess)(id json);
typedef void (^HttpErro)(NSError* error);
@interface AKNetPackegeAFN : NSObject

+(instancetype)shareHttpManager;

/*
 *
 netWorkType:请求方式 GET 或 POST
 signature:是否使用签名证书，是的话直接写入证书名字，否的话填nil
 api:请求的URL接口
 parameters:请求参数
 requestTimes:超时时间
 sucess:请求成功时的返回值
 fail:请求失败时的返回值
 *
 */

- (void)netWorkType:(AKNetWorkType)netWorkType Signature:(NSString *)signature API:(NSString *)api Parameters:(NSDictionary *)parameters RequestTimes:(float)requestTimes Success:(HttpSuccess)sucess Fail:(HttpErro)fail;











@end
