---
layout: post
title:  "VMS Lazy Optimizations"
categories: "OS"
tags: "OS"
---

## Demand Page Zeroing

- Consider adding a page to the address space, say in the heap.
- The OS have to **zero** the page for security reason so that the process cannot know how this page used for.
- Instead of the OS zeros the page **before maps it into your address space**, the OS  the OS just adds an entry to the page table **marking it unavailable**.
- When the process **reads or writes** the page, it **traps** the OS. A demand-zero page is identified by the OS using certain bits designated in the “reserved for OS” portion of the page table entry.
- The OS then finds a physical page, zeroes it, and maps it into the process’s address space. 
- This task(zeros the page) is avoided if the process **never accesses the page**.

## Copy-On-Write

- Instead of copying a page from one address space to another, the OS can **map it into the target address space and declare it read-only in both address spaces**.
- If both address spaces **just read** the page, **no data is moved**.
- A page write attempt from one of the address spaces will be logged into the OS. The OS then allocate a new page, fill it with data, and map it into the address space of the faulting process.
- So it saves **unnecessary copying**.

## References

1. VMS - [https://en.wikipedia.org/wiki/OpenVMS](https://en.wikipedia.org/wiki/OpenVMS)
