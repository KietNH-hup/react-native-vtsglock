#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"


// (swift class name , super class)
@interface RCT_EXTERN_MODULE(TipiLockModule, RCTEventEmitter)

RCT_EXTERN_METHOD(initialise)

RCT_EXTERN_METHOD(startDeviceScan)

RCT_EXTERN_METHOD(stopDeviceScan)

// export to js with different name
// _RCT_EXTERN_REMAP_METHOD(exportedName, testMethod, false)
//
// export method with callback
RCT_EXTERN_METHOD(lockInitialize: (NSString)lockMac callback:(RCTResponseSenderBlock)callback )
//
//// promise test
//RCT_EXTERN_METHOD(
//                  decrement: (RCTPromiseResolveBlock)resolve
//                  rejecter: (RCTPromiseRejectBlock)reject
//                  )


@end
