//
//  ViewController.m
//  XMGDownLoader
//
//  Created by 小码哥 on 2017/1/8.
//  Copyright © 2017年 xmg. All rights reserved.
//

#import "ViewController.h"
#import "XMGDownLoader.h"

#import <AVFoundation/AVFoundation.h>


@interface ViewController ()<XMGDownLoaderDelegate>

@property (nonatomic, strong) XMGDownLoader *downLoader;

@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioPlayerNode *playerNode;



    
@end

@implementation ViewController

- (XMGDownLoader *)downLoader {
    if (!_downLoader) {
        _downLoader = [XMGDownLoader new];
        _downLoader.delegate = self;
    }
    return _downLoader;
}
    
    
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.engine = [[AVAudioEngine alloc] init];
    self.playerNode = [[AVAudioPlayerNode alloc] init];
    
    [self.engine attachNode:self.playerNode];
    [self.engine connect:self.playerNode to:self.engine.mainMixerNode format:nil];
    
    // 安装音频缓冲区的处理
    AVAudioFormat *format = [self.engine.mainMixerNode inputFormatForBus:0];
    [self.playerNode installTapOnBus:0 bufferSize:4096 format:format block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        [self processAudioBuffer:buffer];
    }];
    
    NSError *error = nil;
    if (![self.engine startAndReturnError:&error]) {
        NSLog(@"Audio Engine error: %@", error.localizedDescription);
    }
    [self.playerNode play];
    
    
    
    // Do any additional setup after loading the view.
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 100, 100, 100)];
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"下载播放" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(downAndPlayAudio) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
}


- (void)downAndPlayAudio {
    NSURL *url1 = [NSURL URLWithString:@"http://cdnringhs.shoujiduoduo.com/ringres/userv1/m96/482/317324482.mp3"];//短mp3音频
    NSURL *url2 = [NSURL URLWithString:@"http://cdnringhs.shoujiduoduo.com/ringres/userv1/m96/290/315379290.mp3"];//长mp3音频
    [self.downLoader downLoader:url2];
}

- (void)playWithUrl:(NSURL *)url {
    
    NSError *error = nil;
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:url error:&error];
    if (error) {
        NSLog(@"Audio file error: %@", error.localizedDescription);
        return;
    }
    
    [self.playerNode scheduleFile:file atTime:nil completionHandler:^{
        NSLog(@"播放完成");
    }];
}



- (void)processAudioBuffer:(AVAudioPCMBuffer *)buffer {
    AVAudioChannelCount channelCount = buffer.format.channelCount;
    if (channelCount > 0) {
        float *channelData = buffer.floatChannelData[0];
        NSUInteger frameLength = buffer.frameLength;
        
        NSMutableArray<NSNumber *> *channelDataArray = [NSMutableArray arrayWithCapacity:frameLength];
        for (NSUInteger i = 0; i < frameLength; i++) {
            [channelDataArray addObject:@(channelData[i])];
        }
        
        float rms = 0;
        for (NSNumber *value in channelDataArray) {
            rms += value.floatValue * value.floatValue;
        }
        rms = sqrt(rms / frameLength);
        float avgPower = 20 * log10(rms);

        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"Current audio power: %f dB", avgPower);
            // 你可以在这里更新UI，如进度条或波动图
        });
    }
}


    
 

    
#pragma mark - XMGDownLoaderDelegate

- (void)downloadData:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    [self playWithUrl:url];
        
}


@end
