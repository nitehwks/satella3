#include <objc/runtime.h>
#include <objc/message.h>
#include <Foundation/Foundation.h>
#include <StoreKit/StoreKit.h>

// Define the original method signature
typedef void (*OriginalAddPayment)(id, SEL, SKPayment *);

// Replacement implementation for addPayment:
void MyAddPayment(id self, SEL _cmd, SKPayment *payment) {
    NSLog(@"Intercepted addPayment: %@", payment);

    // Simulate a successful transaction
    SKPaymentTransaction *fakeTransaction = [[SKPaymentTransaction alloc] init];
    [fakeTransaction setValue:@(SKPaymentTransactionStatePurchased) forKey:@"transactionState"];
    [fakeTransaction setValue:payment.productIdentifier forKey:@"payment"];
    
    // Notify the delegate about the transaction
    id<SKPaymentTransactionObserver> observer = [[SKPaymentQueue defaultQueue] transactionObservers].firstObject;
    if (observer && [observer respondsToSelector:@selector(paymentQueue:updatedTransactions:)]) {
        [observer paymentQueue:[SKPaymentQueue defaultQueue] updatedTransactions:@[fakeTransaction]];
    }

    // Call the original method (optional, can be skipped)
    OriginalAddPayment original = (OriginalAddPayment)objc_msgSendSuper;
    struct objc_super superInfo = { self, class_getSuperclass(object_getClass(self)) };
    original(&superInfo, _cmd, payment);
}

// Entry point for the DYLIB
__attribute__((constructor))
static void initialize() {
    NSLog(@"DYLIB loaded: Intercepting StoreKit methods");

    // Get the SKPaymentQueue class
    Class paymentQueueClass = objc_getClass("SKPaymentQueue");

    // Get the original addPayment: method
    Method originalMethod = class_getInstanceMethod(paymentQueueClass, @selector(addPayment:));

    // Replace it with our custom implementation
    method_setImplementation(originalMethod, (IMP)MyAddPayment);
}
