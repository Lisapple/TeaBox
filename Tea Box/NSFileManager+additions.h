//
//  NSFileManager+additions.h
//  FileManagerPlus
//
//  Created by Max on 04/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@interface NSFileManager (additions)

- (void)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath progressionHandler:(void (^)(float progression))progressionHandler completionHandler:(void (^)(void))completionHandler errorHandler:(void (^)(NSError * error))errorHandler;
- (void)copyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL progressionHandler:(void (^)(float progression))progressionHandler completionHandler:(void (^)(void))completionHandler errorHandler:(void (^)(NSError * error))errorHandler;

@end
