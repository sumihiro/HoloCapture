//
//  HoloDeviceClient.m
//  HoloKeyboard
//
//  Created by Sumihiro Ueda on 2017/02/08.
//

#import "HoloDeviceClient.h"


@interface HoloDeviceClient () <NSURLSessionDelegate>

@property (nonatomic,copy) NSString *host;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *password;

@property (nonatomic,strong) NSURL *baseUrl;
@property (nonatomic,strong) NSURLSession *session;

@property (nonatomic,copy) NSString *token;

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


- (void)login:(HoloDeviceClientLoginSuccess)success failure:(HoloDeviceClientLoginFailure)failure {
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


- (void)handleResponseError:(NSHTTPURLResponse*)response error:(NSError*)error success:(HoloDeviceClientLoginSuccess)success failure:(HoloDeviceClientLoginFailure)failure {
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

@end
