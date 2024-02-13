---
layout: post
title:  "Event Based Concurrency"
categories: "OS"
tags: "OS"
---

## What is Event Based Concurrency?

The method of **constructing the concurrent servers without relying on threads** is event-based concurrency.

## The Essence of Event-Based Concurrency

- **Event Monitoring**: The server **waits for specific events (like I/O requests) and reacts** when they occur.
- **Minimal Work Execution**: Upon an event’s occurrence, the server **identifies the event type and performs only the necessary actions**, which may include **initiating further I/O requests or scheduling future events**.

## Advantages of Event-Based Concurrency

- Event-based concurrency **sidesteps the concurrency issues like missing locks or deadlocks** by handling tasks in response to specific events.
- Unlike multi-threaded systems where the operating system manages thread scheduling, event-based concurrency offers developers **more control over task execution**.

## A canonical event-based server: event loop

### Pseudo Code

A handler’s processing of an event is the system’s **only activity**.

```c
while (1){
  event=getEvents();
  for (something in event)
    processEvent(e);
}
```

### How can an event server detect if a message has arrived for it?

We can use the `select()` or `poll()` system call as API’s when receiving the event. Run `man select` to check more.

## The Challenge of Blocking System Calls

- System calls such as `open()` and `read()` can cause **delays**, especially if the required data isn’t immediately available in memory. These calls can initiate slow I/O requests to the storage system.
- With only a single event loop in action, any event handler making a blocking call causes **the entire server to stall**.
- To maintain efficiency and avoid stalling the entire server, event-based systems must adhere to a crucial rule: **avoid making any blocking calls**.

## Asynchronous I/O

### Understanding Asynchronous I/O

Asynchronous I/O allows applications to issue I/O requests to the disk system **without waiting for the operation to complete**.

### Checking I/O Completion

- **Frequent Checks**: Continuously polling to check the completion of I/O operations can be cumbersome, especially when numerous operations are ongoing.
- **Interrupt**: Using signals to inform applications of completed I/O operations. This method contrasts with the traditional polling approach and is often debated in the context of device management.

### Implications for Event-Based Systems

It necessitates **a balance between efficient event handling and the complexities of managing asynchronous I/O operations**, including the decision between polling and interrupt-driven approaches.

## State Management and Challenges

### Manual Stack Management

- In thread-based applications, the state is maintained on the thread’s stack. In contrast, event-based systems require **explicit** state management, often called “manual stack management.”
- To handle events like asynchronous I/O, event-based systems use ‘**continuations**’ - structures that **store necessary information for event processing**. This approach requires careful management of these continuations to ensure correct program execution.

### Example Scenario: Handling Asynchronous I/O

#### Thread-based Server

In a thread-based server, reading from a file and writing to a socket is straightforward, with the socket descriptor (`sd`) **readily available on the thread’s stack**.

```c
int rc = read(fd, buffer, size);
rc = write(sd, buffer, size);
```

#### Event-based Server

In an event-based server, this operation requires additional steps. After performing an asynchronous read, the server **uses a data structure (like a hash table) to link the file descriptor (`fd`) with the socket descriptor (`sd`)**. When the read completes, the server retrieves `sd` using `fd` from the data structure and then proceeds with writing to the socket.

## Other issues on Event Based Concurrency

- **Scaling on Multi-CPU Systems**: Running **multiple event handlers concurrently reintroduces synchronization challenges** typical in multi-threaded environments.
- **Incompatibility with System Activities**: Event-based methods struggle with activities that **inherently block**, such as paging. For instance, **a page fault in an event handler can halt the entire server**, undermining the non-blocking nature of event-based systems.
