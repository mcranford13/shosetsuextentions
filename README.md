# Novel Phoenix Shosetsu Extension

This repository contains a Shosetsu Lua extension for
[Novel Phoenix](https://novelphoenix.com).

## Repository URL

After this branch is published, add the raw GitHub branch URL to Shosetsu:

`https://raw.githubusercontent.com/mcranford13/shosetsuextentions/cursor/novelphoenix-extension-becf/`

Then refresh repositories and install **Novel Phoenix** from the English
extensions list.

## Development

The extension source is `src/en/NovelPhoenix.lua`. It supports paginated
listings and search, novel metadata, complete paginated chapter lists, and
HTML chapter reading.

Novel Phoenix currently uses Cloudflare. The extension enables Shosetsu's
Cloudflare handling, but users may occasionally need to open the source in
WebView and complete a challenge before retrying.
