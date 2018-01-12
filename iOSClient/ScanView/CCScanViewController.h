//
//  ViewController.h
//  ScanQRCode
//
//

#import <UIKit/UIKit.h>
typedef void (^ResultBolck)(NSString *str);
@interface CCScanViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *annulla;
@property (weak, nonatomic) IBOutlet UILabel *alignMessage;

@property (nonatomic, copy) ResultBolck resultBlock;

@end

