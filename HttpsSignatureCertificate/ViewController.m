//
//  ViewController.m
//  HttpsSignatureCertificate
//
//  Created by 李亚坤 on 2016/12/13.
//  Copyright © 2016年 Kuture. All rights reserved.
//

#import "ViewController.h"
#import "AKNetPackegeAFN.h"

#define WIDTH  [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollV;
@property (strong, nonatomic) UILabel *contentLable;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

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
