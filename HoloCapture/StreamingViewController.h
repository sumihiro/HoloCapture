//
//  StreamingViewController.h
//  HoloCapture
//
//  Created by Sumihiro Ueda on 2017/02/14.
//

#import <UIKit/UIKit.h>
#import "HoloDeviceClient.h"

@interface StreamingViewController : UIViewController

@property (nonatomic,strong) HoloDeviceClient *client;

@end
