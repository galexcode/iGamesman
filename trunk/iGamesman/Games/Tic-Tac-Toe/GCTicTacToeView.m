//
//  GCTicTacToeView.m
//  iGamesman
//
//  Created by Kevin Jorgensen on 1/10/12.
//  Copyright (c) 2012 GamesCrafters. All rights reserved.
//

#import "GCTicTacToeView.h"

#import "GCUtilities.h"
#import "GCTicTacToePosition.h"


@implementation GCTicTacToeView

@synthesize delegate = _delegate;


- (id) initWithFrame: (CGRect) frame
{
    self = [super initWithFrame: frame];
    
    if (self)
    {
        [self setOpaque: NO];
        
        _acceptingTouches = NO;
    }
    
    return self;
}


#pragma mark - Touch handling

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
    if (!_acceptingTouches)
        return;
    
    
    GCTicTacToePosition *position = [_delegate position];
    
    CGPoint location = [[touches anyObject] locationInView: self];
    
    CGFloat width  = [self bounds].size.width;
    CGFloat height = [self bounds].size.height;
    
    CGFloat maxCellWidth  = (width / [position columns]);
    CGFloat maxCellHeight = (height / [position rows]);
    
    CGFloat cellSize = MIN(maxCellWidth, maxCellHeight);
    
    CGFloat originX = CGRectGetMinX([self bounds]) + (width - [position columns] * cellSize) / 2.0f;
    CGFloat originY = CGRectGetMinY([self bounds]) + (height - [position rows] * cellSize) / 2.0f;
    
    for (int row = 0; row < [position rows]; row += 1)
    {
        for (int column = 0; column < [position columns]; column += 1)
        {
            CGRect cellRect = CGRectMake(originX + column * cellSize, originY + row * cellSize, cellSize, cellSize);
            
            if (CGRectContainsPoint(cellRect, location))
            {
                NSNumber *slotNumber = [NSNumber numberWithInt: row * [position columns] + column];
                if ([[[position board] objectAtIndex: [slotNumber unsignedIntegerValue]] isEqualToString: GCTTTBlankPiece])
                    [_delegate userChoseMove: slotNumber];
            }
        }
    }
}


#pragma mark -

- (void) startReceivingTouches
{
    _acceptingTouches = YES;
}


- (void) stopReceivingTouches
{
    _acceptingTouches = NO;
}


#pragma mark - Drawing

- (void) drawXInRect: (CGRect) rect intoContext: (CGContextRef) ctx
{
    CGContextSetRGBStrokeColor(ctx, 0, 0, 1, 1);
    CGContextSetLineWidth(ctx, rect.size.width * 0.1f);
    
    CGFloat insetX = rect.size.width * 0.15f;
    CGFloat insetY = rect.size.height * 0.15f;
    
    CGRect insetRect = CGRectInset(rect, insetX, insetY);
    
    CGFloat minX = CGRectGetMinX(insetRect);
    CGFloat minY = CGRectGetMinY(insetRect);
    CGFloat maxX = CGRectGetMaxX(insetRect);
    CGFloat maxY = CGRectGetMaxY(insetRect);
    
    CGContextMoveToPoint(ctx, minX, minY);
    CGContextAddLineToPoint(ctx, maxX, maxY);
    
    CGContextMoveToPoint(ctx, minX, maxY);
    CGContextAddLineToPoint(ctx, maxX, minY);
    
    CGContextStrokePath(ctx);
}


- (void) drawOInRect: (CGRect) rect intoContext: (CGContextRef) ctx
{
    CGContextSetRGBStrokeColor(ctx, 1, 0, 0, 1);
    CGContextSetLineWidth(ctx, rect.size.width * 0.1f);
    
    CGFloat insetX = rect.size.width * 0.15f;
    CGFloat insetY = rect.size.height * 0.15f;
    
    CGContextStrokeEllipseInRect(ctx, CGRectInset(rect, insetX, insetY));
}


- (void) drawRect: (CGRect) rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
#ifdef DEMO
    CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.5f);
    CGContextFillRect(ctx, [self bounds]);
#endif
    
    GCTicTacToePosition *position = [_delegate position];
    
    CGFloat width  = [self bounds].size.width;
    CGFloat height = [self bounds].size.height;
    
    CGFloat maxCellWidth  = (width / [position columns]);
    CGFloat maxCellHeight = (height / [position rows]);
    
    CGFloat cellSize = MIN(maxCellWidth, maxCellHeight);
    
    CGFloat originX = CGRectGetMinX([self bounds]) + (width - [position columns] * cellSize) / 2.0f;
    CGFloat originY = CGRectGetMinY([self bounds]) + (height - [position rows] * cellSize) / 2.0f;
    
    
    CGRect backgroundRect = CGRectMake(originX, originY, cellSize * [position columns], cellSize * [position rows]);
    
    /* Background rectangle */
    CGContextSetRGBFillColor(ctx, 0.5f, 0.5f, 0.5f, 1);
    CGContextFillRect(ctx, backgroundRect);
    
    /* Inset the board inside the background rectangle (need to recompute originX/Y and cellSize) */
    CGRect boardRect = CGRectInset(backgroundRect, cellSize * 0.05f, cellSize * 0.05f);
    maxCellWidth = boardRect.size.width / [position columns];
    maxCellHeight = boardRect.size.height / [position rows];
    cellSize = MIN(maxCellWidth, maxCellHeight);
    originX = CGRectGetMinX([self bounds]) + (width - [position columns] * cellSize) / 2.0f;
    originY = CGRectGetMinY([self bounds]) + (height - [position rows] * cellSize) / 2.0f;
    
    /* Horizontal separators */
    for (NSUInteger i = 1; i < [position columns]; i += 1)
    {
        CGContextMoveToPoint(ctx, originX + cellSize * i, originY);
        CGContextAddLineToPoint(ctx, originX + cellSize * i, originY + [position rows] * cellSize);
    }
    
    /* Vertical separators */
    for (NSUInteger j = 1; j < [position rows]; j += 1)
    {
        CGContextMoveToPoint(ctx, originX, originY + cellSize * j);
        CGContextAddLineToPoint(ctx, originX + cellSize * [position columns], originY + cellSize * j);
    }
    
    /* Draw the separators */
    CGContextSetRGBStrokeColor(ctx, 1, 1, 1, 1);
    CGContextSetLineWidth(ctx, width / 100.0f);
    CGContextStrokePath(ctx);
    
    
    NSArray *moveValues = [_delegate moveValues];
    NSArray *remotenessValues = [_delegate remotenessValues];
    
    NSArray *sortedValues = [GCValuesHelper sortedValuesForMoveValues: moveValues remotenesses: remotenessValues];
    
    /* For each position in the board */
    for (NSUInteger i = 0; i < [[position board] count]; i += 1)
    {
        GCTTTPiece piece = [[position board] objectAtIndex: i];
        GCGameValue *value = [moveValues objectAtIndex: i];
        NSInteger remoteness = [[remotenessValues objectAtIndex: i] integerValue];
        
        NSUInteger row = i / [position columns];
        NSUInteger column = i % [position columns];
        
        CGRect cellRect = CGRectMake(originX + column * cellSize, originY + row * cellSize, cellSize, cellSize);
        
        
        if (value && ![value isEqualToString: GCGameValueUnknown] && [_delegate isShowingMoveValues])
        {
            CGFloat alpha = 1;
            
            if ([_delegate isShowingDeltaRemoteness])
            {
                alpha = 0.2f;
                
                if ([sortedValues count] > 0)
                {
                    NSArray *pair = [sortedValues objectAtIndex: 0];
                    GCGameValue *v = [pair objectAtIndex: 0];
                    NSNumber *n = [pair objectAtIndex: 1];
                    
                    if ([v isEqualToString: value] && ([n integerValue] == remoteness))
                        alpha = 1;
                }
                
                if ([sortedValues count] > 1)
                {
                    NSArray *pair = [sortedValues objectAtIndex: 1];
                    GCGameValue *v = [pair objectAtIndex: 0];
                    NSNumber *n = [pair objectAtIndex: 1];
                    
                    if ([v isEqualToString: value] && ([n integerValue] == remoteness))
                        alpha = 0.5f;
                }
                
                if ([sortedValues count] > 2)
                {
                    NSArray *pair = [sortedValues objectAtIndex: 2];
                    GCGameValue *v = [pair objectAtIndex: 0];
                    NSNumber *n = [pair objectAtIndex: 1];
                    
                    if ([v isEqualToString: value] && ([n integerValue] == remoteness))
                        alpha = 0.3f;
                }
            }
            
            GCColor color = {0.0f, 0.0f, 0.0f};
            if ([value isEqualToString: GCGameValueWin])
                color = [GCConstants winColor];
            else if ([value isEqualToString: GCGameValueLose])
                color = [GCConstants loseColor];
            else if ([value isEqualToString: GCGameValueTie])
                color = [GCConstants tieColor];
            CGContextSetRGBFillColor(ctx, color.red, color.green, color.blue, alpha);
            
            CGContextFillEllipseInRect(ctx, CGRectInset(cellRect, cellSize / 3.0f, cellSize / 3.0f));
        }
        
        
        if (piece == GCTTTXPiece)
            [self drawXInRect: cellRect intoContext: ctx];
        else if (piece == GCTTTOPiece)
            [self drawOInRect: cellRect intoContext: ctx];
    }
}

@end
