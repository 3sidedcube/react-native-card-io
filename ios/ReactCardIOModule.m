#import "ReactCardIOModule.h"
#import <React/RCTUtils.h>
#import <React/RCTUIManager.h>
#import <React/RCTConvert.h>
#import "UIWindow+VisibleViewController.h"

@interface ReactCardIOModule ()

@property (nonatomic, strong) RCTPromiseResolveBlock resolveScan;
@property (nonatomic, strong) RCTPromiseRejectBlock rejectScan;

@end

@implementation ReactCardIOModule

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.scanRequests = [NSMutableDictionary new];
    }
    return self;
}

RCT_REMAP_METHOD(canScan, canScanWithResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    if ([CardIOUtilities canReadCardWithCamera]) {
        resolve(@"Card Scanning is enabled");
    } else {
        reject(@"ReactCardIOModule",@"Card Scanning is not enabled", nil);
    }
}

- (BOOL)optionalBooleanFromOptions:(NSDictionary *)option forKey:(NSString *)key defaultValue:(BOOL)value
{
    if (option && [option isKindOfClass:[NSDictionary class]] && option[key] && [option[key] isKindOfClass:[NSNumber class]]) {
        return [option[key] boolValue];
    }
    return value;
}

- (NSString *)optionalStringFromOptions:(NSDictionary *)option forKey:(NSString *)key defaultValue:(NSString *)value
{
    if (option && [option isKindOfClass:[NSDictionary class]] && option[key] && [option[key] isKindOfClass:[NSString class]]) {
        return option[key];
    }
    return value;
}

RCT_EXPORT_METHOD(scan:(id)config resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    UIViewController *controller = RCTKeyWindow().visibleViewController;
    
    // Careful here, default value must be true in order for it to correctly transfer to true
    BOOL useCamera = ![self optionalBooleanFromOptions:config forKey:@"noCamera" defaultValue:false];
    
    CardIOPaymentViewController *paymentVC = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self scanningEnabled:useCamera];
    paymentVC.collectExpiry = [self optionalBooleanFromOptions:config forKey:@"requireExpiry" defaultValue:false];
    paymentVC.collectCVV = [self optionalBooleanFromOptions:config forKey:@"requireCVV" defaultValue:false];
    paymentVC.collectPostalCode = [self optionalBooleanFromOptions:config forKey:@"requirePostalCode" defaultValue:false];
    paymentVC.disableManualEntryButtons = [self optionalBooleanFromOptions:config forKey:@"supressManual" defaultValue:false];
    paymentVC.restrictPostalCodeToNumericOnly = [self optionalBooleanFromOptions:config forKey:@"restrictPostalCodeToNumericOnly" defaultValue:false];
    paymentVC.keepStatusBarStyleForCardIO = [self optionalBooleanFromOptions:config forKey:@"keepApplicationTheme" defaultValue:false];
    paymentVC.collectCardholderName = [self optionalBooleanFromOptions:config forKey:@"requireCardholderName" defaultValue:false];
    // Careful here, default value must be true in order for it to correctly transfer to false
    paymentVC.useCardIOLogo = [self optionalBooleanFromOptions:config forKey:@"useCardIOLogo" defaultValue:false];
    paymentVC.hideCardIOLogo = [self optionalBooleanFromOptions:config forKey:@"hideCardIOLogo" defaultValue:true];
    paymentVC.scanExpiry = [self optionalBooleanFromOptions:config forKey:@"scanExpiry" defaultValue:false];
    paymentVC.suppressScanConfirmation = [self optionalBooleanFromOptions:config forKey:@"suppressConfirmation" defaultValue:false];
    paymentVC.suppressScannedCardImage = [self optionalBooleanFromOptions:config forKey:@"suppressScannedCardImage" defaultValue:false];
    
    paymentVC.scanInstructions = [self optionalStringFromOptions:config forKey:@"scanInstructions" defaultValue:nil];
    paymentVC.languageOrLocale = [self optionalStringFromOptions:config forKey:@"languageOrLocale" defaultValue:nil];
    
    if (config && config[@"guideColor"]) {
        paymentVC.guideColor = [RCTConvert UIColor:config[@"guideColor"]];
    }
    
    self.resolveScan = resolve;
    self.rejectScan = reject;
    
    [controller presentViewController:paymentVC animated:true completion:nil];
}

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)paymentViewController
{
    [paymentViewController dismissViewControllerAnimated:true completion:nil];
    self.rejectScan(@"card scan cancelled", @"card scan was cancelled", nil);
    self.resolveScan = nil;
    self.rejectScan = nil;
}

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)cardInfo inPaymentViewController:(CardIOPaymentViewController *)paymentViewController
{
    [paymentViewController dismissViewControllerAnimated:true completion:nil];
    
    NSMutableDictionary *cardInfoDictionary = [NSMutableDictionary new];
    
    if (cardInfo.cardNumber) {
        cardInfoDictionary[@"cardNumber"] = cardInfo.cardNumber;
    }
    
    cardInfoDictionary[@"cardType"] = @(cardInfo.cardType);
    
    if (cardInfo.redactedCardNumber) {
        cardInfoDictionary[@"redactedCardNumber"] = cardInfo.redactedCardNumber;
    }
    
    if (cardInfo.expiryYear) {
        cardInfoDictionary[@"expiryYear"] = @(cardInfo.expiryYear);
    }
    
    if (cardInfo.expiryMonth) {
        cardInfoDictionary[@"expiryMonth"] = @(cardInfo.expiryMonth);
    }
    
    if (cardInfo.cvv) {
        cardInfoDictionary[@"cvv"] = cardInfo.cvv;
    }
    
    if (cardInfo.postalCode) {
        cardInfoDictionary[@"postalCode"] = cardInfo.postalCode;
    }
    
    if (cardInfo.cardholderName) {
        cardInfoDictionary[@"cardHolderName"] = cardInfo.cardholderName;
    }
    
    self.resolveScan(cardInfoDictionary);
    self.resolveScan = nil;
    self.rejectScan = nil;
}

@end
