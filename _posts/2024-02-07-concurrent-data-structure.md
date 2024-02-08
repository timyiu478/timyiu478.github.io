---
layout: post
title:  "Concurrent Data Structures"
categories: "OS"
tags: "OS"
---

## Challenges of Concurrency in Data Structures

- What are the strategies for adding locks to a data structure to ensure **correct, concurrent** access?
- How can locks be applied in a way that maintains the **speed** and allows **simultaneous access by multiple threads**?

## Ideal Scenario: Perfect Scaling

Perfect scaling is achieved when the time taken for threads to complete tasks on multiple processors is **as fast as on a single processor, despite the increase in workload**.

## Concurrent Counter Data Structure by adding lock

### C++ Implementation

```c
#include <stdio.h>

#include <pthread.h>

// Counter with lock
typedef struct __counter_t {
    int value;
    pthread_mutex_t lock;
} counter_t;

void init(counter_t *c) {
    c->value = 0;
    pthread_mutex_init(&c->lock, NULL);
}

void increment(counter_t *c) {
    pthread_mutex_lock(&c->lock);
    c->value++;
    printf("Incremented: %d\n", c->value);
    pthread_mutex_unlock(&c->lock);
}

void decrement(counter_t *c) {
    pthread_mutex_lock(&c->lock);
    c->value--;
    printf("Decremented: %d\n", c->value);
    pthread_mutex_unlock(&c->lock);
}

int get(counter_t *c) {
    pthread_mutex_lock(&c->lock);
    int rc = c->value;
    pthread_mutex_unlock(&c->lock);
    return rc;
}

void* threadFunction(void* arg) {
    counter_t *c = (counter_t*)arg;

    for (int i = 0; i < 5; ++i) {
        increment(c);
    }

    for (int i = 0; i < 3; ++i) {
        decrement(c);
    }

    printf("Final value in thread: %d\n", get(c));
    return NULL;
}

int main() {
    counter_t counter;
    init(&counter);

    pthread_t threads[2];

    for (int i = 0; i < 2; ++i) {
        pthread_create(&threads[i], NULL, threadFunction, &counter);
    }

    for (int i = 0; i < 2; ++i) {
        pthread_join(threads[i], NULL);
    }

    printf("Final value in main: %d\n", get(&counter));
    return 0;
}
```

### Evaluations

- **Single Lock Bottleneck**: A single lock might not be sufficient for high-performance needs. Further optimizations may be required, which will be the focus of the rest of the chapter.
- **Sufficiency for Basic Needs**: If performance isn’t a critical issue, a simple lock might suffice, and no further complexity is necessary.

## The Approximation Counter Approach

- The logical counter is represented by **a global counter** and **one local counter for each CPU core**.
- Each local counter is synchronized with its own local lock, and a global lock is used for the global counter.
- When a thread wants to increment the counter, it updates its corresponding local counter, which is efficient due to **reduced contention across CPUs**.
- Regularly, the value from a local counter is transferred to the global counter by acquiring the global lock. This process involves **incrementing the global counter based on the local counter’s value** and then **resetting the local counter to zero**.
- The frequency of local-to-global updates is determined by a threshold **S**. A smaller **S** makes the counter behave more like a non-scalable counter, while **a larger S enhances scalability at the expense of accuracy in the global count**.

## Concurrent Operations in a Linked List

### C++ Implementation

```c

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

// Define the structure for a linked list node
typedef struct node {
    int key;
    struct node *next;
} node_t;

// Define the structure for the linked list
typedef struct list {
    node_t *head;
    pthread_mutex_t lock;
} list_t;

// Initialize the linked list
void List_Init(list_t *L) {
    L->head = NULL;
    pthread_mutex_init(&L->lock, NULL);
}

// Insert a new node with the given key at the beginning of the list
void List_Insert(list_t *L, int key) {
    // Allocate memory for a new node
    node_t *new = malloc(sizeof(node_t));
    if (new == NULL) {
        perror("malloc");
        return;
    }
    new->key = key;

    // Lock the critical section
    pthread_mutex_lock(&L->lock);

    // Update the pointers to insert the new node at the beginning
    new->next = L->head;
    L->head = new;

    // Unlock the critical section
    pthread_mutex_unlock(&L->lock);
}

// Lookup a key in the linked list and return 0 if found, -1 if not found
int List_Lookup(list_t *L, int key) {
    int rv = -1;

    // Lock the critical section
    pthread_mutex_lock(&L->lock);

    // Traverse the linked list to find the key
    node_t *curr = L->head;
    while (curr) {
        if (curr->key == key) {
            rv = 0; // Key found
            break;
        }
        curr = curr->next;
    }

    // Unlock the critical section
    pthread_mutex_unlock(&L->lock);

    return rv; // Return 0 for success and -1 for failure
}
```

### Evaluation

- The lock is only held around the **critical region** of the `insert` or `lookup` operations. This makes the implementation more robust.
- Assumed `malloc()` is **thread-safe** that can be called without a lock, **reducing the duration for which the lock is held**. 
- The `lookup` function has a **single exit path** for decreasing the likelihood of errors like **forgetting to unlock before returning**.

### Hand-Over-Hand Locking in Linked Lists

- This approach involves **adding a lock to each node of the list**. As one traverses the list, they **acquire the next node’s lock before releasing the current one**.
- Conceptually, hand-over-hand locking **increases parallelism** in list operations. However, in practice, the **overhead of locking each node can be prohibitive**, often making it less efficient than a single lock, especially for extensive lists and numerous threads. A hybrid method where a lock is **acquired for every few nodes** might be a more practical solution.

## Concurrent Queues

- A queue involves **two separate locks**: one for the head and another for the tail.
- Allows **enqueue** operations to primarily use the **tail** lock and **dequeue** operations to use the **head** lock, enabling concurrent execution of these functions.
- A **dummy node**, allocated during the queue’s **initialization**, **separates the head and tail operations**, further enhancing concurrency.

## Concurrent Non-resizable Hash Table

- **Each hash bucket, represented by a list, has its own lock**. This differs from using a single lock for the entire table.
- By allocating a lock per hash bucket, the hash table allows multiple operations to occur simultaneously, significantly enhancing its performance.
