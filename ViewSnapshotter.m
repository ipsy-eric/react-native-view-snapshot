#import "ViewSnapshotter.h"
#import "RCTConvert.h"
#import "RCTBridge.h"
#import "RCTUIManager.h"
#import "RCTWebView.h"

@implementation ViewSnapshotter

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(saveSnapshotToPath:(nonnull NSNumber *)reactTag
                  path:(NSString *)filePath
                  callback:(RCTResponseSenderBlock)callback)
{
    
    UIView *view = [self.bridge.uiManager viewForReactTag:reactTag];
    
    // defaults: snapshot the same size as the view, with alpha transparency, with current device's scale factor
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0.0);
    
    [view drawViewHierarchyInRect:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height) afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    NSData *data = UIImagePNGRepresentation(image);
    
    NSError *error;
    
    BOOL writeSucceeded = [data writeToFile:filePath options:0 error:&error];
    
    if (!writeSucceeded) {
        return callback(@[[NSString stringWithFormat:@"Could not write file at path %@", filePath]]);
    }
    
    callback(@[[NSNull null], [NSNumber numberWithBool:writeSucceeded]]);
}

RCT_EXPORT_METHOD(saveFullHeightWebpageSnapshotToPath:(nonnull NSNumber *)reactTag
                  path:(NSString *)filePath
                  callback:(RCTResponseSenderBlock)callback)
{
    
    UIView *view = [self.bridge.uiManager viewForReactTag:reactTag];
    
    UIScrollView* scrollView = [self findScrollViewForWebViewInViewHierarchy:view];
    
    if (nil == scrollView) {
        NSLog(@"Error: could not find scrollview to snapshot!");
        return callback(@[@"Error: could not find scrollview to snapshot!"]);
    }
    
    UIImage* image = nil;
    UIGraphicsBeginImageContext(scrollView.contentSize);
    {
        CGPoint savedContentOffset = scrollView.contentOffset;
        CGRect savedFrame = scrollView.frame;
        
        scrollView.contentOffset = CGPointZero;
        scrollView.frame = CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height);
        
        [scrollView.layer renderInContext:UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        scrollView.contentOffset = savedContentOffset;
        scrollView.frame = savedFrame;
    }
    UIGraphicsEndImageContext();
    
    NSData *data = UIImagePNGRepresentation(image);
    
    NSError *error;
    
    BOOL writeSucceeded = [data writeToFile:filePath options:0 error:&error];
    
    if (!writeSucceeded) {
        return callback(@[[NSString stringWithFormat:@"Could not write file at path %@", filePath]]);
    }
    
    callback(@[[NSNull null], [NSNumber numberWithBool:writeSucceeded]]);
}

- (UIScrollView *)findScrollViewForWebViewInViewHierarchy:(UIView *)view
{
    UIScrollView* targetScrollView = nil;
    
    for (UIView* subview in view.subviews) {
        for (UIView* childView in subview.subviews) {
            if ([childView isKindOfClass:[UIWebView class]]) {
                NSLog(@"Found the target webview: %@", childView);
                targetScrollView = [(UIWebView *)childView scrollView];
            }
        }
    }
    
    return targetScrollView;
}

@end
