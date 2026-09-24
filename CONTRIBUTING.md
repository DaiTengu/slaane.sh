# Contributing

Bug reports, ideas and pull requests are all welcome. This file explains how
issues are written and labeled, so that humans and AI agents can both use the
tracker.

## Writing an issue

Every issue has two parts: the opening post for humans, and an optional
comment for AI agents.

### 1. The opening post (for everyone)

- **Start with a TL;DR.** The first line is `**TL;DR:**` followed by one or two
  plain sentences that sum up the issue. Someone who reads only that line
  should know what's wrong.
- **Anyone should be able to understand it.** Assume the reader is not a bash
  expert or a systems engineer. Say what goes wrong in plain words before you
  use a technical term. If a term is needed, explain it in the same sentence.
- **Keep it short.** Say what happens, what should happen instead, and why it
  matters. Longer technical detail goes in the AI comment, not here.
- **Chaos flavor is welcome.** A little sarcasm and some Warhammer 40K
  (Chaos) flavor is fine. It must never hide, soften, exaggerate or change what
  the issue actually is. When in doubt, cut the joke.
- **Check it against the details.** Before posting, make sure every claim in
  the opening post agrees with the technical detail in the AI comment. Simple
  wording must never turn into wrong wording.
- **Keep your own machine out of it.** Describe the problem generally ("a
  customized `~/.bashrc` gets overwritten"). Don't post hostnames, local
  paths, account names or other details about your own system.

### 2. The "Machine Spirit Cogitation" comment (AI agents only)

Deeper detail for AI agents (Claude, Codex, Qwen and others) goes in a
**comment** on the issue, not in the opening post. It must start exactly like
this:

```markdown
## Machine Spirit Cogitation

> 🤖 **AI agents only.** Humans can skip this.

<!-- audience: ai-agents-only -->
```

Rules for these comments:

- The heading "Machine Spirit Cogitation" is the only flavor text allowed.
  Everything after it is plain, precise, technical writing.
- Include what an agent needs to act without re-deriving it: file paths and
  line numbers (with the commit they refer to), the exact mechanism, how the
  problem was verified, proposed fix options, and what is still unknown.
- Say which claims were verified by running something and which come from
  reading the code.
- The same privacy rule applies: no details about a specific user's machine.
- Add the `ai:cogitation` label to the issue.

Agents can find these comments by searching for `audience: ai-agents-only`.

### Issues written only for AI agents

If a whole issue is meant only for AI agents, start its title with `[AI]` and
add the `ai:only` label. Its opening post can skip the plain-language and
flavor rules.

### Overlap with TODO.md

`TODO.md` still holds planned features that have not been moved to the
tracker. If an issue covers something already listed there, say so in the
issue, so the `TODO.md` entry can be removed when the issue is closed.

## Labels

Labels are grouped by prefix. Most issues get one `type:` label, one or more
`area:` labels, and a `severity:` label if they are bugs.

| Prefix | Labels | Meaning |
|---|---|---|
| `type:` | `bug`, `feature`, `cleanup`, `docs`, `tests` | What kind of work it is |
| `severity:` | `data-loss`, `broken`, `annoying` | How bad a bug is. `data-loss` means it can delete or overwrite user files |
| `area:` | `installer`, `bashrc`, `modules`, `uninstall`, `tests`, `docs` | Which part of the project |
| `distro:` | `debian`, `rhel`, `arch`, `gentoo` | Only affects some Linux distributions |
| `status:` | `needs-decision`, `ready`, `blocked` | Where it stands |
| `ai:` | `only`, `cogitation` | AI-agent content, see above |

GitHub's defaults `duplicate`, `invalid`, `wontfix`, `question`,
`good first issue` and `help wanted` are still available.
