//
//  ViewController.m
//  HttpsSignatureCertificate
//
//  Created by 李亚坤 on 2016/12/13.
//  Copyright © 2016年 Kuture. All rights reserved.
//

#import "ViewController.h"
#import "AKNetPackegeAFN.h"
#import "AKImgUploadView.h"

#define WIDTH  [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollV;
@property (strong, nonatomic) UILabel *contentLable;

@property (nonatomic,strong) AKImgUploadView *upload;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //--为了能上传图片设置了ATS为YES,测试https时可以在info.plist中将其删除--
    
    
    //单张或多张图片上传
    [self uploadPicture];
    
    //自签名https请求Json数据
//    [self loadHttpsJson];
    
}

#pragma makr ***单张或多张图片上传***
- (void)uploadPicture{
    
    //选择视图
    _upload = [[AKImgUploadView alloc]initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
    _upload.backgroundColor = [UIColor whiteColor];
    
    //发送按钮
    UIButton *selectedPic = [[UIButton alloc]initWithFrame:CGRectMake(350, 500, 50, 50)];
    selectedPic.backgroundColor = [UIColor redColor];
    selectedPic.layer.cornerRadius = 10;
    selectedPic.layer.masksToBounds = YES;
    
    [selectedPic setTitle:@"上传" forState:UIControlStateNormal];
    [selectedPic addTarget:self action:@selector(imgSData) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_upload];
    [self.view addSubview:selectedPic];
}

- (void)imgSData{
    
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
    
//    NSString *url = @"https://sm.ms/api/upload"; @"smfile",
//    NSString *url = @"http://chuantu.biz/upload.php";
    NSString *url = @"http://123.56.1.180:9999/api";
    NSMutableDictionary *parmeters = [NSMutableDictionary new];
    [parmeters setValue:@"token" forKey:@"0090990390039020048777589839"];
    [parmeters setValue:@"wbcontext" forKey:@"lsldfkalsdfl;asdf;llkskdjf"];
    
    AKNetPackegeAFN *uploadPic = [AKNetPackegeAFN shareHttpManager];
    
    //选择的图片会存于_upload.images中
    
    [uploadPic uploadPictureWithAPI:url
                          Signature:nil
                         Parameters:parmeters
                       RequestTimes:500.f
                             Images:_upload.images
                 CompressionQuality:0.1 fileName:@"picFile"
                          ImageName:@"picFileFileName"
                          ImageType:@"image/png"
                     UploadProgress:^(NSProgress *uploadProgress) {
                         
                         NSLog(@"=========uploadProgress:%@",uploadProgress);
                     } Success:^(id json) {
                         
                         NSLog(@"====Success:%@",json);
                         
                         UIAlertController *alertV = [UIAlertController alertControllerWithTitle:@"上传成功" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                         UIAlertAction *donev = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:nil];
                         
                         [alertV addAction:donev];
                         [self presentViewController:alertV animated:YES completion:nil];
                         
                     } Fail:^(NSError *error) {
                         
                         NSLog(@"Error====:%@",error);
                     }];
}


#pragma mark ***自签名https请求Json数据***
- (void)loadHttpsJson{
    
    //创建对象
    //如果是自签名证书，使用前先将自签名证书进行绑定（证书直接拖入项目中即可）
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
    
    AKNetPackegeAFN *netHttps = [AKNetPackegeAFN shareHttpManager];
    [netHttps netWorkType:AKNetWorkGET Signature:nil API:@"https://api.map.baidu.com/telematics/v3/weather?location=%E7%BB%A5%E5%BE%B7&output=json&ak=11ffd27d38deda622f51c9d314d46b17" Parameters:nil RequestTimes:2.f Success:^(id json) {
        
        NSLog(@"Json:%@",[self logDic:json]);
        [self contentLabel:json];
    } Fail:^(NSError *error) {
        
        NSLog(@"Error:%@",error);
    }];
}

- (void)contentLabel:(id)content{
    
    _contentLable = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    _contentLable.text = [self logDic:content];
    _contentLable.numberOfLines = 0;
    CGSize maxSize = CGSizeMake(WIDTH - 20,9999);
    CGSize realSize = [_contentLable sizeThatFits:maxSize];
    
    _scrollV.contentSize = realSize;
    _contentLable.frame = CGRectMake(10, 0, realSize.width, realSize.height);
    [_scrollV addSubview:_contentLable];
}

//Unicode编码转中文
- (NSString *)logDic:(NSDictionary *)dic {
    
    if (![dic count]) {
        return nil;
    }
    
    NSString *tempStr1 =
    [[dic description] stringByReplacingOccurrencesOfString:@"\\u"
                                                 withString:@"\\U"];
    NSString *tempStr2 =
    [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *tempStr3 =
    [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *str = [NSPropertyListSerialization propertyListWithData:tempData options:0 format:NULL error:nil];
    return str;
}







@end
