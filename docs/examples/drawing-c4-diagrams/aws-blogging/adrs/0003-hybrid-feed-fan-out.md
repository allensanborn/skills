# 3. Hybrid fan-out for home feeds

Date: 2026-11-17

## Status

Proposed

## Context

Home feeds must load fast for readers who follow many writers. Computing the feed at read time is a heavy join per request; pushing every story to every follower at publish time is expensive for writers with millions of followers.

## Decision

Fan out on write: the worker pushes new story IDs into each follower's Redis sorted set (capped at 1,000). Writers above ~50K followers are skipped and their recent stories are merged into the feed at read time.

## Consequences

- Feed reads are one Redis call plus story hydration.
- Feeds are eventually consistent (seconds after publish).
- A lost Redis cluster means feeds are rebuilt from Aurora follows and stories, which is slow but safe.
