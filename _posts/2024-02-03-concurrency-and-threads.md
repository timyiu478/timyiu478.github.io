---
layout: post
title:  "Concurrency and Threads"
categories: ["os", "concurrency"]
tags: ["os", "concurrency"]
---

## Threads

- Each thread is like an independent worker, but they all **share the same memory space**.
- Each thread has its own **Program Counter(PC)** to keeps track of where a thread is in its execution.
- Just like a process has a control block to **keep track of its state**, each thread has its own **Thread Control Block(TCB)**.
- Each thread has its own **stack**. This means each thread can handle its own functions and data, keeping them in its personal stack.
- **Context switch** is allowed by saving and loading different sets of registers for each thread.

## Why use threads?

They are useful on **parallelism** and handling **I/O (Input/Output) operations**.

### Parallelism

In multi-processor system, we can speed up the process by **dividing the task(e.g. adding numbers in a huge array) among multiple threads**, with each processor handling a part of the job.

### Avoid delays caused by I/O operations

If a program only used one thread and had to wait for an I/O operation to complete, it couldn’t do anything else during that time. By using multiple threads, **one thread can handle the I/O operation while others continue processing or initiating more I/O requests**.

### Why not just use multiple processes instead of threads?

Threads have a special advantage: they **share the same address space**. This makes **data sharing between threads straightforward and efficient**, especially suitable for tasks that are **closely related**. 

## Race Condition

- When multiple threads access and **modify the same data**, **unpredictable outcomes** can occur because of the **uncontrollable threads scheduling**.
- For example, in order to increment an counter, **3 machine codes** will be generated by compiler.
  1. load counter value from memory to register(e.g. `eax`).
  2. increment the register.
  3. store back the updated register value to counter memory location.
- Two threads (Thread 1 and Thread 2) executing this sequence concurrently so that **the code executed twice, but the counter incremented only once**.
  1. Thread 1: loading the counter value(`10`) into `eax` and increments it to `11`.
  2. Context Switch to Thread 2.
  3. Thread 2: loading the counter value(`10`) into `eax` and increments it to `11`, store its `eax` value(`11`) back to memory.
  4. Context Switch to Thread 1.
  5. Thread 1: store its `eax` value(`11`) back to memory.

## Critical Section

From the above code sequence example, we can see that increment an counter is an **critical section** that the code that **accesses a shared resource** and should not be executed by **more than one thread** at a time.

## Mutual Exclusion

To prevent race conditions, we need mutual exclusion in critical sections. **If one thread operates within the critical part, the others are stopped**.

## Atomicity

- In multi-threading, a major challenge is ensuring that certain operations are **executed without interruption, maintaining consistency in shared data**. 
- **add instruction** is one of an atomic instructions.
- In practice, we often don’t have such atomic instructions for **complex operations** in regular instruction set and we have to break it down to multiple instructions.
- Since we can’t rely on **hardware** for atomicity, we turn to **synchronization primitives**.
