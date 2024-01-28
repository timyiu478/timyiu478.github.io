---
layout: post
title:  "Memory Segmentation"
categories: "OS"
tags: "OS"
---

## What is Memory Segmentation?

- It allows the segments(code, stack, heap) of the address space can be stored in different physical memory locations so that we do not need to allocate the physical memory for the "free" segment.
- Each segment has its own base/bound registers.

## Which segment the virtual memory address related to?

### Explicit Approach

> we divide the address space into segments based on the first few bits of the virtual address.

- the top 2 most bits represent which segment the address corresponds to.
- the other bits represent the offset.

```
// get top 2 bits of 14-bit VA
Segment = (VirtualAddress & SEG_MASK) >> SEG_SHIFT
// now get offset
Offset  = VirtualAddress & OFFSET_MASK
if (Offset >= Bounds[Segment])
  RaiseException(PROTECTION_FAULT)
else
  PhysAddr = Base[Segment] + Offset
  Register = AccessMemory(PhysAddr)
```

### Implicit Approach

> determines the segment by examining the address.

- If the address came from the program counter (i.e., an instruction fetch), it’s in the code segment.
- If it came from the stack or base pointer, it’s in the stack segment.
- All others are in the heap.

## How to handle stack

- The difference between the stack and the other segment is it now grows backwards (towards lower addresses).
- We need more hardware support so that the hardware knows the segment grows positive or negative from the base address.
- We can get the correct physical address by *base address + offset - max segment size*.

| Segment         | Base     | Size (Max 4K) | Grows Positive? |
|--------------|-----------|------------|-------------|
| Code      | 32K | 2K       | 1 |
| Heap      | 34K | 3K       | 1 |
| Code      | 28K | 2K       | 0 |

## Segmentation presents new challenges for the OS

- The segment registers must be saved and restored becase each process has its own virtual address space for context switch.
- Able to update the segment size register to the new (larger/smaller) size.
- Able to find physical memory space for new address spaces.
- handle external fragmentation: physical memory soon fills up with pockets of free space, making it impossible to assign new segments or expand old ones.
