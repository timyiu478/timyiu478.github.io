---
layout: post
title:  "Condition Variables in Threading"
categories: "OS"
tags: "OS"
---

## What is Condition Variables?

Condition variables in threading allow **threads to wait for certain conditions to be true**. When the condition changes, threads can be **woken up** by **signaling** the condition variable.  

## Why we need Condition Variables?

It allows a thread to wait for a specific condition **without wasting CPU cycles**.

## Mesa vs. Hoare Semantics

- In Mesa semantics, signaling indicates a state change **without guaranteeing the state upon the thread’s activation**. 
- Hoare semantics ensures **immediate action post-signaling** but is harder to implement. Most systems opt for Mesa semantics.

## The Producer/Consumer (Bounded Buffer) Problem

This problem involves **producer threads creating data items** and storing them in a **share buffer**, and **consumer threads taking these items from the buffer** for use.

### Synchronization requirement

Producers only put data into the buffer when count is buffer is **empty** and consumers only retrieve data when count is buffer is **full**.

### Initial Implementation in C++

```c
int loops; // Initialized elsewhere
cond_t cond;
mutex_t mutex;

void *producer(void *arg) {
 for (int i = 0; i < loops; i++) {
  Pthread_mutex_lock(&mutex); 
  if (count == 1)
   Pthread_cond_wait(&cond, &mutex);
  put(i);
  Pthread_cond_signal(&cond);
  Pthread_mutex_unlock(&mutex);
 }
}

void *consumer(void *arg) {
 for (int i = 0; i < loops; i++) {
  Pthread_mutex_lock(&mutex); 
  if (count == 0)
   Pthread_cond_wait(&cond, &mutex);
  int tmp = get();
  Pthread_cond_signal(&cond);
  Pthread_mutex_unlock(&mutex);
  printf("%d\n", tmp);
 }
}
```

### Problem of Initial Implementation

The issue stems from the buffer state changing after Consumer thread `Tc1` is signaled but before it acts since the system use Mesa semantics.

Assume there are 1 producer `Tp` and two consumers `Tc1` and `Tc2`.

1. `Tc1` checked count = 0 so it waits.
2. `Tp` puts item since count = 0 and then signals `Tc1` to **Ready** state.
3. Before `Tc1` can consume, `Tc2` **intervenes and consumes the buffer value**.
4. When `Tc1` resumes, it finds an **empty** buffer, leading to an assertion failure.

### Implementing a While Loop for Condition Variables

Replacing `if` statements with `while` loops in both producer and consumer functions. This ensures that whenever a thread wakes up, it **rechecks** the shared variable’s state.

### Unresolved Issue: DeadLock

1. Both consumers go to sleep as the buffer is empty.
2. `Tp` fills the buffer and signals, waking `Tc1`.
3. `Tp` producer keeps take control the CPU and try to add more data, it finds the buffer full and sleeps.
4. `Tc1` consumes the buffer and signals, but if it accidentally wakes `Tc2`.
5. `Tc2` finds an empty buffer and sleeps again.
6. `Tp` also asleep, leaves the system in a deadlock.

### Implementing Dual Condition Variables

- The root of the problem lies in using only **one condition variable** `cond` for **both full and empty states** of the buffer. This can lead to incorrect signaling and subsequent deadlocks in a multi-threaded environment.
- So we use two condition variables instead: `empty` and `fill`.
- **Producer** threads wait on the `empty` condition. Once a buffer space is available (`empty`), they proceed to fill the buffer and then signal `fill`, indicating the buffer is no longer empty.
- **Consumer** threads wait for the `fill` condition, meaning the buffer has data. After consuming, they signal `empty`, indicating space availability in the buffer.

### Multiple buffer slots

To further optimize for concurrency and efficiency, we introduce multiple buffer slots. This enhancement allows for **multiple values to be produced and consumed without frequent sleeping**, reducing context switches and boosting efficiency. 

### Enhanced C++ Implementation

```c
#include <stdio.h>
#include <pthread.h>

int buffer[MAX];
int fill_ptr = 0; // Points to where to fill next
int use_ptr = 0;  // Points to where to use next
int count = 0;    // Number of items in the buffer

void put(int value) {
 buffer[fill_ptr] = value;
 fill_ptr = (fill_ptr + 1) % MAX; // Circular increment
 count++;
}

int get() {
 int tmp = buffer[use_ptr];
 use_ptr = (use_ptr + 1) % MAX; // Circular increment
 count--;
 return tmp;
}

cond_t empty, fill; // Condition variables for synchronization
mutex_t mutex; // Mutex for protecting shared data

void *producer(void *arg) {
    int i;
    for (i = 0; i < loops; i++) {
        Pthread_mutex_lock(&mutex); // p1: Acquire the mutex for exclusive access
        while (count == MAX) // p2: Check if the buffer is full (use a while loop to handle spurious wake-ups)
            Pthread_cond_wait(&empty, &mutex); // p3: Wait for the buffer to have space
        put(i); // p4: Put the value into the buffer
        Pthread_cond_signal(&fill); // p5: Signal that the buffer is no longer empty
        Pthread_mutex_unlock(&mutex); // p6: Release the mutex
    }
}

void *consumer(void *arg) {
    int i;
    for (i = 0; i < loops; i++) {
        Pthread_mutex_lock(&mutex); // c1: Acquire the mutex for exclusive access
        while (count == 0) // c2: Check if the buffer is empty (use a while loop to handle spurious wake-ups)
            Pthread_cond_wait(&fill, &mutex); // c3: Wait for the buffer to have data
        int tmp = get(); // c4: Get a value from the buffer
        Pthread_cond_signal(&empty); // c5: Signal that the buffer is no longer full
        Pthread_mutex_unlock(&mutex); // c6: Release the mutex
        printf("%d\n", tmp); // Print the retrieved value
    }
}
```
