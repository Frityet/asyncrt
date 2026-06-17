// #import <AsyncRT/Application/Core.h>
// #import <AsyncRT/Database/Providers/SQLite.h>

// #pragma clang assume_nonnull begin

// @interface Semaphore : OFObject {
// @private
//     OFCondition *_condition;
//     size_t _count;
// }

// @property(readonly, nonatomic) size_t count;

// - (instancetype)initWithValue: (size_t)value;

// - (void)wait;
// - (bool)tryWait;
// - (void)signal;

// @end

// @implementation Semaphore

// - (instancetype)initWithValue: (size_t)value
// {
//     self = [super init];

//     _condition = [[OFCondition alloc] init];
//     _count = value;

//     return self;
// }

// - (size_t)count
// {
//     size_t count;

//     [_condition lock];
//     count = _count;
//     [_condition unlock];

//     return count;
// }

// - (void)wait
// {
//     [_condition lock];

//     while (_count == 0)
//         [_condition wait];

//     _count--;

//     [_condition unlock];
// }

// - (bool)tryWait
// {
//     bool success = false;

//     if (not [_condition tryLock])
//         return false;

//     if (_count > 0) {
//         _count--;
//         success = true;
//     }

//     [_condition unlock];

//     return success;
// }

// - (void)signal
// {
//     [_condition lock];

//     _count++;
//     [_condition signal];

//     [_condition unlock];
// }

// @end

// @interface MyThread : OFThread {
//     @public Semaphore *semaphore;
// }

// - (instancetype)initWithSemaphore: (Semaphore *)semaphore;

// @end

// @implementation MyThread

// - (instancetype)initWithSemaphore: (Semaphore *)sem
// {
//     self = [super init];
//     self->semaphore = sem;
//     return self;
// }

// - (nillable id)main
// {   
//     OFLog(@"Thread waiting...");
//     [self->semaphore wait];
//     OFLog(@"Thread proceeding...");

//     return nilptr;
// }

// @end

// struct Order {
//     size_t id;
//     OFString *drink;
// };

// constexpr size_t SCREEN_CAPACITY = 5;
// constexpr size_t CASHIERS = 3;
// constexpr size_t BARISTAS = 2;
// constexpr size_t ORDERS_PER_CASHIER = 4;

// @interface LockedValue<T> : OFObject {
//     @private OFMutex *_mutex;
// }

// @property(nonatomic) T value;

// - (instancetype)initWithValue: (T)value;

// - (void)withLock: (void (^)(T value))block;

// @end

// @implementation LockedValue {
//     id _value;
// }

// - (instancetype)initWithValue: (id)value
// {
//     self = [super init];
//     _mutex = [[OFMutex alloc] init];
//     _value = value;
//     return self;
// }

// - (void)withLock: (void (^)(id value))block
// {
//     [_mutex lock];
//     block(_value);
//     [_mutex unlock];
// }

// - (void)setValue: (id)value
// {
//     [_mutex lock];
//     _value = value;
//     [_mutex unlock];
// }

// - (id)value
// {
//     id value;

//     [_mutex lock];
//     value = [_value copy];
//     [_mutex unlock];

//     return value;
// }

// @end

// @interface Cashier : OFThread {
//     @public LockedValue<OFNumber *> *id;
// }

// - (instancetype)initWithID: (OFNumber *)id;

// @end

// @implementation Cashier

// - (instancetype)initWithID: (OFNumber *)x
// {
//     self = [super init];
//     self->id = [[LockedValue alloc] initWithValue: x];
//     return self;
// }

//     //     for (int i = 0; i < ORDERS_PER_CASHIER; i++) {
//     //         Order order;

//     //         {
//     //             std::lock_guard<std::mutex> lock(id_mutex);
//     //             order.id = next_order_id++;
//     //         }

//     //         order.drink = "latte";

//     //         // TODO:
//     //         // Wait until there is space on the order screen.

//     //         // TODO:
//     //         // Lock the screen mutex.
//     //         // Add the order to the queue.
//     //         // Unlock the screen mutex.

//     //         {
//     //             std::lock_guard<std::mutex> lock(cout_mutex);
//     //             std::cout << "Cashier " << cashier_id
//     //                       << " added order " << order.id << '\n';
//     //         }

//     //         // TODO:
//     //         // Signal that there is now one more full slot.

//     //         std::this_thread::sleep_for(std::chrono::milliseconds(100));
//     //     }
//     // };

// - (nillable id)main
// {
    
// }

// @end

// @interface AsyncDBExampleApplication : AsyncApplication
// @end

// /*
// int main() {
//     constexpr int SCREEN_CAPACITY = 5;
//     constexpr int CASHIERS = 3;
//     constexpr int BARISTAS = 2;
//     constexpr int ORDERS_PER_CASHIER = 4;

//     std::deque<Order> order_screen;

//     std::mutex screen_mutex;
//     std::mutex cout_mutex;

//     Semaphore empty_slots(SCREEN_CAPACITY);
//     Semaphore full_slots(0);

//     int next_order_id = 1;
//     std::mutex id_mutex;

//     auto cashier = [&](int cashier_id) {
//         for (int i = 0; i < ORDERS_PER_CASHIER; i++) {
//             Order order;

//             {
//                 std::lock_guard<std::mutex> lock(id_mutex);
//                 order.id = next_order_id++;
//             }

//             order.drink = "latte";

//             // TODO:
//             // Wait until there is space on the order screen.

//             // TODO:
//             // Lock the screen mutex.
//             // Add the order to the queue.
//             // Unlock the screen mutex.

//             {
//                 std::lock_guard<std::mutex> lock(cout_mutex);
//                 std::cout << "Cashier " << cashier_id
//                           << " added order " << order.id << '\n';
//             }

//             // TODO:
//             // Signal that there is now one more full slot.

//             std::this_thread::sleep_for(std::chrono::milliseconds(100));
//         }
//     };

//     auto barista = [&](int barista_id) {
//         int total_orders = CASHIERS * ORDERS_PER_CASHIER;
//         int orders_per_barista = total_orders / BARISTAS;

//         for (int i = 0; i < orders_per_barista; i++) {
//             Order order;

//             // TODO:
//             // Wait until there is at least one order on the screen.

//             // TODO:
//             // Lock the screen mutex.
//             // Remove an order from the queue.
//             // Unlock the screen mutex.

//             // TODO:
//             // Signal that there is now one more empty slot.

//             {
//                 std::lock_guard<std::mutex> lock(cout_mutex);
//                 std::cout << "Barista " << barista_id
//                           << " is making order " << order.id << '\n';
//             }

//             std::this_thread::sleep_for(std::chrono::milliseconds(250));
//         }
//     };

//     std::vector<std::thread> threads;

//     for (int i = 0; i < CASHIERS; i++) {
//         threads.emplace_back(cashier, i + 1);
//     }

//     for (int i = 0; i < BARISTAS; i++) {
//         threads.emplace_back(barista, i + 1);
//     }

//     for (auto& t : threads) {
//         t.join();
//     }

//     std::cout << "All orders completed.\n";
// }
// */

// @implementation AsyncDBExampleApplication

// - (id)applicationDidFinishLaunchingAsync: (OFNotification *)notification
//                                taskGroup: (AsyncTaskGroup *)taskGroup
// {
//     auto sem = [[Semaphore alloc] initWithValue: 0];


//     return AsyncUnit.unit;
// }

// @end

// OF_APPLICATION_DELEGATE(AsyncDBExampleApplication)

// #pragma clang assume_nonnull end

int main()
{}
