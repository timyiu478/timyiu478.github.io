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

## Machine Language

tbc
