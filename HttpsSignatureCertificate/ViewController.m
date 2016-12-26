//
//  ViewController.m
//  HttpsSignatureCertificate
//
//  Created by 李亚坤 on 2016/12/13.
//  Copyright © 2016年 Kuture. All rights reserved.
//

#import "ViewController.h"
#import "AKNetPackegeAFN.h"

@interface ViewController ()

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
     sucess:请求成功时的返回值
     fail:请求失败时的返回值
     *
     */
    
    AKNetPackegeAFN *netHttps = [AKNetPackegeAFN shareHttpManager];
    [netHttps netWorkType:AKNetWorkGET Signature:nil API:@"https://d.jd.com/lab/get?callback=lab" Parameters:nil Success:^(id json) {
        
        NSLog(@"Json:%@",json);
    } Fail:^(NSError *error) {
        
        NSLog(@"Error:%@",error);
    }];
}












@end
