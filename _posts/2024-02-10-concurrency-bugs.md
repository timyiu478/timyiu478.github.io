---
layout: post
title:  "Concurrency Bugs"
categories: ["os", "concurrency"]
tags: ["os", "concurrency"]
---

## Types of Bugs 

- Non-Deadlock
  - Atomicity violation bugs.
  - Order violation bugs.
- Deadlock

## Atomicity violation bugs

A code region is intended to be atomic but the atomicity is not enforced during execution. For example,

```
Thread 1::
if (thd->proc_info) {
    fputs(thd->proc_info, ...);
}

Thread 2::
thd->proc_info = NULL;
```

Execution Order:

1. Thread 1: `thd->proc_info`
2. Thread 2: `thd->proc_info = NULL;`
3. Thread 1: `fputs(thd->proc_info, ...);`
4. Thread 1: crash as a `NULL` pointer will be dereferenced by `fputs`

The fix to this type of bug is generally to **acquire this lock before accesses the shared structure**.

## Order violation bugs

The desired order between two (groups of) memory accesses is flipped. For example,

```
Thread 1::
void init() {
      mThread = PR_CreateThread(mMain, ...);
}

Thread 2::
void mMain(...) {
    mState = mThread->State;
}
```

Execution Order:

1. Thread 2: `mState = mThread->State;`
2. Thread 2: crash with NULL-pointer dereference

The fix to this type of bug is generally to **enforce the order(e.g. use condition variables)**.

## Deadlock

### Conditions for deadlock

- **Mutual exclusion**: Threads claim exclusive control of resources that they require (e.g., a thread grabs a lock).
- **Hold-and-wait**: Threads hold resources allocated to them(e.g., locks that they have already acquired) while waiting for additional resources (e.g., locks that they wish to acquire).
- **No preemption**: Resources (e.g., locks) cannot be forcibly removed from threads that are holding them.
- **Circular wait**: There exists a circular chain of threads such that each thread holds one or more resources (e.g., locks) that are being requested by the next thread in the chain.

If any of these four conditions are not met, deadlock cannot occur.

### Prevention

#### Circular wait

- To prevent curcular wait, Write your locking code such that you **never induce a circular wait**.
- One way to do that is provide a **total ordering** on lock acquisition(e.g. always acquire lock 1 before lock 2).
- In complext system that involves many locks, **partial ordering** is useful as well.
- But **odering** just a **convention** that programmer can be ingored and it requires **deep understanding to the code base**.

#### Hold-and-wait

- To prevent hold-and-wait, **acquiring all locks at once, atomically**.
- It requires that any thread grabs a lock any time it first acquires the **global prevention lock**.
- This approach requires us to know **exactly which locks must be held and to acquire them ahead of time**.
- This technique also is likely to **decrease concurrency** as all locks must be acquired early on (at once) instead of when they are truly needed.

#### No preemption

- To prevent no preemption, we either **grabs the lock (if it is available)** and returns success or returns an error code indicating the lock is held; in the latter case, you can **try again** later if you want to grab that lock.
- The **try-lock** approach to allow a developer to **back out of lock ownership (i.e., preempt their own ownership) in a graceful way**.

```
top:
    pthread_mutex_lock(L1);
    if (pthread_mutex_trylock(L2) != 0) {
        pthread_mutex_unlock(L1);
        goto top;
    }
```

- But **livelock** can be occurred that two threads could both be repeatedly attempting this sequence and repeatedly failing to acquire both locks. For example, the livelock is happended if the following execution order keep repeat. 

1. Thread 1: lock(L1)
2. Thread 2: lock(L2)
3. Thread 1: try_lock(L2) != 0 
4. Thread 2: try_lock(L1) != 0
5. Thread 1: unlock(L1)
6. Thread 2: unlock(L2)

- To address the livelock problem, one could add **a random delay** before looping back and trying the entire thing over again, thus decreasing the odds of repeated interference among competing threads.

#### Mutual Exclusion

- To prevent mutual exclusion, we **avoid the need** for mutual exclusion at all.
- E.g. design **data structures without lock** at all(lock-free or wait-free) with the help of powerful **hardware instructions**.
- But design a lock-freee data structure is **non-trival**.

### Avoidance via Scheduling

Avoidance requires some **global knowledge** of **which locks various threads might grab during their execution**, and subsequently, schedules said threads in a way as to guarantee no deadlock can occur. 

### Detection And Recovery

- Allow deadlocks to occur occasionally, and then take some action once such a deadlock has been detected.
- Many database systems employ deadlock detection and recovery techniques. A **deadlock detector** runs periodically, building a **resource graph** and checking it for cycles. In the event of a cycle (deadlock), the system needs to be **restarted**.
- If more intricate repair of data structures is first required, a **human being may be involved** to ease the process.
