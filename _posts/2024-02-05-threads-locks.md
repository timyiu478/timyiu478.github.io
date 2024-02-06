---
layout: post
title:  "Threads Locks"
categories: "OS"
tags: "OS"
---

## What is a Lock

Lock is a tool for allowing running critical section code atomically by only allow one thread to be execute that part of code.

## How does a lock work?

- **Lock Variable**: e.g. mutex. It holds the **lock state**.  It indicates whether the lock is free or acquired by a thread.
- **Acquiring a Lock**: When a thread executes `lock(&mutex)`, it acquires the lock if it’s free, allowing the thread to enter the critical section.
- **Waiting Threads**: If there are threads waiting (**blocked in the `lock()` function**), the lock won’t be set to free immediately. Instead, one of the waiting threads will enter the critical section.
- **Releasing a Lock**: Using `unlock(&mutex)` releases the lock, making it available for other threads.

## Supports for implementing lock

- **Hardware**: special hardware instructions for implementing locks that are both efficient and effective.
- **OS**: complements these hardware capabilities by providing the necessary context and controls to ensure that locks are used appropriately within the system.

## Key Criteria for Assessing Lock Efficacy

- **Basic Functionality**: The primary function of a lock is to ensure **mutual exclusion**, keeping multiple threads out of a critical section simultaneously.
- **Equal Opportunity**: Fairness in locks means each competing thread should have a reasonable chance of acquiring the lock once it’s available.
- **Avoiding Starvation**: Assess whether any thread **consistently fails to acquire the lock**, leading to starvation.
- **Overhead Assessment**: Consider the **time overheads** incurred by using the lock in different scenarios:
  - Single CPU, Single Thread
  - Single CPU, Multiple Threads
  - Multiple CPUs, Multiple Threads

## Achieving mutual exclusion on single-processor systems by controlling interrupts.

### Idea

- Before entering a critical section, interrupts are disabled to **prevent interruption**.
- After exiting the critical section, **interrupts are re-enabled**.

### Pros

Simple.

### Cons

- Trust the programs.
- Cant ensure mutual exclusion on multi-processor systems.
- Prolonged disabling of interrupts might lead to missed signals, causing system issues.
- Interrupt masking and unmasking operations can be slow on modern CPUs.

## Implementing a Flag-Based Lock

### Lock Structure and Functions

```c
typedef struct __lock_t { int flag; } lock_t;

void init(lock_t *mutex) {
    // 0 -> lock is available, 1 -> held
    mutex->flag = 0;
}

void lock(lock_t *mutex) {
    while (mutex->flag == 1) // TEST the flag
        ; // spin-wait (do nothing)
    mutex->flag = 1; // now SET it!
}

void unlock(lock_t *mutex) {
    mutex->flag = 0;
}
```

### Issues

- **Potential for Race Conditions**: a critical window between the check `while (mutex->flag == 1)` and the set `mutex->flag = 1;` so that more than one thread could acquire the lock. For example,
  1. Thread 1: `unlock()`
  2. Thread 2: `mutex->flag == 1` is false
  3. Thread 3: `mutex->flag == 1` is false
  4. Thread 2: `mutex->flag = 1`
  5. Thread 3: `mutex->flag = 1`
- **Spin-wait**: consume CPU with do nothing.

## Spin Lock with Test-And-Set

### Test-And-Set

The test-and-set instruction is a fundamental piece of **hardware support** for locking which is the **atomic** instruction.

```c
int TestAndSet(int *old_ptr, int new) {
    // logical implementation that should be executed atomically in reality
    int old = *old_ptr; // Fetch old value
    *old_ptr = new;     // Store 'new' into old_ptr
    return old;         // Return the old value
}
```

### Lock Acquisition

- If a thread calls `lock()` and no other thread holds the lock, `TestAndSet(flag, 1)` will return **0** (the old value), and the thread **acquires the lock while setting the flag to 1**.
- If another thread already holds the lock (flag is 1), `TestAndSet(flag, 1)` will return **1**, causing the thread to enter a **spin-wait** loop until the lock is released.

### Releasing the Lock

The unlocking thread sets the flag back to **0**, allowing other threads to acquire the lock.

### Evaluation

- achieve mutual exclustion
- potential for starvation
- waste CPU cycles in the spin-wait loop 

## Spin Lock with Compare-And-Swap

Compare-And-Swap (CAS), known as Compare-And-Exchange on x86 architectures, is a **hardware primitive** provided by some systems to aid in concurrent programming.

### CAS Functionality in C Pseudocode

```c
int CompareAndSwap(int *ptr, int expected, int new) {
    int original = *ptr;
    if (original == expected)
        *ptr = new;
    return original;
}
```

- CAS returns the original value at ptr, allowing the calling code to **determine whether the update was successful**.
- atomically updates ptr with new if the value at the address specified by `ptr` equals `expected`.

### CAS Lock Implemention

```c
void lock(lock_t *lock) {
    while (CompareAndSwap(&lock->flag, 0, 1) == 1)
        ; // Spin-wait
}
```

### Compare with Test-And-Set

- Lock acquisition and releasing are the same.
- CAS is more flexible than test-and-set, opening possibilities for more advanced synchronization techniques like **lock-free synchronization**.

## Spin Lock with Load-Linked and Store-Conditional

### Load-Linked and Store-Conditional

Load-Linked (LL) and Store-Conditional (SC) are pairs of instructions used on platforms like MIPS, ARM, and PowerPC to create locks and other concurrent structures

- Load-Linked (LL): This instruction **loads a value from a memory location into a register**. It prepares for a subsequent conditional store.
- Store-Conditional (SC): This instruction **attempts to store a value to the memory location if no updates have been made to that location since the last load-linked operation**. It returns **0 on failure**, leaving the value unchanged.

### Lock Implementation in Pseudo C Code

```c
void lock(lock_t *lock) {
    while (LoadLinked(&lock->flag) || 
           !StoreConditional(&lock->flag, 1))
        ; // Spin-wait
}
```

When two threads attempt to acquire the lock simultaneously after an LL operation, only one will succeed with the SC. The other thread’s SC will fail, forcing it to retry.

## Ticket Lock with Fetch-And-Add

### Fetch-And-Add Representation in C

The fetch-and-add instruction **atomically increments a value at a specific address** while returning the **old** value.

```c
int FetchAndAdd(int *ptr) {
    int old = *ptr;
    *ptr = old + 1;
    return old;
}
```

### Ticket Lock Representation in C++

```c
class TicketLock {
  private:
    std::atomic<int> ticketCounter;
    std::atomic<int> turn;

  public:
    TicketLock() : ticketCounter(0), turn(0) {}

    void lock() {
        int myTicket = ticketCounter.fetch_add(1); // Fetch-And-Add
        while (turn.load(std::memory_order_relaxed) != myTicket) {
            ; // Spin-wait
        }
    }

    void unlock() {
        turn.fetch_add(1); // Move to next ticket
    }
};
```

- A thread acquires a ticket through an atomic fetch-and-add on the ticket counter. This ticket number (`ticketCOunter`) represents the thread’s place in the queue.
- A thread enters the critical section when its ticket number matches the current turn (`ticketCounter == turn`).
- To release the lock, the thread simply increments the `turn` variable, allowing the next thread in line to enter the critical section.

### Advantages of Ticket Lock

- **Guarantee Progress**: ensures that all threads make progress. Each thread is assigned a ticket, and they enter the critical section in the order of their tickets.
- **Fairness**: guarantees that each thread will eventually get its turn to enter the critical section.

## Yield to Avoid Spin Waiting

### Basic Idea

Instead of spinning, a thread could yield the CPU to another thread through a basic `yield()` system call, where the yielding thread **de-schedules itself**, changing its state from running to ready.

### Challenges

- In a system with many threads competing for a lock, yielding can lead to **frequent context switches**. If one thread acquires the lock and is preempted, the other threads will sequentially find the lock held, yield, and enter a **run-and-yield cycle**.
- The starvation problem is unaddressed.

## Sleep and Waiting Queue  

### Solaris Implementation in C

```c
// Define a structure for the lock
typedef struct __lock_t {
    int flag;       // 0 if lock is available, 1 if locked
    int guard;      // To prevent concurrent guard lock
    queue_t *q;     // Queue to hold waiting threads
} lock_t;

// Initialize the lock
void lock_init(lock_t *m) {
    m->flag = 0;     // Lock is initially available
    m->guard = 0;    // Guard is initially free
    queue_init(m->q); // Initialize the queue for waiting threads
}

// Acquire the lock
void lock(lock_t *m) {
    while (TestAndSet(&m->guard, 1) == 1)
        ; // Acquire guard lock by spinning

    if (m->flag == 0) {
        m->flag = 1;   // Lock is acquired
        m->guard = 0;  // Release the guard lock
    } else {
        queue_add(m->q, gettid()); // Add current thread to the waiting queue
        m->guard = 0;              // Release the guard lock
        park();                     // Put the thread to sleep
    }
}

// Release the lock
void unlock(lock_t *m) {
    while (TestAndSet(&m->guard, 1) == 1)
        ; // Acquire guard lock by spinning

    if (queue_empty(m->q))
        m->flag = 0; // Release the lock; no one wants it
    else
        unpark(queue_remove(m->q)); // Wake up the next waiting thread
    m->guard = 0; // Release the guard lock
}
```

### Addressing Race Conditions

The race condition can occurs just before the `park` call. For example,

1. Thread-1: `m->guard = 0;`
2. Thread-2: `unlock(Thread-1);`
3. Thread-1: `park();`

To ensure `unpark` is called before `park`, the thread does not sleep unnecessarily by adding `setpark()` before `m->guard = 0`.

```c
queue_add(m->q, gettid());
setpark(); // new code
m->guard = 0;
```

Or place the `guard` directly within the kernel, allowing for atomic operations in lock release and thread dequeuing.
