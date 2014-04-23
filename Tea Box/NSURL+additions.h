//
//  NSURL+additions.h
//  Tea Box
//
//  Created by Maxime Leroy on 12/8/12.
//
//

#import <Foundation/Foundation.h>

@interface NSURL (additions)

- (BOOL)fileIsBundle:(BOOL *)isBundle isPackage:(BOOL *)isPackage;

@end
