//
//  ViewController.m
//  RunTimeTest
//
//  Created by 志方 on 2018/3/22.
//  Copyright © 2018年 志方. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import <objc/runtime.h>
#import "ViewController2.h"
#import "UIButton+EnlargeTouchAre.h"
///使用自己打的静态framework模块
#import <FrameworkTest/IrregularLabel.h>
#import <AVFoundation/AVFoundation.h>
#import "MovieDownLoadAndPlay.h"

static CGFloat screenWidth;

@interface ViewController ()<UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) NSThread *myThread;
@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    screenWidth = [UIScreen mainScreen].bounds.size.width;
//    [self isRootClass];
//    [self objcSendMsg];
//    [self getPropertyStruct];
//    [self methodRootFinish];
//    [self methodSwizzling];
    [self setBackImage];
    [self setIrregularLabel];
    [self runtimeWeak];
    [self setButton:CGRectMake(screenWidth/2 - 25, 100, 50, 40) title:@"push" action:@selector(push)];
    [self setButton:CGRectMake(screenWidth/2-50, 200, 100, 40) title:@"剪切板通讯" action:@selector(pasteBoardNoti)];
    [self setButton:CGRectMake(screenWidth/2-100, 300, 200, 40) title:@"documentInteraction通讯共享文件" action:@selector(documentInteractionController)];
    [self sort];
    NSLog(@"一共%ld个参数", [self moreParas:@"123",@"456",@"676",nil]);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CFRunLoopRef loop = CFRunLoopGetCurrent();
        NSLog(@"当前loop:%@",loop);
        
    });
    
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(myThreadRun) object:@"etund"];
    self.myThread = thread;
    [self.myThread start];
//    [self gcdForTimer];
    [self kvoRealize];
    
    NSMutableArray *arr = [NSMutableArray arrayWithObjects:@32,@43,@2,@34,@6,@12,@65, nil];
    [self headSort:arr];
    NSLog(@"堆排序以后：%@",arr);
    
}

-(void) setBackImage {
    UIImageView *backImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    backImage.backgroundColor = [UIColor grayColor];
    backImage.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:backImage];
    
    NSData *data = [self imageData:[UIImage imageNamed:@"IMG_0677.JPG"]];
    backImage.image = [UIImage imageWithData:data];
}

#pragma mrak 压缩图片
-(NSData *)imageData: (UIImage *) image {
    UIImage *scaledImage = [self originImage:image scaleToSize:image.size];
    NSData *data = UIImageJPEGRepresentation(scaledImage, 1.0);
    if (data.length > 100*1024) {
        if (data.length > 1024*1024) {
            data = UIImageJPEGRepresentation(scaledImage, 0.1);
        }else if (data.length > 512*1024){
            data = UIImageJPEGRepresentation(scaledImage, 0.5);
        }else if (data.length > 200*1024){
            data = UIImageJPEGRepresentation(scaledImage, 0.9);
        }
    }
    return data;
}

-(UIImage *) originImage: (UIImage *) image scaleToSize: (CGSize) size {
        // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(size, YES, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

#pragma mark KVO内部runtime实现原理
-(void) kvoRealize {
    Person *person = [[Person alloc] init];
    NSLog(@"class-withOutKVO: %@\n",object_getClass(person));
    NSLog(@"setterAddress-withOutKVO: %p\n",[person methodForSelector:@selector(setName:)]);
    [person addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:(__bridge void *)(self)];
    ///添加完监听后，运行期会动态创建派生类NSKVONotifying_Person，重写基类中任何被观察属性的setter方法，然后对象的指针从指向父类变成指向派生类
    NSLog(@"class-addKVO:%@\n",object_getClass(person));
    NSLog(@"setterAddress-addKVO:%p\n",[person methodForSelector:@selector(setName:)]);
//    [person removeObserver:self forKeyPath:@"name"];
    NSLog(@"class-removeKVO:%@",object_getClass(person));
    NSLog(@"setterAddress-removeKVO:%p\n",[person methodForSelector:@selector(setName:)]);
    
    person.name = @"fsd";///执行的是派生类重写的setterName方法，通知对象值改变了，执行回调方法
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"监听的改变的值::%@",change);
}

#pragma mark 串行队列的runloop  可以通过CFRunLoopPerformBlock将任务直接加入到runloop自身的任务队列中，检测这个任务是否被执行
-(void) serialRunloop {
    __block CFRunLoopRef serialRunloop = NULL;
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_queue_t serialQueue = dispatch_queue_create("serial.queue", DISPATCH_QUEUE_SERIAL);//并行DISPATCH_QUEUE_CONCURRENT
    dispatch_async(serialQueue, ^{
        NSLog(@"the task tun the thread:");
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
            NSLog(@"ns timer in the thread:");
        }];
        serialRunloop = [NSRunLoop currentRunLoop].getCFRunLoop;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:600]];
    });
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, mainQueue);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        dispatch_async(serialQueue, ^{
            NSLog(@"gcd timer in the thread");
        });
        CFRunLoopPerformBlock(serialRunloop, NSDefaultRunLoopMode, ^{
            NSLog(@"perform block in thread");
        });
    });
    dispatch_resume(timer);
    
}

#pragma mark GCD实现定时器，误差比较准
-(void) gcdForTimer {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    uint64_t interval = (uint64_t)(1.0 * NSEC_PER_SEC);
    dispatch_source_set_timer(self.timer, start, interval, 0.0);
    dispatch_source_set_event_handler(self.timer, ^{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"gcdtimer");
        });
    });
    dispatch_resume(self.timer);
    ///停止定时器
//    dispatch_source_cancel(self.timer);
}

#pragma mark 检测后台线程，为后台线程添加runloop让线程一直存在
///线程的五大状态:新建状态、就绪状态、运行状态、阻塞状态、死亡状态
///为后台线程的runloop添加source，让线程执行完不死亡，一直等待响应
-(void) myThreadRun {
    NSLog(@"my threa run");
    [[NSRunLoop currentRunLoop] addPort:[[NSPort alloc] init] forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
    NSLog(@"my threa run");
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self performSelector:@selector(doBackThreadWork) onThread:self.myThread withObject:nil waitUntilDone:NO];
}
-(void) doBackThreadWork {
    NSLog(@"do some work %s",__FUNCTION__);
}

///测试不规则label
-(void) setIrregularLabel {
    IrregularLabel *label = [[IrregularLabel alloc] initWithFrame:CGRectMake(90, 380, 200, 40)];
    [self.view addSubview:label];
    label.text = @"这是一个不规则的label";
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor redColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:16];
}

#pragma mark 多个可变参数写法,返回参数个数(这个写法在swift中调用不了)
-(NSInteger) moreParas: (NSString *) value,...{
    va_list list;
    va_start(list, value);
    NSInteger count = 0;
    id arg;
    while ((arg = va_arg(list, id))) {
        NSLog(@"%@",arg);
        count++;
    }
    va_end(list);
    return count;
}

///这个可以在swift中调用
-(NSInteger) morePara: (va_list) list {
    NSInteger count = 0;
    id arg;
    while ((arg = va_arg(list, id))) {
        count ++;
    }
    
    return count;
}

-(void) setButton: (CGRect) rect title: (NSString *) title action:(SEL) action {
    UIButton *push = [UIButton buttonWithType:UIButtonTypeSystem];
    [push setTitle:title forState:UIControlStateNormal];
    push.frame = rect;
    push.backgroundColor = [UIColor orangeColor];
    [push setEnlargeEdgeWithTop:30 right:30 bottom:30 left:30];
    
    [push addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:push];
}

#pragma mark 基数排在前面，偶数排在后面
-(void) sort {
    NSMutableArray *array = [NSMutableArray arrayWithObjects:@12,@3,@5,@9,@43,@53, nil];
    
    NSInteger front = 0;
    NSInteger later = array.count-1;
    id temp = nil;
    id temp2 = nil;
    while (later > front || later - front > 1) {
        if ((NSInteger)array[front] % 2 > 0) {
            front ++;
        }else {
            temp = array[front];
        }
        
        if ([array[later] integerValue] % 2 == 0) {
            later --;
        }else {
            if (temp == nil) {
                temp2 = array[later];
            }else {
                array[front] = array[later];
                array[later] = temp;
                front++;
                temp = nil;
                temp2 = nil;
            }
        }
    }
    NSLog(@"排序以后的值:%@",array);
    
}

#pragma mark 堆排序
-(void) headSort: (NSMutableArray *) nums {
    NSInteger size = nums.count;
    [self buildMinHead:nums];
    while (size != 0) {
        ///交换堆顶和最后一个元素
        id tmp = nums[0];
        nums[0] = nums[size - 1];
        nums[size - 1] = tmp;
        size --;
        [self siftDown:nums i:0 newSize:size];
    }
}
///建立小顶堆
-(void) buildMinHead: (NSMutableArray *) nums {
    int size = (int)nums.count;
    for (int j = size / 2 - 1; j >= 0; j--) {
        [self siftDown:nums i:j newSize:size];
    }
}

-(void) siftDown: (NSMutableArray *) nums i:(NSInteger) i newSize:(NSInteger)newSize {
    id key = nums[i];
    while (i < newSize >> 1) {
        NSInteger leftChild = (i << 1) + 1;
        NSInteger rightChild = leftChild + 1;
        ///最小的孩子，比最小的孩子还小
        NSInteger min = (rightChild >= newSize || nums[leftChild] < nums[rightChild]) ? leftChild : rightChild;
        if (key <= nums[min]) {
            break;
        }
        nums[i] = nums[min];
        i = min;
    }
    nums[i] = key;
}

#pragma mark - 快速排序
///快速排序
-(void) quicklySort: (NSMutableArray *)array startIndex: (NSInteger) startIndex endIndex:(NSInteger) endIndex {
    if (startIndex >= endIndex) {
        return;
    }
    
    
    NSInteger boundary = [self boundary:array startIndex:startIndex endIndex:endIndex];
    [self quicklySort:array startIndex:startIndex endIndex:boundary - 1];
    [self quicklySort:array startIndex:boundary + 1 endIndex:endIndex];
    
}

-(NSInteger) boundary: (NSMutableArray *) array startIndex: (NSInteger) starIndex endIndex:(NSInteger) endIndex {
    NSInteger standant = [array[starIndex] integerValue];///定义标准
    NSInteger leftIndex = starIndex;///左指针
    NSInteger rightIndex = endIndex;///右指针
    
    while (leftIndex < rightIndex) {
        while (leftIndex < rightIndex && [array[rightIndex] integerValue] >= standant) {
            rightIndex --;
        }
        array[leftIndex] = array[rightIndex];
        
        while (leftIndex < rightIndex && [array[leftIndex] integerValue] <= standant) {
            leftIndex ++;
        }
        array[rightIndex] = array[leftIndex];
    }
    
    [array replaceObjectAtIndex:leftIndex withObject:[NSNumber numberWithInteger:standant]];
    
    return leftIndex;
}

-(void) push {
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    ViewController2 *contr = [storyboard instantiateViewControllerWithIdentifier:@"pushControler2"];
//    [self.navigationController pushViewController:contr animated:YES];
    MovieDownLoadAndPlay *contoller = [MovieDownLoadAndPlay new];
    [self.navigationController pushViewController:contoller animated:YES];
}

#pragma mark 使用系统剪切板进行app间通讯
-(void) pasteBoardNoti {
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    [pasteBoard setString:@"复制这条信息，打开->手机淘宝，即可看到【天猫.天天搞机】￥AADFAFNDF"];///往系统剪切板中写入淘口令
    ///然后从其他app读取剪切板中的内容进行操作
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"淘口令" message:pasteBoard.string delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"立即查看", nil];
    [alert show];
    
}
#pragma mark documentInteractionController实现共享文件通讯
-(void) documentInteractionController {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"toefl_student_test_prep_planner" withExtension:@"pdf"];
    if (url) {
        ///初始化Document InteractionController
        UIDocumentInteractionController *document = [UIDocumentInteractionController interactionControllerWithURL:url];
        ///设置UIDocumentInteractionControllerDelegate
        document.delegate = self;
        ///显示窗口预览
        [document presentPreviewAnimated:YES];
    }
}

-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

#pragma mark runtime下weak的底层原理
-(void) runtimeWeak {
    NSString *name = @"Jiaming Chen";
    __weak NSString *weakStr = name;
    /**
     当为weakStr这一weak类型的对象赋值时，编译器会根据name的地址为key去查找weak哈希表，该表项的值为一个数组，将weakStr对象的地址加入到数组中，当name变量超出变量作用域或引用计数为0时，会执行dealloc函数，在执行该函数时，编译器会以name变量的地址去查找weak哈希表的值，并将数组里所有 weak对象全部赋值为nil。
     */
}

#pragma mark Method Swizzling 方法交换
-(void) methodSwizzling {
    /**
     该函数用于交换两个方法的实现，也就是说前文讲述的结构体struct _objc_method中的函数指针_imp被交换了，原来的选择子@selector(helloWorld)对应着方法helloWorld的实现，原来的选择子@selector(showMyself)对应着方法showMyself的实现。
     */
    Person *p = [[Person alloc] initWithName:@"Jiaming Chen" age:22];
    Method method1 = class_getInstanceMethod([p class], @selector(helloWorld));
    Method method2 = class_getInstanceMethod([p class], @selector(showMyself));
    method_exchangeImplementations(method1, method2); ///交换方法实现
    
    [p showMyself];
    [p helloWorld];
    
}


#pragma mark 实例方法相关的结构体和底层实现
-(void) methodRootFinish {
    Person *p = [[Person alloc] initWithName:@"Jiaming Chen" age:22];
    [p showMyself];
    unsigned int count = 0;
    Method *methodList = class_copyMethodList([p class], &count);
    for (int i = 0; i < count; i++) {
        SEL s = method_getName(methodList[i]);
        NSLog(@"%@", NSStringFromSelector(s));
        if ([NSStringFromSelector(s) isEqualToString:@"helloWorld"]) {
            IMP imp = method_getImplementation(methodList[i]);
            imp();
            
        }
    }
    
}

#pragma mark 获取属性在底层就是一个结构体描述
-(void) getPropertyStruct {
    Person* p = [[Person alloc] init];
    p.name = @"Jiaming Chen";
    unsigned int propertyCount = 0;
    objc_property_t *propertyList = class_copyPropertyList([p class], &propertyCount);
    for (int i = 0; i < propertyCount; i++) {
        const char* name = property_getName(propertyList[i]);
        const char* attributes = property_getAttributes(propertyList[i]);
        NSLog(@"%s %s", name, attributes);
        
    }
    ///添加属性
    objc_property_attribute_t attributes = {
        "T@\"NSString\",C,N,V_studentIdentifier",
        "",
    };
    class_addProperty([p class], "studentIdentifier", &attributes, 1);
    objc_property_t property = class_getProperty([p class], "studentIdentifier");
    NSLog(@"%s %s", property_getName(property), property_getAttributes(property));
    
}

#pragma mark 消息发送和消息转发
-(void) objcSendMsg {
    id p = [[Person alloc] init];
    [p appendString:@""]; ///发送appendString消息给接受者p，如果找不到appendString，则实现消息转发
}

-(void) isRootClass {
    Person *p = [[Person alloc] init];
    /**
     [p class] 获取的是类对象
     object_getClass 获取的是对象的isa指针指向的对象
     class_isMetaClass 判断Class对象是否为元类
     object_getClass([Person class]) Person类对象的isa指针指向的是Person类对象的元类
     */
    NSLog(@"%d", [p class] == object_getClass(p)); //输出1
    NSLog(@"%d", class_isMetaClass(object_getClass(p))); //输出0
    NSLog(@"%d", class_isMetaClass(object_getClass([Person class]))); //输出1
    NSLog(@"%d", object_getClass(p) == object_getClass([Person class]));//输出0
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
