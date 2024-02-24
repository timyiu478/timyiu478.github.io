---
layout: post
title:  "Thread API"
categories: ["os", "concurrency"]
tags: ["os", "concurrency"]
---

## Thread Creation in POSIX

### Functions

- create thread: `pthread_create`
- wait a thread to complete: `pthread_join`

### Example Code

```c
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

// Define structures for argument and return values
typedef struct {
    int a;
    int b;
} myarg_t;

typedef struct {
    int x;
    int y;
} myret_t;

// Thread function to perform a task and return values
void *mythread(void *arg) {
    myret_t *rvals = (myret_t *)malloc(sizeof(myret_t));  // Allocate memory for return values

    // Simulate some work and set return values
    rvals->x = 1;
    rvals->y = 2;

    return (void *)rvals;  // Return the allocated struct
}

int main(int argc, char *argv[]) {
    pthread_t p;          // Thread object
    myret_t *rvals;       // Pointer to store returned values
    myarg_t args = {10, 20};  // Example argument values

    // Create a new thread with the specified function and arguments
    pthread_create(&p, NULL, mythread, &args);

    // Wait for the thread to finish and retrieve its return values
    pthread_join(p, (void **) &rvals);

    // Print the returned values
    printf("returned %d %d\n", rvals->x, rvals->y);

    free(rvals);  // Free the allocated memory

    return 0;
}
```

## Mutual Exclusion with POSIX Threads

**Mutexes** are essential for protecting critical sections of code to ensure correct operation.

### Usage Example

```c
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER; // Static Initialization to set mutex to default state.
// int rc = pthread_mutex_init(&lock, NULL); // Dynamic Initialization with NULL indicating default attributes.
// assert(rc == 0); // Check for successful initialization
pthread_mutex_lock(&lock); // Acquire the lock. If the lock is already held by another thread, the calling thread will block until it can acquire the lock.
x = x + 1; // Critical section
pthread_mutex_unlock(&lock); // Release the lock
pthread_mutex_destroy(&lock); // Clean up
```

### Advanced Mutex Operations

- **Timed Locks**: Acquire a lock with a timeout, useful in scenarios where avoiding deadlock is crucial.
- **Try Locks**: Non-blocking lock attempts that can be useful in certain advanced programming scenarios.

## Condition variables

They are used when threads need to **signal** each other to proceed with their tasks.

### Example C++ Code

```c
#include <iostream>
#include <pthread.h>
#include <unistd.h> // For sleep()

pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER; // Mutex
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;  // Condition variable

// Shared variable
bool ready = false;

// Thread function that waits for the condition
void* wait_thread(void* arg) {
    pthread_mutex_lock(&lock);

    while (!ready) { // Using while loop for spurious wake-ups
        std::cout << "Waiting thread is waiting for the condition..." << std::endl;
        pthread_cond_wait(&cond, &lock);
    }

    std::cout << "Waiting thread received the signal." << std::endl;

    pthread_mutex_unlock(&lock);
    return NULL;
}

// Thread function that signals the condition
void* signal_thread(void* arg) {
    sleep(1); // Sleep for demonstration purposes

    pthread_mutex_lock(&lock);

    ready = true;
    std::cout << "Signaling thread is signaling the condition..." << std::endl;
    pthread_cond_signal(&cond);

    pthread_mutex_unlock(&lock);
    return NULL;
}

int main() {
    pthread_t waitThread, signalThread;

    // Create threads
    pthread_create(&waitThread, NULL, wait_thread, NULL);
    pthread_create(&signalThread, NULL, signal_thread, NULL);

    // Wait for threads to finish
    pthread_join(waitThread, NULL);
    pthread_join(signalThread, NULL);

    // Clean up
    pthread_mutex_destroy(&lock);
    pthread_cond_destroy(&cond);

    return 0;
}
```
- **Hold Lock During Signaling**: Always hold the lock when signaling or modifying the global condition variable to **avoid race conditions**.
- **Lock Handling in Wait and Signal**: The wait function requires the lock as it **releases it when putting the thread to sleep**. The lock is **re-acquired before pthread_cond_wait returns**. The signal function only needs the condition variable.
- **Rechecking the Condition**: Use a while loop rather than an if statement to **recheck the condition**. This is because **some implementations may wake up threads spuriously, without the condition actually being met**.

### Caution Against Using Flags for Synchronization

```c
// Waiting code
while (ready == 0) ; // Spin

// Signaling code
ready = 1;
```

This approach can lead to **excessive CPU usage (busy-waiting)** and is prone to **synchronization errors**.
