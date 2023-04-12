//
//  ViewController.m
//  isEqual
//
//  Created by 马天野 on 2023/4/12.
//

#import "ViewController.h"

@interface Color : NSObject

@property (nonatomic, strong) NSNumber *red;
@property (nonatomic, strong) NSNumber *green;
@property (nonatomic, strong) NSNumber *blue;

@end

@implementation Color

- (BOOL)isEqualToColor:(Color *)color {
    return [self.red isEqualToNumber:color.red] &&
           [self.green isEqualToNumber:color.green] &&
           [self.blue isEqualToNumber:color.blue];
}

- (BOOL)isEqual:(id)object {
    if (object == nil) {
        return NO;
    }
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[Color class]]) {
        return NO;
    }
    return [self isEqualToColor:(Color *)object];
}

/**
 

 关于自定义哈希实现的一个常见误解来自对结果的肯定:认为哈希值必须是不同的。尽管理想的哈希函数会产生所有不同的值，但这比要求的要困难得多——如果你还记得的话:
 重写哈希方法，使相同的对象产生相同的哈希值。
 满足此需求的一个简单方法是对确定相等的属性的哈希值进行XOR运算。
 */
- (NSUInteger)hash {
    return [self.red hash] ^ [self.green hash] ^ [self.blue hash];
}

@end

@interface TYPerson : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDate *birthday;

@end

@implementation TYPerson

//- (BOOL)isEqualToTYPerson:(TYPerson *)typerson {
//    if (!typerson) {
//        return NO;
//    }
//
//    BOOL haveEqualNames = (!self.name && !typerson.name) || [self.name isEqualToString:typerson.name];
//    BOOL haveEqualBirthdays = (!self.birthday && !typerson.birthday) || [self.birthday isEqualToDate:typerson.birthday];
//
//    return haveEqualNames && haveEqualBirthdays;
//}
//
//- (BOOL)isEqual:(id)object {
//    if (self == object) {
//        return YES;
//    }
//
//    if (![object isKindOfClass:[TYPerson class]]) {
//        return NO;
//    }
//
//    return [self isEqualToTYPerson:(TYPerson *)object];
//}
//
//- (NSUInteger)hash {
//    return [self.name hash] ^ [self.birthday hash];
//}

@end

@interface TYStudent : NSObject

@end

@implementation TYStudent


@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    TYPerson *person1 = [[TYPerson alloc] init];
//    person1.name = @"TY";
//    person1.birthday = [NSDate dateWithTimeIntervalSinceNow:1000];
    
    TYPerson *person2 = [[TYPerson alloc] init];
    TYStudent *student = [[TYStudent alloc] init];
    UIColor *color1 = [UIColor colorWithRed:10/255.0 green:10/255.0 blue:10/255.0 alpha:1];
    UIColor *color2 = [UIColor colorWithRed:10/255.0 green:10/255.0 blue:10/255.0 alpha:1];
    BOOL isEqual = [person1 isEqual:student];
    BOOL isE2 = (person1 == person2);
    BOOL isE1 = (person1 == student);
    
    
    NSString *a = @"Hello";
    NSString *b = @"Hello";
    
    NSLog(@"a == b: %d", a==b);
    NSLog(@"a isEqualToString b: %d",[a isEqualToString:b]);
    
    NSLog(@"person1 isEqual student: %d",isEqual);
    NSLog(@"person1 isEqual person2: %d",[person1 isEqual:person2]);
    NSLog(@"person1 == student: %d",isE1);
    NSLog(@"person1 == person2: %d",isE2);
    NSLog(@"Color1 == Color2: %d", color1==color2);
    NSLog(@"Color1 isEqual Color2 : %d", [color1 isEqual:color2]);
    
    NSArray *array1 = @[];
    NSArray *array2 = @[];
    [array1 isEqualToArray:array2];
    
    //********* Tagged Pointers **********/
    NSTimeInterval timeInterval = 556035120;
    NSDate *aDate = [NSDate dateWithTimeIntervalSinceReferenceDate:timeInterval];
    NSDate *bDate = [NSDate dateWithTimeIntervalSinceReferenceDate:timeInterval];
    BOOL valuesHaveSameIdentity = (aDate == bDate);
    BOOL valuesAreEqual = [aDate isEqual:bDate];
    NSLog(@"Tagged Pointers: valuesHaveSameIdentity=%d, valuesAreEqual=%d", valuesHaveSameIdentity, valuesAreEqual);
}


@end
