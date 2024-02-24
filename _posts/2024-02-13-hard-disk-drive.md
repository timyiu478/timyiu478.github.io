---
layout: post
title:  "Hard Disk Drive"
categories: ["os", "persistence"]
tags: ["os", "persistence"]
---

## What is Hard Disk Drive?

Hard disk drives are **persistent storage devices** for computers.

## Interface and Internal 

- Interface: read and write.
  - includes several **sectors** (512 -byte blocks) that each one can be read and write.
  - It’s like an **array** of n sectors, with an address space ranging from 0 to n−1.
  - Some types of interfaces: **SCSI, SATA, and SAS**.
- Internal:
  - A **controller**: this exports the interface and controls the operation of each request given to the device.
  - Mechanics: **Disk platters, Arm, Head**, etc.

## Basic Geometry

- A disk can have one or more **platters**.
- Platter is a hard **circular surface** where **data is permanently stored** by causing magnetic variations.
- The platters are connected around a **spindle** coupled to a motor that spins them at a constant speed measured in rotations per minute (RPM).
- Each surface has data encoded in **nested circles called tracks**.
- **Clusters(two or more sectors)** are subdivided portions of these tracks.
- The disk **head**, one per surface of the drive, **does the reading and writing** by sensing (i.e., read) or creating a change in (i.e., write) the magnetic patterns on the disk.
- One disk **arm** is attached to the disk head that **moves across the surface to put it over the track we want**.

## Read/Write operations

- **Seek** - positioning the read/write head over desired track
- **Rotation** (Rotational Delay) - Waiting for the target sector to rotate under the head
- **Transfer** - performing the read/write

## Performance Evaluation

- **Disk Access Time** = *Seek Time + Rotation Time + Transfer Time*
- **Disk Response Time** = *Queue Time + Disk Access Time*

## Types of workloads 

- **Random workloads** read small (4KB) blocks of data from the disk at random. Database management systems, in particular, use random workloads.
- **Sequential workloads** read several sectors from the disk in a linear fashion. Sequential access patterns are pretty common.

## I/O scheduling

The disk scheduling algorithm affects the efficiency of our service.

- **FIFO**
- **Shortest Seek Time First** prioritizes requests by their seek time.
- **Shortest Access Time First** prioritizes requests by how close they are to the head’s current location.
