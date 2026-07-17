Write a handoff for the next agent, following the "Sessions and handoffs"
convention in CLAUDE.md.

The folder is `docs/handoff/` (it exists; if it ever doesn't, create it). Naming:
`YYYY-MM-DD_NAME_handoff.md` with NAME in uppercase (the dev's short name). If
you do not know the user's name, ask before writing. Check the folder for
handoffs from the same user on the same date: if there is none, no letter; if
one or more exist, append the next letter in alphabetical order (`_B`, `_C`,
...) to keep them ordered.

Write the general context, what we have done (with commit hashes), the main
files touched, and the lessons learned. Pay attention to any problem that was
hard to solve (several tries and errors) and could teach something for similar
future situations, but only if such a problem actually existed; do not invent
one. Do not repeat what is already in CLAUDE.md: the next agent reads it too.
Be thorough: we need a long, good handoff. Structure it as a funnel, from
general to specific, closing with the full picture. If you received a previous
handoff, fold in whatever is still relevant so the next agent gets complete
context. Handoffs ACCUMULATE: never delete or overwrite older ones (that is why
they carry dates); yours becomes the new starting point and the old ones remain
as history.

Also record any operational state that git does not capture: services or jobs
left running, which database or environment is the source of truth right now,
and any long process in progress with the information needed to resume it.

After writing the file, close with LITERAL instructions the user can copy
(assume an inexperienced user):
1. Commit and push all verified work (if the machine has more than one GitHub
   account, check first that the active one is correct for this repo).
2. Tell the user, word for word: "Copy and paste this into this same chat and
   press Enter: `/rename DD-MM-YY <short title of what was done>`" (build the
   date and title yourself; only the human can rename).
3. Tell the user: "Then close this conversation, open a NEW one, and make your
   first message: read the handoff `docs/handoff/<file just created>` and
   let's continue."