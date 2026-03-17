//
//  RNSapling.m
//  react-native-sapling
//

#import "RNSapling.h"

#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#elif __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import "React/RCTBridgeModule.h"
#endif

// Generated Swift header for RNSaplingBridge (name depends on pod/module)
#if __has_include(<react_native_sapling/react_native_sapling-Swift.h>)
#import <react_native_sapling/react_native_sapling-Swift.h>
#elif __has_include("react_native_sapling-Swift.h")
#import "react_native_sapling-Swift.h"
#elif __has_include("RNSapling-Swift.h")
#import "RNSapling-Swift.h"
#else
#import "react-native_sapling-Swift.h"
#endif

@implementation RNSapling

RCT_EXPORT_MODULE(RNSapling)

static void invokeCallback(RCTResponseSenderBlock callback, NSString *error, id result) {
  if (error) {
    callback(@[ error, [NSNull null] ]);
  } else {
    callback(@[ [NSNull null], result ?: [NSNull null] ]);
  }
}

RCT_EXPORT_METHOD(getProofAuthorizingKey:(NSString *)spendingKeyB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getProofAuthorizingKey:spendingKeyB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(verifyCommitment:(NSString *)commitmentB64 addressB64:(NSString *)addressB64 value:(nonnull NSNumber *)value rcmB64:(NSString *)rcmB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge verifyCommitment:commitmentB64 addressB64:addressB64 value:value rcmB64:rcmB64 completion:^(NSString *result, NSString *error) {
    if (error) {
      callback(@[ error, [NSNull null] ]);
    } else {
      callback(@[ [NSNull null], @([result isEqualToString:@"1"]) ]);
    }
  }];
}

RCT_EXPORT_METHOD(initParameters:(NSString *)spendParametersB64 outputParametersB64:(NSString *)outputParametersB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge initParameters:spendParametersB64 outputB64:outputParametersB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(keyAgreement:(NSString *)pB64 skB64:(NSString *)skB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge keyAgreement:pB64 skB64:skB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(merkleHash:(nonnull NSNumber *)depth lhsB64:(NSString *)lhsB64 rhsB64:(NSString *)rhsB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge merkleHash:depth lhsB64:lhsB64 rhsB64:rhsB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(computeNullifier:(NSString *)viewingKeyB64 addressB64:(NSString *)addressB64 value:(nonnull NSNumber *)value rcmB64:(NSString *)rcmB64 position:(nonnull NSNumber *)position callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge computeNullifier:viewingKeyB64 addressB64:addressB64 value:value rcmB64:rcmB64 position:position completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(prepareOutputDescription:(NSString *)contextIdStr viewingKeyB64:(NSString *)viewingKeyB64 addressB64:(NSString *)addressB64 rcmB64:(NSString *)rcmB64 value:(nonnull NSNumber *)value callback:(RCTResponseSenderBlock)callback) {
  NSNumber *contextId = @([contextIdStr integerValue]);
  [RNSaplingBridge prepareOutputDescription:contextId viewingKeyB64:viewingKeyB64 addressB64:addressB64 rcmB64:rcmB64 value:value completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(preparePartialOutputDescription:(NSString *)contextIdStr addressB64:(NSString *)addressB64 rcmB64:(NSString *)rcmB64 eskB64:(NSString *)eskB64 value:(nonnull NSNumber *)value callback:(RCTResponseSenderBlock)callback) {
  NSNumber *contextId = @([contextIdStr integerValue]);
  [RNSaplingBridge preparePartialOutputDescription:contextId addressB64:addressB64 rcmB64:rcmB64 eskB64:eskB64 value:value completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(deriveEpkFromEsk:(NSString *)diversifierB64 eskB64:(NSString *)eskB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge deriveEpkFromEsk:diversifierB64 eskB64:eskB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(getPaymentAddress:(NSString *)viewingKeyB64 indexB64:(NSString *)indexB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getPaymentAddress:viewingKeyB64 indexB64:indexB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(getNextPaymentAddress:(NSString *)viewingKeyB64 indexB64:(NSString *)indexB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getNextPaymentAddress:viewingKeyB64 indexB64:indexB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(getRawPaymentAddress:(NSString *)incomingViewingKeyB64 diversifierB64:(NSString *)diversifierB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getRawPaymentAddress:incomingViewingKeyB64 diversifierB64:diversifierB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(getDiversifierFromRawPaymentAddress:(NSString *)addressB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getDiversifierFromRawPaymentAddress:addressB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(getPkdFromRawPaymentAddress:(NSString *)addressB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getPkdFromRawPaymentAddress:addressB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(initProvingContext:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge initProvingContextWithCompletion:^(NSNumber *result, NSString *error) {
    if (error) {
      callback(@[ error, [NSNull null] ]);
    } else {
      callback(@[ [NSNull null], [result stringValue] ]);
    }
  }];
}

RCT_EXPORT_METHOD(dropProvingContext:(NSString *)contextIdStr callback:(RCTResponseSenderBlock)callback) {
  NSNumber *contextId = @([contextIdStr integerValue]);
  [RNSaplingBridge dropProvingContext:contextId completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(randR:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge randRWithCompletion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(createBindingSignature:(NSString *)contextIdStr balance:(nonnull NSNumber *)balance sighashB64:(NSString *)sighashB64 callback:(RCTResponseSenderBlock)callback) {
  NSNumber *contextId = @([contextIdStr integerValue]);
  [RNSaplingBridge createBindingSignature:contextId balance:balance sighashB64:sighashB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(prepareSpendDescriptionWithSpendingKey:(NSString *)contextIdStr spendingKeyB64:(NSString *)spendingKeyB64 addressB64:(NSString *)addressB64 rcmB64:(NSString *)rcmB64 arB64:(NSString *)arB64 value:(nonnull NSNumber *)value anchorB64:(NSString *)anchorB64 merklePathB64:(NSString *)merklePathB64 callback:(RCTResponseSenderBlock)callback) {
  NSNumber *contextId = @([contextIdStr integerValue]);
  [RNSaplingBridge prepareSpendDescriptionWithSpendingKey:contextId spendingKeyB64:spendingKeyB64 addressB64:addressB64 rcmB64:rcmB64 arB64:arB64 value:value anchorB64:anchorB64 merklePathB64:merklePathB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(prepareSpendDescriptionWithAuthorizingKey:(NSString *)contextIdStr authorizingKeyB64:(NSString *)authorizingKeyB64 addressB64:(NSString *)addressB64 rcmB64:(NSString *)rcmB64 arB64:(NSString *)arB64 value:(nonnull NSNumber *)value anchorB64:(NSString *)anchorB64 merklePathB64:(NSString *)merklePathB64 callback:(RCTResponseSenderBlock)callback) {
  NSNumber *contextId = @([contextIdStr integerValue]);
  [RNSaplingBridge prepareSpendDescriptionWithAuthorizingKey:contextId authorizingKeyB64:authorizingKeyB64 addressB64:addressB64 rcmB64:rcmB64 arB64:arB64 value:value anchorB64:anchorB64 merklePathB64:merklePathB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(signSpendDescription:(NSString *)spendDescriptionB64 spendingKeyB64:(NSString *)spendingKeyB64 arB64:(NSString *)arB64 sighashB64:(NSString *)sighashB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge signSpendDescription:spendDescriptionB64 spendingKeyB64:spendingKeyB64 arB64:arB64 sighashB64:sighashB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(getExtendedSpendingKey:(NSString *)seedB64 derivationPath:(NSString *)derivationPath callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getExtendedSpendingKey:seedB64 derivationPath:derivationPath completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(getExtendedFullViewingKey:(NSString *)seedB64 derivationPath:(NSString *)derivationPath callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getExtendedFullViewingKey:seedB64 derivationPath:derivationPath completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(getExtendedFullViewingKeyFromSpendingKey:(NSString *)spendingKeyB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getExtendedFullViewingKeyFromSpendingKey:spendingKeyB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(getOutgoingViewingKey:(NSString *)viewingKeyB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getOutgoingViewingKey:viewingKeyB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

RCT_EXPORT_METHOD(getIncomingViewingKey:(NSString *)viewingKeyB64 callback:(RCTResponseSenderBlock)callback) {
  [RNSaplingBridge getIncomingViewingKey:viewingKeyB64 completion:^(NSString *result, NSString *error) {
    invokeCallback(callback, error, result);
  }];
}

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

@end
