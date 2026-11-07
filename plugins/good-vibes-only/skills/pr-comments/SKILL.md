---
name: pr-comments
description: Write and post GitHub comments, replies and discussion posts on the user's behalf. Short, in the user's voice, shown as a draft before anything goes to a person, and with an attribution note on replies to bots and reviewers. Use for every comment on an issue, PR, review thread or discussion, and when the user says "draft a reply", "comment on the issue", "answer the bot", or "leave a comment on the discussion".
---

# PR comments

## Who reads it decides the flow

- **People** (users, maintainers, contributors, discussions): draft first and
  show the user the exact text. Post it only after their OK, or when they said
  to post without asking. Once the user has approved the exact wording, post
  it as their own words, without an attribution note.
- **Bots and review findings** (CodeRabbit, Macroscope, Greptile, an agent's
  review), and explanations before resolving a thread: you may post these
  directly, with this note on top:

```md
> [!NOTE]
> 🤖 **<model> responding on behalf of <user>**

The reply starts here.
```

Use the model name the harness reports, or the harness name if it reports
none. Never guess.

## The voice

- **Be short.** Two or three sentences is the default. The user shortens drafts
  more often than they lengthen them.
- **Lead with the point:** the answer, the decision, the fix. Then the evidence
  (the code, a check, a reproduction), and keep verified facts apart from
  opinion.
- **Be friendly and specific** to people. Thank them when it's real (a first
  report, an approval), and apologise for a slow answer once. No canned thanks,
  filler or status narration.
- **Leave out internals** the reader doesn't need: commit SHAs, branch names,
  your process.
- **Give next steps they can follow** when you ask a reporter to try
  something: where to put it, and what to run.
- **Match the language of the thread.**

## Put it in the right place

Check where it belongs before posting:
- a PR comment or an inline review reply
- an issue comment
- a discussion comment
- an edit to the PR description, for results like review scores (never a
  comment)

When the user says "comment on the discussion about the PR", the comment goes
on the discussion.

## Posting

- Check the whole text, quotes and attachments included, for secrets and
  private details.
- Preview the Markdown so quotes and blank lines render as intended.
- Post it with the matching `gh` command: `gh pr comment`, `gh issue comment`,
  `gh api` for review replies, or `gh api graphql` for discussions.
- Confirm GitHub returned the URL.
- Resolve a review thread only after its reply is posted.
- Report the link.
