---
layout: post
title:  "Very Simple File System Implementation"
categories: ["os", "persistence"]
tags: ["os", "persistence"]
---

## A mental model of a File System

- **Data Structure**: what types of on-disk structures are utilized by the file system to organize its data and metadata?
- **Access methods**: How does it map the calls made by a process, such as `open()`, `read()`, `write()`, etc., onto its structures? 


## Overall Organization

- **Block**: divide disk to a series of blocks.
- **Data Region**: reserve a fixed portion of the disk for these blocks to **store user data**.
- **Inodes**: a portion of the disk to store Inode. Inode is a structure for tracking things like which data blocks (in the data region) comprise a file, the size of the file, its owner and access rights, access and modify time.
- **Allocation Structure**: tracks data or inodes blocks are allocated or not. The data structures like **free list** or **bit map** can be used.
- **Superblock**: contains the information about this file system e.g. file system type, # of data/inodes blocks. When mounting a file system, the operating system will **read the superblock first**, to initialize various parameters, and then attach the volume to the file-system tree. 

## Inode

### Index node

Inode is short for index node, as the inode number is used to index into an array of on-disk inodes in order to find the inode of that number.

### Design of the Inode

One of the most important decisions in the design of the inode is **how it refers to where data blocks are**. One simple approach would be to have **one or more direct pointers (disk addresses)** inside the inode; each pointer refers to one disk block that belongs to the file.

### The multi-level index

To support **bigger** files, file system designers have had to introduce different structures. One common idea is to have a special pointer known as an **indirect pointer**. Instead of pointing to a block that contains user data, it **points to a block that contains more pointers**, each of which point to user data.

### Extended Approach

- A different approach is to use extents instead of pointers. An extent is simply a **disk pointer plus a length** (in blocks).
- All one needs is a pointer and a length to specify the on-disk location of a file.
- Just a single extent is limiting, as one may have **trouble finding a contiguous chunk of on-disk free space** when allocating a file.
- Thus, extent-based file systems often allow for **more than one extent**, thus giving more freedom to the file system during file allocation.

## Directory Organization

- A directory basically just contains a **list** of directory entries **(contains e.g. entry name, inode number pairs)**.
  - we can also store entries in B-Tree form.
- Each directory has two extra entries, `.` and `..`.
- A directory has an inode, somewhere in the inode table which its type is directory instead of regular file.

## Free Space management

Use two bitmaps(one for inode blocks, one for data blocks) for free space management.

## Reading File from Disk

1. The file system has to traverse the path name from the root directory where the root directory inode number is "well known" when the file system was mounted. 
2. Once the inode is read in, the FS can look inside of it to find pointers to data blocks, which contain the contents of the root directory. And then find the related entry from the contents.
3. Recursively traverse the pathname until the desired inode is found.
4. The FS then does a final permissions check, allocates a file descriptor for this process in the per-process open-file table, and returns it to the user.
5. Once open, the program can then issue a `read()` system call to read from the file.
6. The first read (at offset 0 unless `lseek()` has been called) will thus read in the first block of the file, consulting the inode to find the location of such a block; it may also update the inode with a new last-accessed time. The read will further update the in-memory open file table for this file descriptor, updating the file offset such that the next read will read the second file block, etc.
7. Deallocated file descriptor when the file is closed.

## Writing File to Disk

### Create File

1. Open the file like how we do for reading a file.
2. One read to the inode bitmap (to find a free inode).
3. One write to the inode bitmap (to mark it allocated).
4. One write to the new inode itself (to initialize it).
5. One to the data of the directory (to link the high-level name of the file to its inode number).
6. One read and write to the directory inode to update it.

### Actual Write

For each data blocl,
1. One read to the file inode.
2. One read and write to the data bitmap (to  find a free data block).
3. One write to the data block.
4. One write to the file inode (update pointer, # of blocks, etc).

## Caching and Buffering

### Speed up Reading

The first open may generate a lot of I/O traffic to read in directory inode and data, but **subsequent file opens of that same file (or files in the same directory) will mostly hit in the cache and thus no I/O is needed**.

#### Static Partitioning 

- introduced a fixed-size cache to hold popular blocks 
- ensures each user receives some share of the resource
- usually delivers more predictable performance
- is often easier to implement

#### Dynamic Partiioning 
- integrate virtual memory pages and file system pages into a unified page cache 
- achieve better utilization, by letting resource-hungry users consume otherwise idle resources
- more complex to implement
- can be worse performance for users whose idle resources get consumed by others and then take a long time to reclaim when needed

### Speed up Writing

Most modern file systems buffer writes in memory for anywhere between five and thirty seconds.

- If the system crashes before the updates have been propagated to disk, **the updates are lost**.
- Keeping writes in memory longer, performance can be improved by **batching, scheduling, and even avoiding writes**.
  - Batching: e.g. One inode bitmap read write for multiple file creations.
  - Scheduling: reorder the writes for reducing seek time, rotation time.
  - Avoiding: e.g. if an process creates a file and then delete that created file, we dont have to write it to disk at all.

