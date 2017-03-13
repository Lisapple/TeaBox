//
//  NSAlert+additions.h
//  Tea Box
//
//  Created by Max on 06/03/2017.
//
//

NS_ASSUME_NONNULL_BEGIN

@interface NSAlert (additions)

+ (instancetype)alertWithStyle:(NSAlertStyle)style
				   messageText:(nullable NSString *)messageText
			   informativeText:(nullable NSString *)informativeText
				  buttonTitles:(NSArray <NSString *> *)titles;

@end

NS_ASSUME_NONNULL_END
