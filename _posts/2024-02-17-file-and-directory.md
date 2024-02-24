---
layout: post
title:  "File and Directory"
categories: ["os", "persistence"]
tags: ["os", "persistence"]
---

## Storage Abstractions

Storage virtualization is based on two main ideas: the file and the directory.

- **File**: A group of bytes that can be read or written. Each file has a low-level name in the form of an **inode** number.
- **Directory**: the user-readable name and the low-level name are listed in **pairs**.

A **file system** consists of groups of directories and the files and other directories they contain.
The **directory hierarchy** starts at the **root** directory and uses a separator to identify sub-directories until the desired file or directory is specified.

## File System Interface

### Creating, Reading, Writing, Closing Files

A program can create a new file by using `open()` and passing it the `O_CREAT` flag. The `open()` returns a **file descriptor**, which is useful. If you have **permission** to read or write to the file, you can **use the file descriptor to read or write it** using `read()` or `write()`. After reading or writing the file, the `close()` should be used to close the file descriptor so that it **no longer refers to any file and can be reused**.

### Reading and Writing, Non-Sequentially

The OS keeps a current offset for each file a process opens. This tells us where the next read or write will begin. An open file has a current offset that can be modified:

- Implicitly:  with each read or write of N bytes, or
- Explicitly: With the `lseek` to **reposition the read/write file offset**.

The offset is stored in the struct `file` and addressed by the struct `proc`. Below is a simplified definition of this:

```
struct file {
    int ref; // A reference counter
    char readable;
    char writable;
    struct inode *ip; // If a file links to any other files through the struct inode pointer ip
    uint off; // A file’s current offset
};
```

## Shared File Table Entries

- In many cases, the mapping of file descriptor to an entry in the open file table is a **one-to-one** mapping. If some other process reads the same file at the same time, each will have its **own entry in the open file table**. In this way, each logical reading or writing of a file is **independent**, and each has its **own current offset** while it accesses the given file.

### fork()

- Each process’s private descriptor array, the shared open file table entry, and the reference from it to the underlying file-system inode.
- When a file table entry is shared, its reference count is incremented; only when both processes close the file (or exit) will the entry be removed.

```c
int main(int argc, char *argv[]) {
    int fd = open("file.txt", O_RDONLY); 
    assert(fd >= 0);
    int rc = fork();
    if (rc == 0) {
        rc = lseek(fd, 10, SEEK_SET);
        printf("child: offset %d\n", rc);
    } else if (rc > 0) {
        (void) wait(NULL);
        printf("parent: offset %d\n", (int) lseek(fd, 0, SEEK_CUR));
    }
    return 0; 
}
```

### dup()

- The `dup()` call allows a process to create a **new file descriptor** that refers to the **same underlying open file as an existing descriptor**.
- The `dup()` and `dup2()` call is useful when writing a UNIX shell and performing operations like **output redirection**. For example, if we want to rewrite the output from standard output to a file A, we can

1. `dup_stdout = dup(1)` to create a new file descriptor for saving a descriptor that refers to standard output.
2. `close(1)` to close the file descriptor 1 so that the file descriptor 1 can be reallocated to the file A.
3. `fd_A = open(A)` to open file A and the `fd_A` file descriptor should be **1** because the function return the **smallest free** file descriptor(assumed file descriptor 0 is in use).
4. Then when the process write things to file descriptor 1, it will write to file A.
5. Finally, we can use `dup2(dup_stdout, 1)` to make the file descriptor 1 refers to standard output since this is the one which `dup_stdout` refers to.

## Writing Immediately With fsync()

- The file system will **buffer such writes in memory** for some time for performance issue. The write(s) will actually be issued to the storage device after few seconds.
- To support the applications like DBMS, the interface `fsync(int fd)` is provided for forcing all dirty (i.e., not yet written) data to disk, for the file referred to by the specified file descriptor `fd`.

## File Metadata

- Apart from the file content, the file system also stores the metadata of the file. To see the metadata for a certain file, we can use the `stat()` or `fstat()` system calls.
- Each file system usually keeps this type of information in a **on-disk** structure called an **inode**.

```shell
> stat /dev/null
  File: /dev/null
  Size: 0               Blocks: 0          IO Block: 4096   character special file
Device: 5h/5d   Inode: 5           Links: 1     Device type: 1,3
Access: (0666/crw-rw-rw-)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2024-02-17 22:49:17.248000219 +0800
Modify: 2024-02-17 22:49:17.248000219 +0800
Change: 2024-02-17 22:49:17.248000219 +0800
 Birth: 2024-02-17 22:49:01.708000001 +0800
```

## Directories

### System Calls

- `opendir()`
- `readdir()`
- `closedir()`
- `rmdir()`: the directory be empty (i.e., only has `.` and `..` entries) before it is deleted.

### Data structure

```
struct dirent {
  char d_name[256];         // filename
  ino_t d_ino;              // inode number
  off_t d_off;              // offset to the next dirent
  unsigned short d_reclen;  // length of this record
  unsigned char  d_type;    // type of file
};
```

## Links

### link()

The way `link()` works is that it **creates another name in the directory** you are creating the link to, and refers it to the **same inode number** (i.e., low-level name) of the original file. The file is not copied.

### unlink()

When `unlink()` is called, it removes the “link” between the human-readable name (the file that is being deleted) to the given inode number, and **decrements the reference count**. When the reference count reaches **zero** does the file system also **free the inode and related data blocks**, and thus truly “delete” the file.

### Hard Link

Hard links are somewhat limited as you can’t create one to a **directory**, for fear that you will create a **cycle** in the directory tree. You can’t hard link to files in other disk partitions, etc., because inode numbers are only **unique within a particular file system**, not across file systems.

### Symbolic Link

- It has its own file type the file system knows about.
- It is formed is by holding **the pathname of the linked-to file** as the **data** of the link file.
- Unlike hard links, removing the original file causes the link to point to a pathname that no longer exists.

## Permission Bits

- 3 groups: owner, group, other
- 3 bits: read, write, execute
- Execute Bit:
  - For regular files, its presence determines whether a program can be run or not.  
  - For directories, it enables a user (or group, or everyone) to do things like **change directories** (i.e., `cd`) into the given directory, and, in combination with the writable bit, create files therein.

```
tim@tim-virtual-machine /tmp> ls -alt
total 100
drwxrwxrwt 21 root root 20480 Feb 24 12:05 .
drw-rw-r--  2 tim  tim   4096 Feb 18 01:44 test

tim@tim-virtual-machine /tmp> cd test
cd: Permission denied: “test”

tim@tim-virtual-machine /tmp [1]> chmod +x test
tim@tim-virtual-machine /tmp> cd test
```

## How to assemble a full directory tree from many underlying file systems?

### Making File System

`mkfs` is used to build a Linux filesystem on a device, usually a **hard disk partition**. The device argument is either the device name (e.g., `/dev/hda1`, `/dev/sdb2`), or a regular file that shall contain the filesystem. The size argument is the number of blocks to be used for the filesystem. and it simply writes an **empty** file system, starting with a **root** directory, onto that disk partition.

### Mount

Once such a file system is created, it needs to be made **accessible within the uniform file-system tree**. This task is achieved via the `mount` program. For example, after we run `mount -t ext3 /dev/sda1 /home/user`, the path name `/home/user` refers to the **root** of the newly-mounted directory.
