# 2. Build home feeds with hybrid fan-out

Date: 2026-11-17

## Status

Proposed

## Context

Home feeds must load in under 100 ms. Pure fan-out-on-write breaks down for writers with millions of
followers; pure fan-out-on-read makes every feed load a large merge query.

## Decision

The worker pushes new stories into each follower's Redis feed for writers with fewer than 10k followers.
For larger accounts the API merges their recent stories into the feed at read time.

## Consequences

Feed reads are a Redis lookup plus a small merge. Redis holds derived data only and can be rebuilt from
Aurora. The 10k threshold is a tunable that needs monitoring.
