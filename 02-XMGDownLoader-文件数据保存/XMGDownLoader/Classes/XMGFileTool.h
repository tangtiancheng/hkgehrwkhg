//
//  XMGFileTool.h
//  XMGDownLoader
//
//  Created by 小码哥 on 2017/1/8.
//  Copyright © 2017年 xmg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMGFileTool : NSObject

    + (BOOL)fileExists:(NSString *)filePath;
    
    + (long long)fileSize:(NSString *)filePath;
    
    
    + (void)moveFile:(NSString *)fromPath toPath:(NSString *)toPath;
    
    + (void)removeFile:(NSString *)filePath;
@end
