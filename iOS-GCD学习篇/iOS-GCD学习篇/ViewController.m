//
//  ViewController.m
//  iOS-GCD学习篇
//
//  Created by zhangzhiliang on 2018/1/24.
//  Copyright © 2018年 zhangzhiliang. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import <objc/NSObjCRuntime.h>
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#import <UIKit/UIKit.h>
#endif

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
#import <Appkit/Appkit.h>
#endif

#define GlobalMainQueue dispatch_get_main_queue()

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.imageView];
    
    /**
     可以避免界面会被一些耗时的操作卡死，比如读取网络数据，大数据IO，还有大量数据的数据库读写，这时需要在另一个线程中处理，然后通知主线程更新界面，GCD使用起来比NSThread和NSOperation方法要简单方便。
     */
    //队列使用举例说明：
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{//先将工作从主线程转移到全局队列中，dispatch_async的异步调用可以保证主线程会继续走完，viewDidLoad可以更早的结束
//        UIImage *overlayImage = self.faceOverlayImageFromImage(self.image)图片处理过程
        dispatch_async(dispatch_get_main_queue(), ^{//新图完成，把一个闭包加入主线程用来更新UIImageView，只有在主线程能操作UIKit。
//            [self fadeInNewImage:overlayImage];// 更新UI
        });
   
    });
    
    unsigned int a = QOS_CLASS_USER_INTERACTIVE;
    a = QOS_CLASS_USER_INITIATED;
    a = QOS_CLASS_DEFAULT;
    a = QOS_CLASS_UTILITY;
    a = QOS_CLASS_BACKGROUND;
    
    dispatch_async(GlobalMainQueue, ^{
        
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL * url = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1517221118606&di=2095411cc9033b7c01bcb7bc5829a500&imgtype=0&src=http%3A%2F%2Fs9.rr.itc.cn%2Fr%2FwapChange%2F201510_12_6%2Fa3ee4o2797907838352.gif"];
        NSData * data = [[NSData alloc]initWithContentsOfURL:url];
        UIImage *image = [[UIImage alloc]initWithData:data];
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
            });
        }
    });
    
    /**
     dispatch_after只是延时提交block，不是延时立刻执行。
     第一个参数为DISPATCH_TIME_NOW表示当前。第二个参数的delta表示纳秒，一秒对应的纳秒为1000000000，系统提供了一些宏来简化
     #define NSEC_PER_SEC 1000000000ull //每秒有多少纳秒
     #define USEC_PER_SEC 1000000ull    //每秒有多少毫秒
     #define NSEC_PER_USEC 1000ull      //每毫秒有多少纳秒
     */
    double delayInSeconds = 5.0;
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds *NSEC_PER_SEC));
    dispatch_after(time, dispatch_get_main_queue(), ^{
        self.imageView.image = nil;
    });
    //这样如果要表示一秒就可以这样写:
    dispatch_time_t *dispatchTime;
    dispatchTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
    dispatchTime = dispatch_time(DISPATCH_TIME_NOW, 1000 * USEC_PER_SEC);
    dispatchTime = dispatch_time(DISPATCH_TIME_NOW, USEC_PER_SEC * NSEC_PER_USEC);
    
}

+ (UIColor *)boringColor {
    
    static UIColor *color;
    
    //只执行一次，常用于单例
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        color = [UIColor yellowColor];
    });
    
    return color;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)test {
    
    //TODO:-----------------------创建一个自定义队列--------------------------
    //创建一个自定义队列
    /**
     dispatch_queue_create:
     包含两个参数，第一个是自定义的队列名，第二个是队列类型（队列类型有三种，默认是NULL，还有DISPATCH_QUEUE_SERIAL串行，DISPATCH_QUEUE_CONCURRENT并行）
     */
    dispatch_queue_t queue0 = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL);//串行队列
   dispatch_queue_t queue1 = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT);//并行队列
    
    /**
     第一个参数：
     #define DISPATCH_QUEUE_PRIORITY_HIGH 2
     #define DISPATCH_QUEUE_PRIORITY_DEFAULT 0
     #define DISPATCH_QUEUE_PRIORITY_LOW (-2)
     #define DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN
     第二个参数：
     QOS_CLASS_USER_INTERACTIVE：user interactive 等级表示任务需要被立即执行提供好的体验，用来更新UI，相应事件等，这个等级最号保持小规模
     QOS_CLASS_USER_INITIATED：user initiated 等级表示任务由UI发起异步执行。适合场景是需要及时结果同时又可以继续交互的时候。
     QOS_CLASS_DEFAULT：
     QOS_CLASS_UTILITY：utility 等级表示需要长时间运行的任务，伴有用户可见进度指示器。经常会用来做计算，I/O，网络，持续的数据填充等任务。这个任务节能
     QOS_CLASS_BACKGROUND：background 等级表示用户不会察觉的任务，使用它来处理预加载，或者不需要用户交互和对时间不敏感的任务
     QOS_CLASS_UNSPECIFIED
     
     何时使用何种队列：
     主队列（顺序）： 需要更新UI，dispatch_after在这种类型中使用
     并发队列：与UI无关的后台任务，dispatch_sync放在这里，方便等待任务完成进行后持续处理或和dispatch barrier同步。dispatch groups 放在这里也不错。
     自定义顺序队列：顺序执行后台任务并追踪它时。这样做同时只有一个任务在执行可以防止资源竞争。dispatch barriers解决读写锁问题的放在这里处理。dispatch groups也是放在这里
     */
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, QOS_CLASS_DEFAULT);//创建四个全球类型的队列的其中任何一个
    
    //TODO:-----------------------线程创建--------------------------
    //线程创建
    dispatch_sync(queue0, ^{
        
    });//同步线程创建
    
    dispatch_async(queue1, ^{
        
    });//异步线程创建
    
    
    
    //TODO:-----------------------自定义队列的优先级--------------------------
    //自定义队列的优先级：可以通过dipatch_queue_attr_make_with_qos_class或dispatch_set_target_queue方法设置队列的优先级,如下：
    dispatch_queue_attr_t attr_t = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, -1);//先设置队列的属性
    dispatch_queue_t queue111 = dispatch_queue_create("222", attr_t);//然后在创建队列时，加入属性值
    
    dispatch_queue_t queue222 = dispatch_queue_create("333", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t referQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_set_target_queue(queue222, referQueue);//设置queue222和referQueue的优先级一样
    
    
    
    //TODO:-----------------------分割线--------------------------
    //dispatch_set_target_queue：可以设置优先级，也可以设置队列层级体系，比如让多个串行和并行队列在统一一个串行队列里串行执行，如下
    
    dispatch_queue_t serialQueue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t firstQueue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t secondQueue = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_set_target_queue(firstQueue, serialQueue);//第一个队列的优先级会和第二个队列优先级一致  firstQueue变成和serialQueue一个优先级
    dispatch_set_target_queue(secondQueue, serialQueue);//secondQueue和serialQueue一个优先级
    //所以并行的队列变成了串行队列
    dispatch_async(firstQueue, ^{
        NSLog(@"1");
        [NSThread sleepForTimeInterval:3.f];
    });
    
    dispatch_async(secondQueue, ^{
        NSLog(@"2");
        [NSThread sleepForTimeInterval:2.f];
    });
    
    dispatch_async(secondQueue, ^{
        NSLog(@"3");
        [NSThread sleepForTimeInterval:1.f];
    });
    
}

- (void)test1 {
    dispatch_queue_t serialQueue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t firstQueue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t secondQueue = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT);
    
//    dispatch_set_target_queue(firstQueue, secondQueue);
    dispatch_set_target_queue(secondQueue, firstQueue);//第一个队列的优先级会和第二个队列优先级一致
    
    dispatch_async(firstQueue, ^{
        NSLog(@"1");
        [NSThread sleepForTimeInterval:3.f];
    });
    
    dispatch_async(secondQueue, ^{
        NSLog(@"2");
        [NSThread sleepForTimeInterval:2.f];
    });
    
    dispatch_async(secondQueue, ^{
        NSLog(@"3");
        [NSThread sleepForTimeInterval:1.f];
    });
}

/**
 dispatch_barrier_async使用Barrier Task方法Dispatch Barrier解决多线程并发读写同一个资源发生死锁
 Dispatch Barrier确保提交的闭包是指定队列中在特定时段唯一在执行的一个。在所有先于Dispatch Barrier的任务都完成的情况下这个闭包才开始执行。轮到这个闭包时barrier会执行这个闭包并且确保队列在此过程不会执行其它任务。闭包完成后队列恢复。需要注意dispatch_barrier_async只在自己创建的队列上有这种作用，在全局并发队列和串行队列上，效果和dispatch_sync一样
 都用异步处理避免死锁，异步的缺点在于调试不方便，但是比起同步容易产生死锁这个副作用还算小的。
 */
- (void)test2 {
    //防止文件读写冲突，可以创建一个串行队列，操作都在这个队列中进行，没有更新数据读用并行，写用串行。
    dispatch_queue_t dataQueue = dispatch_queue_create("com.starming.gcddemo.dataqueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(dataQueue, ^{
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"read data 1");
    });
    dispatch_async(dataQueue, ^{
        NSLog(@"read data 2");
    });
    //等待前面的都完成，在执行barrier后面的
    dispatch_barrier_async(dataQueue, ^{
        NSLog(@"write data 1");
        [NSThread sleepForTimeInterval:1];
    });
    dispatch_async(dataQueue, ^{
        [NSThread sleepForTimeInterval:1.f];
        NSLog(@"read data 3");
    });
    dispatch_async(dataQueue, ^{
        NSLog(@"read data 4");
    });
}

//dispatch_apply进行快速迭代
- (void)dispatchApplyTest {
    /**
     类似for循环，但是在并发队列的情况下dispatch_apply会并发执行block任务。
     dispatch_apply能避免线程爆炸，因为GCD会管理并发
     */
    dispatch_queue_t queue = dispatch_queue_create("dispatch_apply", DISPATCH_QUEUE_CONCURRENT);
    dispatch_apply(10, queue, ^(size_t i) {
        //发现输出不是按照顺序0-9依次输出
        NSLog(@"%zu",i);
    });
    NSLog(@"the end");
    
    [self dealWiththreadWithMaybeExplode:NO];
    
}

- (void)dealWiththreadWithMaybeExplode:(BOOL)explode {
    
    dispatch_queue_t concurrentQueue = dispatch_queue_create("dispatchApply", DISPATCH_QUEUE_CONCURRENT);
    if (explode) {
        //有问题的情况，可能会死锁
        for (int i = 0; i < 999; i ++) {
            dispatch_async(concurrentQueue, ^{
               NSLog(@"wrong %d",i);
            });
        }
    } else {
        //会优化很多，能够利用GCD管理
        dispatch_apply(999, concurrentQueue, ^(size_t i) {
            NSLog(@"correct %zu",i);
        });
    }
}

/**
 dispatch groups 是专门用来监视多个异步任务。dispatch_group_t实例用来追踪不同队列中不同的任务
 当Group里所有事件都完成GCD API有两种方式发童通知，第一种是dispatch_group_wait，会阻塞当前进程，等所有任务都完成或等待超时。第二种方法是使用dispatch_group_notify，异步执行闭包，不会阻塞
 */
- (void)dispatchGroupsTest {
    
    //dispatch_group_wait举例
//    [self dispatchGroupWaitDemo];
    
    //dispatch_group_notify举例
    [self dispatchGroupNotifyDemo];
}

//第一种使用dispatch_group_wait的swift的例子：
- (void)dispatchGroupWaitDemo {
    
    dispatch_queue_t concurrentQueue = dispatch_queue_create("dispatchGroup", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, concurrentQueue, ^{
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"1");
    });
    
    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"2");
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    NSLog(@"go on");
}

- (void)dispatchGroupNotifyDemo {
    
    dispatch_queue_t concurrentQueue = dispatch_queue_create("dispatchGroupNotify", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, concurrentQueue, ^{
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"1");
    });
    
    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"2");
    });
    
    dispatch_group_notify(group, concurrentQueue, ^{
        NSLog(@"end");
    });
    
    NSLog(@"can continue");
}

/**
 dispatch_group_async等价于dispatch_group_enter() 和 dispatch_group_leave()的组合。
 dispatch_group_enter() 必须运行在 dispatch_group_leave() 之前。
 dispatch_group_enter() 和 dispatch_group_leave() 需要成对出现的
 */

//给Core Data的-performBlock:添加groups。组合完成任务后使用dispatch_group_notify来运行一个block即可。
- (void)withGroup:(dispatch_group_t)group performBlock:(dispatch_block_t)block
{
//    if (group == NULL) {
//        [self performBlock:block];
//    } else {
//        dispatch_group_enter(group);
//        [self performBlock:^(){
//            block();
//            dispatch_group_leave(group);
//        }];
//    }
}

//NSURLConnection也可以这样做
+ (void)withGroup:(dispatch_group_t)group
sendAsynchronousRequest:(NSURLRequest *)request
            queue:(NSOperationQueue *)queue
completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
//    if (group == NULL) {
//        [self sendAsynchronousRequest:request
//                                queue:queue
//                    completionHandler:handler];
//    } else {
//        dispatch_group_enter(group);
//        [self sendAsynchronousRequest:request
//                                queue:queue
//                    completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
//                        handler(response, data, error);
//                        dispatch_group_leave(group);
//                    }];
//    }
}

/**
 Dispatch Block
 队列执行任务都是block的方式，
 */
- (void)dispatchBlockTest {
    //normal way
    dispatch_queue_t queue = dispatch_queue_create("dispatchBlock", DISPATCH_QUEUE_CONCURRENT);
    dispatch_block_t block = dispatch_block_create(0, ^{
        
    });
    dispatch_async(queue, block);
    
    dispatch_block_t qosBlock = dispatch_block_create_with_qos_class(0, QOS_CLASS_USER_INITIATED, -1, ^{
        NSLog(@"run qos block");
    });
    dispatch_async(queue, qosBlock);
    
}

/**
 dispatch_block_wait：可以根据dispatch block来设置等待时间，参数DISPATCH_TIME_FOREVER会一直等待block结束
 */

- (void)dispatchBlockWaitDemo {
    dispatch_queue_t serialQueue = dispatch_queue_create("com.starming.gcddemo.serialqueue", DISPATCH_QUEUE_SERIAL);
    dispatch_block_t block = dispatch_block_create(0, ^{
        NSLog(@"star");
        [NSThread sleepForTimeInterval:5.f];
        NSLog(@"end");
    });
    
    dispatch_async(serialQueue, block);
    //设置DISPATCH_TIME_FOREVER会一直等到前面任务都完成
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC);//等待一秒
    dispatch_block_wait(block, time);
    NSLog(@"ok, now can go on");
}

/**
 dispatch_block_notify：可以监视指定dispatch block结束，然后再加入一个block到队列中。
 */
- (void)dispatchBlockNotifyTest {
    
    dispatch_queue_t queue = dispatch_queue_create("dispatchBlockNotifyTest", DISPATCH_QUEUE_SERIAL);
    dispatch_block_t block = dispatch_block_create(0, ^{
        NSLog(@"first block start");
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"first block end");
    });
    dispatch_async(queue, block);
    dispatch_block_t block2 = dispatch_block_create(0, ^{
        NSLog(@"second block run");
    });
    
    /**
     三个参数分别为:
     第一个是需要监视的block
     ，第二个参数是需要提交执行的队列
     第三个是待加入到队列中的block
     */
    dispatch_block_notify(block, queue, block2);
}

/**
 dispatch_block_cancel：iOS8后GCD支持对dispatch block的取消
 */
- (void)dispatchBlockCancelDemo {
    dispatch_queue_t serialQueue = dispatch_queue_create("com.starming.gcddemo.serialqueue", DISPATCH_QUEUE_SERIAL);
    dispatch_block_t firstBlock = dispatch_block_create(0, ^{
        NSLog(@"first block start");
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"first block end");
    });
    dispatch_block_t secondBlock = dispatch_block_create(0, ^{
        NSLog(@"second block run");
    });
    dispatch_async(serialQueue, firstBlock);
    dispatch_async(serialQueue, secondBlock);
    //取消secondBlock
    dispatch_block_cancel(secondBlock);
}

/**
 Dispatch IO 文件操作
 dispatch io读取文件的方式类似于下面的方式，多个线程去读取文件的切片数据，对于大的数据文件这样会比单线程要快很多。
 dispatch_io_create：创建dispatch io
 dispatch_io_set_low_water：指定切割文件大小
 dispatch_io_read：读取切割的文件然后合并。
 */

- (void)dispatchIOTest {
    dispatch_queue_t queue = dispatch_queue_create("dispatchIOTest", NULL);
    
    dispatch_io_t pipe_channel = dispatch_io_create(DISPATCH_IO_STREAM, 0, queue, ^(int error) {
        close(0);
    });
    dispatch_io_set_low_water(pipe_channel, SIZE_MAX);
    
    dispatch_io_read(pipe_channel, 0, SIZE_MAX, queue, ^(bool done, dispatch_data_t  _Nullable data, int error) {
        
    });
}

/**
 Dispatch Source 用GCD监视进程
 Dispatch Source用于监听系统的底层对象，比如文件描述符，Mach端口，信号量等。主要处理的事件如下表
             方法                         说明
 DISPATCH_SOURCE_TYPE_DATA_ADD          数据增加
 DISPATCH_SOURCE_TYPE_DATA_OR           数据OR
 DISPATCH_SOURCE_TYPE_MACH_SEND         Mach端口发送
 DISPATCH_SOURCE_TYPE_MACH_RECV         Mach端口接收
 DISPATCH_SOURCE_TYPE_MEMORYPRESSURE    内存情况
 DISPATCH_SOURCE_TYPE_PROC              进程事件
 DISPATCH_SOURCE_TYPE_READ              读数据
 DISPATCH_SOURCE_TYPE_SIGNAL            信号
 DISPATCH_SOURCE_TYPE_TIMER             定时器
 DISPATCH_SOURCE_TYPE_VNODE             文件系统变化
 DISPATCH_SOURCE_TYPE_WRITE             文件写入
 
 dispatch_source_create：创建dispatch source，创建后会处于挂起状态进行事件接收，需要设置事件处理handler进行事件处理。
 dispatch_source_set_event_handler：设置事件处理handler
 dispatch_source_set_cancel_handler：事件取消handler，就是在dispatch source释放前做些清理的事。
 dispatch_source_cancel：关闭dispatch source，设置的事件处理handler不会被执行，已经执行的事件handler不会取消。
 */
- (void)dispatchSourceTest {

}

/**
 Dispatch Semaphore和的介绍
 另外一种保证同步的方法。使用dispatch_semaphore_signal加1dispatch_semaphore_wait减1，为0时等待的设置方式来达到线程同步的目的和同步锁一样能够解决资源抢占的问题。
 */
- (void)dispatchSemaphoreDemo {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"start");
        [NSThread sleepForTimeInterval:1.f];
        NSLog(@"semaphore +1");
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"continue");
}

/**
 GCD死锁
 */
- (void)deadLockCase1 {
    NSLog(@"1");
    //主队列的同步线程，按照FIFO的原则（先入先出），2排在3后面会等3执行完，但因为同步线程，3又要等2执行完，相互等待成为死锁。
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"2");
    });
    NSLog(@"3");
}

- (void)deadLockCase2 {
    NSLog(@"1");
    //3会等2，因为2在全局并行队列里，不需要等待3，这样2执行完回到主队列，3就开始执行
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSLog(@"2");
    });
    NSLog(@"3");
}

- (void)deadLockCase3 {
    dispatch_queue_t serialQueue = dispatch_queue_create("com.starming.gcddemo.serialqueue", DISPATCH_QUEUE_SERIAL);
    NSLog(@"1");
    dispatch_async(serialQueue, ^{
        NSLog(@"2");
        //串行队列里面同步一个串行队列就会死锁
        dispatch_sync(serialQueue, ^{
            NSLog(@"3");
        });
        NSLog(@"4");
    });
    NSLog(@"5");
}

- (void)deadLockCase4 {
    NSLog(@"1");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"2");
        //将同步的串行队列放到另外一个线程就能够解决
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"3");
        });
        NSLog(@"4");
    });
    NSLog(@"5");
}

- (void)deadLockCase5 {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"1");
        //回到主线程发现死循环后面就没法执行了
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"2");
        });
        NSLog(@"3");
    });
    NSLog(@"4");
    //死循环
    while (1) {
        //
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self deadLockCase5];
}

- (UIImageView *)imageView {
    
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    }
    
    return _imageView;
}

@end
