# Contributing to Minerva

:+1::tada: First off, thanks for taking the time to contribute! :tada::+1:

The following is a set of guidelines for contributing to Minerva, which is
hosted in the [minerva](https://github.com/hendrikx-itc/minerva) repository on
GitHub. These are mostly guidelines, not rules. Use your best judgment, and
feel free to propose changes to this document in a pull request.

## Table Of Contents

[Code of Conduct](#code-of-conduct)

[How Can I Contribute?](#how-can-i-contribute)
  * [Reporting Bugs](#reporting-bugs)
  * [Suggesting Enhancements](#suggesting-enhancements)

[Styleguides](#styleguides)
  * [Git Commit Messages](#git-commit-messages)

## Code of Conduct

This project and everyone participating in it is governed by the [Code of
Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this
code. Please report unacceptable behavior to
[info@hendrikx-itc.nl](mailto:info@hendrikx-itc.nl).

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report for Minerva. Following
these guidelines helps maintainers and the community understand your report
:pencil:, reproduce the behavior :computer: :computer:, and find related
reports :mag_right:.

#### How Do I Submit A (Good) Bug Report?

Explain the problem and include additional details to help maintainers
reproduce the problem:

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps which reproduce the problem** in as many details
  as possible. For example, start by explaining how you started Minerva, e.g.
  which command exactly you used in the terminal, or how you started Minerva
  otherwise. When listing steps, **don't just say what you did, but explain how
  you did it**.
* **Provide specific examples to demonstrate the steps**. Include links to
  files or GitHub projects, or copy/pasteable snippets, which you use in those
  examples. If you're providing snippets in the issue, use [Markdown code
  blocks](https://help.github.com/articles/markdown-basics/#multiple-lines).
* **Describe the behavior you observed after following the steps** and point
  out what exactly is the problem with that behavior.
* **Explain which behavior you expected to see instead and why.**

Provide more context by answering these questions:

* **Did the problem start happening recently** (e.g. after updating to a new
  version of Minerva) or was this always a problem?
* If the problem started happening recently, **can you reproduce the problem in
  an older version of Minerva?** What's the most recent version in which the
  problem doesn't happen?
* **Can you reliably reproduce the issue?** If not, provide details about how
  often the problem happens and under which conditions it normally happens.

Include details about your configuration and environment:

* **Which version of Minerva are you using?** You can get the exact version by
  running the query `SELECT * FROM system.version();` in a psql session.
* **What's the PostgreSQL version you're using**?
* **What's the name and version of the OS you're using**?

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion for
Minerva, including completely new features and minor improvements to existing
functionality. Following these guidelines helps maintainers and the community
understand your suggestion :pencil: and find related suggestions :mag_right:.

#### How Do I Submit A (Good) Enhancement Suggestion?

* **Use a clear and descriptive title** for the issue to identify the suggestion.
* **Provide a step-by-step description of the suggested enhancement** in as
    many details as possible.
* **Provide specific examples to demonstrate the steps**. Include
  copy/pasteable snippets which you use in those examples, as [Markdown code
  blocks](https://help.github.com/articles/markdown-basics/#multiple-lines).
* **Describe the current behavior** and **explain which behavior you expected
  to see instead** and why.
* **Explain why this enhancement would be useful** to most Minerva users.
* **List some other text editors or applications where this enhancement exists.**
* **Specify which version of Minerva you're using.** You can get the exact
  version by running the query `SELECT * FROM system.version();` in a psql
  session.
* **What's the PostgreSQL version you're using**
* **Specify the name and version of the OS you're using.**

### Pull Requests

The process described here has several goals:

- Maintain Minerva's quality
- Fix problems that are important to users
- Engage the community in working toward the best possible Minerva
- Enable a sustainable system for Minerva's maintainers to review contributions

Please follow these steps to have your contribution considered by the maintainers:

1. Follow all instructions in [the template](PULL_REQUEST_TEMPLATE.md)
2. Follow the [styleguides](#styleguides)

While the prerequisites above must be satisfied prior to having your pull
request reviewed, the reviewer(s) may ask you to complete additional design
work, tests, or other changes before your pull request can be ultimately
accepted.

## Styleguides

### Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Drop old partition after..." not "Drops old
  partition after...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line
* Consider starting the commit message with an applicable emoji:
    * :art: `:art:` when improving the format/structure of the code
    * :racehorse: `:racehorse:` when improving performance
    * :non-potable_water: `:non-potable_water:` when plugging memory leaks
    * :memo: `:memo:` when writing docs
    * :penguin: `:penguin:` when fixing something on Linux
    * :apple: `:apple:` when fixing something on macOS
    * :checkered_flag: `:checkered_flag:` when fixing something on Windows
    * :bug: `:bug:` when fixing a bug
    * :fire: `:fire:` when removing code or files
    * :green_heart: `:green_heart:` when fixing the CI build
    * :white_check_mark: `:white_check_mark:` when adding tests
    * :lock: `:lock:` when dealing with security
    * :arrow_up: `:arrow_up:` when upgrading dependencies
    * :arrow_down: `:arrow_down:` when downgrading dependencies
    * :shirt: `:shirt:` when removing linter warnings

