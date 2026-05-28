#import <ObjFW/ObjFW.h>

#pragma clang diagnostic ignored "-Wmissing-method-return-type"

#define _STR(...) #__VA_ARGS__
#define $str(...) _STR(__VA_ARGS__)

#define _CONCAT(x, y) x##y
#define $concat(...) _CONCAT(__VA_ARGS__)

struct DBEntityOptions {
    OFConstantString *tableName;
};

#define dbsql clang
#define sqltable(...)\
    objc_runtime_name("DBEntity {"__VA_OPT__(#__VA_ARGS__)", .at=\""__FILE__":"$str(__LINE__)"\"}"), clang::annotate("", @encode(typeof((struct DBEntityOptions){ __VA_ARGS__ })))

@interface Money : OFObject @end
@interface DBDeleteAction : OFObject

+ (instancetype)cascade;
+ (instancetype)restrict;
+ (instancetype)setNull;

@end

@protocol DBExpression
@end

@protocol DBBooleanPredicate <DBExpression>

- (id<DBBooleanPredicate>)and:(id<DBBooleanPredicate>)other;
- (id<DBBooleanPredicate>)or:(id<DBBooleanPredicate>)other;
- (id<DBBooleanPredicate>)not;

@end

@protocol DBComparableExpression <DBExpression>

- (id<DBBooleanPredicate>)isEqualTo:(id<DBExpression>)other;
- (id<DBBooleanPredicate>)isNotEqualTo:(id<DBExpression>)other;

@end

@protocol DBOrderedExpression <DBComparableExpression>

- (id<DBBooleanPredicate>)isLessThan:(id<DBExpression>)other;
- (id<DBBooleanPredicate>)isLessThanOrEqualTo:(id<DBExpression>)other;
- (id<DBBooleanPredicate>)isGreaterThan:(id<DBExpression>)other;
- (id<DBBooleanPredicate>)isGreaterThanOrEqualTo:(id<DBExpression>)other;

@end

@protocol DBCollectionExpressions <DBExpression, OFCollection>

- (id<DBBooleanPredicate>)contains:(id<DBExpression>)element;
- (id<DBBooleanPredicate>)isEmpty;

@end

@protocol DBStringExpression <DBOrderedExpression>

- (id<DBBooleanPredicate>)isLike:(OFString *)pattern;
- (id<DBBooleanPredicate>)isNotLike:(OFString *)pattern;

@end

@interface OFNumber (DBComparableExpression) <DBComparableExpression> @end
@interface OFString(DBStringExpression) <DBStringExpression> @end

@protocol Column<DBOrderedExpression>

@end


@protocol PrimaryKey<Column> @end
@protocol ForeignKey<Column>

- (instancetype)references: (id<Column>)col;
- (instancetype)references: (id<Column>)col onDelete: (DBDeleteAction *)deleteAction;

@end

@protocol DBTableConfiguration;

@interface DBSelectQuery<__covariant T> : OFObject

- (OFArray<T> *)all;
- (T)first;
- (T)firstOrNil;

@end

@interface DBQueryBuilder<T> : OFObject

+ (instancetype)from: (id<DBTableConfiguration>)table;

- (instancetype)distinct;

- (instancetype)join: (id<DBTableConfiguration>)table;
- (instancetype)join: (id<DBTableConfiguration>)table on: (id<DBBooleanPredicate>)pred;
- (instancetype)leftJoin: (id<DBTableConfiguration>)table;
- (instancetype)leftJoin: (id<DBTableConfiguration>)table on: (id<DBBooleanPredicate>)pred;
- (instancetype)rightJoin: (id<DBTableConfiguration>)table;
- (instancetype)rightJoin: (id<DBTableConfiguration>)table on: (id<DBBooleanPredicate>)pred;
- (instancetype)fullJoin: (id<DBTableConfiguration>)table;
- (instancetype)fullJoin: (id<DBTableConfiguration>)table on: (id<DBBooleanPredicate>)pred;
- (instancetype)crossJoin: (id<DBTableConfiguration>)table;

typedef id<DBBooleanPredicate> (^DBQueryBuilderJoinAll_f)(id<DBTableConfiguration>);
- (instancetype)joinAll: (OFArray<id<DBTableConfiguration>> *)tables;
- (instancetype)joinAll: (OFArray<id<DBTableConfiguration>> *)tables on: (DBQueryBuilderJoinAll_f)pred;
- (instancetype)leftJoinAll: (OFArray<id<DBTableConfiguration>> *)tables;
- (instancetype)leftJoinAll: (OFArray<id<DBTableConfiguration>> *)tables on: (DBQueryBuilderJoinAll_f)pred;
- (instancetype)rightJoinAll: (OFArray<id<DBTableConfiguration>> *)tables;
- (instancetype)rightJoinAll: (OFArray<id<DBTableConfiguration>> *)tables on: (DBQueryBuilderJoinAll_f)pred;
- (instancetype)fullJoinAll: (OFArray<id<DBTableConfiguration>> *)tables;
- (instancetype)fullJoinAll: (OFArray<id<DBTableConfiguration>> *)tables on: (DBQueryBuilderJoinAll_f)pred;
- (instancetype)crossJoinAll: (OFArray<id<DBTableConfiguration>> *)tables;

- (instancetype)where: (id<DBBooleanPredicate>)pred;
- (instancetype)andWhere: (id<DBBooleanPredicate>)pred;
- (instancetype)orWhere: (id<DBBooleanPredicate>)pred;

- (instancetype)groupBy: (OFArray<id<Column>> *)columns;
- (instancetype)having: (id<DBBooleanPredicate>)pred;
- (instancetype)andHaving: (id<DBBooleanPredicate>)pred;
- (instancetype)orHaving: (id<DBBooleanPredicate>)pred;

- (instancetype)orderBy: (id<Column>)column;
- (instancetype)orderBy: (id<Column>)column ascending: (bool)ascending;

- (instancetype)limit: (size_t)limit;
- (instancetype)offset: (size_t)offset;
- (instancetype)limit: (size_t)limit offset: (size_t)offset;

- (DBSelectQuery<T> *)selectAllInto: (Class)cls;
- (DBSelectQuery<T> *)select: (OFDictionary<OFString *, id<Column>> *)columns into: (Class)cls;
- (DBSelectQuery<T> *)selectExpressions: (OFDictionary<OFString *, id<Column>> *)expressions into: (Class)cls;
- (DBSelectQuery<T> *)selectFrom: (Class)cls;

@end


@protocol DBTableConfiguration<OFObject>

@optional
- (OFArray<id<Column>> *)unique;
- (OFArray<id<ForeignKey>> *)relationships;

- (DBQueryBuilder<id<DBTableConfiguration>> *)where: (id<DBBooleanPredicate>)pred;

@end

@interface DBTable : OFObject<DBTableConfiguration>

+ (instancetype)table;

@end



@protocol Optional<Column> @end
@protocol Unique<Column> @end
@protocol Nullable<Column> @end

#define sqlname synthesize

[[dbsql::sqltable(.tableName = @"movies")]]
@interface Movie : DBTable

@property OFNumber<Column, PrimaryKey> *id;
@property OFString<Column> *name;
@property OFDate<Column> *releaseDate;
@property OFNumber<Column> *runtime;
@property OFDate<Column> *createdAt;

@end

@implementation Movie

@sqlname releaseDate = release_date;
@sqlname createdAt = created_at;

@end

[[dbsql::sqltable(.tableName = @"cinemas")]]
@interface Cinema : DBTable

@property OFNumber<Column, PrimaryKey> *id;
@property OFString<Column> *name;
@property OFString<Column> *city;
@property OFString<Column> *country;
@property OFDate<Column> *createdAt;

@end

@implementation Cinema

@sqlname createdAt = created_at;

-unique { return @[ self.name, self.city, self.country ]; }

@end

[[dbsql::sqltable(.tableName = @"showings")]]
@interface Showing : DBTable

@property OFNumber<Column, PrimaryKey> *id;
@property Movie<ForeignKey> *movie;
@property Cinema<ForeignKey> *cinema;

@property OFString<Column> *auditorium;
@property OFDate<Column> *startsAt;
@property OFDate<Column> *endsAt;

@end

@implementation Showing

-unique { return @[ self.cinema, self.auditorium, self.startsAt ]; }
-relationships
{
    return @[
        [self.movie references: Movie.table.id onDelete: DBDeleteAction.cascade],
        [self.cinema references: Cinema.table.id onDelete: DBDeleteAction.cascade],
    ];
}

@end

[[dbsql::sqltable(.tableName = @"tickets")]]
@interface Ticket : DBTable

@property OFNumber<Column, PrimaryKey> *id;
@property Showing<ForeignKey> *showing;
@property OFString<Column> *seat;

@property Money<Column> *price;

@property OFString<Column> *status;

@property OFDate<Column> *createdAt;
@property OFDate<Column> *updatedAt;

@end

@implementation Ticket

@sqlname createdAt = created_at;
@sqlname updatedAt = updated_at;

-unique { return @[ self.showing, self.seat ]; }
-relationships
{
    return @[
        [self.showing references: Showing.table.id onDelete: DBDeleteAction.cascade],
    ];
}
@end

[[dbsql::sqltable(.tableName = @"ticket_reservations")]]
@interface TicketReservation : DBTable

@property OFNumber<Column, PrimaryKey> *id;
@property Ticket<ForeignKey> *ticket;

@property OFNumber<Column> *customerID;
@property OFDate<Column> *reservedAt;
@property OFDate<Column> *expiresAt;

@end

@implementation TicketReservation

-relationships
{
    return @[
        [self.ticket references: Ticket.table.id onDelete: DBDeleteAction.cascade],
    ];
}

@end

@interface TicketReservationQueryRow : OFObject

@property OFString *movieName;
@property OFString *cinemaName;
@property OFString *city;
@property OFString *country;
@property OFString *auditorium;
@property OFDate *startsAt;
@property OFDate *endsAt;
@property OFString *seat;
@property Money *price;
@property OFString *status;
@property OFNumber *customerID;
@property OFDate *reservedAt;
@property OFDate *expiresAt;

@end

@implementation TicketReservationQueryRow

@end

#define auto __auto_type

// static const int EBP = 4;

int main(int argc, const char *argv[])
{
    (void)(argc, argv);
}

static void f()
{
    // int guess = 0;
    // char buffer[15];
    // int target = random();


    // (void)buffer, (void)target, (void)guess, (void)eIP;
    const auto Tickets = Ticket.table;
    const auto Showings = Showing.table;
    const auto Movies = Movie.table;
    const auto Cinemas = Cinema.table;
    const auto Reservations = TicketReservation.table;

    auto query = [[[[[[[[DBQueryBuilder<TicketReservationQueryRow *> from: Tickets] joinAll: @[ Movies, Cinemas, Showings ]] leftJoin: Reservations]
                         where: [[Tickets.status isEqualTo: @"reserved"] and: [Reservations.expiresAt isGreaterThan: Reservations.reservedAt]]]
                         orderBy: Showings.startsAt ascending: true]
                         orderBy: Cinemas.name ascending: true]
                         limit: 50]
                         select: @{
                            @"movieName": Movies.name,
                            @"cinemaName": Cinemas.name,
                            @"city": Cinemas.city,
                            @"country": Cinemas.country,
                            @"auditorium": Showings.auditorium,
                            @"startsAt": Showings.startsAt,
                            @"endsAt": Showings.endsAt,
                            @"seat": Tickets.seat,
                            @"price": Tickets.price,
                            @"status": Tickets.status,
                            @"customerID": Reservations.customerID,
                            @"reservedAt": Reservations.reservedAt,
                            @"expiresAt": Reservations.expiresAt,
                         }
                         into: TicketReservationQueryRow.class];

    (void)query;
}
