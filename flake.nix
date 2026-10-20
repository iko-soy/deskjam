{
  description = "The %deskjam desk";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Desk dependencies, pinned to the revisions in mortar.yaml.
    urbit = {
      url = "github:urbit/urbit/0a9a312e133891937de9c4df1ebecad5cf669c7c";
      flake = false;
    };
    landscape = {
      url = "github:tloncorp/landscape/46c6ed8738082b6a94558710b1e3619befa83057";
      flake = false;
    };
    fang-suite = {
      url = "github:Fang-/suite/2417ed8702547b04b6ee47a7db678e64cf82e18c";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      urbit,
      landscape,
      fang-suite,
      ...
    }:
    # The systems nixpkgs has urbit (vere) for, which the Hoon tests run on.
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        # Mirrors the dependency list in mortar.yaml: each entry copies
        # `paths` (relative to the desk root) from the directory `root` of
        # the GitHub repo `repo`, fetched as the input `src`. They're in
        # mortar's priority order, lowest first, so on a clash the later
        # entry wins, and the repo's own desk wins over all of them.
        imports =
          map (dep: dep // { from = if dep.root == "" then "${dep.src}" else "${dep.src}/${dep.root}"; })
            [
              {
                repo = "Fang-/suite";
                src = fang-suite;
                root = "";
                paths = [ "lib/rudder.hoon" ];
              }
              {
                repo = "tloncorp/landscape";
                src = landscape;
                root = "desk";
                paths = [
                  "mar/docket-0.hoon"
                  "lib/docket.hoon"
                  "lib/multipart.hoon"
                  "sur/docket.hoon"
                ];
              }
              {
                repo = "urbit/urbit";
                src = urbit;
                root = "pkg/base-dev";
                paths = [
                  "mar/bill.hoon"
                  "mar/hoon.hoon"
                  "mar/html.hoon"
                  "mar/kelvin.hoon"
                  "mar/mime.hoon"
                  "mar/noun.hoon"
                  "mar/txt-diff.hoon"
                  "mar/txt.hoon"
                  "lib/dbug.hoon"
                  "lib/default-agent.hoon"
                  "lib/server.hoon"
                  "lib/skeleton.hoon"
                  "lib/strand.hoon"
                  "lib/strandio.hoon"
                  "sur/spider.hoon"
                ];
              }
            ];

        # desk/desk.docket-0 carries the tile icon, url-encoded, as a data
        # url. Check that it's still assets/deskjam.svg.
        iconUrl = "data:image/svg+xml,${lib.escapeURL (builtins.readFile ./assets/deskjam.svg)}";
        iconMatches = lib.hasInfix "image+'${iconUrl}'" (builtins.readFile ./desk/desk.docket-0);

        # The full desk, as `mortar build` writes it to dist/.
        deskjam =
          assert lib.assertMsg iconMatches
            "desk/desk.docket-0's image isn't assets/deskjam.svg, url-encoded. See Building in the README.";
          pkgs.runCommand "deskjam" { } ''
            ${lib.concatMapStrings (
              { from, paths, ... }:
              lib.concatMapStrings (path: ''
                install -D -m 644 ${from}/${path} $out/${path}
              '') paths
            ) imports}
            cp -r --no-preserve=mode ${./desk}/. $out
          '';
      in
      {
        packages = {
          inherit deskjam;
          default = deskjam;
        };

        checks = {
          inherit deskjam;

          # mortar.yaml must take the same files from the same repos at the
          # same revisions, in the same priority order, as `imports`.
          mortar-pins =
            pkgs.runCommand "deskjam-mortar-pins"
              {
                nativeBuildInputs = [
                  pkgs.yq-go
                  pkgs.jq
                ];
                expected = builtins.toJSON (
                  map (dep: {
                    inherit (dep) repo root;
                    revision = dep.src.rev;
                    include = dep.paths;
                  }) imports
                );
                passAsFile = [ "expected" ];
              }
              ''
                yq -o=json . ${./mortar.yaml} > mortar.json
                jq -S 'map(.include |= sort)' "$expectedPath" > flake.json
                jq -S '[to_entries[] | select(.key | startswith("github ")) | .value]
                  | sort_by(.priority)
                  | map({repo, root: (.root // ""), revision, include: (.include | sort)})' \
                  mortar.json > mortar-github.json
                if ! diff -u flake.json mortar-github.json; then
                  echo "mortar.yaml's github dependencies (+) differ from flake.nix's imports (-). Change them together." >&2
                  exit 1
                fi
                # and the desk itself, over all of them
                jq -e '[to_entries[] | select(.key | startswith("local ")) | .value] as $local
                  | ([to_entries[] | select(.key | startswith("github ")) | .value.priority] | max) as $top
                  | ($local | length) == 1 and $local[0].path == "./desk" and $local[0].priority > $top
                    and ([keys[] | select(. != "output" and (startswith("github ") or startswith("local ") | not))] == [])' \
                  mortar.json > /dev/null || {
                  echo "mortar.yaml should take ./desk over its github dependencies, and nothing else." >&2
                  exit 1
                }
                touch $out
              '';

          # Hoon unit tests of the libraries without Ford runes, run with
          # `urbit eval`, which needs no ship. See tests/hoon/run.sh.
          hoon-tests = pkgs.runCommand "deskjam-hoon-tests" { nativeBuildInputs = [ pkgs.urbit ]; } ''
            DESK=${./desk} bash ${./tests/hoon}/run.sh
            touch $out
          '';
        };
      }
    );
}
