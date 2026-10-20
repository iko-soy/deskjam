# deskjam

## How this fork differs

This is a fork of [tinnus-napbus/deskjam](https://github.com/tinnus-napbus/deskjam). It adds support for installing and updating apps by uploading `.deskjam` files.

Everything upstream deskjam does still works the same way, and stays the default:

- Merging an upload into an existing desk still writes its files and keeps the desk's other files.
- New desks still start suspended.
- Downloads, subsets and url uploads work as before.
- The old form fields and the old `%new-desk` and `%add-files` pokes still work.

What's new is opt-in:

- **Replace**: update a desk so it becomes exactly the upload. Files the upload lacks are deleted, so files a new version of an app removed or renamed don't linger.
- **Start after upload**: optionally `|revive` the desk in the same commit.
- **Stop kiln syncing**: optionally `|pause` a desk that kiln overwrites from a publisher, so the next update doesn't undo yours.
- **A fuller confirm page**: before committing, it lists the files that will be deleted, added, changed and left alone, and checks the upload against what Clay will do. It refuses only commits Clay would reject or ignore anyway, plus replacing `%base` or `%kids` and replaces that would stop a desk's agents. Everything else, including desks that are synced from elsewhere, gets a warning.
- **A status page**: after each commit, it says whether the upload landed and whether the desk is running.
- **Url uploads**: they follow redirects and send escapes like `%20` as written, so GitHub release links work. When a fetch fails, they say why.

It also fixes two security problems in upstream deskjam. These fixes are always on:

- **Forms from other websites are refused.** Upstream accepts a form submission from any web page you visit while logged in to your ship. A malicious page could have your browser upload a desk, or have your ship fetch one from the attacker's server, and commit it, even into a running desk. deskjam now answers 403 when the browser says a submission came from a page on another origin. Browsers say so in `Sec-Fetch-Site` to https and localhost addresses. Over plain http, and in browsers from before 2023, they send only `Origin`, which then has to match the address you reached your ship at. Requests with neither header, such as from `curl` or scripts, work as before.
- **No event stream for other ships.** Upstream wraps the agent in the `verb` library, which lets any ship subscribe to a stream of deskjam's events. The stream shows when you use deskjam and the names of the desks you upload to. This fork drops `verb`, so `:deskjam +verb` no longer works either, and ends existing subscriptions when it loads.

If you reach your ship over plain http through a reverse proxy that changes the `Host` header, the proxy has to tell your ship the address the browser used. Otherwise deskjam refuses its own forms, with a message that says so. Passing on the browser's `Host` works (in nginx, `proxy_set_header Host $http_host;`), and so does an `X-Forwarded-Host` header, which Apache adds by default, or `Forwarded: host="..."`.

The tile icon is part of the docket, url-encoded, where upstream's comes from a web server. deskjam only reaches outside your ship when you upload from a url.

See [Installing and updating apps](#installing-and-updating-apps) for details, and [Replacing upstream deskjam](#replacing-upstream-deskjam) to switch to this fork.

## Building

You can build the full `%deskjam` desk with the [`mortar` build tool available here](https://github.com/tinnus-napbus/mortar). It writes the desk to `dist`.

Or, with Nix with flakes enabled, run `nix build`, which writes the same desk to `result`. `flake.nix` pins the same dependencies as `mortar.yaml`, so change them together. Nix only sees files git knows about, so after adding a file to `desk`, run `git add` (or any `jj` command, such as `jj status`) before `nix build`.

The app's tile icon, [`assets/deskjam.svg`](assets/deskjam.svg), is a copy of upstream's. `desk/desk.docket-0` carries it url-encoded, as a `data:` URL, so Landscape shows it without loading anything, including in previews on other ships before they install deskjam. After changing the icon, put its new URL in the docket's `image`, from `python3 -c 'import urllib.parse as u; print("data:image/svg+xml," + u.quote(open("assets/deskjam.svg").read(), safe=""))'`. `nix build` checks that the two match.

## Installation
1. Clone this repo: `git clone https://github.com/iko-soy/deskjam`.
2. Boot up a ship (fakezod or moon or whatever you use).
3. `|new-desk %deskjam` to create a new desk called `%deskjam`.
4. `|mount %deskjam` to access the `%deskjam` desk from the unix command line.
5. At the unix command line `rm -rf [ship-name]/deskjam/*` to empty out the contents of the desk.
6. In the repo, run `mortar build`, or `nix build`.
7. Copy the contents of `dist` to `[ship-name]/deskjam`. After `nix build`, copy `result` instead, and make the copies writable, since files Nix builds are read-only. From the repo: `cp -R result/. /path/to/[ship-name]/deskjam/ && chmod -R u+w /path/to/[ship-name]/deskjam`.
8. At the dojo command line `|commit %deskjam`.
9. Install with `|install our %deskjam`.

### Replacing upstream deskjam

If your ship already runs upstream deskjam, you can install this fork through it, without access to the ship's files:

1. Get this fork as a deskjam: on a ship that runs it, such as a fakezod installed as above, download the `%deskjam` desk from `[your-domain-name]/apps/deskjam`.
2. On your ship, run `+vats %deskjam` in the dojo. If its source ship isn't `~`, kiln keeps it in sync with the ship you installed it from, and that ship's next release would replace the fork. Run `|pause %deskjam` first.
3. Upload the deskjam on `[your-domain-name]/apps/deskjam`, add its files to the existing desk `%deskjam`, and confirm.

This drops any upload you had staged but not yet committed. To install a later version of this fork, upload it the same way and choose **Replace**.

## Usage
1. To download a desk as a jam file go to `[your-domain-name]/apps/deskjam/download`.
2. To download a subset of the files in this desk as a jam file click the desk name on this page.
3. To install or update an app, or upload a jammed desk, go to `[your-domain-name]/apps/deskjam` and follow the instructions there. See [Installing and updating apps](#installing-and-updating-apps).

## Installing and updating apps

Upload a deskjam on `[your-domain-name]/apps/deskjam`, from a file or a url. The next page describes the upload (its app, kernel version and agents) and asks where it should go:

- **Install it as a new desk.** New desks start suspended, as with `|new-desk`. On the confirm page you can tick "start its agents after uploading", which does what `|revive` does.
- **Update an existing desk**, in one of two ways:
  - **Merge**, the default, writes the upload's files and leaves the desk's other files in place.
  - **Replace** makes the desk exactly the upload: files the upload lacks are deleted. Use this to update an app, so files a new version removed or renamed don't linger.

Every upload is a single Clay commit. When the desk is running, Clay rebuilds its agents as part of that commit and reloads those whose code changed. If a file or agent fails to build, or a running agent fails to load its state, Clay rejects the whole commit. The desk stays as it was, the browser shows an error, and your ship's dojo shows why. (An agent that is new to the desk and crashes as it starts doesn't stop the commit.)

Before you confirm, deskjam lists the files it will delete, add and change, the files that stay the same, and for a merge the files it leaves in place. Files it can't compare, because it doesn't know how their mark stores them, are listed as files that may change. Files that stay the same are left out of the commit. It also checks the upload. It only refuses what Clay would reject or ignore anyway, such as a desk without `/sys/kelvin`, a kelvin no kernel can use, or a file with no mark to convert it. It also refuses two things only the new replace option could do: replacing `%base` or `%kids`, or dropping a desk's `/desk/bill` and so stopping all its agents. Everything else is a warning:

- When the upload's agents already run from another running desk. Committing it to a running desk moves them over, and every later kernel update then fails with `cannot run app from two desks`. deskjam won't offer to start a desk in that state.
- When the upload is built for a different kernel than your ship runs. If it only supports newer kernels, Clay holds it until your ship upgrades, and nothing changes now. For `%base`, deskjam applies Clay's rules for kernel updates and says whether the commit would change your ship's kernel right away or wait.
- When the desk is overwritten from outside: kiln keeps it in sync with another desk, as with an app installed with `|install ~publisher %desk`, or copies another desk's updates into it, as with `%kids` and `%base`. The source's next update would undo yours. Tick "stop kiln syncing" to do what `|pause` does. The desk list on the staged page marks synced desks, and the status page warns again after a commit if the sync is still on.
- When the upload changes nothing, when merging would leave files behind, when the upload is a copy of a differently named desk, and when merging into `%base`.

The confirm page only commits what it showed you. If the upload or its destination changed in another tab, it asks you to check again.

After the commit deskjam shows the desk's status. That covers its revision, whether it is running, its agents, the kernel it is for, whether kiln syncs it, and whether the upload made a new revision. If the upload matched what the desk already had, or Clay is holding it for a newer kernel, there is no new revision. If the desk should have started but didn't, the status page says so.

Url uploads follow redirects and send escapes like `%20` as written (the runtime on its own would decode them), so links to GitHub release assets work. If a fetch fails, the staged page says why.
