//
//  NSString+AES256.h
//  EncryptedTest
//
//  Created by 志方 on 2018/3/26.
//  Copyright © 2018年 志方. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (AES256)

-(NSString *) aes256_encrypted: (NSString *) key;
-(NSString *) aes256_decrypted: (NSString *) key;

@end
