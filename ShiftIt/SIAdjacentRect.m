//
//  Created by krikava on 01/12/11.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Carbon/Carbon.h>
#import "SIAdjacentRect.h"
#import "FMT/FMT.h"

@implementation SIRectWithValue {
@private
    NSRect rect_;
    id value_;
}

@synthesize rect = rect_;
@synthesize value = value_;

- (id)initWithRect:(NSRect)rect value:(id)value {
    if (![super init]) {
        return nil;
    }

    rect_ = rect;
    value_ = [value retain];

    return self;
}

- (void)dealloc {
    [value_ release];
    [super dealloc];
}

+ (id)rect:(NSRect)rect withValue:(id)value {
    return [[[SIRectWithValue alloc] initWithRect:rect value:value] autorelease];
}


@end

@implementation SIRectDistance {
@private
    CGFloat distance_;
    NSRect rect_;
    id value_;
}

@synthesize distance = distance_;
@synthesize rect = rect_;
@synthesize value = value_;

- (id)initWithDistance:(CGFloat)distance rect:(NSRect)rect value:(id)value {
    if (![super init]) {
        return nil;
    }

    distance_ = distance;
    rect_ = rect;
    value_ = [value retain];

    return self;
}

- (void)dealloc {
    [value_ release];
    [super dealloc];
}

@end

@implementation SIAdjacentRect {
@private
    NSArray *rectValues_;
}

- (id)initWithRectValues:(NSArray *)rectValues {
    if (![super init]) {
        return nil;
    }

    FMTAssertNotNil(rectValues);
    rectValues_ = [rectValues retain];

    return self;
}

- (void)dealloc {
    [rectValues_ release];

    [super dealloc];
}

- (NSArray *)rectsInDirection:(FMTDirection)direction fromRect:(NSRect)rect {
    NSMutableArray *res = [NSMutableArray array];

    [rectValues_ enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRect cRect = [obj rect];
        
        if (NSEqualRects(rect, cRect)) {
            return;
        }
        
        if (FMTIsRectInDirection(cRect, rect, direction)) {
            NSPoint a;
            NSPoint b;
            NSPoint p;

            switch (direction) {
                case kLeftDirection:
                    a = NSMakePoint(rect.origin.x, rect.origin.y);
                    b = NSMakePoint(rect.origin.x, rect.origin.y+rect.size.height);
                    p = NSMakePoint(cRect.origin.x+cRect.size.width, cRect.origin.y);
                    break;
                case kTopDirection:
                    a = NSMakePoint(rect.origin.x, rect.origin.y);
                    b = NSMakePoint(rect.origin.x+rect.size.width, rect.origin.y);
                    p = NSMakePoint(cRect.origin.x, cRect.origin.y+cRect.size.height);
                    break;
                case kBottomDirection:
                    a = NSMakePoint(rect.origin.x, rect.origin.y+rect.size.height);
                    b = NSMakePoint(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);
                    p = NSMakePoint(cRect.origin.x, cRect.origin.y);
                    break;
                case kRightDirection:
                    a = NSMakePoint(rect.origin.x+rect.size.width, rect.origin.y);
                    b = NSMakePoint(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);
                    p = NSMakePoint(cRect.origin.x, cRect.origin.y);
                    break;
                default:
                    FMTAssert(NO, @"Unknown direction %d", direction);
            }

            CGFloat dist = FMTPointDistanceToLine(a, b, p);
            [res addObject:[[[SIRectDistance alloc] initWithDistance:dist rect:cRect value:[obj value]] autorelease]];
        }
    }];

    return [NSArray arrayWithArray:[res sortedArrayUsingComparator: ^(id obj1, id obj2) {

        if ([obj1 distance] > [obj2 distance]) {
            return (NSComparisonResult)NSOrderedDescending;
        }

        if ([obj1 distance] < [obj2 distance]) {
            return (NSComparisonResult)NSOrderedAscending;
        }

        return (NSComparisonResult)NSOrderedSame;
    }]];
}

- (NSArray *)rectsInDirection:(FMTDirection)direction fromValue:(id)value {
    SIRectWithValue *rv = [rectValues_ find:^BOOL(id item) {
        return ([[item value] isEqualToScreen:value]);
    }];
    
    return [self rectsInDirection:direction fromRect:[rv rect]];
}

- (NSArray *)buildDirectionalPath:(FMTDirection *)directions fromValue:(id)value {
    NSMutableArray *res = [NSMutableArray array];
    
    for (int i=0; i<4; i++) {
        FMTDirection direction = directions[i];
        
        // get all the rectangles in the direction
        NSArray *rects = [self rectsInDirection:direction fromValue:value];
                
        // TODO: sort by the relative distance from the main one
        
        // add to path
        for (id r in rects) {
            id val = [r value];
            if (![res containsObject:val]) {
                [res addObject:val];
            }
        }
    }
    
    [res addObject:value];
    
    return res;
}


+ (id)adjacentRect:(NSArray *)rectValues {
    return [[[SIAdjacentRect alloc] initWithRectValues:rectValues] autorelease];
}

@end