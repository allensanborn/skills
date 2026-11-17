# 3. Start in a single region, Multi-AZ

Date: 2026-11-17

## Status

Proposed

## Context

CloudFront already serves most reads from the edge worldwide. Multi-region writes would need conflict
handling and would roughly double the cost of running the platform.

## Decision

Deploy to us-east-1 only, with every stateful tier spread across two Availability Zones.

## Consequences

A full regional outage takes down publishing and uncached reads; cached pages keep serving from the
edge. If that risk becomes unacceptable, the next step is an Aurora Global Database standby region.
