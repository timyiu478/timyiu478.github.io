---
layout: post
title:  ""
title:  "11 Takeaways from Observability Engineering Book"
categories: ["takeaways", "observability"]
tags: ["takeaways", "observability"]
---

## Abstract

This post is about my key takeaways from the [Observability Engineering Book](https://www.oreilly.com/library/view/observability-engineering/9781492076438/) by Charity Majors, Liz Fong-Jones, George Miranda.

## What is Observability

For a software application to have observability, you must be able to do the following:

- Understand the inner workings and system state **solely** by observing and interrogating with external tools
- Can continually answer **open-ended** questions about the inner workings of
your applications to explain any anomalies, without hitting investigative dead ends

It is about how people interact with and try to understand their complex systems

## The Role of Cardinality

- In the database context, the cardinality refers to the **uniqueness** of the data values contained in a set.
- Cardinality matters for observability, because **high**-cardinality information (e.g *userId*, *requestId*) is almost always the most useful in **identifying** data for debugging or understanding a system.
- Unfortunately, **metrics**-based tooling systems can deal with only **low**-cardinality dimensions at any reasonable scale[^1].

## The Role of Dimensionality

- The dimensionality refers to the **keys** within that data.
- In observable systems, the telemetry data is generated as an arbitrarily wide(can contain thousands of **key-value pairs**) structured event.
- Imagine that you have an event schema that defines six high-cardinality dimensions per event: **time, app, host, user, endpoint, and status**. With those six dimensions, you can create queries that analyze any **combination** of dimensions to surface relevant patterns that may be contributing to anomalies.

## The Limitations of Metrics as a Building Block

The numerical values generated by a metric reflect an **aggregated** report of system state over a **predefined** period of time that pre-aggregated measure now becomes the **lowest possible level of granularity** for examining system state. That aggregation obscures many possible problems.

## Unstructured Log vs Structured Log

- Unstructured Log is **human readable** but **difficult for machines to process**.
- A structured Log is the **opposite** of an unstructured log.

Unstructured logs example:

```
6:01:00 accepted connection on port 80 from 10.0.0.3:63349
6:01:03 basic authentication accepted for user foo
6:01:15 processing request for /super/slow/server
```

Structured log example:

```json
{
  "authority":"10.0.0.3:63349",
  "duration_ms":123,
  "level":"info",
  "msg":"Served HTTP request",
  "path":"/super/slow/server",
  "port":80,
  "service_name":"slowsvc",
  "status":200,
  "time":"2019-08-22T11:57:03-07:00",
  "trace.trace_id":"eafdf3123",
  "user":"foo"
}
```

## The Core Analysis Loop

1. Start with the overall view of what prompted your investigation: what did the
customer or alert tell you?
2. verify what you know so far is true: is a notable change in performance
happening somewhere in this system?
3. Search for **dimensions** that might drive that change in performance.
4. Do you now know enough about what might be occurring? If not, filter your view to isolate this area of performance as your next starting
point. Then return to step 3.

## Determining Where to Debug

- Observability operates on the order of **systems**, not on the order of **functions**. Emitting enough detail at the line level to reliably debug code would emit so much output that it would swamp most observability systems with an obscene amount of storage and scale.
- Observability is not for debugging your code logic. Observability is for **figuring out where in your systems to find the code you need to debug**. 

## The Functional Requirements for Observability

- Queries against your observability data must return results as quickly as possible. 
- An ability to analyze high-cardinality and high-dimensionality data.
- Queries return all data recorded within specific time intervals, so you must ensure that it is indexed appropriately.
- That data store must also be durable and reliable.

## When constant sampling is not effective 

- You care a lot about **error** cases and not very much about success cases.
- You want to ensure that a huge increase in traffic on your servers can’t overwhelm your analytics backend.

## Choosing Dynamic Sampling Options

- Are you dealing with a front-page app, and 90% of the requests hitting it are nearly indistinguishable from one another?
- A backend behind a read-through cache, where each request is mostly unique.
- Each of these situations benefits from a slightly different sampling strategy that optimizes for their needs.

## When to Make a Sampling Decision for Traces

- **head**-based sampling: the decision is made when the trace event is initiated. That decision is then propagated further downstream (e.g., by inserting a “require sampling” header bit) to ensure that every span necessary to complete the trace is sampled.
- **tail**-based sampling: a decision on values known only at the end of a request. To collect full traces in the tail-based approach, all spans must **first be collected in a buffer** and then, retrospectively, a sampling decision can be made

## References

[^1]: https://grafana.com/blog/2022/02/15/what-are-cardinality-spikes-and-why-do-they-matter/
