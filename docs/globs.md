# Apps with globs

Most Urbit apps have a web frontend called a glob: a bundle of the app's HTML, JavaScript and other files. The glob isn't part of the app's desk. The desk's `desk.docket-0` says where to get it, and Landscape's `%docket` agent fetches it and serves it.

This page covers installing and updating such apps with deskjam, and serving a glob from your own ship.

## Where a glob comes from

The docket names the glob by its hash, and says where to get it, in one of two ways:

- `glob-http+['https://example.com/glob-0v1.abcde.glob' 0v1.abcde]`: `%docket` downloads the file from the url. Tlon's apps work this way.
- `glob-ames+[~sampel-palnet 0v1.abcde]`: `%docket` asks that ship's `%docket` for it, over Ames. When that ship is your own, there's nowhere to fetch it from: `%docket` waits for you to upload the glob on its upload page, `/docket/upload`.

The hash comes from the glob's contents, so it changes with every build of the frontend. When a commit changes the docket's glob line, `%docket` fetches the glob it names. For a glob your ship serves, it keeps the one it has if the hashes match, and otherwise waits for an upload. Until then, the app has no frontend.

That only holds while the desk keeps running. When a suspended desk starts again, for example when you update an app that a kernel update suspended, `%docket` forgets a glob your ship served for it, whatever the hash. Upload the glob again at `/docket/upload` after the commit. deskjam's confirm page warns you when this applies.

deskjam's status page for a desk shows its docket's glob line, under **glob**.

## Apps whose glob comes from elsewhere

Install or update the desk with deskjam as usual. `%docket` fetches the glob itself once the desk is running.

## Serving a glob from your ship

This is how you share an app you build, frontend included, from your ship. Others can install it once you publish the desk: `:treaty|publish %your-app` makes it public and lists it in Landscape, and for `|install` alone, `|public %your-app` is enough. Ships that install the app from you get the glob from your ship, so it has to be online for them to install the app or take an update.

Keep the docket's `base` the same as the desk's name, and have others install the app under that name. Other ships ask your `%docket` for the glob by their desk's name, which has to match a `base` on your ship.

You upload the glob at `/docket/upload`, which takes a folder: your frontend's build output, with an `index.html` at its top. Safari can't upload folders, so use another browser. When `%docket` takes the glob, and the docket names your ship, it writes the glob's hash into the desk's docket.

The hash in the docket on your ship has to match the glob `%docket` holds. Your app's repo can't know that hash before you build the frontend. You can commit the hash to the repo after each frontend build, or let deskjam set it, as below.

If you let deskjam set it, the docket in your repo can keep a placeholder with your own ship and any hash, such as `glob-ames+[~sampel-palnet 0v0]`. With your own ship there, if you forget to set the hash, uploading the glob at `/docket/upload` still fixes the docket. Two caveats:

- Update the desk only through deskjam, setting the hash each time. A `|commit` or merge of the repo's files puts the placeholder back, and `%docket` drops the frontend, without a warning, until you upload the glob again.
- A deskjam built from the repo carries the placeholder, so it isn't much use to anyone else. To give the app to others, have them install it from your ship, or give them a deskjam downloaded from your ship, which has the real hash.

### Installing the app

1. Upload the app's deskjam at `/apps/deskjam` and install it as a new desk.
2. If the docket doesn't already say `glob-ames` with your ship, click **set** in the glob box on the confirm page. Any hash will do. Setting it reloads the page, which clears the boxes below it, so do this first.
3. Tick **start its agents after uploading** (for an app without agents, **mark it running after uploading**), then confirm. `%docket` only takes a glob for a desk that has run.
4. Open `/docket/upload`, choose the desk, choose your frontend's build folder, and click **glob!**. `%docket` serves the glob from then on, and writes its hash into the desk's docket.

### Updating the agents only

Upload the new deskjam and choose the desk to update. In the glob box on the confirm page, deskjam offers the hash of the glob your ship serves now: click **set**, then confirm. The docket keeps that hash, so `%docket` keeps serving the glob.

If you skip this and the upload's docket has a different hash, the app has no frontend until you upload the glob again. The confirm page warns you when that would happen.

### Updating the frontend

Upload the new build folder at `/docket/upload`. `%docket` serves the new glob at once, and writes its hash into the docket. If the agents change too, upload the desk with deskjam afterwards: the glob box then offers the new hash.

If the new frontend needs the new agents, upload the desk first, keeping the current hash, and then the frontend.

## When the frontend is missing

If an app's tile stays on installing, `%docket` is probably waiting for a glob. Check the glob row on deskjam's status page for the desk:

- If it says **from this ship**, upload the glob again at `/docket/upload`.
- If it names another ship or a url, `%docket` fetches the glob from there, so that ship or server is where the problem is. If you meant your ship to serve it, upload the desk again with deskjam, set the hash, and then upload the glob.
