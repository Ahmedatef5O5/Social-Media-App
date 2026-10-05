# Commit Message Suggestions

When suggesting a commit message, use one commit in this format:

```text
type: concise summary of the overall change

- Describe a meaningful related change
- Describe another relevant change, when needed
```

- Do not add a scope in parentheses, such as `feat(group_calls):`.
- Output exactly one commit message with one clear summary for the whole change; never suggest multiple separate commit subjects or alternatives.
- Keep the body as concise bullets that describe only the actual changes.
- Choose a fitting Conventional Commit type (`feat`, `fix`, `refactor`, `docs`, `chore`, or `test`); use `chore` for maintenance, configuration, and documentation changes.
- Do not invent changes or include unrelated work in the message.