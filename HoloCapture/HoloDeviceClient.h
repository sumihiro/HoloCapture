//
//  HoloDeviceClient.h
//  HoloKeyboard
//
//  Created by Sumihiro Ueda on 2017/02/08.
//

#import <Foundation/Foundation.h>

@import AVFoundation;

typedef void(^HoloDeviceClientLoginSuccess)();
typedef void(^HoloDeviceClientLoginFailure)(NSError *error);

typedef enum : int {
    HoloDeviceClientSpecialCharBackSpace = 0x08,
    HoloDeviceClientSpecialCharTab = 0x09,
    HoloDeviceClientSpecialCharLineFeed = 0x0A,
    HoloDeviceClientSpecialCharCarriageReturn = 0x0D,
    HoloDeviceClientSpecialCharUnitSeparator = 0x1F,
    HoloDeviceClientSpecialCharUnitSpace = 0x20,
} HoloDeviceClientSpecialChar;

typedef int HoloDeviceClientKeyCode;


typedef enum : NSUInteger {
    HoloDeviceClientStremQualityNormal = 0,
    HoloDeviceClientStremQualityHigh = 1,
    HoloDeviceClientStremQualityLow = 2,
} HoloDeviceClientStremQuality;

@interface HoloDeviceClient : NSObject

- (instancetype)initWithHost:(NSString*)host username:(NSString*)username password:(NSString*)password;

// Configuration

- (NSURLSessionConfiguration*)sessionConfiguration;
- (NSURLSessionConfiguration*)backgroundSessionConfiguration;

// Common
- (void)login:(HoloDeviceClientLoginSuccess)success failure:(HoloDeviceClientLoginFailure)failure;

// Mixed Reality Capture
- (NSURL*)streamingURL;
- (NSURL*)streamingURL:(HoloDeviceClientStremQuality)quality holo:(BOOL)holo pv:(BOOL)pv mic:(BOOL)mic loopback:(BOOL)loopback;

@end
