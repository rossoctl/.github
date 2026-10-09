# Contributing to rossoctl

The rossoctl contribution process — how to claim an issue, how review works, the developer's
guide and the path to becoming a maintainer — is maintained in the main project repository:

**→ [rossoctl/rossoctl/CONTRIBUTING.md](https://github.com/rossoctl/rossoctl/blob/main/CONTRIBUTING.md)**

GitHub serves this file to any rossoctl repository that does not define its own, so the
process is written once and inherited everywhere rather than copied and left to drift.

## Project-wide documents

| Topic                       | Document                                                                                      |
| --------------------------- | --------------------------------------------------------------------------------------------- |
| Contribution process        | [CONTRIBUTING.md](https://github.com/rossoctl/rossoctl/blob/main/CONTRIBUTING.md)             |
| Governance & voting         | [GOVERNANCE.md](https://github.com/rossoctl/rossoctl/blob/main/GOVERNANCE.md)                 |
| Maintainers                 | [MAINTAINERS.md](https://github.com/rossoctl/rossoctl/blob/main/MAINTAINERS.md)               |
| Becoming a maintainer       | [CONTRIBUTOR_LADDER.md](https://github.com/rossoctl/rossoctl/blob/main/CONTRIBUTOR_LADDER.md) |
| How features are accepted   | [FEATURE_ACCEPTANCE.md](https://github.com/rossoctl/rossoctl/blob/main/FEATURE_ACCEPTANCE.md) |
| Personas and roles          | [PERSONAS_AND_ROLES.md](https://github.com/rossoctl/rossoctl/blob/main/PERSONAS_AND_ROLES.md) |
| Code of conduct             | [CODE_OF_CONDUCT.md](https://github.com/rossoctl/rossoctl/blob/main/CODE_OF_CONDUCT.md)       |
| Security policy             | [SECURITY.md](https://github.com/rossoctl/rossoctl/blob/main/SECURITY.md)                     |
| License (Apache-2.0)        | [LICENSE](https://github.com/rossoctl/rossoctl/blob/main/LICENSE)                             |

## What an individual repository adds

A rossoctl repository may carry its own `CONTRIBUTING.md` covering **only what is specific to
it** — prerequisites, build, test and lint commands — and link back here for the process. Note
that a local file **replaces** this one rather than merging with it, so a repo-specific
`CONTRIBUTING.md` should link the process documents above explicitly.

Two files are **not** inherited and must exist in every repository:

- **`LICENSE`** — GitHub does not inherit a license. A repository without one is
  all-rights-reserved regardless of the organization's intent.
- **`CODEOWNERS`** — review assignment is per-repository.

New repositories should start from
[**rossoctl/repo-template**](https://github.com/rossoctl/repo-template), which ships both of
those plus the project's documentation convention.
