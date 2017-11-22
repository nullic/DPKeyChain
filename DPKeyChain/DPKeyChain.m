//
//  DPKeyChain.m
//  DP Commons
//
//  Created by Dmitriy Petrusevich on 11.11.11.
//  Copyright (c) 2012 Dmitriy Petrusevich. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "DPKeyChain.h"

#import <Security/Security.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif


@interface DPKeyChain ()
@end

@implementation DPKeyChain

+ (instancetype)keychain {
    static DPKeyChain *keychain = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keychain = [[self alloc] initWithIdentifier:@"ind.keychain.dp" accessGroup:nil];
    });
    return keychain;
}

- (instancetype)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup {
    if ((self = [super init])) {
        self.identifier = identifier;
        self.accessGroup = accessGroup;
    }
    return self;
}

- (NSMutableDictionary *)queryWithKey:(NSString *)key {
    NSData *encodedIdentifier = [self.identifier dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *genericPasswordQuery = [NSMutableDictionary dictionaryWithObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [genericPasswordQuery setObject:key forKey:(__bridge id)kSecAttrService];
    [genericPasswordQuery setValue:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [genericPasswordQuery setValue:self.accessGroup forKey:(__bridge id)kSecAttrAccessGroup];

    return genericPasswordQuery;
}

- (void)setObject:(id<NSCoding>)obj forKeyedSubscript:(NSString *)key {
    NSMutableDictionary *genericPasswordQuery = [self queryWithKey:key];

    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)genericPasswordQuery, NULL);
    if (status == errSecItemNotFound) {
        if (obj) {
            [genericPasswordQuery setValue:[NSKeyedArchiver archivedDataWithRootObject:obj] forKey:(__bridge id)kSecValueData];

            status = SecItemAdd((__bridge CFDictionaryRef)genericPasswordQuery, NULL);
            if (status != errSecSuccess) NSLog(@"ERROR: KeyChain (SecItemAdd) error:%ld", (long)status);
        }
    }
    else if (status == errSecSuccess) {
        if (obj) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj];
            NSDictionary *updateDictionary = @{(__bridge id)kSecValueData: data};
            status = SecItemUpdate((__bridge CFDictionaryRef)(genericPasswordQuery), (__bridge CFDictionaryRef)(updateDictionary));
        }
        else {
            status = SecItemDelete((__bridge CFDictionaryRef)genericPasswordQuery);
        }

        if (status != errSecSuccess) NSLog(@"ERROR: KeyChain (SecItemUpdate) error:%ld", (long)status);
    }
    else {
        NSLog(@"ERROR: KeyChain (SecItemCopyMatching) error:%ld", (long)status);
    }
}

- (id)objectForKeyedSubscript:(NSString *)key {
    NSMutableDictionary *genericPasswordQuery = [self queryWithKey:key];
    [genericPasswordQuery setValue:@YES forKey:(__bridge id)kSecReturnData];

    CFTypeRef dataTypeRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)genericPasswordQuery, &dataTypeRef);
    NSData *data = (__bridge NSData *)dataTypeRef;

    id result = nil;
    if (status == errSecSuccess && data) {
        @try {
            result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        } @catch (NSException *exception) {
            self[key] = nil;
        }
    }
    else if (status != errSecItemNotFound) {
        NSLog(@"ERROR: KeyChain (SecItemCopyMatching) error:%ld", (long)status);
    }
    return result;
}

@end

