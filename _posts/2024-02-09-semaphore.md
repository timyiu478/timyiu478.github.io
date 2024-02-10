---
layout: post
title:  "Semaphore"
categories: "OS"
tags: "OS"
---

## What is Semaphore?

Semaphores serve as a unified primitive, adept at handling synchronization tasks traditionally managed by both locks and condition variables. 

## Essence of a Semaphore

- Semaphores operate on a **integer value**, manipulated by two pivotal routines:
  - `sem_wait()`: **Decreases** the semaphore value by one. If this action would lead to **a negative value, the thread must wait**.
  - `sem_post()`: **Increments** the semaphore value by one, with the potential to **wake a waiting thread if such a thread exists**.
- A semaphore is initialized with a value that will **dictate its forthcoming behavior** e.g `1` is promising **mutual exclusivity**. For threads of a single process, the second argument to remains `0`, keeping the semaphore’s scope localized in its process.
- It is an atomic operation by leveraging **locks and condition variables**.

## Semaphores For Ordering

### A parent thread must wait for a child thread to complete

```c
sem_t s;

void *child(void *arg) {
    printf("child\n");
    sem_post(&s); // Signal: child is done
    return NULL;
}

int main(int argc, char *argv[]) {
    sem_init(&s, 0, 0); // Initialize semaphore to 0
    printf("parent: begin\n");
    pthread_t c;
    Pthread_create(&c, NULL, child, NULL);
    sem_wait(&s); // Parent waits for the child
    printf("parent: end\n");
    return 0;
}
```

### Evaluations

- If the parent thread executes `sem_wait(&s)` before the child runs, the semaphore decrement will cause the parent to wait, given its initial value of `0`.
- If the child complete first and invoke `sem_post(&s)`, the semaphore’s value becomes `1`, allowing the parent to **bypass waiting** and continue execution upon reaching `sem_wait(&s)`.
- In both cases, the semaphore’s initial value of `0` ensures that the parent thread will only proceed after the child has signaled its completion.

## The producer/consumer or bounded buffer problem

Semaphores can act as versatile tools to handle this problem, functioning as **locks when initialized to 1** and as **signaling mechanisms when initialized to 0(a thread called `sem_wait()` must have to wait another thread to call `sem_post()` to wake it up)**. The initialization value of a semaphore typically reflects the count of resources available for distribution at startup.

### Requirements

- **Mutual Exclusion**: Only one producer can write to a buffer slot at a time, and only one consumer can read from a buffer slot at a time.
- **Correct Ordering**: Producers must wait for available space, and consumers must wait for available data.

### C++ Implementation

```c
#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>

#define MAX 10 // Define the size of the buffer
#define loops 20 // Define the number of iterations

int buffer[MAX]; // Shared buffer
int fill = 0; // Index for the next item to be produced
int use = 0; // Index for the next item to be consumed
sem_t empty; // Semaphore indicating the number of empty slots
sem_t full; // Semaphore indicating the number of full slots
sem_t mutex; // Binary semaphore used as a mutex

void put(int value) {
    buffer[fill] = value;
    fill = (fill + 1) % MAX;
}

int get() {
    int tmp = buffer[use];
    use = (use + 1) % MAX;
    return tmp;
}

void *producer(void *arg) {
    for (int i = 0; i < loops; i++) {
        sem_wait(&empty); // Wait for an empty slot
        sem_wait(&mutex); // Acquire mutex
        put(i); // Produce an item
        sem_post(&mutex); // Release mutex
        sem_post(&full); // Signal that a new item is available
    }
    return NULL;
}

void *consumer(void *arg) {
    for (int i = 0; i < loops; i++) {
        sem_wait(&full); // Wait for a full slot
        sem_wait(&mutex); // Acquire mutex
        int tmp = get(); // Consume an item
        sem_post(&mutex); // Release mutex
        sem_post(&empty); // Signal that a slot is now empty
        printf("Consumed: %d\n", tmp);
    }
    return NULL;
}

int main(int argc, char *argv[]) {
    // Initialize semaphores
    sem_init(&empty, 0, MAX);
    sem_init(&full, 0, 0);
    sem_init(&mutex, 0, 1);

    // Create producer and consumer threads
    pthread_t p, c;
    pthread_create(&p, NULL, producer, NULL);
    pthread_create(&c, NULL, consumer, NULL);

    // Wait for threads to complete
    pthread_join(p, NULL);
    pthread_join(c, NULL);

    // Clean up
    sem_destroy(&empty);
    sem_destroy(&full);
    sem_destroy(&mutex);

    return 0;
}
```

### Evaluations

- The mutex semaphore is used to protect critical sections within `put()` and `get()` for preventing simultaneous access by multiple producers or consumers.
- The mutex semaphore is acquired only **after** successfully passing the empty or full semaphore wait for **avoiding the deadlock issue**.
- If the mutex semaphore is acquired **before** passing the empty or full semaphore wait, the deadlock occurs when the consumer acquires the mutex and is then **blocked waiting for a full signal**. Meanwhile, the **producer is blocked** that it cannot put data and signal full because **it cannot acquire the mutex held by the consumer**.
- The semaphores full and empty are still used to **signal the availability of data** and **space in the buffer**.

## Reader-Writer Lock

### The need of reader-writer lock

- operations like data insertions **alter** the structure and necessitate **exclusive access**.
- while **read** operations can often proceed in **parallel without such restrictions**.

### C++ Implementation

```c
#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>

typedef struct _rwlock_t {
    sem_t lock; // Binary semaphore (basic lock)
    sem_t writelock; // Allow ONE writer/MANY readers
    int readers; // Number of readers in critical section
} rwlock_t;

void rwlock_init(rwlock_t *rw) {
    rw->readers = 0;
    sem_init(&rw->lock, 0, 1);
    sem_init(&rw->writelock, 0, 1);
}

void rwlock_acquire_readlock(rwlock_t *rw) {
    sem_wait(&rw->lock);
    rw->readers++;
    if (rw->readers == 1) // First reader gets writelock
        sem_wait(&rw->writelock);
    sem_post(&rw->lock);
    printf("Reader acquired read lock\n");
}

void rwlock_release_readlock(rwlock_t *rw) {
    sem_wait(&rw->lock);
    rw->readers--;
    if (rw->readers == 0) // Last reader lets it go
        sem_post(&rw->writelock);
    sem_post(&rw->lock);
    printf("Reader released read lock\n");
}

void rwlock_acquire_writelock(rwlock_t *rw) {
    sem_wait(&rw->writelock);
    printf("Writer acquired write lock\n");
}

void rwlock_release_writelock(rwlock_t *rw) {
    sem_post(&rw->writelock);
    printf("Writer released write lock\n");
}

void *reader(void *arg) {
    rwlock_t *rw = (rwlock_t *)arg;
    rwlock_acquire_readlock(rw);
    // Simulate reading operation
    rwlock_release_readlock(rw);
    return NULL;
}

void *writer(void *arg) {
    rwlock_t *rw = (rwlock_t *)arg;
    rwlock_acquire_writelock(rw);
    // Simulate writing operation
    rwlock_release_writelock(rw);
    return NULL;
}

int main() {
    rwlock_t rwlock;
    rwlock_init(&rwlock);

    pthread_t r1, r2, w1, w2;
    pthread_create(&r1, NULL, reader, &rwlock);
    pthread_create(&r2, NULL, reader, &rwlock);
    pthread_create(&w1, NULL, writer, &rwlock);
    pthread_create(&w2, NULL, writer, &rwlock);

    pthread_join(r1, NULL);
    pthread_join(r2, NULL);
    pthread_join(w1, NULL);
    pthread_join(w2, NULL);

    return 0;
}
```

### Evaluations

- a risk that readers could continually access the data structure, starving writers who are waiting for an opportunity to acquire the write lock.
- don’t always result in performance improvement over simpler, faster locking primitives.

## Thread throttling

Thread throttling is a semaphore application in concurrency control, where the goal is to **limit the number of threads running simultaneously** to prevent system slowdowns. 

### Semaphore as a Solution

```c
sem_t semaphore;
sem_init(&semaphore, 0, threshold); // threshold is the max allowed threads

void memory_intensive_operation() {
    sem_wait(&semaphore); // Enter region
    // Perform memory-intensive work
    sem_post(&semaphore); // Leave region
}
```

### Implementing Semaphores

Unlike traditional semaphores, where the negative value indicates the number of waiting threads, in this implementation, **the semaphore value never goes below zero**. This approach simplifies the implementation and aligns with current practices like those in Linux.

```c
typedef struct __Zem_t {
    int value;
    pthread_cond_t cond;
    pthread_mutex_t lock;
} Zem_t;

// Initialize the semaphore
void Zem_init(Zem_t *s, int value) {
    s->value = value;
    pthread_cond_init(&s->cond, NULL);
    pthread_mutex_init(&s->lock, NULL);
}

// Semaphore wait operation
void Zem_wait(Zem_t *s) {
    pthread_mutex_lock(&s->lock);
    while (s->value <= 0)
        pthread_cond_wait(&s->cond, &s->lock);
    s->value--;
    pthread_mutex_unlock(&s->lock);
}

// Semaphore post operation
void Zem_post(Zem_t *s) {
    pthread_mutex_lock(&s->lock);
    s->value++;
    pthread_cond_signal(&s->cond);
    pthread_mutex_unlock(&s->lock);
}
```

### Use Zem_t to throttle threads

```c
void *memory_intensive_operation(void *arg) {
    Zem_t *sem = (Zem_t *)arg;
    Zem_wait(sem);
    printf("Thread entered memory-intensive region\n");
    sleep(1);
    // Simulate memory-intensive work
    Zem_post(sem);
    printf("Thread exited memory-intensive region\n");
    return NULL;
}

int main() {
    const int MAX_THREADS = 5; // Maximum number of concurrent threads in the region
    Zem_t sem;
    Zem_init(&sem, 3); // Allowing 3 threads to enter the region simultaneously

    pthread_t threads[MAX_THREADS];
    for (int i = 0; i < MAX_THREADS; i++) {
        pthread_create(&threads[i], NULL, memory_intensive_operation, &sem);
    }

    for (int i = 0; i < MAX_THREADS; i++) {
        pthread_join(threads[i], NULL);
    }

    return 0;
}
```
