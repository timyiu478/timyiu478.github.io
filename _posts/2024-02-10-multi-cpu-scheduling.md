---
layout: post
title:  "Multi CPU Scheduling"
categories: ["os", "concurrency"]
tags: ["os", "concurrency"]
---

## Key Questions

- **How to Schedule Jobs on Multiple CPUs?** Strategies and mechanisms for effectively distributing tasks across multiple processing units.
- Emerging **Challenges in Multiprocessor Scheduling**: Identifying and addressing unique issues that arise when transitioning from single to multiple CPU systems.
- **Load Balancing in Multi-Queue Multiprocessor Schedulers**: Methods to achieve optimal workload distribution among CPUs, ensuring efficient utilization of resources.

## Implications for Applications

- Conventional Applications: Standard applications, like a C program, typically **utilize only one CPU**. Therefore, adding more CPUs doesn’t inherently boost their performance.
- **Multi-Threaded** Applications: These applications can **distribute their workload across multiple CPUs**, achieving significant performance gains.

## Role of Caches in Multiprocessor Systems

- Caches are **small, fast memory units that store copies of data from the system’s main memory**, crucial for enhancing processing speed.
- Each processor has its **own chache** but several processors **share a single main memory**.

## Challenges in Multiprocessor Caching

How data is **shared and cached across multiple CPUs**, affecting data access patterns and efficiency.

## Cache Coherence Problem

The problem of cache coherence becomes evident when **processes migrate between CPUs or when multiple CPUs access the same memory block**.

- **Process Migration**: If a program initially running on CPU A switches to CPU B, the latter CPU **lacks immediate access to the previously cached data in CPU A’s cache**.
- **Inefficient Data Access**: CPU B, lacking the needed data in its cache, **must access the main memory**, leading to inefficiencies and potential data inconsistencies.
- **Inconsistency Risks**: The situation becomes even more complicated if **both CPUs attempt to modify the same memory location**, leading to potential data inconsistencies between their caches and the main memory.

## Addressing Cache Coherence

- Modern multiprocessor systems implement **hardware-level mechanisms** to ensure cache coherence. These mechanisms can **detect and manage data that is simultaneously accessed or modified by multiple CPUs**.
- Operating systems and applications can also be designed to **minimize cache coherence issues**, for instance, by **managing process allocation to CPUs** or **optimizing memory access patterns**.

## Synchronization in Multiprocessor Systems

Even with cache coherence protocols in place, challenges persist in ensuring consistent and correct data manipulation.

### Case Study: Shared Linked List

Imagine a scenario where two CPU threads concurrently execute a routine to **remove an element from a shared linked list**:

1. Thread 1 executes the first line, storing the current `head` value in its `tmp` variable.
2. Thread 2 also executes the same line, capturing the same `head` value in its separate `tmp` variable (since tmp is stack-allocated and thus private to each thread).

Both threads attempt to **remove the same element**, leading to potential data corruption or other unintended consequences.

To prevent the concurrent access issues, we use **mutex locks** for the critical section (data manipulation part).

## Cache Affinity

- A multiprocessor scheduler should consider Cache affinity when **scheduling**, and thus if possible **keeping a process on the same CPU**.
- When a process runs on the same CPU repeatedly, benefiting from the state information accumulated in that CPU’s caches
- When a process is frequently shifted between different CPUs, it faces a performance hit. Each CPU switch **forces the process to reload its state into a new cache**, which is a slower operation.

## Single-Queue Multiprocessor Scheduling (SQMS)

SQMS involves **placing all jobs in a single queue**, adopting a structure similar to single-processor scheduling.

- The use of **locks** to access the single queue can lead to **performance bottlenecks**, especially as the number of CPUs increases. The **competition for the single lock results in increased overhead** and reduced job execution time.
- In SQMS, jobs tend to **move between CPUs**, which goes against the principle of cache affinity. 

## Multi-Queue Multiprocessor Scheduling (MQMS)

MQMS addresses the limitations of SQMS by **assigning each CPU its own scheduling queue**.

- Each queue **operates independently**, significantly reducing the need for synchronization and information sharing across CPUs.
- Jobs are more likely to **remain on the same CPU across executions**, allowing them to benefit from cache affinity
- While MQMS supports cache affinity, it requires **effective load balancing strategies** to ensure that **no single CPU is overwhelmed or underutilized**.
  - A technique that **move jobs around CPUs** which we call **migration**.
  - **Work stealing** is one basic method the system used to decide how to perform such a migration.

## Work Stealing

- When work-stealing takes place, **a queue that is low on jobs occasionally peeks into another queue, to determine how full it is**.
- The **source to “steal” one or more jobs from a target queue to balance the load** but this strategy creates **friction**.
- **Overlooking other queues** causes significant overhead and scaling issues, which was the whole point of introducing MQMS.
- Conversely, if you don’t glance at other queues often, you risk significant **load imbalances**.
- Finding the proper **threshold** is a dark art in system policy design.
