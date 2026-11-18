# 1. Run the apps on ECS with Fargate

Date: 2026-11-17

## Status

Proposed

## Context

We have three long-running Node.js workloads (web, API, worker) with steady traffic and spikes when a story goes viral. The team is small and does not want to operate Kubernetes. Lambda was considered for the API, but SSR cold starts, connection pooling to Aurora and long-running worker jobs make it a worse fit for the main path.

## Decision

Run web, API and worker as separate ECS services on Fargate, at least one task per AZ, auto-scaled on CPU, request count and SQS queue depth.

## Consequences

- No nodes or control plane to manage; per-task IAM roles.
- Higher per-vCPU cost than EC2; offset by Graviton and Fargate Spot for the worker.
- Moving to EKS later is possible because the services are plain containers.
