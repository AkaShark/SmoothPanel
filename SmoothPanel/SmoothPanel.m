//
//  SmoothPanel.m
//  SmoothPanel
//
//  Created by Sharker on 2021/1/16.
//

#import "SmoothPanel.h"

@interface PanelPanGestureRecognizer ()

@property (nonatomic, assign) BOOL dragging; // 判断panel是否可以跟随移动的标志
@property (nonatomic, assign) CGFloat originY;
@property (nonatomic, assign) CGFloat originOffsetY;

@end

@implementation PanelPanGestureRecognizer

// 重写手势方法
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    // 手势加载的view是否是ScrollView
    // 找父视图 找到SmoothPanel
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        SmoothPanel *panel = (SmoothPanel *)self.view;
        while (panel.superview) {
            panel = (SmoothPanel *)panel.superview;
            if ([panel isKindOfClass:[SmoothPanel class]]) {
                break;
            }
        }
        // 修改y 这个y是作用在panel上的y
        self.originY = [[touches anyObject] locationInView:panel].y;
        self.originOffsetY = ((UIScrollView *)self.view).contentOffset.y;
        
        if ([panel isKindOfClass:[SmoothPanel class]] && panel.state != PandelStateMax) {
            // 非全屏状态，需要允许整体上拉
            if (!self.dragging) {
                self.dragging = YES;
                // panel响应事件
                [panel touchesBegan:touches withEvent:event];
            }
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        SmoothPanel *panel = (SmoothPanel *)self.view;
        while (panel.superview) {
            panel = (SmoothPanel *)panel.superview;
            if ([panel isKindOfClass:[SmoothPanel class]]) {
                break;
            }
        }
        
        CGFloat y = [[touches anyObject] locationInView:panel].y;
        if (y >= self.originY + self.originOffsetY) {
            // 下拉并且scrollview已经拉到顶，开始触发panel的跟随
            if (!self.dragging) {
                self.dragging = YES;
                [panel touchesBegan:touches withEvent:event];
            }
            [panel touchesMoved:touches withEvent:event];
            if (y >= self.originY) {
                [((UIScrollView *)self.view) setContentOffset:CGPointMake(0, 0)];
            }
        } else {
            // 上拉
            if ([panel isKindOfClass:[SmoothPanel class]] && panel.state != PandelStateMax) {
                // 非全屏状态，需要允许整体上拉
                if (!self.dragging) {
                    self.dragging = YES;
                    [panel touchesBegan:touches withEvent:event];
                }
            }
            if (self.dragging) {
                [panel touchesMoved:touches withEvent:event];
            }
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        SmoothPanel *panel = (SmoothPanel *)self.view;
        while (panel.superview) {
            panel = (SmoothPanel *)panel.superview;
            if ([panel isKindOfClass:[SmoothPanel class]]) {
                break;
            }
        }
        
        if (self.dragging) {
            [panel touchesEnded:touches withEvent:event];
            self.dragging = NO;
        }
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        SmoothPanel *panel = (SmoothPanel *)self.view;
        while (panel.superview) {
            panel = (SmoothPanel *)panel.superview;
            if ([panel isKindOfClass:[SmoothPanel class]]) {
                break;
            }
        }
        if (self.dragging) {
            [panel touchesCancelled:touches withEvent:event];
            self.dragging = NO;
        }
    }
}


@end

@interface SmoothPanel ()

@property (nonatomic, assign) CGFloat originY;

@property (nonatomic, assign) CGFloat originTouchPointY;

@property (nonatomic, assign) BOOL isAnimating;

@property (nonatomic, strong) UIButton *handleButton;

@property (nonatomic, strong) UIView *shadowView;

// 状态表示
@property (nonatomic, assign) BOOL hasHandleAnimated;

@property (nonatomic, assign) BOOL isCanMove;

@property (nonatomic, assign) BOOL isMoving;

// 回调
@property (nonatomic, copy) dispatch_block_t stopBlock;

@end

@implementation SmoothPanel

#pragma mark liftCycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.state = PandelStateNormal;
        self.maxY = 0;
        self.isAnimating = NO;
        self.hasHandleAnimated = NO;
        self.isCanMove = YES;
        [self addSubview:self.handle];
        [self addSubview:self.handleButton];
        [self addSubview:self.shadowView];
        // 监听是否挂起程序
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UI
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    // 执行动画的时候不改变大小
    if (self.isAnimating) {
        return;
    }
}

// 有动画的修改panel的NormalY以及设置动画参数
- (void)transPanelToNormalY:(CGFloat)normalY
          animationDuration:(NSTimeInterval)duration
           animationOptions:(UIViewAnimationOptions)options
                 changeFrom:(PanelStateChangeFrom)changeFrom {
    self.normalY = normalY;
    if (self.state == PandelStateNormal) {
        [self transPanelState:PandelStateNormal animated:YES animationTime:duration animationOptions:options changeFrom:changeFrom];
    }
    
}

- (void)transPanelState:(PanelState)state {
    [self transPanelState:state animated:NO changeFrom:PanelStateChangeFrom_UnKnown];
}
- (void)transPanelState:(PanelState)state changeFrom:(PanelStateChangeFrom)changeFrom {
    [self transPanelState:state animated:NO changeFrom:changeFrom];
}
- (void)transPanelState:(PanelState)state animated:(BOOL)animated {
    [self transPanelState:state animated:animated changeFrom:PanelStateChangeFrom_UnKnown];
}
- (void)transPanelState:(PanelState)state animated:(BOOL)animated changeFrom:(PanelStateChangeFrom)changeFrom {
    [self transPanelState:state animated:animated animationTime:0.25f animationOptions:UIViewAnimationOptionCurveEaseOut changeFrom:changeFrom];
}



// 外面接口调用的收口方法 设置动画的方法
- (void)transPanelState:(PanelState)state
               animated:(BOOL)animated
          animationTime:(CGFloat)animationTime
       animationOptions:(UIViewAnimationOptions)animationOptions
             changeFrom:(PanelStateChangeFrom)changeFrom {
    // 正在执行动画的直接返回
    if (self.isAnimating) {
        return;
    }
    PanelState finalState = state;
    
    if (![self hasMinState]) {
        // 如果normalY和minY设为一样的值，则无视min
        if (state == PandelStateMin) {
            finalState = PandelStateNormal;
        }
    }
    // 定义animationBlock
    void (^animationBlock)(void) = ^void() {
        CGFloat y = self.normalY;
        if (state == PandelStateMax) {
            y = self.maxY;
        } else if (state == PandelStateMin) {
            y = self.minY;
        } else if (state == PandelStateDefault) {
            y = self.defaultY;
        }
        CGRect rect = CGRectMake(self.frame.origin.x, y, self.frame.size.width, self.frame.size.height);
        [self setFrame:rect];
        // 隐藏shadow
        if (finalState == PandelStateMax) {
            self.shadowView.alpha = 0;
        } else {
            self.shadowView.alpha = 1;
        }
        // delegate willchange
        if ([self.delegate respondsToSelector:@selector(panelStateWillChange:)]) {
            [self.delegate panelStateWillChange:finalState];
        } else if ([self.delegate respondsToSelector:@selector(panelStateWillChange:changeFrom:)]) {
            [self.delegate panelStateWillChange:finalState changeFrom:changeFrom];
        }
        // 开始动画标记
        self.isAnimating = YES;
    };
    
    // 完成block
    void (^completionBlock)(BOOL) = ^void(BOOL finished) {
        if (self.state != finalState) {
            self.state = finalState;
        }
        // shadow 隐藏
        if (finalState == PandelStateMax) {
            self.shadowView.alpha = 0;
        } else {
            self.shadowView.alpha = 1;
        }
        // didchange
        if ([self.delegate respondsToSelector:@selector(panelStateDidChange:)]) {
            [self.delegate panelStateDidChange:finalState];
        } else if ([self.delegate respondsToSelector:@selector(panelStateDidChange:changeFrom:)]) {
            [self.delegate panelStateDidChange:finalState changeFrom:changeFrom];
        }
        self.originY = self.frame.origin.y;
//        if (finalState == PandelStateMax) {
//            [self.countingManager addOnce];
//        }
        // 动画标记改变
        self.isAnimating = NO;
        
        // stopBlock
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.stopBlock) {
                self.stopBlock();
                self.stopBlock = nil;
            }
        });
    };
    
    if (animated) {
        // 调用view动画
        [UIView animateWithDuration:animationTime delay:0 options:animationOptions animations:animationBlock completion:completionBlock];
    } else {
        
        animationBlock();
        completionBlock(YES);
    }
    
}

- (void)animationStopAction:(dispatch_block_t)stopBlock {
    
    if (self.isAnimating) {
        [self.layer removeAllAnimations];
        self.stopBlock = stopBlock;
        return;
    }
    
    if (stopBlock) {
        stopBlock();
    }
}

// 根据移动距离计算阴影
- (void)updateMoveDistance:(CGFloat)distance {
    if (self.maxY == self.normalY) {
        CGFloat distanceToMax = self.minY - self.frame.origin.y;
        if (self.normalY >= self.frame.origin.y) {
            distanceToMax = self.minY - self.normalY;
        }
        if (self.minY != self.normalY) {
            CGFloat ratio = distanceToMax / (MIN(self.minY - self.normalY, 300));
            if (ratio < 0) ratio = 0;
            if (ratio > 1) ratio = 1;
            self.shadowView.alpha = (1 - ratio);
            if ([self.delegate respondsToSelector:@selector(panelMoveDistance:distanceToMax:ratio:)]) {
                [self.delegate panelMoveDistance:distance distanceToMax:distanceToMax ratio:ratio];
            }
        }
    } else {
        CGFloat distanceToMax = self.normalY - self.frame.origin.y;
        CGFloat ratio = distanceToMax / [self finalDistanceToMax];
        if (ratio < 0) ratio = 0;
        if (ratio > 1) ratio = 1;
        
        self.shadowView.alpha = (1 - ratio);
        if ([self.delegate respondsToSelector:@selector(panelMoveDistance:distanceToMax:ratio:)]) {
            [self.delegate panelMoveDistance:distance distanceToMax:distanceToMax ratio:ratio];
        }
    }
}

- (CGFloat)finalDistanceToMax {
    CGFloat maxY = self.maxY;
    if (maxY < 0) {
        maxY = 0;
    }
    return MIN(self.normalY - maxY, 300);
}

# pragma mark touches 处理滑动事件 
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.isCanMove) {
        return;
    }
    
    if (self.isMoving) {
        return;
    }
    self.isMoving = YES;
    CGPoint point = [[touches anyObject] locationInView:self.superview];
    self.originTouchPointY = point.y;
    self.originY = self.frame.origin.y;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.isCanMove) {
        return;
    }
    if (!self.isMoving) {
        return;
    }
    CGPoint point = [[touches anyObject] locationInView:self.superview];
    CGFloat offset = self.originTouchPointY - point.y;
    CGRect rect = self.frame;
    rect.origin.y = self.originY - offset;
    
    if (rect.origin.y < self.maxY) {
        rect.origin.y = self.maxY;
    }
    if (self.minY > 0) {
        if (rect.origin.y > self.minY) {
            rect.origin.y = self.minY;
        }
    }
    [self setFrame:rect];
    [self updateMoveDistance:-offset];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.isCanMove) {
        return;
    }
    if (!self.isMoving) {
        return;
    }
    self.isMoving = NO;
    CGFloat y = self.frame.origin.y;
    
    CGPoint point = [[touches anyObject] locationInView:self.superview];
    CGFloat offset = self.originTouchPointY - point.y;
    
    // 上拉下拉
    PanelStateChangeFrom changeFrom = offset > 0 ?PanelStateChangeFrom_DragUp: PanelStateChangeFrom_DragDown;
    
    if (self.state == PandelStateNormal) {
        if (y < (_normalY - _maxY) * 0.8 + _maxY) {
            [self transPanelState:PandelStateMax animated:YES changeFrom:changeFrom];
            [self impact];
        }
        else if (y > (_minY - _normalY) * 0.2 + _normalY && [self hasMinState]) {
            [self transPanelState:PandelStateMin animated:YES changeFrom:changeFrom];
            [self impact];
        }
        else if (fabs(y - self.originY) > 1) {
            [self transPanelState:PandelStateNormal animated:YES changeFrom:changeFrom];
        }
    }
    else if (self.state == PandelStateMax) {
        if (y > (_minY - _normalY) * 0.2 + _normalY) {
            [self transPanelState:PandelStateMin animated:YES changeFrom:changeFrom];
            [self impact];
        }
        else if (y > (_normalY - _maxY) * 0.2 + _maxY) {
            [self transPanelState:PandelStateNormal animated:YES changeFrom:changeFrom];
            [self impact];
        }
        else if (fabs(y - self.originY) > 1) {
            [self transPanelState:PandelStateMax animated:YES changeFrom:changeFrom];
        }
    }
    else if (self.state == PandelStateMin) {
        if (y < (_normalY - _maxY) * 0.8 + _maxY) {
            [self transPanelState:PandelStateMax animated:YES changeFrom:changeFrom];
            [self impact];
        }
        else if (y < (_minY - _normalY) * 0.8 + _normalY) {
            [self transPanelState:PandelStateNormal animated:YES changeFrom:changeFrom];
            [self impact];
        }
        else if (fabs(y - self.originY) > 1){
            [self transPanelState:PandelStateNormal animated:YES changeFrom:changeFrom];
        }
    }
}


# pragma mark helper

- (void)onHandleButtonClick:(UIButton *)btn {
    if (self.state != PandelStateMax && ![self hasMinState]) {
        // 渐出
        [self transPanelState:PandelStateMax animated:YES animationTime:0.4f animationOptions:UIViewAnimationOptionCurveEaseOut changeFrom:PanelStateChangeFrom_Click];
    }
}

- (BOOL)hasMinState {
    return fabs(self.normalY - self.minY) > 1;
}

- (void)impact {
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedBackGenertor = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [feedBackGenertor impactOccurred];
    }
}

- (void)stopPanelMove {
    [self touchesEnded:[NSSet set] withEvent:[UIEvent new]];
}

- (void)onEnterBackground {
    [self touchesEnded:[NSSet set] withEvent:[UIEvent new]];
}

- (void)updateMoveState:(BOOL)canMove {
    self.isCanMove = canMove;
}


#pragma mark setter
- (void)setNormalY:(CGFloat)normalY {
    _normalY = normalY;
    if (self.state == PandelStateNormal) {
        [self transPanelState:PandelStateNormal animated:NO changeFrom:PanelStateChangeFrom_SetValue];
    }
}

- (void)setMinY:(CGFloat)minY {
    _minY = minY;
    if (self.state == PandelStateMin) {
        [self transPanelState:PandelStateMin animated:NO changeFrom:PanelStateChangeFrom_SetValue];
    }
}

- (void)setMaxY:(CGFloat)maxY {
    _maxY = maxY;
    if (self.state == PandelStateMax) {
        [self transPanelState:PandelStateMax animated:NO changeFrom:PanelStateChangeFrom_SetValue];
    }
}

# pragma mark lazy

- (UIView *)handle {
    if (!_handle) {
        // bar
        _handle = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 20.5, 7.5, 41, 5)];
        [_handle setBackgroundColor:[UIColor colorWithRed:192.0/225.0 green:192.0/255.0 blue:192.0/255.0 alpha:1]];
        [_handle.layer setMasksToBounds:YES];
        [_handle.layer setCornerRadius:2.5];
    }
    return _handle;
}

- (UIButton *)handleButton {
    if (!_handleButton) {
        _handleButton = [[PanelHandleButton alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 30, 0, 60, 20)];
        [_handleButton addTarget:self action:@selector(onHandleButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _handleButton;
}

- (UIView *)shadowView {
    // 添加CAGradientLayer来实现阴影效果 不用layer的shadow 防止离屏渲染
    if (!_shadowView) {
        _shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, -12, self.bounds.size.width, 12)];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = _shadowView.bounds;
        gradient.colors = @[(id)[UIColor colorWithWhite:0 alpha:0].CGColor, (id)[UIColor colorWithWhite:0 alpha:0.06].CGColor];
        gradient.startPoint = CGPointMake(0, 0);
        gradient.endPoint = CGPointMake(0, 1);
        [_shadowView.layer addSublayer:gradient];
    }
    return _shadowView;
}


@end

@implementation PanelHandleButton

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self.nextResponder touchesBegan:touches withEvent:event];

}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    [self.nextResponder touchesMoved:touches withEvent:event];
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self.nextResponder touchesEnded:touches withEvent:event];
}

@end
