//
//  AKNetPackegeAFN.h
//  AKPackageAFN
//
//  Created by 李亚坤 on 2016/10/20.
//  Copyright © 2016年 Kuture. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    
    /**
     * GET请求
     */
    AKNetWorkGET ,
    
    /**
     * POST 请求
     */
    AKNetWorkPOST = 1
}AKNetWorkType;

/**
 * 请求成功时的返回值
 */
typedef void (^HttpSuccess)(id json);

/**
 * 请求失败时的返回值
 */
typedef void (^HttpErro)(NSError* error);

/**
 * 当前传输进程的返回值
 */
typedef void (^HttpProgress)(NSProgress* uploadProgress);


@interface AKNetPackegeAFN : NSObject

/**
 * 单例
 */
+(instancetype)shareHttpManager;

/**
 *
 * 自签名https请求Json数据
 *
 */
- (void)netWorkType:(AKNetWorkType)netWorkType
          Signature:(NSString *)signature
                API:(NSString *)api
         Parameters:(NSDictionary *)parameters
       RequestTimes:(float)requestTimes
            Success:(HttpSuccess)sucess
               Fail:(HttpErro)fail;

/**
 *
 * 单张或多张图片的上传
 *
 */
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
                        Fail:(HttpErro)fail;

















@end
