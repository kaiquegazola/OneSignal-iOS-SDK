/*
 Modified MIT License

 Copyright 2026 OneSignal

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 1. The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 2. All copies of substantial portions of the Software may only be used in connection
 with services provided by OneSignal.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <XCTest/XCTest.h>
#import "OneSignalFramework.h"
#import <OneSignalCore/OneSignalCore.h>
#import <OneSignalOSCore/OneSignalOSCore-Swift.h>
#import <OneSignalExtension/OneSignalExtension.h>

@interface OneSignal (AutoInitGateTests)
+ (void)setAppId:(nullable NSString*)newAppId;
+ (void)downloadIOSParamsWithAppId:(NSString *)appId;
@end

/// Answers every request synchronously with a fixed ios_params payload.
@interface AutoInitGateParamsClient : NSObject <IOneSignalClient>
@property (nonatomic, copy) NSDictionary *params;
@end

@implementation AutoInitGateParamsClient
- (void)executeRequest:(OneSignalRequest *)request onSuccess:(OSResultSuccessBlock)successBlock onFailure:(OSClientFailureBlock)failureBlock {
    if (successBlock) successBlock(self.params);
}
@end

@interface AutoInitGateTests : XCTestCase
@end

@implementation AutoInitGateTests

static NSString *const kAppId = @"11111111-2222-3333-4444-555555555555";

- (void)setUp {
    [super setUp];
    [OneSignalUserDefaults.initShared saveStringForKey:OSUD_APP_ID withValue:kAppId];
    [OneSignalUserDefaults.initShared removeValueForKey:OSUD_AUTO_INIT_ALLOWED];
    OneSignalIdentifiers.currentAppId = nil;
}

- (void)tearDown {
    [OneSignalUserDefaults.initShared removeValueForKey:OSUD_APP_ID];
    [OneSignalUserDefaults.initShared removeValueForKey:OSUD_AUTO_INIT_ALLOWED];
    OneSignalIdentifiers.currentAppId = nil;
    [super tearDown];
}

- (void)testCachedAppIdIgnoredByDefault {
    [OneSignal initialize:(NSString * _Nonnull)nil withLaunchOptions:nil];
    XCTAssertNil(OneSignalIdentifiers.currentAppId);
    [OneSignal setAppId:nil];
    XCTAssertNil(OneSignalIdentifiers.currentAppId);
}

- (void)testCachedAppIdUsedWhenAllowed {
    [OneSignal setAutoInitAllowed:YES];
    [OneSignal setAppId:nil];
    XCTAssertEqualObjects(OneSignalIdentifiers.currentAppId, kAppId);
}

- (void)testSetAutoInitAllowedNoBlocksAgain {
    [OneSignal setAutoInitAllowed:YES];
    [OneSignal setAutoInitAllowed:NO];
    [OneSignal setAppId:nil];
    XCTAssertNil(OneSignalIdentifiers.currentAppId);
}

- (void)testReceiveReceiptSkippedWhenNotAllowed {
    __block BOOL failed = NO;
    [[OneSignalReceiveReceiptsController new] sendReceiveReceiptWithPlayerId:@"player" notificationId:@"notif" appId:kAppId delay:0 successBlock:nil failureBlock:^(NSError *error) {
        failed = YES;
    }];
    XCTAssertTrue(failed);
}

- (void)testReceiveReceiptRechecksGateAfterDelay {
    [OneSignalUserDefaults.initShared saveBoolForKey:OSUD_RECEIVE_RECEIPTS_ENABLED withValue:YES];
    [OneSignal setAutoInitAllowed:YES];
    XCTestExpectation *skipped = [self expectationWithDescription:@"receipt skipped after delay"];
    [[OneSignalReceiveReceiptsController new] sendReceiveReceiptWithPlayerId:@"player" notificationId:@"notif" appId:kAppId delay:1 successBlock:^(NSDictionary *result) {
        XCTFail(@"receipt must not be sent");
    } failureBlock:^(NSError *error) {
        // nil error = skipped by the gate; a sent request would fail with a network/HTTP error
        XCTAssertNil(error);
        [skipped fulfill];
    }];
    // Disallowed during the delay, before the request is executed
    [OneSignal setAutoInitAllowed:NO];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    [OneSignalUserDefaults.initShared removeValueForKey:OSUD_RECEIVE_RECEIPTS_ENABLED];
}

- (void)testClosingGateSilencesEvenWhenRemoteParamsDidNotRequireConsent {
    // ios_params already stored "consent not required" and consent was granted.
    [[OSRemoteParamController sharedController] saveRemoteParams:@{IOS_REQUIRES_USER_PRIVACY_CONSENT: @NO}];
    [[OSRemoteParamController sharedController] savePrivacyConsentRequired:NO];
    [OSPrivacyConsentController consentGranted:YES];
    [OneSignalUserDefaults.initShared saveBoolForKey:OSUD_RECEIVE_RECEIPTS_ENABLED withValue:YES];
    XCTAssertFalse([OSPrivacyConsentController requiresUserPrivacyConsent]);

    [OneSignal setAutoInitAllowed:NO];

    // Non-GET requests (sessions, user updates, receipts) are now blocked.
    XCTAssertTrue([OSPrivacyConsentController requiresUserPrivacyConsent]);
    XCTAssertFalse([OneSignalUserDefaults.initShared getSavedBoolForKey:OSUD_RECEIVE_RECEIPTS_ENABLED defaultValue:YES]);
    XCTAssertEqualObjects([OSResilientStorage stringForKey:OSResilientStorage.keyReceiveReceiptsEnabled], @"0");

    // Giving consent again resumes.
    [OSPrivacyConsentController consentGranted:YES];
    XCTAssertFalse([OSPrivacyConsentController requiresUserPrivacyConsent]);

    [OneSignalUserDefaults.initShared removeValueForKey:OSUD_REQUIRES_USER_PRIVACY_CONSENT];
    [OneSignalUserDefaults.initShared removeValueForKey:GDPR_CONSENT_GRANTED];
    [OneSignalUserDefaults.initShared removeValueForKey:OSUD_RECEIVE_RECEIPTS_ENABLED];
}

- (void)testIosParamsDoNotUndoSilencingWhileGateClosed {
    [OneSignal setAutoInitAllowed:NO];
    AutoInitGateParamsClient *client = [AutoInitGateParamsClient new];
    client.params = @{IOS_REQUIRES_USER_PRIVACY_CONSENT: @NO, IOS_RECEIVE_RECEIPTS_ENABLE: @YES};
    [OneSignalCoreImpl setSharedClient:client];

    [OneSignal downloadIOSParamsWithAppId:kAppId];

    XCTAssertTrue([OSPrivacyConsentController requiresUserPrivacyConsent]);
    XCTAssertFalse([OneSignalUserDefaults.initShared getSavedBoolForKey:OSUD_RECEIVE_RECEIPTS_ENABLED defaultValue:YES]);

    // With the gate open, ios_params apply as upstream.
    [OneSignal setAutoInitAllowed:YES];
    [OneSignal downloadIOSParamsWithAppId:kAppId];
    XCTAssertTrue([OneSignalUserDefaults.initShared getSavedBoolForKey:OSUD_RECEIVE_RECEIPTS_ENABLED defaultValue:NO]);
    XCTAssertFalse([OneSignalUserDefaults.initShared getSavedBoolForKey:OSUD_REQUIRES_USER_PRIVACY_CONSENT defaultValue:YES]);

    [OneSignalCoreImpl setSharedClient:OneSignalClient.sharedClient];
    [OneSignalUserDefaults.initShared removeValueForKey:OSUD_REQUIRES_USER_PRIVACY_CONSENT];
    [OneSignalUserDefaults.initShared removeValueForKey:GDPR_CONSENT_GRANTED];
    [OneSignalUserDefaults.initShared removeValueForKey:OSUD_RECEIVE_RECEIPTS_ENABLED];
}

@end
