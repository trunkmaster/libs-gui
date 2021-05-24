/* Implementation of class NSStackView
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento <greg.casamento@gmail.com>
   Date: 08-08-2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import "AppKit/NSStackView.h"
#import "GSFastEnumeration.h"

@interface NSView (__NSViewPrivateMethods__)
- (void) _insertSubview: (NSView *)sv atIndex: (NSUInteger)idx; // implemented in NSView.m
@end

@interface NSView (__StackViewPrivate__)
- (void) insertView: (NSView *)v atIndex: (NSUInteger)i;
- (void) removeAllSubviews;
- (void) addSubviews: (NSArray *)views;
@end

@implementation NSView (__StackViewPrivate__)
- (void) insertView: (NSView *)v atIndex: (NSUInteger)i
{
  [self _insertSubview: v atIndex: i];
}

- (void) removeAllSubviews
{
  NSArray *subviews = [self subviews];
  FOR_IN(NSView*, v, subviews)
    {
      [v removeFromSuperview];
    }
  END_FOR_IN(subviews);
}

- (void) addSubviews: (NSArray *)views
{
  FOR_IN(NSView*, v, views)
    {
      [self addSubview: v];
    }
  END_FOR_IN(views);
}
@end

@interface NSStackViewContainer : NSView
@end

@implementation NSStackViewContainer
@end

@implementation NSStackView

- (void) _layoutViewsInView: (NSView *)view withOrientation: (NSUserInterfaceLayoutOrientation)o
{
  NSRect currentFrame = [view frame];
  NSRect newFrame = currentFrame;
  NSSize s = currentFrame.size;
  NSArray *sv = [view subviews];
  NSUInteger n = [sv count];
  CGFloat sp = 0.0;
  CGFloat x = 0.0;
  CGFloat y = 0.0;
  CGFloat newHeight = 0.0;
  CGFloat newWidth = 0.0;
  NSUInteger i = 0;
  
  if ([view isKindOfClass: [NSStackViewContainer class]])
    {
      sp = (s.height / (CGFloat)n); // / 2.0;
    }
  if ([view isKindOfClass: [NSStackView class]])
    {
      sp = [(NSStackView *)view spacing];
    }

  NSLog(@"Subviews = %ld", n);
  NSLog(@"Spacing = %f", sp);

  if (o == NSUserInterfaceLayoutOrientationVertical)
    {
      if (sp == 0.0)
        {
          if (n >= 0)
            {
              NSView *v = [sv objectAtIndex: 0];
              sp = [v frame].size.height;
            }
        }

      newFrame.size.height += sp; // * 2; // expand height
      newFrame.origin.y -= (sp / 2.0); // move the view down.
      newHeight = newFrame.size.height; // start at top of view...
    }
  else
    {
      if (sp == 0.0)
        {
          if (n >= 0)
            {
              NSView *v = [sv objectAtIndex: 0];
              sp = [v frame].size.width;
            }
        }

      newFrame.size.width += sp;
      newWidth = newFrame.size.width;
    }
  
  NSLog(@"frame for stack view %@", NSStringFromRect(newFrame));
  [view setFrame: newFrame];
  FOR_IN(NSView*,v,sv)
    {
      NSRect f; 
      
      f = [v frame];
      if (f.origin.x < 0.0)
        {
          f.origin.x = 0.0;
        }

      if (o == NSUserInterfaceLayoutOrientationVertical)
        {
          y = (newHeight - ((CGFloat)i * sp)) - f.size.height;              
          f.origin.y = y;
        }
      else
        {
          x = ((CGFloat)i * sp);
          f.origin.x = x;
        }
      
      [v setFrame: f];
      NSLog(@"new frame = %@", NSStringFromRect(f));
      i++;
    }
  END_FOR_IN(sv);
  [view setNeedsDisplay: YES];
}

- (void) _refreshView
{
  NSRect currentFrame = [self frame];
  NSLog(@"orientation = %ld", _orientation);
  NSLog(@"distribution = %ld, _beginningContainer = %@", _distribution, _beginningContainer);

  if (_orientation == NSUserInterfaceLayoutOrientationHorizontal)
    {
      if (_beginningContainer != nil)
        {
          NSSize s = currentFrame.size;
          CGFloat w = s.width / 3.0; // three sections, always.
          CGFloat h = s.height; // since we are horiz. the height is the height of the view
          NSUInteger i = 0;
          CGFloat y = 0.0;
          CGFloat x = 0.0;

          // NSLog(@"Size = %@", NSStringFromSize(s));
          
          for (i = 0; i < 3; i++)
            {
              NSRect f;

              x = w * (CGFloat)i;
              f = NSMakeRect(x,y,w,h);
              
              if (i == 0)
                {
                  [_beginningContainer setFrame: f];
                  [self addSubview: _beginningContainer];
                }
              if (i == 1)
                {
                  [_middleContainer setFrame: f];
                  [self addSubview: _middleContainer];
                }
              if (i == 2)
                {
                  [_endContainer setFrame: f];
                  [self addSubview: _endContainer];
                }
            }
        }
      else
        {
          [self _layoutViewsInView: self withOrientation: _orientation];
          NSLog(@"Horizontal no containers");
        }
    }
  else
    {
      if (_beginningContainer != nil) // if one exists, they all do...
        {
          NSSize s = currentFrame.size;
          CGFloat w = s.width; // since vert... w is constant...
          CGFloat h = s.height / 3.0; // 3 sections
          NSUInteger i = 0;
          CGFloat y = 0.0;
          CGFloat x = 0.0;

          // NSLog(@"V. Size = %@", NSStringFromSize(s));
          
          for (i = 0; i < 3; i++)
            {
              NSRect f;

              y = h * (CGFloat)i;
              f = NSMakeRect(x,y,w,h);
              
              if (i == 0)
                {
                  [_beginningContainer setFrame: f];
                  NSLog(@"Adding beginning container with frame %@", NSStringFromRect(f));
                  [self addSubview: _beginningContainer];
                }
              if (i == 1)
                {
                  [_middleContainer setFrame: f];
                  NSLog(@"Adding mid container with frame %@", NSStringFromRect(f));
                  [self addSubview: _middleContainer];
                }
              if (i == 2)
                {
                  [_endContainer setFrame: f];
                  NSLog(@"Adding end container with frame %@", NSStringFromRect(f));
                  [self addSubview: _endContainer];
                }
            }
        }
      else
        {
          [self _layoutViewsInView: self withOrientation: _orientation];
          NSLog(@"Vertical no containers");
        }
    }
  [self setNeedsDisplay: YES];
}

// Properties
- (void) setDelegate: (id<NSStackViewDelegate>)delegate
{
  _delegate = delegate;
}

- (id<NSStackViewDelegate>) delegate
{
  return _delegate;
}

- (void) setOrientation: (NSUserInterfaceLayoutOrientation)o
{
  _orientation = o;
  [self _refreshView];
}

- (NSUserInterfaceLayoutOrientation) orientation
{
  return _orientation;
}

- (void) setAlignment: (NSLayoutAttribute)alignment
{
  _alignment = alignment;
  [self _refreshView];
}

- (NSLayoutAttribute) alignment
{
  return _alignment;
}

- (void) setEdgeInsets: (NSEdgeInsets)insets
{
  _edgeInsets = insets;
  [self _refreshView];
}

- (NSEdgeInsets) edgeInsets
{
  return _edgeInsets;
}

- (void) setDistribution: (NSStackViewDistribution)d
{
  _distribution = d;
  [self _refreshView];
}

- (NSStackViewDistribution) distribution
{
  return _distribution;
}

- (void) setSpacing: (CGFloat)f
{
  _spacing = f;
  [self _refreshView];
}

- (CGFloat) spacing
{
  return _spacing;
}

- (void) setDetachesHiddenViews: (BOOL)f
{
  _detachesHiddenViews = f;
}

- (BOOL) detachesHiddenViews
{
  return _detachesHiddenViews;
}

- (void) setArrangedSubviews: (NSArray *)arrangedSubviews
{
  ASSIGN(_arrangedSubviews, arrangedSubviews);
}

- (NSArray *) arrangedSubviews
{
  return _arrangedSubviews;
}

- (void) setDetachedViews: (NSArray *)detachedViews
{
  ASSIGN(_detachedViews, detachedViews);
}

- (NSArray *) detachedViews
{
  return _detachedViews;
}

// Instance methods
// Manage views...
- (instancetype) initWithViews: (NSArray *)views
{
  self = [super init];
  if (self != nil)
    {
      NSUInteger c = [views count];
      
      _arrangedSubviews = [[NSMutableArray alloc] initWithArray: views];
      _detachedViews = [[NSMutableArray alloc] initWithCapacity: c];
      ASSIGNCOPY(_views, views);
      _customSpacingMap = RETAIN([NSMapTable weakToWeakObjectsMapTable]);
      _visiblePriorityMap = RETAIN([NSMapTable weakToWeakObjectsMapTable]);

      // Gravity...  not used by default.
      _beginningContainer = nil; // [[NSStackViewContainer alloc] init];
      _middleContainer = nil; // [[NSStackViewContainer alloc] init]; 
      _endContainer = nil; // [[NSStackViewContainer alloc] init];

      [self _refreshView];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_arrangedSubviews);
  RELEASE(_detachedViews);
  RELEASE(_views);
  RELEASE(_customSpacingMap);
  RELEASE(_visiblePriorityMap);

  RELEASE(_beginningContainer);
  RELEASE(_middleContainer);
  RELEASE(_endContainer);
  
  _delegate = nil;
  [super dealloc];
}

+ (instancetype) stackViewWithViews: (NSArray *)views
{
  return AUTORELEASE([[self alloc] initWithViews: views]);
}

- (void) setCustomSpacing: (CGFloat)spacing afterView: (NSView *)v
{
  if (_hasEqualSpacing == NO)
    {
      NSNumber *n = [NSNumber numberWithFloat: spacing];
      [_customSpacingMap setObject: n
                            forKey: v];
      [self _refreshView];
    }
}

- (CGFloat) customSpacingAfterView: (NSView *)v
{
  return [[_customSpacingMap objectForKey: v] floatValue];
}

- (void) addArrangedSubview: (NSView *)v
{
  [_arrangedSubviews addObject: v];
  [self _refreshView];
}

- (void) insertArrangedSubview: (NSView *)v atIndex: (NSInteger)idx
{
  [_arrangedSubviews insertObject: v atIndex: idx];
}

- (void) removeArrangedSubview: (NSView *)v
{
  [_arrangedSubviews removeObject: v];
}

// Custom priorities
- (void)setVisibilityPriority: (NSStackViewVisibilityPriority)priority
                      forView: (NSView *)v
{
  NSNumber *n = [NSNumber numberWithInteger: priority];
  [_visiblePriorityMap setObject: n
                          forKey: v];
  [self _refreshView];
}

- (NSStackViewVisibilityPriority) visibilityPriorityForView: (NSView *)v
{
  NSNumber *n = [_visiblePriorityMap objectForKey: v];
  NSStackViewVisibilityPriority p = (NSStackViewVisibilityPriority)[n integerValue];
  return p;
}
 
- (NSLayoutPriority)clippingResistancePriorityForOrientation:(NSLayoutConstraintOrientation)o
{
  NSLayoutPriority p = 0L;
  if (o == NSLayoutConstraintOrientationHorizontal)
    {
      p = _horizontalClippingResistancePriority;
    }
  else if (o == NSLayoutConstraintOrientationVertical)
    {
      p = _verticalClippingResistancePriority;
    }
  return p;
}

- (void) setClippingResistancePriority: (NSLayoutPriority)clippingResistancePriority
                        forOrientation: (NSLayoutConstraintOrientation)o
{
  if (o == NSLayoutConstraintOrientationHorizontal)
    {
      _horizontalClippingResistancePriority = clippingResistancePriority;
    }
  else if (o == NSLayoutConstraintOrientationVertical)
    {
      _verticalClippingResistancePriority = clippingResistancePriority;
    }
  [self _refreshView];
}

- (NSLayoutPriority) huggingPriorityForOrientation: (NSLayoutConstraintOrientation)o
{
  NSLayoutPriority p = 0L;
  if (o == NSLayoutConstraintOrientationHorizontal)
    {
      p = _horizontalHuggingPriority;
    }
  else if (o == NSLayoutConstraintOrientationVertical)
    {
      p = _verticalHuggingPriority;
    }
  return p;
}

- (void) setHuggingPriority: (NSLayoutPriority)huggingPriority
             forOrientation: (NSLayoutConstraintOrientation)o
{
  if (o == NSLayoutConstraintOrientationHorizontal)
    {
      _horizontalHuggingPriority = huggingPriority;
    }
  else if (o == NSLayoutConstraintOrientationVertical)
    {
      _verticalHuggingPriority = huggingPriority;
    }
  [self _refreshView];
}

- (void) setHasEqualSpacing: (BOOL)f
{
  _hasEqualSpacing = f;
}

- (BOOL) hasEqualSpacing
{
  return _hasEqualSpacing;
}

- (void)addView: (NSView *)view inGravity: (NSStackViewGravity)gravity
{
  if (_beginningContainer != nil)
    {
      switch (gravity)
        {
        case NSStackViewGravityTop:  // or leading...
          [_beginningContainer addSubview: view];
          break;
        case NSStackViewGravityCenter:
          [_middleContainer addSubview: view];
          break;
        case NSStackViewGravityBottom:
          [_endContainer addSubview: view]; // or trailing...
          break;
        default:
          [NSException raise: NSInternalInconsistencyException
                      format: @"Attempt to add view %@ to unknown container %ld.", view, gravity];
          break;
        }
    }
  else
    {
      [self addSubview: view];
    }
  
  [self _refreshView];
}

- (void)insertView: (NSView *)view atIndex: (NSUInteger)index inGravity: (NSStackViewGravity)gravity
{
  switch (gravity)
    {
    case NSStackViewGravityTop:  // or leading...
      [_beginningContainer insertView: view atIndex: index];
      break;
    case NSStackViewGravityCenter:
      [_middleContainer insertView: view atIndex: index];
      break;
    case NSStackViewGravityBottom:
      [_endContainer insertView: view atIndex: index]; // or trailing...
      break;
    default:
      [NSException raise: NSInternalInconsistencyException
                  format: @"Attempt insert view %@ at index %ld into unknown container %ld.", view, index, gravity];
      break;
    }
  [self _refreshView];
}

- (void)removeView: (NSView *)view
{
  [view removeFromSuperview];
  [self _refreshView];
}

- (NSArray *) viewsInGravity: (NSStackViewGravity)gravity
{
  NSMutableArray *result = [NSMutableArray array];

  if (_beginningContainer != nil)
    {
      switch (gravity)
        {
        case NSStackViewGravityTop:  // or leading...
          [result addObjectsFromArray: [_beginningContainer subviews]];
          break;
        case NSStackViewGravityCenter:
          [result addObjectsFromArray: [_middleContainer subviews]];
          break;
        case NSStackViewGravityBottom:
          [result addObjectsFromArray: [_endContainer subviews]];
          break;
        default:
          [NSException raise: NSInternalInconsistencyException
                      format: @"Attempt get array of views from unknown gravity %ld.", gravity];
          break;
        }
    }
  
  return result;
}

- (void)setViews: (NSArray *)views inGravity: (NSStackViewGravity)gravity
{
  if (_beginningContainer != nil)
    {
      switch (gravity)
        {
        case NSStackViewGravityTop:  // or leading...
          [_beginningContainer removeAllSubviews];
          [_beginningContainer addSubviews: views];
          break;
        case NSStackViewGravityCenter:
          [_middleContainer removeAllSubviews];
          [_middleContainer addSubviews: views];
          break;
        case NSStackViewGravityBottom:
          [_endContainer removeAllSubviews];
          [_endContainer addSubviews: views];
          break;
        default:
          [NSException raise: NSInternalInconsistencyException
                      format: @"Attempt set array of views %@ into unknown gravity %ld.", views, gravity];
          break;
        }
    }
  else
    {
      FOR_IN(NSView*,v,views)
        {
          [self addSubview: v];
        }
      END_FOR_IN(views);
    }
  
  [self _refreshView];
}

- (void) setViews: (NSArray *)views
{
  ASSIGN(_arrangedSubviews, views);
  [self _refreshView];
}

- (NSArray *) views
{
  return _arrangedSubviews;
}

// Encoding...
- (void) encodeWithCoder: (NSCoder *)coder
{
  [super encodeWithCoder: coder];
  if ([coder allowsKeyedCoding])
    {
      [coder encodeInteger: _alignment forKey: @"NSStackViewAlignment"];
      [coder encodeObject: _beginningContainer forKey: @"NSStackViewBeginningContainer"];
      [coder encodeObject: _middleContainer forKey: @"NSStackViewMiddleContainer"];
      [coder encodeObject: _endContainer forKey: @"NSStackViewEndContainer"];
      [coder encodeBool: _detachesHiddenViews forKey: @"NSStackViewDetachesHiddenViews"];
      [coder encodeFloat: _edgeInsets.bottom forKey: @"NSStackViewEdgeInsets.bottom"];
      [coder encodeFloat: _edgeInsets.left forKey: @"NSStackViewEdgeInsets.left"];
      [coder encodeFloat: _edgeInsets.right forKey: @"NSStackViewEdgeInsets.right"];
      [coder encodeFloat: _edgeInsets.top forKey: @"NSStackViewEdgeInsets.top"];
      [coder encodeBool: _hasFlagViewHierarchy forKey: @"NSStackViewHasFlagViewHierarchy"];
      [coder encodeFloat: _horizontalClippingResistancePriority forKey: @"NSStackViewHorizontalClippingResistance"];
      [coder encodeFloat: _horizontalHuggingPriority forKey: @"NSStackViewHorizontalHuggingPriority"];
      [coder encodeInteger: _orientation forKey: @"NSStackViewOrientation"];
      [coder encodeInteger: _alignment forKey: @"NSStackViewSecondaryAlignment"];
      [coder encodeFloat: _spacing forKey: @"NSStackViewSpacing"];
      [coder encodeFloat: _verticalClippingResistancePriority forKey: @"NSStackViewVerticalClippingResistance"];
      [coder encodeFloat: _verticalHuggingPriority forKey: @"NSStackViewVerticalHuggingPriority"];
      [coder encodeInteger: _distribution forKey: @"NSStackViewdistribution"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(NSUInteger)
                                at: &_alignment];
      [coder encodeObject: _beginningContainer];
      [coder encodeObject: _middleContainer];
      [coder encodeObject: _endContainer];
      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_detachesHiddenViews];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_edgeInsets.bottom];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_edgeInsets.left];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_edgeInsets.right];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_edgeInsets.top];
      [coder encodeValueOfObjCType: @encode(BOOL)
                                at: &_hasFlagViewHierarchy];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_horizontalClippingResistancePriority];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_horizontalHuggingPriority];
      [coder encodeValueOfObjCType: @encode(NSInteger)
                                at: &_orientation];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_secondaryAlignment];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_spacing];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_verticalClippingResistancePriority];
      [coder encodeValueOfObjCType: @encode(CGFloat)
                                at: &_verticalHuggingPriority];
      [coder encodeValueOfObjCType: @encode(NSInteger)
                                at: &_distribution];
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          if ([coder containsValueForKey: @"NSStackViewAlignment"])
            {
              _alignment = [coder decodeIntForKey: @"NSStackViewAlignment"];
            }
          if ([coder containsValueForKey: @"NSStackViewBeginningContainer"])
            {
              ASSIGN(_beginningContainer, [coder decodeObjectForKey: @"NSStackViewBeginningContainer"]);
              NSLog(@"_beginningContainer = %@", _beginningContainer);
            }
          if ([coder containsValueForKey: @"NSStackViewMiddleContainer"])
            {
              ASSIGN(_middleContainer, [coder decodeObjectForKey: @"NSStackViewMiddleContainer"]);
            }
          if ([coder containsValueForKey: @"NSStackViewEndContainer"])
            {
              ASSIGN(_endContainer, [coder decodeObjectForKey: @"NSStackViewEndContainer"]);
            }
          if ([coder containsValueForKey: @"NSStackViewDetachesHiddenViews"])
            {
              _detachesHiddenViews = [coder decodeBoolForKey: @"NSStackViewDetachesHiddenViews"];
            }
          if ([coder containsValueForKey: @"NSStackViewEdgeInsets.bottom"])
            {
              _edgeInsets.bottom = [coder decodeFloatForKey: @"NSStackViewEdgeInsets.bottom"];
            }
          if ([coder containsValueForKey: @"NSStackViewEdgeInsets.left"])
            {
              _edgeInsets.left = [coder decodeFloatForKey: @"NSStackViewEdgeInsets.left"];
            }
          if ([coder containsValueForKey: @"NSStackViewEdgeInsets.right"])
            {
              _edgeInsets.right = [coder decodeFloatForKey: @"NSStackViewEdgeInsets.right"];              
            }
          if ([coder containsValueForKey: @"NSStackViewEdgeInsets.top"])
            {
              _edgeInsets.top = [coder decodeFloatForKey: @"NSStackViewEdgeInsets.top"];              
            }
          if ([coder containsValueForKey: @"NSStackViewHasFlagViewHierarchy"])
            {
              _hasFlagViewHierarchy = [coder decodeBoolForKey: @"NSStackViewHasFlagViewHierarchy"];
            }
          if ([coder containsValueForKey: @"NSStackViewHorizontalClippingResistance"])
            {
              _horizontalClippingResistancePriority = [coder decodeFloatForKey: @"NSStackViewHorizontalClippingResistance"];
            }
          if ([coder containsValueForKey: @"NSStackViewHorizontalHuggingPriority"])
            {
              _horizontalHuggingPriority = [coder decodeFloatForKey: @"NSStackViewHorizontalHuggingPriority"];
            }
          if ([coder containsValueForKey: @"NSStackViewOrientation"])
            {
              _orientation = [coder decodeIntForKey: @"NSStackViewOrientation"];
            }
          if ([coder containsValueForKey: @"NSStackViewSecondaryAlignment"])
            {
              _secondaryAlignment = [coder decodeFloatForKey: @"NSStackViewSecondaryAlignment"];
            }
          if ([coder containsValueForKey: @"NSStackViewSpacing"])
            {
              _spacing = [coder decodeFloatForKey: @"NSStackViewSpacing"];
              NSLog(@"Spacing = %f", _spacing);
            }
          if ([coder containsValueForKey: @"NSStackViewVerticalClippingResistance"])
            {
              _verticalClippingResistancePriority = [coder decodeFloatForKey: @"NSStackViewVerticalClippingResistance"];
            }
          if ([coder containsValueForKey: @"NSStackViewVerticalHugging"])
            {
              _verticalHuggingPriority = [coder decodeFloatForKey: @"NSStackViewVerticalHugging"];
            }
          if ([coder containsValueForKey: @"NSStackViewdistribution"])
            {
              _distribution = [coder decodeIntForKey: @"NSStackViewdistribution"];
            }        
        }
      else
        {
          [coder decodeValueOfObjCType: @encode(NSUInteger)
                                    at: &_alignment];
          ASSIGN(_beginningContainer, [coder decodeObject]);
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_detachesHiddenViews];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_edgeInsets.bottom];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_edgeInsets.left];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_edgeInsets.right];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_edgeInsets.top];
          [coder decodeValueOfObjCType: @encode(BOOL)
                                    at: &_hasFlagViewHierarchy];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_horizontalClippingResistancePriority];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_horizontalHuggingPriority];
          [coder decodeValueOfObjCType: @encode(NSInteger)
                                    at: &_orientation];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_secondaryAlignment];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_spacing];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_verticalClippingResistancePriority];
          [coder decodeValueOfObjCType: @encode(CGFloat)
                                    at: &_verticalHuggingPriority];
          [coder decodeValueOfObjCType: @encode(NSInteger)
                                    at: &_distribution];
        }
      [self _refreshView];
    }
  return self;
}
  
@end

