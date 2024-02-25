---
layout: post
title:  "Fast File System"
categories: ["os", "persistence"]
tags: ["os", "persistence"]
---

## Old Unix File System

### Structure

- Super Block: information about the entire file system e.g. how big the volume is, how many inodes there are, a pointer to the head of a free list of blocks.
- Inode Region
- Data Region

### Poor Performance

- The main issue was that the old UNIX file system treated the disk like it was a **random-access memory**. The data was spread all over the place without regard to the fact that **the medium holding the data was a disk**, and thus had real and expensive **positioning** costs. 
- The free space is managed by free list that a **logically contiguous file would be accessed by going back and forth across the disk**, thus reducing performance dramatically.
  - disk defragmentation tool can help by reorganizing on-disk data to place files contiguously.

## Fast File System: Disk Awareness

The idea was to design the file system structures and allocation policies to be “disk aware” and thus improve performance.

### Organizing structure: the cylinder group

- **Cylinder** is **a set of tracks** on different surfaces of a hard drive that are the **same distance** from the center of the drive.a
- FFS aggregates N **consecutive cylinders** into a group, and thus the entire disk can thus be viewed as a collection of cylinder groups.
- To improve performance, FFS puts files into the same group for reducing the seek time.
- Each group include all file system structures including super block, bitmaps, inode region, and data region.
- Super block is duplicated in each group for reliabiltiy.
- Use data and inode bitmaps manage free space in a file system because it is **easy to find a large chunk of free space** and allocate it to a file, perhaps avoiding some of the **fragmentation problems of the free list**.

### Policies: How to Allocate Files and Directories

**Keep related stuff together(same block group), keep unrelated stuff far apart(different block group)**.

#### Placement of Directories

Find a group that 

- a lower number of allocated directories for balancing directiories across groups.
- a high number of free inodes which implies can allocate a lot of files.

Then put the inode and data block of the directory to that group.

#### Placement of Files

- Allocate the data blocks of a file in the same group as its inode.
- Places all files that are in the same directory in the cylinder group of the directory they are in.

#### The Large File exception

- Without a different rule, a large file would **entirely fill the block group** it is first placed within such that it prevents subsequent “related” files from being placed within this block group, and thus may **hurt file-access locality**.
- After some number of blocks are allocated into the first block group, the next large chunk of file will be placed into the next block group , and so on.
- How to choose the chunk size? FFS decide it based on the **inode structure**. The first twelve direct blocks were placed in the same group as the inode. Each subsequent indirect block, and all the blocks it pointed to, were placed in a different group.

### Internal Fragmentation

- FFS designed to to **sub-blocks(512 bytes size blocks)** to fix the internal fragmentation problem.
- The sub-blocks will be allocated to a small file(smaller than 4KB) until the file acquires a full 4KB of data.
- At that point, FFS will find a 4KB block, copy the sub-blocks into it, and free the sub-blocks for future use.
- Since this introduces additional I/0s, buffer write is used to aviod the sub-block specialization entirely in most cases.
