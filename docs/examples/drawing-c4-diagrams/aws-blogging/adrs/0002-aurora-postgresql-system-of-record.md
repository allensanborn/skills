# 2. Aurora PostgreSQL as the system of record

Date: 2026-11-17

## Status

Proposed

## Context

The core data (users, stories, follows, comments) is relational and needs transactions, for example writing a story and its outbox event together. DynamoDB would scale writes further but makes ad-hoc queries, stats and the comment tree harder, and our write volume is modest.

## Decision

Use Aurora PostgreSQL (writer plus two readers across AZs, RDS Proxy in front) as the only system of record. Redis and OpenSearch hold derived data that can be rebuilt from it.

## Consequences

- Strong consistency and SQL for features and analytics.
- The writer instance is the write ceiling; claps are buffered in Redis to keep hot writes off it.
- Aurora Global Database is the path to cross-region DR.
