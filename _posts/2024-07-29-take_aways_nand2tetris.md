---
layout: post
title:  "Takeaways from Nand2Tetris course"
categories: ["takeaways", "nand2tetris"]
tags: ["takeaways", "nand2tetris"]
---

## Abstracts

I took the [Nand2Tetris](https://www.coursera.org/learn/build-a-computer) course in few months ago for consolidating my computing knowledge by its hands-on projects. This post is about my key takeaways from this course. If you are intereted in my solutions of the projects, you can check [this Github repository](https://github.com/timyiu478/nand2tetris).

## Random Access Memory

The reason why we can access an arbitrary memory element of a sequence in equal time is **the processing of chips or memory elements are paralleled**. The following HDL example code is one of the RAM implementation. From the code, we can see how we use the *address*, *multiplexer* and *de-multiplexer* to select which *register* and use the *load* to control whether the selected *register* saves the input *in*.


```
CHIP RAM8 {
    IN in[16], load, address[3];
    OUT out[16];

    PARTS:
    DMux8Way(in=load, sel=address, a=load0, b=load1, c=load2, d=load3, e=load4, f=load5, g=load6, h=load7);
    Register(in=in, load=load0, out=out0);
    Register(in=in, load=load1, out=out1);
    Register(in=in, load=load2, out=out2);
    Register(in=in, load=load3, out=out3);
    Register(in=in, load=load4, out=out4);
    Register(in=in, load=load5, out=out5);
    Register(in=in, load=load6, out=out6);
    Register(in=in, load=load7, out=out7);
    Mux8Way16(a=out0, b=out1, c=out2, d=out3, e=out4, f=out5, g=out6, h=out7, sel=address, out=out);
}
```

## Computer Architecture

- There are two main type of computer architecture for general use: [Von Neumann architecture](https://en.wikipedia.org/wiki/Von_Neumann_architecture) and [Harvard architecture](https://en.wikipedia.org/wiki/Harvard_architecture).
- Before I took this course, I had knew the components of a computer architecture such as *CPU* and *Memory*, the communication between them via *BUS* and the *fetch and execute cycle*. But I did not exactly know how the inputs of the *CPU* affect the bits(specifically the control bits) of the *CPU* internal components so that we can get the desired outputs and figure out which instruction to execute next when I looked the below CPU diagram.
- After I [built the HACK computer](https://github.com/timyiu478/nand2tetris/blob/main/projects/05/CPU.hdl) by writing *HDL*, I have a much clear understanding on the interactions of CPU components in *bit* level.

![cpu](/assets/img/nand2tetris/cpu.png)

## Assembler

- Assembler is a software to **translate** the **symbolic and human-readable** language called assembly to **binary** machine language. For example, `LOAD R3,7` rather than `110000101000000110000000000000111`.
- The symbols are introduced into assembly programs from two sources: **variables** and **labels**.
  - Variable: the programmer can use symbolic variable names, and the translator will assign them to memory addresses.
  - Label: the programmer can mark various **locations in the program** with symbols.
- To implement an assembler, we need to write a **parser** that get the revelent instructions from the file, a **translation table** to help us to translate characters to proper binaries and the symbols need to be inserted(retreived) to(from) the **symbol tables** for setting(getting) correct memory locations or instruction addresses. For example, the below code snippet shows how to set(get) the unique free memory address for the variable.

```python
if self.symbolTable.contains(p.symbol()) == False:
  self.symbolTable.addEntry(p.symbol(), self.freeMemoryAddress)
  self.freeMemoryAddress += 1
hackFileStr += decimalToBinary(self.symbolTable.getAddress(p.symbol()))
```

## Virtual Machine

- The high-level language is compiled to virtual machine code and then the virtual machine code is translated to assembly and then the assembly is transformed to binaries instead of the high-level language is directly compiled to assembly or binaries.
- Because it is too hard to write such compiler and it supports cross hardware platform or computer architecture.

### VM Abstraction

- The VM language consists of *arithmetic, memory access, program flow, and subroutine calling* operations.
- The *operands* and the *results* are put on the **stack** data structure.
- In a stack machine model, arithmetic commands `pop` their operands from the top of the stack and `push` their results back onto the top of the stack. Other commands transfer data items from the stack’s top to designated memory locations, and vice versa.
- A complete VM program is organized in program units called **function**. Each function has its own stand-alone code and is separately handled.
- Apart from *stack*, a VM program has other **memory regions** where they can have different lifecycles.

![vm_memory_segments](/assets/img/nand2tetris/vm_memory_segments.png)

### Function Call and Return

#### Abstraction

- In the VM language, we have `call` and `return` commands to write a program by calling different functions.
- The *caller* function puts the arguments for calling the *callee* function to the *stack* before calls the *callee* function and it expects the *callee* puts the result on top of its *stack*. The *callee* function expects its needed arguments are stored in its *argument* memory segment instead of the *stack* and it will puts the result to the correct *stack* location for the *caller*.
- Apart from the handling of the arguments and the return value, the VM run-time abstracts the handling of the *programming counter* so that we can switch to the *callee* commands and switch back the next command of the `call` command once the *callee* function is finished.

![function_call_and_return](/assets/img/nand2tetris/function_call_and_return.png)

#### Call Implementation

Note: Apart from pushing the arugments for the *callee*, we have to push the *caller*'s return address and its memory segments pointers for the `return` command to know how to restore the state of the *caller*. Also, we have to provide the *callee* own memory segments by repositioning the pointers. 

Example code snippet: [https://github.com/timyiu478/nand2tetris/blob/main/projects/08/vmTranslator/submit/code_writer.py#L304-L367](https://github.com/timyiu478/nand2tetris/blob/main/projects/08/vmTranslator/submit/code_writer.py#L304-L367)

![call_command_implementaion](/assets/img/nand2tetris/call_command_implementaion.png)

#### Function Implementation

Example code snippet: [https://github.com/timyiu478/nand2tetris/blob/main/projects/08/vmTranslator/submit/code_writer.py#L282-L302](https://github.com/timyiu478/nand2tetris/blob/main/projects/08/vmTranslator/submit/code_writer.py#L282-L302)

![function_implementation](/assets/img/nand2tetris/function_implementation.png)

#### Return Implementation

Note: We do not need to **clean up** the memory used by the *callee* **explicitly**. We only need to update the *stack pointer* to *ARG + 1* memory location since the *caller* and the *callee* agreed to store the return value in *ARG* location. The memory locations that are lower than or equal to the *stack pointer* are treated as **free** or can be **overrided**.

Example code snippet: [https://github.com/timyiu478/nand2tetris/blob/main/projects/08/vmTranslator/submit/code_writer.py#L369-L443](https://github.com/timyiu478/nand2tetris/blob/main/projects/08/vmTranslator/submit/code_writer.py#L369-L443)

![return_implementation](/assets/img/nand2tetris/return_implementation.png)

## Operating System

### Heap Management using first-fit free list

Note: The lenght of the link list will be longer and the size of the free block will be smaller over time. The OS can run the **defragmentation** periodically to mitigate this.

Example code snippet: [https://github.com/timyiu478/nand2tetris/blob/main/projects/12/Memory.jack](https://github.com/timyiu478/nand2tetris/blob/main/projects/12/Memory.jack)

![free_list](/assets/img/nand2tetris/free_list.png)
