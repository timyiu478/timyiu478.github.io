---
layout: post
title:  "Multilevel Feedback Queue Scheduling"
categories: "OS"
tags: "OS"
---

## Example Run

```
Enter the number of processes: 3
Enter duration for process 1: 10
Process 1 enqueued in queue with time quantum 2
Enter duration for process 2: 20
Process 2 enqueued in queue with time quantum 2
Enter duration for process 3: 30
Process 3 enqueued in queue with time quantum 2
Process 1 dequeued from queue with time quantum 2
Process 1 is running in high priority queue
Process 1 enqueued in queue with time quantum 4
Process 2 dequeued from queue with time quantum 2
Process 2 is running in high priority queue
Process 2 enqueued in queue with time quantum 4
Process 3 dequeued from queue with time quantum 2
Process 3 is running in high priority queue
Process 3 enqueued in queue with time quantum 4
Process 1 dequeued from queue with time quantum 4
Process 1 is running in medium priority queue
Process 1 enqueued in queue with time quantum 8
Process 2 dequeued from queue with time quantum 4
Process 2 is running in medium priority queue
Process 2 enqueued in queue with time quantum 8
Process 3 dequeued from queue with time quantum 4
Process 3 is running in medium priority queue
Process 3 enqueued in queue with time quantum 8
Process 1 dequeued from queue with time quantum 8
Process 1 is running in low priority queue
Process 1 finished execution
Process 2 dequeued from queue with time quantum 8
Process 2 is running in low priority queue
Process 2 enqueued in queue with time quantum 8
Process 3 dequeued from queue with time quantum 8
Process 3 is running in low priority queue
Process 3 enqueued in queue with time quantum 8
Process 2 dequeued from queue with time quantum 8
Process 2 is running in low priority queue
Process 2 finished execution
Process 3 dequeued from queue with time quantum 8
Process 3 is running in low priority queue
Process 3 enqueued in queue with time quantum 8
Process 3 dequeued from queue with time quantum 8
Process 3 is running in low priority queue
Process 3 finished execution

Process Duration        Waiting Time    Turnaround Time
1       10      12      22
2       20      24      44
3       30      30      60
```

## Example C Code 

```c
#include<stdio.h>
#include<stdlib.h>

typedef struct {
  int id;
  int duration;
  int remaining_time;
  int waiting_time;
  int turnaround_time;
} Process;

typedef struct {
  Process* processes;
  int front;
  int rear;
  int time_quantum;
} Queue;

void init_queues(Queue* high_q, Queue* mid_q, Queue* low_q){
  high_q->processes = malloc(10*sizeof(Process));
  mid_q->processes = malloc(10*sizeof(Process));
  low_q->processes = malloc(10*sizeof(Process));

  high_q->time_quantum = 2;
  mid_q->time_quantum = 4;
  low_q->time_quantum = 8;

  high_q->front = -1;
  mid_q->front = -1;
  low_q->front = -1;

  high_q->rear = -1;
  mid_q->rear = -1;
  low_q->rear = -1;
}

void enqueue(Queue* q, Process* p){
  printf("Process %d enqueued in queue with time quantum %d\n", p->id, q->time_quantum);
  if(q->front > 9) { return; }
  q->front += 1;
  q->processes[q->front].id = p->id;
  q->processes[q->front].duration = p->duration;
  q->processes[q->front].remaining_time = p->remaining_time;
  q->processes[q->front].waiting_time = p->waiting_time;
  q->processes[q->front].turnaround_time = p->turnaround_time;
}

Process* dequeue(Queue* q){
  if(q->rear >= q->front) { 
    q->rear = -1;
    q->front = -1;
    return NULL;
  }
  q->rear += 1;
  printf("Process %d dequeued from queue with time quantum %d\n", q->processes[q->rear].id, q->time_quantum);
  return &q->processes[q->rear];
}

void mlfq(Process* processes, int n, Queue* high_q, Queue* mid_q, Queue* low_q) {
  Process* current_p;
  int total_turnaround_time = 0;

  if (n<= 0) { return; }

  while(1){
    current_p = dequeue(high_q);
    if(current_p != NULL){
      printf("Process %d is running in high priority queue\n", current_p->id);
      if (current_p->duration > high_q->time_quantum) {
        current_p->duration -= high_q->time_quantum;
        enqueue(mid_q, current_p);
        total_turnaround_time += high_q->time_quantum;
      } else {
        total_turnaround_time += current_p->duration;
        processes[current_p->id-1].turnaround_time = total_turnaround_time;
        processes[current_p->id-1].waiting_time = total_turnaround_time - processes[current_p->id-1].duration;
      }
      continue;
    }
    current_p = dequeue(mid_q);
    if(current_p != NULL){
      printf("Process %d is running in medium priority queue\n", current_p->id);
      if (current_p->duration > mid_q->time_quantum) {
        current_p->duration -= mid_q->time_quantum;
        enqueue(low_q, current_p);
        total_turnaround_time += mid_q->time_quantum;
      } 
      else {
        total_turnaround_time += current_p->duration;
        processes[current_p->id-1].turnaround_time = total_turnaround_time;
        processes[current_p->id-1].waiting_time = total_turnaround_time - processes[current_p->id-1].duration;
        printf("Process %d finished execution\n", current_p->id);
      }
      continue;
    }
    current_p = dequeue(low_q);  
    if(current_p != NULL){
      printf("Process %d is running in low priority queue\n", current_p->id);
      if (current_p->duration > low_q->time_quantum) {
        current_p->duration -= low_q->time_quantum;
        enqueue(low_q, current_p);
        total_turnaround_time += low_q->time_quantum;
      } 
      else {
        total_turnaround_time += current_p->duration;
        processes[current_p->id-1].turnaround_time = total_turnaround_time;
        processes[current_p->id-1].waiting_time = total_turnaround_time - processes[current_p->id-1].duration;
        printf("Process %d finished execution\n", current_p->id);
      }
      continue;
    }
    printf("\n");
    break;  
  }
}

int main(){
  int n;
  float total_waiting_time=0, total_turnaround_time=0;
  Queue* high_q = malloc(sizeof(Queue));
  Queue* mid_q = malloc(sizeof(Queue));
  Queue* low_q = malloc(sizeof(Queue));
  
  printf("Enter the number of processes: ");
  scanf("%d", &n);
  Process* processes = malloc(n*sizeof(Process));
  
  init_queues(high_q, mid_q, low_q);

  for(int i=0;i<n;i++){
    processes[i].id = i+1;
    printf("Enter duration for process %d: ", i+1);
    scanf("%d", &processes[i].duration);
    enqueue(high_q, &processes[i]);
  }

  mlfq(processes, n, high_q, mid_q, low_q);

  printf("Process\tDuration\tWaiting Time\tTurnaround Time\n");
  for(int i=0; i<n; i++){
    printf("%d\t%d\t%d\t%d\n", processes[i].id, processes[i].duration, processes[i].waiting_time, processes[i].turnaround_time);
    total_turnaround_time += processes[i].turnaround_time;
    total_waiting_time += processes[i].waiting_time;
  }

  free(processes);
  return 0;
}
```
