---
layout: post
title:  "Transaction Lookaside Buffer"
categories: "OS"
tags: "OS"
---

## Problem of Paging

Paging needs an additional memory lookup in order to translate each virtual address, but it takes too long to obtain translation information before every instruction fetch, load, or store.

## What is Transaction Lookaside Buffer?

In order to speed up the process of address translation, we use the **hardware cache** for the address translation. This cache is called **Transaction Lookaside Buffer(TLF)** which is part of the *MMU*.

## TLB Entry

TLBs generally include 32 or 64 of TLB entries. A few are for the OS (using the G bit). The OS can set a wired register to instruct the hardware how many TLB slots to reserve for it. The OS uses these reserved mappings for code and data it needs to access during key moments when a TLB miss would be troublesome (e.g., in the TLB miss handler).

TLB Entry:
- Virtual Page Number (VPN)
- Process ID (PID) or Address Space ID(ASID)
- Page Frame Number (PFN)
- V bit: Valid bit - indicates whether the entry has a valid translation or not
- G bit: Global bit - If set, TLB does not check PID for translation
- ...

## What if TLB miss

### Hardware approach

- If the virtual address does not in the TLB entries, we have to **check the page table** to find the translation. 
- The hardware has to know the exact location of the page tables in memory (through **a page-table base register**)

### OS approach

- The hardware mimics an exception, pausing the current instruction stream, switching to kernel mode, and **jumping to a trap handler**.
- Returning from a TLB miss-handling trap causes the hardware to **retry the instruction**, resulting in a TLB hit.
- OS must avoid creating **endless loops of TLB misses** by keeping the TLB miss handler in physical memory.
  - reserve some TLB entries for always valid transaction. Or
  - unmapped and not subject to address translation.
- OS can use **any data structure it wants to implement the page table**. 

## Array Access Example

### A memory array of 10 4-byte integers.

The page size is 16 bytes.

| VPN    | Offset 0-4    | Offset 5-8    | Offset 9-12    | Offset 13-16    |
|---------------- | --------------- | --------------- | --------------- | --------------- |
| VPN 0    |     |     |     | arr[0]   |
| VPN 1    | arr[1]    | arr[2]    | arr[3]    | arr[4]   |
| VPN 2    | arr[5]    | arr[6]    | arr[7]    | arr[8]   |
| VPN 3    | arr[9]    | | |   |

### The TLB hit rate the first time the array is accessed

The hit rate is 60%.

- arr[0]: Miss (VPN 0 stored in TLB)
- arr[1]: Miss (VPN 1 stored in TLB)
- arr[2]: Hit (VPN 1)
- arr[3]: Hit (VPN 1)
- arr[4]: Hit (VPN 1)
- arr[5]: Miss (VPN 2 stored in TLB)
- arr[6]: Hit (VPN 2)
- arr[7]: Hit (VPN 2)
- arr[8]: Hit (VPN 2)
- arr[9]: Miss (VPN 3 stored in TLB)

### The TLB hit rate the second time the array is accessed

The hit rate is 100% because VPN 0-4 stored in TLB already in the first time access.

## Context Switching

How to make sure the process does not reuse the TLB entries of the old process?

- flushing: clears the TLB by **setting all valid bits to 0**.
- ASID: TLBs include an address space identifier (ASID) field. The ASID is a **Process ID (PID) with less bits**. So the TLB can hold several processes’ translations.

## Two entries for two processes with two VPNs point to the same physical page

When two processes share a page (for example, a code page), this can occur. Also, it reduces memory overheads by reducing the number of physical pages needed.

| VPN    | PFN    | ASID    | Prot-bit    | Valid-bit    |
|---------------- | --------------- | --------------- | --------------- | --------------- |
| VPN 0    | **PFN 100**    |  1   |  r-x   | 1  |
| VPN 5    | **PFN 100**    |  2   |  r-x   | 1   |

## TLB Replacement Policy

- LRU
- Random
