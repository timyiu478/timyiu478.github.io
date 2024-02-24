---
layout: post
title:  "Page Swapping"
categories: ["os", "memory"]
tags: ["os", "memory"]
---

## What is page swapping

Swap pages to disk so that the running programs to **use more RAM than is physically accessible**.

## Swap Space

- Swap space is **reserved space on the disk** for moving pages between memory and the file system.
- This assumes the OS can read and write to swap space in **page-sized units**.

## The *free* Command

The `free` command displays amount of free and used memory in the system.

```
               total        used        free      shared  buff/cache   available
Mem:         8086120     2908832      577556       56540     4599732     4815504
Swap:        2097148          12     2097136
```

- In the “Mem” or memory row, there is more “available” space than “free” because **there are pages the system knows it can get rid of if needed**.
- The “Swap” row which reports **the usage of the swap space** as distinct from your memory.

## Swapping Mechanism

- In a software-managed TLB architecture, the OS **determines if a page exists in physical memory** using a new piece of information in each page-table entry called the **present bit**.
- A **page fault** occurs when a program accesses a page that isn’t in physical memory.
- A page fault will require the OS to **swap in a page from disk**.
  1. use the **PTE’s data bits**, like the page’s PFN, to store a disk address. 
  2. Once the page is located on the disk, it is **swapped into memory via I/O**. The process will be blocked while the I/O is running, so the OS can run other ready processes while the page fault is handled.
  3. The OS will **update the page table** to reflect the new page, update the PFN field of the page-table entry (PTE) to reflect the new page’s address in memory, and **retry** the instruction.

## When to swap out(swap page to disk)?

### High/Low Watermark

When the OS detects that there are more pages in memory than the **high watermark (HW)**, a background process called the swap daemon  starts to evict pages from memory until the number of pages is less than the **low watermark (LW)**. The daemon then **sleeps until the HW is reached again**.

### Invoke by Process

The swap can also be awoken by a process if there are **no free pages available**; Once the daemon has freed up some pages, it will **re-awaken the original thread**, which will then be able to page in the appropriate page and continue working.

### Performancement Optimization

Many systems, will cluster or group a number of pages and **write them out to the swap partition all at once**.

## Other useful commands

- `vmstat`

## Implementing LRU

### Problem

Scanning a wide array of times to **discover the least-recently-used page is expensive**.

### Approximating LRU 

- When a page is referenced (read or written), the hardware sets the **use bit to 1**.
- The system’s pages organized in a **circle**.
- Initially, a clock hand points to any page.
- When replacing a page, the OS checks if the use bit is 1 or 0.
  - If **1**, page P was **recently used**. The usage bit for P is **cleared (set to 0)**, and the clock hand is advanced one page (P + 1).
  - If the use bit is set to **0**, the page is **evicted** (in the worst case, all pages have been recently used and we have now searched through the entire set of pages, clearing all the bits).

### Dirty Pages

- The clock algorithm may be altered to look for pages that are both unused and **clean** to evict first; if those aren’t found, then look for **unused dirty** pages, and so on.
- Because if a page has been updated and is thus unclean, it must be evicted by writing it back to disk, which is **costly**.
- The eviction is **free** if it has not been updated; the physical frame can simply be reused for other purposes **without further I/O**. 
- A **modified/dirty bit** should be included in the hardware to accommodate this behavior.

## Thrashing

- Thrashing is used to describe the system is **continuously paging** because the memory demands of the operating processes simply outnumber the physical memory available.
- The methods to address thrashing
  - **not to execute a subset of them** in the hopes that the pages of the reduced set of processes will fit in memory, allowing progress.
  - launch an **out-of-memory killer**; this daemon selects a memory-intensive process and kills it.
