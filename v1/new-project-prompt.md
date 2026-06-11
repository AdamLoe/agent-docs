I want you to orchestrate doc overhaul for this project
You should rebuild from scratch all of our docs following the practices of my other apps.

You can find this apps docs here
docs/

You can find the generic claude docs and skills that apply to all projects here
~.claude/agent-docs

You can an example of a different project's docs here
../quoridor-ml-studio/docs/

Mainly, you should rebuild everything into the /docs/architecture and /docs/decisions/ like the other app, as well as other things while following all of the guidance and fitting in with the generic claude docs.

You should use subagents where optimal to reduce your context efficiently. You should use sonnet mostly but use opus for high thinking tasks.