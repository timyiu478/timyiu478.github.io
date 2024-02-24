---
layout: post
title:  "Advanced Page Table"
categories: ["os", "memory"]
tags: ["os", "memory"]
---

## Problem of Linear Page Table

- The size of the page table is **too big**.
- We need to allocate the physical memory for the page table entries that **there is no physical frame** as well.

## Larger Page size

- One way to make the page table smaller is make the **page size larger** because it makes **the number of page table entries** to be decreased.
- The major drawback to this strategy is that large pages result in waste within each page, a problem known as **internal fragmentation**. Applications allocate pages but only use small portions of each, and memory quickly fills up with these excessively large pages. 

## Combining Paging and segmentation

- The goal of combining paging and segmentation is **removing the erroneous entries between the heap, and stack segments(unallocated pages between the stack and the heap are no longer needed)** to reduce the size of page table.
- Instead of one page table for the process’s whole address space, we have **one page table for each segments(code, heap, and stack)** so we have three page tables.
- The base register holds **the physical address of the segment’s page table**.
- The limits register indicates the page table’s end (i.e., how many valid pages it has).
- During a context switch, these registers must be updated to reflect the new process’s page tables.
- On a TLB miss (assuming a hardware-managed TLB), the hardware utilizes the segment bits (SN) to identify which base and bounds pair to use. The hardware then combines the physical address with the VPN to generate the page table entry (PTE) address.

```
SN           = (VirtualAddress & SEG_MASK) >> SN_SHIFT
VPN          = (VirtualAddress & VPN_MASK) >> VPN_SHIFT
AddressOfPTE = Base[SN] + (VPN * sizeof(PTE))

Virtual Address:
|****SN*****|*****VPN******|*****OFFSET******|
```

- The downsides of this approach:
  - Use segmentation so assumes a fixed address space utilization pattern; **a huge but sparsely used heap**
  - External fragmentation: page tables can now **be any size** (in multiples of PTEs). Finding memory space for them is more difficult.

## Multi-Level Page Tables

- This is approach to get rid of all those incorrect sections in the page table **without using segmentation**.
- It first divide the page table into **page-sized units**.
- If **all page-table entries (PTEs) of that page are invalid**, then **do not assign that page of the page table** at all.
- So, it’s generally **compact** and **supports sparse address spaces**.
- To know **the memory location of the pages of the page table and their validities**, it use the new data structure called **page directory**.
- When the OS wants to allocate or grow a page table, it may simply grab the **next free page-sized unit(the size is much smaller than the size of page table)**.
- But, on a TLB miss, two loads from memory are necessary to acquire the proper translation information from the page table (**one for the page directory, and one for the PTE itself**).
- For 2-level page table, to find out the page table entry, we can use *base pointer + PD.index * sizeof(page directory)* to find out the address of *page-sized unit = PD.PFN* , then we use *PD.PFN + PT.index * sizeof(PTE)* to find out the *PTE* address.

```
|******** VPN **********************|****** Offset *********|
| 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|**** PD.Index *****|** PT.index ***|
```

## Inverted Page Table

- Rather than having many page tables (one for each system process), we have a **single** page table with an item for each physical page of the system. 
- This entry indicates **which process uses this page** and which virtual page of that process corresponds to this physical page.
- A **hash table** is frequently added on top of the underlying structure to speed up lookups.

## Swapping the Page Tables to Disk

Some systems store page tables in kernel virtual memory, allowing the system to swap portions of these page tables to disk if memory becomes scarce.
