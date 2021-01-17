//
//  SmoothPanel.h
//  SmoothPanel
//
//  Created by Sharker on 2021/1/16.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PanelState) {
    PandelStateNormal,
    PandelStateMax,
    PandelStateMin,
    PandelStateDefault
};

typedef NS_ENUM(NSUInteger, PanelStateChangeFrom) {
    PanelStateChangeFrom_UnKnown,
    PanelStateChangeFrom_SetValue,
    PanelStateChangeFrom_Load,
    PanelStateChangeFrom_LoadFinish,
    PanelStateChangeFrom_Refresh,
    PanelStateChangeFrom_BackClick,
    PanelStateChangeFrom_Click,
    PanelStateChangeFrom_DragUp,
    PanelStateChangeFrom_DragDown
};

NS_ASSUME_NONNULL_BEGIN


@interface PanelPanGestureRecognizer : UIPanGestureRecognizer

@end

/*
 如果panel上有UIScrollView组件 需要在ScrollView上添加PanPanDelegate 将手势传递给panel
 PanelPanGestureRecognizer *panGesture = [[PanelPanGestureRecognizer alloc] init];
 panGesture.minimumNumberOfTouches = 1;
 panGesture.delegate = self;
 [self.scrollView addGestureRecognizer:panGesture];
 
 // 实现下面代理方法
 - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
        return YES;
}
 */
@protocol PanelPanDelegate <NSObject>

@optional

/// state发生变化的时候
/// @param state 状态变化的值
- (void)panelStateWillChange:(PanelState)state;

- (void)panelStateWillChange:(PanelState)state changeFrom:(PanelStateChangeFrom)changeFrom;

- (void)panelStateDidChange:(PanelState)state;

- (void)panelStateDidChange:(PanelState)state changeFrom:(PanelStateChangeFrom)changeFrom;


/// 滑动的实时位置 外部调用监听panel的滑动
/// @param distance panel下滑的距离(如果上滑动的话为负)
/// @param distanceToMax 面板当前位置与NormalY的距离
/// @param ratio distanceToMax与渐变截止位置的距离百分比 0~1
- (void)panelMoveDistance:(CGFloat)distance distanceToMax:(CGFloat)distanceToMax ratio:(CGFloat)ratio;

@end


@interface SmoothPanel : UIView

@property (nonatomic, weak) id<PanelPanDelegate> delegate;

@property (nonatomic, assign) PanelState state;

@property (nonatomic, assign) CGFloat normalY; // 正常视图时的Y

@property (nonatomic, assign) CGFloat minY; // 最小视图时的Y

@property (nonatomic, assign) CGFloat maxY; // 最大视图时的Y

@property (nonatomic, assign) CGFloat defaultY; // 加载视图时的Y

@property (nonatomic, strong) UIView *handle; // panel上面的view


// 默认没有动画
- (void)transPanelState:(PanelState)state;

- (void)transPanelState:(PanelState)state
             changeFrom:(PanelStateChangeFrom)changeFrom;

- (void)transPanelState:(PanelState)state animated:(BOOL)animated;

// 收口函数 
- (void)transPanelState:(PanelState)state animated:(BOOL)animated changeFrom:(PanelStateChangeFrom)changeFrom;

- (CGFloat)finalDistanceToMax; // ratio=1时对应的值

- (void)updateMoveState:(BOOL)canMove;

/// 游动的修改panel的normalY以及设置动画参数
/// @param normalY 正常的y值
/// @param duration 动画时长
/// @param options 动画参数
/// @param changeFrom 改变前状态
- (void)transPanelToNormalY:(CGFloat)normalY
          animationDuration:(NSTimeInterval)duration
           animationOptions:(UIViewAnimationOptions)options
                 changeFrom:(PanelStateChangeFrom)changeFrom;

// 强制停止panel移动
- (void)stopPanelMove;

- (void)animationStopAction:(dispatch_block_t)stopBlock;

@end

@interface PanelHandleButton : UIButton

@end


NS_ASSUME_NONNULL_END
