---
layout: post
title:  "Memory Space Management with paging"
categories: "OS"
tags: "OS"
---

## What is Paging

Paging is another memory space management approach that **dividing memory into fixed size of chuncks called pages**. In contrast to segmentation, paging **does not have external fragmentation** and support **the abstraction of an address space effectively**, regardless of how a process uses the address space since it won’t make assumptions about the way the heap and stack grow and how they are use.

## Address Translation

To translate the virtual address the process generates:

1. We have to break the resulting virtual address into two parts:
  - The virtual page number (**VPN**) and
  - The **offset** within the page.
2. Using our *VPN*, we can now index our **page table** and find out which physical frame virtual page lives in.

## Page Table

- The page table is a **data structure** that **maps virtual addresses (or virtual page numbers) into physical addresses (physical frame numbers)**.
- Each process has its own page table.

## Linear Page Table

Linear Page table is an **array**.

- *VPN* is an **index** of the array.
- Each page table entry(**PTE**) contains *PFN* and other useful *bits*.

## The steps of address translation by hardware

```
// Extract the VPN from the virtual address
VPN = (VirtualAddress & VPN_MASK) >> SHIFT
// Form the address of the page-table entry (PTE)
PTEAddr = PTBR + (VPN * sizeof(PTE))
// Fetch the PTE
PTE = AccessMemory(PTEAddr)
// Check if process can access the page
if (PTE.Valid == False)
    RaiseException(SEGMENTATION_FAULT)
else if (CanAccess(PTE.ProtectBits) == False)
    RaiseException(PROTECTION_FAULT)
else
    // Access is OK: form physical address and fetch it
offset = VirtualAddress & OFFSET_MASK
PhysAddr = (PTE.PFN << PFN_SHIFT) | offset
Register = AccessMemory(PhysAddr)
```
