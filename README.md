# Novel Phoenix Shosetsu Extension

This repository contains a Shosetsu Lua extension for
[Novel Phoenix](https://novelphoenix.com).

## Repository URL

Once this repository is public, add its raw `main` URL to Shosetsu:

`https://raw.githubusercontent.com/mcranford13/shosetsuextentions/main/`

Then refresh repositories and install **Novel Phoenix** from the English
extensions list.

The repository is currently private, so the raw URL cannot yet be consumed by
Shosetsu without first publishing the repository. For local testing, download
Shosetsu's extension tester as described in the official extensions repository,
run it with `--generate-index --watch --host`, and add the displayed local
server URL to Shosetsu.

## Development

The extension source is `src/en/NovelPhoenix.lua`. It supports paginated
listings and search, novel metadata, complete paginated chapter lists, and
HTML chapter reading.

Novel Phoenix currently uses Cloudflare. The extension enables Shosetsu's
Cloudflare handling, but users may occasionally need to open the source in
WebView and complete a challenge before retrying.
