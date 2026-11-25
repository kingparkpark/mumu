# Built deliverable verification

## Open every export

- Open each file the build exports and read its contents before you call the build done.

- Treat a successful pipeline run as proof that files were produced and never as proof that any file is correct.

- Treat a file you have not opened as unchecked and never describe it as verified.

- Compare each opened export against the data it should carry and record any mismatch where you found it.

## Exercise every claimed control

- Click each button the build claims to offer and watch what it does before you present the build.

- Drag a node, move a card, or run a queue when the build claims that interaction works.

- Check that status, counts, and progress derive from real state and never accept a value set by hand.

- Load each preset or saved workflow the build offers and confirm it fills the workspace as promised.

## Compare the brief and the reference

- Read the brief again after the build and check each requirement against the finished build.

- Compare the layout against any reference build the user named and name each place where yours differs.

- Check that a canvas the brief calls a node canvas lets you place and connect nodes instead of listing rows.

- Treat a missing core control as a failed build even when the rest of the build looks finished.

## Report only what you verified

- Present the build as usable only when every export opened and every claimed control worked.

- Label a build with a failed check as a failed preview and list each failure with where you found it.

- State what you opened and what you clicked in one short line when you deliver the build.

- Fix the failures and verify them again instead of softening them into minor differences.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Alternatives for better results

- Build a checklist from the brief before you start and check each item off only after you have opened or clicked it.

- Deliver one zone first and verify it end to end before building the rest when the build has several zones.

- Ask the user for one reference build when the brief names a style and compare your layout against it before delivery.
