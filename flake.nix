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
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        # Mirrors the dependency list in mortar.yaml: each entry copies
        # `paths` (relative to the desk root) from the directory `from`.
        # They're in mortar's priority order, lowest first, so on a clash the
        # later entry wins, and the repo's own desk wins over all of them.
        imports = [
          {
            from = "${fang-suite}";
            paths = [ "lib/rudder.hoon" ];
          }
          {
            from = "${landscape}/desk";
            paths = [
              "mar/docket-0.hoon"
              "lib/docket.hoon"
              "lib/multipart.hoon"
              "sur/docket.hoon"
            ];
          }
          {
            from = "${urbit}/pkg/base-dev";
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
              "lib/verb.hoon"
              "sur/spider.hoon"
              "sur/verb.hoon"
            ];
          }
        ];

        # The full desk, as `mortar build` writes it to dist/.
        deskjam = pkgs.runCommand "deskjam" { } ''
          ${lib.concatMapStrings (
            { from, paths }:
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
      }
    );
}
