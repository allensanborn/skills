# 1. Run the web app, API and worker on ECS Fargate

Date: 2026-11-17

## Status

Proposed

## Context

We have three long-running services with different scaling signals (CPU, request count, queue depth).
The team is small and has no Kubernetes operators. Next.js server rendering and long-lived DB
connection pools fit poorly into Lambda's execution model.

## Decision

Run each container as its own ECS service on Fargate behind one ALB, autoscaled independently.

## Consequences

No nodes to patch, and per-service scaling. We pay a small premium over EC2 and give up the
Kubernetes ecosystem. Revisit if task count makes EC2 capacity providers clearly cheaper.
