//
//  LibraryViewController.h
//  HoloCapture
//
//  Created by 上田 澄博 on 2017/02/20.
//  Copyright © 2017年 Sumihiro Ueda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HoloDeviceClient.h"

@interface LibraryViewController : UICollectionViewController

@property (nonatomic,strong) HoloDeviceClient *client;

@end
