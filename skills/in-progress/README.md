# In progress

Beta. Not shipped in the plugin (`.claude-plugin/plugin.json`), not listed in the root
README, and no docs page. `scripts/link-skills.sh` still links them locally, so you can use
them while you work on them.

To promote a skill: move it into a promoted bucket (`engineering/`, `productivity/`), add its
path to `plugin.json`'s `skills` array, list it in the root and bucket READMEs, write its
`docs/<bucket>/<name>.md` page, and add a changeset (`npx changeset`).

This bucket is currently empty.
