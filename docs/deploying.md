# Deploying an app with deskjam, deskjam included

The simplest way to put an app on your ship is to pack its desk into one file, a deskjam, and upload that file with deskjam. You update the app the same way. deskjam can deploy itself like this too: once it's on your ship, every later version of deskjam is just another upload.

Installing and updating need only your ship's web interface, not its files. A few steps below use the dojo, your ship's command line, which is also where Clay says why a commit failed. That's the terminal your ship runs in, or, in a browser, Landscape's Terminal app.

## What you need

- A clone of this repo, Nix with flakes, and Linux, to pack desks. `tests/fakezod/pack.sh` uses bash 4 and GNU coreutils. On a Mac, run it with Nix's: `nix shell nixpkgs#bash nixpkgs#coreutils -c bash tests/fakezod/pack.sh ...` (only tested on Linux).
- The app's desk: a folder with every file the desk needs, as you would `|commit` it. A desk only sees its own files, so that means:
  - `sys.kelvin`, listing your ship's kernel, such as `[%zuse 408]`;
  - `desk.bill`, listing the agents to start, such as `:~  %my-app  ==`;
  - `desk.docket-0`, if the app should have a tile in Landscape;
  - the app's agent, such as `app/my-app.hoon`, and every `lib`, `sur`, `mar` and `ted` file it uses, with the files those import in turn, such as `lib/skeleton.hoon` for `lib/default-agent.hoon`;
  - the usual marks, which Clay builds whenever it commits to or starts a desk with agents: `mar/bill.hoon`, `mar/hoon.hoon`, `mar/kelvin.hoon`, `mar/mime.hoon`, `mar/noun.hoon` and `mar/txt.hoon`, and for a docket, `mar/docket-0.hoon` with the `lib/docket.hoon` and `sur/docket.hoon` it imports. deskjam's own build has them all: after `nix build` in this repo, copy them from `result`. If the desk lacks one that Clay needs, deskjam's confirm page says which, and what needs it.

  If the app's repo builds the desk with `mortar build` or `nix build`, that build is this folder. File names must be lowercase, as Clay's are, and end in their mark, such as `app/my-app.hoon` or `desk.bill`.

For deskjam itself, `nix build` in this repo makes the folder, as `result`.

## 1. Pack the desk

In your clone of this repo, run:

```sh
tests/fakezod/pack.sh path/to/the/desk my-app my-app.deskjam
```

`my-app` is the desk's name. The script needs no ship. The first time, it gets `urbit` from Nix, which takes a minute. It prints how many files it packed: it leaves out hidden files and symbolic links, so if the folder links files in, pack a copy made with `cp -RL path/to/the/desk /tmp/my-app` instead.

For deskjam itself:

```sh
nix build
tests/fakezod/pack.sh result deskjam deskjam.deskjam
```

If the app is already published as a deskjam, for example as a GitHub release asset, skip this step and use that file, or its link.

## 2. Install it

1. Open `https://your-ship/apps/deskjam`.
2. Choose `my-app.deskjam` under **upload deskjam** and click **upload**. For a file on the web, paste its link in the box below instead, and click **fetch**.
3. The next page describes the app. Under **Install it as a new desk**, keep or change the name, and click **next**.
4. Read the confirm page. If deskjam can't do it, it says why, such as a mark the desk lacks. Otherwise, tick **start its agents after uploading** (for an app without agents, **mark it running after uploading**), then click **confirm**.
5. The status page says whether the app runs. If it has a docket, its tile shows up in Landscape.

## 3. Update it

Pack the new version the same way and upload it. On the next page, **Update an existing desk** already has the app's desk and **replace it** selected, because the upload is a whole app with that desk's name. Click **next**. Replace makes the desk exactly the upload, so files the new version removed don't linger.

The confirm page offers a download of the desk as it is now. Keep it if you might want to go back: uploading it with **replace it** puts the old version back, unless the update changed the state an agent keeps. Then the old agent can't load that state, Clay refuses the commit, and nothing changes.

Then confirm. Clay rebuilds the agents as part of the commit. If one fails to build or to load its state, nothing changes, and the dojo shows why.

If the confirm page says kiln keeps the desk in sync from another ship, that ship's next release would undo your upload. Tick **stop kiln syncing** to keep yours.

## Deploying deskjam itself

### The first time

deskjam can't upload itself onto a ship that doesn't have it yet. Choose one of these:

- **Your ship runs the original deskjam.** Pack this fork as in step 1, then follow [Replacing upstream deskjam](../README.md#replacing-upstream-deskjam) from its step 2, uploading that `deskjam.deskjam`.
- **Another ship publishes this fork.** Run `|install ~that-ship %deskjam` in your dojo. kiln then brings you each version that ship publishes.
- **You can reach your ship's files.** Follow [Installation](../README.md#installation).

### Updating deskjam with deskjam

Get the new version into your clone, with `git pull`, and pack it as in step 1. Upload it on `https://your-ship/apps/deskjam`. On the next page, **Update an existing desk** already has `deskjam` and **replace it** selected, so click **next**. Then click **confirm** on the confirm page. Clay rebuilds deskjam as part of the commit, and the status page that follows comes from the new version.

If deskjam came from another ship with `|install`, tick **stop kiln syncing** on the confirm page, or that ship's next release replaces your version. If the commit fails, the deskjam you had keeps running, so you can try again.

### Before a kernel update

When Urbit releases a new kernel, your ship suspends every desk whose `sys.kelvin` doesn't list it, deskjam included, and a suspended deskjam can't upload its own fix. So once this repo's `desk/sys.kelvin` lists the new kernel, update deskjam to it, as above, before your ship upgrades. It still lists your current kernel too, so Clay applies it at once, and deskjam keeps running through the upgrade. Do the same for the other apps you deploy this way.

If your ship upgrades first, [Kernel updates](../README.md#kernel-updates) says how to put a new version on through your ship's files. Without them, `|install ~that-ship %deskjam`, from a ship that publishes a version for the new kernel, brings deskjam back too.

## If the app has a web frontend

An app's web frontend, its glob, isn't part of the desk: Landscape's `%docket` agent fetches it, as the app's `desk.docket-0` says.

- If the docket says `glob-http`, with a link, or `glob-ames` with another ship, `%docket` fetches the glob itself. There's nothing to do.
- If it says `glob-ames` with your ship, or your ship should serve the glob, follow [Apps with globs](globs.md).

deskjam has no glob: its pages come from its agent.

## Sharing it

To let other ships install an app from yours, deskjam included, run this in your dojo:

```
:treaty|publish %my-app
```

That makes the desk public and lists it in Landscape. Others install it with `|install ~your-ship %my-app`, and kiln brings them each update you upload. For deskjam, that also means they get the versions you make for new kernels without doing anything.

`:treaty|publish` reads the app's `desk.docket-0`, so it fails for an app without one. Run `|public %my-app` instead: others can then install it with `|install`, but Landscape doesn't list it.

## When something goes wrong

- **The confirm page won't do it.** It says why. For example, "no mark file for .json files" means the desk needs `mar/json.hoon`, and `mar/mime.hoon`, which it names. Copy marks from deskjam's build, or from `pkg/base-dev/mar` in [urbit/urbit](https://github.com/urbit/urbit), add them to the folder, and pack again.
- **Confirming shows an error page that only says `crud!`.** Clay refused the commit, so nothing changed, and the upload is still staged. The dojo shows why, usually a file that doesn't build, such as a type error. deskjam's confirm page checks that every file the marks and agents import exists, but it doesn't compile them. Fix the file, pack the folder again, and upload it.
- **The app doesn't start.** If its desk is suspended, the status page says so: run `|revive %my-app` in the dojo, which says why if it can't start it. If an agent crashes as it starts, the commit still lands and the status page lists the agent as running, but the dojo shows `gall: failed`, and the agent's setup never ran. Fix the agent and upload it again with **replace it**. Then, in the dojo, run `|nuke %my-agent`, which asks you to confirm and deletes the agent's state, and `|revive %my-app`, which starts the agent afresh.
- **A kernel update suspended the app.** Its `sys.kelvin` doesn't list the new kernel. Get a version of the app made for it, or add the kernel to `sys.kelvin` once the app, and the marks and libraries it copies, build on the new kernel. Pack it and upload it with **replace it**. Clay starts the app in a separate step after the commit, and if it can't, the status page and the dojo say why. If deskjam itself is suspended, see [Before a kernel update](#before-a-kernel-update).
