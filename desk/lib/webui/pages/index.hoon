/-  *deskjam
/+  sty=webui-styles, scr=webui-scripts, h=deskjam, par=webui-parts
|_  [=bowl:gall data msg=(unit [o=? =@t])]
+*  hc  ~(. h [our now]:bowl)
++  page
  ^-  manx
  ;html(lang "en")
    ;head
      ;title: Deskjam
      ;meta(charset "utf-8");
      ;meta
        =name     "viewport"
        =content  "width=device-width, initial-scale=1";
      ;style: {global:sty}
      ;script: {download-form:scr}
    ==
    ;body
      ;*  (banner:par msg)
      ;+  upload-jamfile
      ;br;
      ;br;
      ;+  download-jamfile
    ==
  ==
::
++  upload-jamfile
  ^-  manx
  ;div(style "max-width: 50ch; width: 100%")
    ;h2: upload deskjam
    ;p: A deskjam is a desk, such as an app, in one file. Upload one from your computer, or from a link to the file itself, such as a release download. Next you choose whether to install it as a new desk or update an existing one.
    ;p: Only upload deskjams from people you trust: an app's agents run as your ship, and can read and change anything on it.
    ;br;
    ;form
      =method   "post"
      =enctype  "multipart/form-data"
      =action   "/apps/deskjam"
      =class    "justified-form"
      ;input
        =id          "file-select"
        =type        "file"
        =name        "file"
        =accept      ".deskjam"
        =aria-label  "deskjam file"
        =required    "required";
      ;input(type "submit", value "upload");
    ==
    ;form(method "post", class "justified-form")
      ;input
        =type         "url"
        =name         "url"
        =placeholder  "https://example.com/app.deskjam"
        =aria-label   "deskjam url"
        =required     "required"
        =style        "max-width: 30ch; width: 100%;";
      ;input(type "submit", value "fetch");
      ;label
        ;input(type "checkbox", name "local", value "y");
        ; allow local addresses: this machine and its network
      ==
    ==
  ==
::
++  download-jamfile
  ^-  manx
  ;div(style "max-width: 50ch; width: 100%;")
    ;h2: download deskjam
    ;p: Download a desk as a deskjam, to keep a copy or to install it on another ship. Check "subset" to choose files, or see a desk's status.
    ;br;
    ;form
      =id      "download-form"
      =method  "get"
      =action  "/apps/deskjam/download"
      =class   "justified-form"
      ;select(name "desk", required "required", aria-label "desk")
        ::  desks with no commit have no files to download
        ::
        ;*  =/  have=(list desk)
              %+  murn  ~(tap by domes:hc)
              |=([d=desk =dome:clay] ?:(=(0 let.dome) ~ `d))
            %+  turn  (sort have aor)
            |=  =desk
            ^-  manx
            ;option(value (trip desk)): {(trip desk)}
      ==
      ;span
        ;label(for "subset-checkbox"): subset:
        ;input
          =id       "subset-checkbox"
          =type     "checkbox"
          =onclick  "changeDownloadFormAction()";
      ==
      ;input(type "submit", value "download");
      ;button(type "submit", formaction "/apps/deskjam/status"): status
    ==
  ==
--
