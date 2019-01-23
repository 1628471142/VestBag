//
//  ViewController.m
//  FastLaneTestDemo
//
//  Created by 1 on 2019/1/3.
//  Copyright © 2019 weiyian. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary * infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString * ip = infoDic[@"CustomDomainName"];
    if (ip.length == 0) {
        NSLog(@"warn:网络地址为空");
    }
    WKWebView * webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:ip]];
    [webView loadRequest:request];
    [self.view addSubview:webView];
    
    NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(0, 20 , [UIScreen mainScreen].bounds.size.width, 40)];
    lab.numberOfLines = 0;
    lab.font = [UIFont systemFontOfSize:14];
    lab.textAlignment = NSTextAlignmentCenter;
    lab.backgroundColor = [UIColor redColor];
    lab.textColor = [UIColor whiteColor];
    lab.text = [NSString stringWithFormat:@"ip:%@\nbundleID:%@",ip,bundleID];
    [self.view addSubview:lab];
    
}


@end
