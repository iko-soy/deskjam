# fakezod test harness

Scripts that boot a local fake ship (`~zod`) and run deskjam on it. They install the desk that `nix build .#desk` builds, run dojo commands on the ship, drive deskjam's web interface with curl, and collect everything the ship prints in one log. `smoke-test.sh` uses them to upload, install and update a test app through deskjam's web interface, the way a browser would.

Fake networking only covers Ames, the network between ships. The ship can reach other fake ships on this machine, but no real ones. Its HTTP requests still go out to the internet. At boot, Landscape's `%docket` downloads the web frontends of `%webterm`, `%landscape` and `%groups`. A url upload to deskjam on this ship fetches the url you give it too.

CI runs `bootstrap.sh -n` and `smoke-test.sh` on pull requests (see `.github/workflows/ci.yml`).

## Requirements

- Linux. The scripts use `/proc`, `setsid`, `flock` and GNU coreutils.
- Nix with flakes enabled. The scripts get vere (`urbit`) from the nixpkgs that `flake.lock` pins, and build deskjam with `nix build`.
- bash, curl, jq, rsync, procps (`pgrep`, `ps`, `top`) and util-linux (`setsid`, `flock`, `rev`).
- About 1 GB of disk for the pill and the pier, plus 600 MB for the snapshot, in `tests/fakezod/.work/`.
- Free ports: 8483 for the web interface and 31483 for ames, both on 127.0.0.1 only. vere takes the next free port when one is taken, and the scripts read the ports it took from the pier.

## Running it

```sh
tests/fakezod/bootstrap.sh     # boot a new fakezod and install deskjam (about 4 minutes)
tests/fakezod/smoke-test.sh    # upload, install and replace a test app (a minute or two)
tests/fakezod/stop.sh          # stop the ship
```

The first `bootstrap.sh` also downloads the boot pill, `urbit-v4.6.pill` (220 MB), from bootstrap.urbit.org, and checks its sha256 against the one in `env.sh`. Later runs reuse it.

Then, while you work on deskjam:

```sh
tests/fakezod/reset.sh                     # back to the fresh ship bootstrap.sh saved (5 to 10 seconds)
tests/fakezod/sync-deskjam.sh              # build your working copy, |commit it, print what the ship logged
tests/fakezod/dojo.sh '+vats %deskjam'     # any dojo command
tests/fakezod/curl.sh /apps/deskjam -i     # the web interface, logged in
```

Nix only sees files git knows about. After adding a file to `desk/`, run `git add` or any `jj` command, such as `jj status`, before `sync-deskjam.sh`.

All the scripts are bash and work from any directory. Each starts with a comment that explains it and its options.

## What it makes

Everything goes in `tests/fakezod/.work/`, which git ignores:

| path | what |
|---|---|
| `urbit` | link to vere from nixpkgs (a GC root) |
| `dl/urbit-v4.6.pill` | the boot pill |
| `zod/` | the pier. Mounted desks appear in it, such as `zod/deskjam/`. |
| `zod.log` | everything the ship printed, plus `=== harness ... ===` lines from `start.sh`, `stop.sh` and `reset.sh` |
| `zod-fresh/` | the snapshot `reset.sh` restores: a fresh fakezod with `%harness` and `%deskjam` installed, and no `%hello` |
| `dist/` | the last `%deskjam` build that `sync-deskjam.sh` committed, as a writable copy |
| `harness-desk/` | the `%harness` desk as `bootstrap.sh` built it |
| `apps/` | the `%hello` test desks and their `.deskjam` files, from `make-hello.sh` |
| `cookies.txt` | the web login cookie, from `login.sh` |
| `tmp/` | scratch space. `tmp/smoke/` has the pages `smoke-test.sh` got. |

Every path and port can be changed with an environment variable: `WORK`, `URBIT`, `PIER`, `LOG`, `PILL`, `PILL_URL`, `PILL_SHA256`, `HTTP_PORT`, `AMES_PORT`, `DIST`, `APPS`, `COOKIES` and `SNAPSHOT`. See `env.sh`.

## Scripts

| script | what it does |
|---|---|
| `env.sh` | settings and helpers that the other scripts source |
| `bootstrap.sh [-f] [-n] [-F FLAKE]` | boot a new fakezod from the pill, install `%harness` and `%deskjam`, check that `GET /apps/deskjam` answers 200 after logging in, make the test desks, and save the snapshot (`-n`: don't). `-f` replaces an existing pier. `-F FLAKE` installs another deskjam, such as `github:iko-soy/deskjam`. |
| `start.sh [-c] [-w SECS]` | start the pier in the background and wait until it answers. `-c` boots a new one from the pill. |
| `stop.sh` | stop cleanly: SIGTERM to vere, which saves a snapshot and exits. It only signals processes that run `$URBIT`. |
| `snapshot.sh [-n] [DIR]` | stop, copy the pier to `zod-fresh/` (or DIR), start again |
| `reset.sh [-n] [DIR]` | stop, replace the pier with a copy of `zod-fresh/` (or DIR), start, log in |
| `interrupt.sh` | like ^C: abort the event the ship is computing, when it's stuck at 100% CPU |
| `dojo.sh [-l] CMD` | run one dojo command through `%lens` and print its result. `-l` also prints the log lines it caused. |
| `logmark.sh`, `logsince.sh MARK` | the end of the log as a byte offset; the log since an offset, optionally after waiting for quiet (`-q`) or for a line (`-u`) |
| `sync-desk.sh DESK DIR` | make the mounted desk a copy of DIR (deleting what DIR lacks), `\|commit` it, wait, print the log, and say whether it worked |
| `sync-deskjam.sh [-F FLAKE \| -d DIR]` | `nix build .#desk` (or FLAKE's, or the desk in DIR), copy it to `dist/`, and `sync-desk.sh deskjam dist` |
| `build-file.sh DESK PATH` | compile one file as it is in clay, with `-build-file`, and print the error if it fails |
| `login.sh` | get `+code`, `POST /~/login`, keep the cookie |
| `curl.sh PATH [ARGS]` | curl the web interface with the cookie (`-sS`, and no `-L` unless you pass it) |
| `make-hello.sh [-F FLAKE]` | write the `%hello` test desks to `apps/` and pack them |
| `pack.sh DIR DESK OUT` | pack a directory of desk files into a `.deskjam` file, as jammer does, with `urbit eval` |
| `smoke-test.sh` | the end-to-end test below |

## The smoke test

`smoke-test.sh` needs a fresh ship, since it installs `%hello`. It sends what a browser would: an `Origin` header with each form, and the hidden fields of the confirm page. It checks that:

1. a form that a page on another site sends gets 403, whether `Sec-Fetch-Site` or `Origin` says so, and stages nothing;
2. `hello-v1.deskjam`, installed as the new desk `%hello` with "start its agents after uploading" ticked, makes a desk with exactly its files, and its agent starts (`hello v1 init` in the log) and answers on `/apps/hello`. The status page says the commit landed and the agent runs.
3. `hello-v2.deskjam`, replacing `%hello`, deletes the two files v2 dropped, and the running agent reloads and migrates its state (`hello v2 load: migrated state-0 -> state-1`);
4. deskjam's older form fields (`new-desk=` on the staged and confirm pages) still install a desk, `%hello-copy`, which starts suspended.

It prints each request with its status, and the log lines each commit caused. On failure it prints the page it got, and exits 1.

## The test desks

`make-hello.sh` writes three versions of a small app, `%hello`, and packs each into a `.deskjam` file with `pack.sh`. Their marks, libraries and `/sys/kelvin` come from deskjam's own build, so they match the revisions `flake.nix` pins.

| desk | contents |
|---|---|
| `hello-v1` (19 files) | agent `%hello` with state `[%0 count=@ud]`; slogs `hello v1 init` when it starts; imports `/lib/hello-old.hoon`; has `/fil/notes.txt`; docket version 0.0.1 |
| `hello-v2` (18 files) | drops `hello-old` and `notes.txt`, imports `/lib/hello-new.hoon` instead; state `[%1 count=@ud note=@t]`, migrated from state 0 in `on-load`, which slogs `hello v2 load: migrated state-0 -> state-1 ...`; docket version 0.0.2 |
| `hello-broken` (18 files) | v2 with a type error in `/lib/hello-new.hoon`, so its agent can't build: clay rejects any commit of it to a running desk |

Every version binds `/apps/hello` and answers a GET with a line of status, such as `hello v1 state-0 count=1 greeting=hello from hello-old`.

## The log

vere runs with `-d` (daemon mode, which implies `-t`, no terminal). In that mode it drops almost everything dill prints: dojo output, gall's messages, and the traces of failed events, such as a commit clay rejected. So `bootstrap.sh` installs the desk `%harness`, whose agent `%logtap` (in `harness-desk/`) listens to dill's output and slogs it, prefixed `logtap: `. Slogs go straight to the log. Keep `%harness` installed. It also shows up in deskjam's desk list.

In the log you'll see:

- clay's changes: `logtap: + /~zod/hello/2/app/hello/hoon` (added), `:` (changed) and `-` (deleted)
- agents: `gall: installing %x`, `gall: reloading %x`, `logtap: gall: booted %x`, and so on
- slogs and `~&` from your code
- failed events: `logtap: crud: %<task> event failed`, then the trace and the error

To see what one command logged:

```sh
m=$(tests/fakezod/logmark.sh)
tests/fakezod/dojo.sh '|install our %hello'
tests/fakezod/logsince.sh -q 5 "$m"                       # after 5 quiet seconds (-m: at most 120)
tests/fakezod/logsince.sh -u 'hello v1 init' -m 60 "$m"   # once a line appears (exit 3 if it doesn't)
```

## Quirks

- `%lens`, which runs dojo commands for `dojo.sh`, gets stuck when dojo can't parse a command, or when a command pokes an agent that isn't running: it never answers, and answers every later request with 500. `dojo.sh` notices, cancels the stuck job and retries once.
- Generators that ask for confirmation, such as `|new-desk` and `|nuke`, return nothing, and dojo logs `[%dojo-lame %poke-ack]`, which is harmless. Their y/N prompts can't be answered, so pass `=hard &`: `|nuke %x, =hard &`.
- Don't print big nouns untyped, such as `.^(* %gx /=deskjam=/dbug/state/noun)`: dojo's printer can spin on them for minutes. `interrupt.sh` stops it. `:deskjam +dbug` prints the state into the log instead.
- On a desk that's running, clay builds its agents in the commit. If one fails, clay rejects the whole commit: the revision stays the same and the old agent keeps running, but the mount keeps your new files. `sync-desk.sh` says so (`FAILED: log shows errors`) and shows where in your code.
- When `bootstrap.sh` syncs `%deskjam` into its new desk, `mar/hoon.hoon` and `sys.kelvin` show as changed: `|new-desk` copies them from the ship's `%base`, and deskjam's pinned `base-dev` has others.
