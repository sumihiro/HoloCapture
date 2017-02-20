//
//  HoloDeviceClient.m
//  HoloKeyboard
//
//  Created by Sumihiro Ueda on 2017/02/08.
//

#import "HoloDeviceClient.h"

@import UIKit;

@interface HoloMrcRecording ()

@property (readwrite) HoloMrcRecordingMediaType mediaType;

@end

@implementation HoloMrcRecording

- (void)setFileName:(NSString *)fileName {
    _fileName = fileName;
    
    NSString *ext = [fileName pathExtension];
    if ([ext isEqualToString:@"mp4"]) {
        self.mediaType = HoloMrcRecordingMediaTypeVideo;
    } else {
        self.mediaType = HoloMrcRecordingMediaTypePhoto;
    }
}
- (NSString*)base64EncodedFileName {
    return [[self.fileName dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (NSDate*)creationDate {
    NSDate *refDate = [self refDate];

    return [NSDate dateWithTimeInterval:self.creationTime / 10000000. sinceDate:refDate];
    
}

- (NSDate*)refDate {
#warning will not work
    
    // https://msdn.microsoft.com/en-us/library/windows/desktop/ms724290(v=vs.85).aspx
    
    static NSDate *refDate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        calendar.timeZone = [NSTimeZone systemTimeZone];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.calendar = calendar;
        
        components.year = 1601;
        components.month = 1;
        components.day = 1;
        components.hour = 0;
        components.minute = 0;
        components.second = 0;
        
        refDate = [components date];
    });
    return refDate;
}

@end


@interface HoloDeviceClient () <NSURLSessionDelegate>

@property (nonatomic,copy) NSString *host;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *password;

@property (nonatomic,strong) NSURL *baseUrl;
@property (nonatomic,strong) NSURLSession *session;

@property (nonatomic,copy) NSString *token;

@property (nonatomic,strong) NSDate *windowsRefDate;

@end

@implementation HoloDeviceClient


- (instancetype)initWithHost:(NSString*)host username:(NSString*)username password:(NSString*)password {
    self = [super init];
    if (self) {
        self.host = host;
        self.username = username;
        self.password = password;
        
        self.baseUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@",self.host]];

        NSURLSessionConfiguration *sessionConfig = [self sessionConfiguration];
        self.session =
        [NSURLSession sessionWithConfiguration:sessionConfig delegate:self
                                 delegateQueue:nil];

    }
    return self;
}

#pragma mark -

- (NSURLSessionConfiguration*)sessionConfiguration {
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfig setHTTPAdditionalHeaders:@{
                                              @"Authorization": [self authString]
                                              }
     ];
    return sessionConfig;
}

- (NSURLSessionConfiguration*)backgroundSessionConfiguration {
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[[self class] description]];
    [sessionConfig setHTTPAdditionalHeaders:@{
                                              @"Authorization": [self authString]
                                              }
     ];
    return sessionConfig;
}

- (NSString*)authString {
    NSString *authString = [NSString stringWithFormat:@"%@:%@",
                            self.username,
                            self.password];
    NSData *authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *headerValue = [NSString stringWithFormat: @"Basic %@",
                            [authData base64EncodedStringWithOptions:0]];
    return headerValue;
}

#pragma mark -


- (void)login:(HoloDeviceClientRequestSuccess)success failure:(HoloDeviceClientLoginFailure)failure {
    __weak typeof(self) this = self;
    
    NSURL *url = self.baseUrl;
    [[self.session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (response) {
            NSDictionary *fields = [(NSHTTPURLResponse*)response allHeaderFields];
            NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:fields forURL:response.URL];
            
            for (NSHTTPCookie *cookie in cookies) {
                if ([cookie.name isEqualToString:@"CSRF-Token"]) {
                    NSString *token = cookie.value;
                    self.token = token;
                    
                }
            }
        }

        [this  handleResponseError:(NSHTTPURLResponse*)response error:error success:success failure:failure];
    }] resume];
}

- (void)appendCSRFFieldToRequest:(NSMutableURLRequest*)request {
    NSAssert(self.token != nil, @"CSRF token not found.");
    
    NSDictionary *headers = self.session.configuration.HTTPAdditionalHeaders;
    NSMutableDictionary *mdic = [headers mutableCopy];
    mdic[@"X-CSRF-Token"] = self.token;
    request.allHTTPHeaderFields = mdic;
}


- (void)handleResponseError:(NSHTTPURLResponse*)response error:(NSError*)error success:(HoloDeviceClientRequestSuccess)success failure:(HoloDeviceClientLoginFailure)failure {
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failure(error);
        });
    } else if(response.statusCode != 200) {
        NSError *error = [NSError errorWithDomain:@"error" code:response.statusCode userInfo:@{@"response":response}];
        dispatch_async(dispatch_get_main_queue(), ^{
            failure(error);
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            success();
        });
    }
}


- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    
    NSLog(@"challenge");
    
    if (challenge.previousFailureCount > 1) {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }else {
        NSURLCredential *credential = [NSURLCredential credentialWithUser:self.username
                                                                 password:self.password
                                                              persistence:NSURLCredentialPersistenceForSession];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}


#pragma mark -

- (NSURL*)streamingURL {
    return [self streamingURL:HoloDeviceClientStremQualityNormal holo:YES pv:YES mic:YES loopback:YES];
}

- (NSURL*)streamingURL:(HoloDeviceClientStremQuality)quality holo:(BOOL)holo pv:(BOOL)pv mic:(BOOL)mic loopback:(BOOL)loopback {
    NSString *qualityString = @"";
    if (quality == HoloDeviceClientStremQualityHigh) {
        qualityString = @"_high";
    } else if (quality == HoloDeviceClientStremQualityLow) {
        qualityString = @"_low";
    }
    NSString *dataText = [NSString stringWithFormat:@"https://%@:%@@%@/api/holographic/stream/live%@.mp4?holo=%@&pv=%@&mic=%@&loopback=%@",
                          self.username,
                          self.password,
                          self.host,
                          qualityString,
                          holo ? @"true" : @"false",
                          pv ? @"true" : @"false",
                          mic ? @"true" : @"false",
                          loopback ? @"true" : @"false"
                          ];
    
    NSURL *url = [NSURL URLWithString:dataText relativeToURL:self.baseUrl];
    return url;
}

#pragma mark -

- (void)mrcFiles:(HoloDeviceClientListSuccess)success failure:(HoloDeviceClientLoginFailure)failure {
    __weak typeof(self) this = self;
    
    NSURL *url = [self.baseUrl URLByAppendingPathComponent:@"/api/holographic/mrc/files"];
    [[self.session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [this  handleResponseError:(NSHTTPURLResponse*)response error:error success:^() {
            NSError *error;
            NSDictionary *all = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                failure(error);
                return;
            }
            
            NSMutableArray *recordings = [NSMutableArray array];
            NSArray *items = all[@"MrcRecordings"];
            for (NSDictionary *item in items) {
                HoloMrcRecording *record = [HoloMrcRecording new];
                record.creationTime = [item[@"CreationTime"] longLongValue];
                record.fileName = item[@"FileName"];
                record.fileSize = [item[@"FileSize"] integerValue];
                [recordings insertObject:record atIndex:0];
            }
            
            [recordings sortUsingComparator:^NSComparisonResult(HoloMrcRecording *obj1, HoloMrcRecording *obj2) {
                if (obj1.creationTime > obj2.creationTime) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedDescending;
                }
            }];
            success(recordings);
        } failure:failure];
    }] resume];
}

- (NSURL*)mrcThumbnailURL:(HoloMrcRecording*)recording {
    NSString *dataText = [NSString stringWithFormat:@"https://%@:%@@%@/api/holographic/mrc/thumbnail?filename=%@",
                          self.username,
                          self.password,
                          self.host,
                          recording.base64EncodedFileName
                          ];
    
    NSURL *url = [NSURL URLWithString:dataText relativeToURL:self.baseUrl];
    return url;
}

- (NSURL*)mrcFileURL:(HoloMrcRecording*)recording {
    NSString *dataText = [NSString stringWithFormat:@"https://%@:%@@%@/api/holographic/mrc/file?filename=%@",
                          self.username,
                          self.password,
                          self.host,
                          recording.base64EncodedFileName
                          ];
    
    NSURL *url = [NSURL URLWithString:dataText relativeToURL:self.baseUrl];
    return url;
}

- (void)mrcDelete:(HoloMrcRecording*)recording success:(HoloDeviceClientRequestSuccess)success failure:(HoloDeviceClientLoginFailure)failure {
    __weak typeof(self) this = self;
    
    NSURL *url = [self mrcFileURL:recording];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"DELETE"];
    [self appendCSRFFieldToRequest:request];
    [[self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [this  handleResponseError:(NSHTTPURLResponse*)response error:error success:success failure:failure];
    }] resume];
}

- (void)mrcTakePictureHolo:(BOOL)holo pv:(BOOL)pv success:(HoloDeviceClientRequestSuccess)success failure:(HoloDeviceClientLoginFailure)failure {
    __weak typeof(self) this = self;
    
    NSString *path = [NSString stringWithFormat:@"/api/holographic/mrc/photo?holo=%@&pv=%@",
                            holo ? @"true" : @"false",
                            pv ? @"true" : false
                          ];
    
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [self appendCSRFFieldToRequest:request];
    [[self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [this  handleResponseError:(NSHTTPURLResponse*)response error:error success:success failure:failure];
    }] resume];
}

@end
