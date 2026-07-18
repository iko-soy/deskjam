# deskjam

You can build the full `%deskjam` desk with the [`mortar` build tool available here](https://github.com/tinnus-napbus/mortar).

## Installation
1. Clone this repo.
2. Boot up a ship (fakezod or moon or whatever you use).
4. `|new-desk %deskjam` to create a new desk called `%deskjam.
5. `|mount %deskjam` to access the `%deskjam` desk from the unix command line.
6. At the unix command line `rm -rf [ship-name]/deskjam/*` to empty out the contents of the desk.
7. In the repo, run `mortar build`
7. Copy the contents of `dist` to `[ship-name]/deskjam`
8. At the dojo command line `|commit %deskjam`.
9. Install with `|install our %deskjam`.

## Usage
1. To download a desk as a jam file go to `[your-domain-name]/apps/deskjam/download`.
2. To download a subset of the files in this desk as a jam file click the desk name on this page.
3. To upload a jammed desk go to `[your-domain-name]/apps/deskjam` and follow the instructions there.
