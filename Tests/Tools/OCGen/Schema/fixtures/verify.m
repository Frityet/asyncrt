@interface Object
@end

@interface Point : Object
@property int x;
@property int y;
@end

@implementation Point
@end

int addPoint(Point *point)
{
    return point.x + point.y;
}
