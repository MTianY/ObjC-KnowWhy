//
//  TYTestModel.h
//  TYCopyIvarDemo
//
//  Created by 马天野 on 2018/10/26.
//  Copyright © 2018 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYTestModel : NSObject

@property (nonatomic, copy) NSString * name;
@property (nonatomic, assign) int age;
@property (nonatomic, assign) int no;

@end

NS_ASSUME_NONNULL_END
