//
//  ViewController.m
//  XMGDownLoader
//
//  Created by 小码哥 on 2017/1/8.
//  Copyright © 2017年 xmg. All rights reserved.
//

#import "ViewController.h"
#import "XMGDownLoader.h"

@interface ViewController ()

    @property (nonatomic, strong) XMGDownLoader *downLoader;
    
@end

@implementation ViewController

    - (XMGDownLoader *)downLoader {
        if (!_downLoader) {
            _downLoader = [XMGDownLoader new];
        }
        return _downLoader;
    }
    
    
- (void)viewDidLoad {
    [super viewDidLoad];
   
    
    
    
    
}

    
    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
        
        NSURL *url = [NSURL URLWithString:@"http://free2.macx.cn:8281/tools/photo/SnapNDragPro418.dmg"];
//        [XMGDownLoader downLoader:url];
        [self.downLoader downLoader:url];
        
        
        
    }
    

@end
