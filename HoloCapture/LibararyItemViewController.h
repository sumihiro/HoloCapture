//
//  LibararyItemViewController.h
//  HoloCapture
//
//  Created by 上田 澄博 on 2017/02/20.
//  Copyright © 2017年 Sumihiro Ueda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HoloDeviceClient.h"

@interface LibararyItemViewController : UIViewController

@property (nonatomic,strong) HoloDeviceClient *client;
@property (nonatomic,strong) HoloMrcRecording *reording;

@end
