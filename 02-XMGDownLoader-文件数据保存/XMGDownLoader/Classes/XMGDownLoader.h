//
//  XMGDownLoader.h
//  XMGDownLoader
//
//  Created by 小码哥 on 2017/1/8.
//  Copyright © 2017年 xmg. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XMGDownLoaderDelegate <NSObject>

- (void)downloadData:(NSString *)path;


@end

@interface XMGDownLoader : NSObject

    
- (void)downLoader:(NSURL *)url;

@property (nonatomic, weak) id<XMGDownLoaderDelegate> delegate;
    
    
@end
