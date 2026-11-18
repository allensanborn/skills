# Security policy

## Reporting a vulnerability

Report it privately through [GitHub's private vulnerability reporting](https://github.com/allensanborn/skills/security/advisories/new), not in a public issue. You'll get a reply within a week.

## What counts

These are agent skills: instructions a model follows, plus a few scripts. A security problem here is usually one of:

- a skill telling the agent to run something unsafe, or to send data somewhere it shouldn't;
- a way for untrusted input (a pasted image, a file in the user's repo) to steer a skill into doing either of those;
- a secret, credential, or personal data committed to the repo.

A diagram that comes out wrong is a bug, not a vulnerability: use the [bug form](https://github.com/allensanborn/skills/issues/new?template=bug.yml).

## Supported versions

Only the latest release of the `allensanborn-skills` plugin, and `main`.

## What's in place

Secret scanning with push protection, Dependabot, CodeQL, and the checks in `.github/workflows/ci.yml` (including gitleaks and zizmor) run on every pull request. [OpenSSF Scorecard](https://scorecard.dev/viewer/?uri=github.com/allensanborn/skills) publishes a weekly score.
