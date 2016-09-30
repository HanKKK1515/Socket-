//
//  ViewController.m
//  小聊天室
//
//  Created by 韩露露 on 16/9/28.
//  Copyright © 2016年 HLL. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController () <NSStreamDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, GCDAsyncSocketDelegate>

@property (strong, nonatomic) NSInputStream *input;
@property (strong, nonatomic) NSOutputStream *output;
@property (strong, nonatomic) NSMutableArray *chatMsgs;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textBottomConstrain;

@property (strong, nonatomic) GCDAsyncSocket *socket;

- (IBAction)connect:(UIBarButtonItem *)sender;
- (IBAction)login:(UIBarButtonItem *)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWillChange:(NSNotification *)notif {
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGRect keyboardFrame = [notif.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat height = screenHeight - keyboardFrame.origin.y;
    self.textBottomConstrain.constant = height;
    if (height > 10) {
        [self reloadDataWithText:nil];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)connect:(UIBarButtonItem *)sender {
    // 创建socket连接
    NSString *hostStr = @"127.0.0.1";
//    CFStringRef host = (__bridge CFStringRef)hostStr;
//    CFHostRef hostRef = CFHostCreateWithName(NULL, host);
//    SInt32 port = 12345;
//    CFReadStreamRef readStream;
//    CFWriteStreamRef writeStream;
//    CFStreamCreatePairWithSocketToCFHost(nil, hostRef, port, &readStream, &writeStream);
//    // 把C语言的输出流转换为OC对象
//    self.input = (__bridge NSInputStream *)(readStream);
//    self.output = (__bridge NSOutputStream *)(writeStream);
//    // 设置代理
//    self.input.delegate = self;
//    self.output.delegate = self;
//    // 把输入输出流放进主运行循环
//    [self.input scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
//    [self.output scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
//    // 打开输入输出流
//    [self.input open];
//    [self.output open];
    
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSError *error = nil;
    [self.socket connectToHost:hostStr onPort:12345 error:&error];
    if (error) {
        NSLog(@"socket创建失败：%@", error.localizedDescription);
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"socket连接成功.");
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socket连接失败.");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    [self.socket readDataWithTimeout:-1 tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (tag == 1001) {
        NSLog(@"登录成功:%@", msg);
    } else if (tag == 1002) {
        [self reloadDataWithText:msg];
    }
}

//- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
//    switch (eventCode) {
//        case NSStreamEventOpenCompleted: // 输入输出流打开完成
//            NSLog(@"输入输出流打开完成");
//            break;
//        case NSStreamEventHasBytesAvailable: // 有字节可读
//            NSLog(@"有字节可读");
//            [self readData];
//            break;
//        case NSStreamEventHasSpaceAvailable: // 可发送字节
//            NSLog(@"可发送字节");
//            break;
//        case NSStreamEventErrorOccurred: // 连接出错
//            NSLog(@"连接出错");
//            break;
//        case NSStreamEventEndEncountered: // 连接完成
//            NSLog(@"连接完成");
//            [self.input close];
//            [self.output close];
//            [self.input removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
//            [self.output removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
//            break;
//        default:
//            break;
//    }
//}

- (IBAction)login:(UIBarButtonItem *)sender {
    // 发送登录数据
    NSString *loginStr = @"iam:服务器";
    NSData *loginData = [loginStr dataUsingEncoding:NSUTF8StringEncoding];
//    [self.output write:loginData.bytes maxLength:loginData.length];
    
    [self.socket writeData:loginData withTimeout:-1 tag:1001];
}

//- (void)readData {
//    // 读取数据
//    // 创建一个缓冲区
//    uint8_t buf[1024];
//    // 返回实际字节数
//    NSUInteger dataLength = [self.input read:buf maxLength:sizeof(buf)];
//    // 获取数据并转换为OC字符串
//    NSData *data = [NSData dataWithBytes:buf length:dataLength];
//    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    
//    [self reloadDataWithText:msg];
//}

- (void)reloadDataWithText:(NSString *)text {
    if (text.length > 0 && text) {
        [self.chatMsgs addObject:text];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.chatMsgs.count > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.chatMsgs.count - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    });
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *msg = [NSString stringWithFormat:@"msg:%@", textField.text];
    [self reloadDataWithText:msg];
    NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
//    [self.output write:msgData.bytes maxLength:msgData.length];
    [self.socket writeData:msgData withTimeout:-1 tag:1002];
    textField.text = @"";
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chatMsgs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = self.chatMsgs[indexPath.row];
    return cell;
}

- (NSMutableArray *)chatMsgs {
    if (!_chatMsgs) {
        _chatMsgs = [NSMutableArray array];
    }
    return _chatMsgs;
}

@end
