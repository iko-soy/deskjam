/-  *deskjam
/+  sty=webui-styles, scr=webui-scripts, img=webui-images,
    h=deskjam, par=webui-parts
::
::  .dex: the desk to choose files from, or why there's none
::
|_  [=bowl:gall dex=(each desk tape)]
+*  hc  ~(. h [our now]:bowl)
++  page
  ^-  manx
  ;html(lang "en")
    ;head
      ;title: {?:(?=(%& -.dex) "Deskjam: files of %{(trip p.dex)}" "Deskjam")}
      ;meta(charset "utf-8");
      ;meta
        =name     "viewport"
        =content  "width=device-width, initial-scale=1";
      ;style: {global:sty}
      ;script: {subset:scr}
    ==
    ;body
      ;+  icons:par
      ;a/"/apps/deskjam": return home
      ;br;
      ;+  ?-  -.dex
            %|  ;p.bad: {p.dex}
            %&  (display-desk p.dex)
          ==
    ==
  ==
++  display-desk
  |=  =desk
  ^-  manx
  ;form(method "get", action "/apps/deskjam/download")
    ;input(type "hidden", name "desk", value (trip desk));
    ;table
      ;tr
        ;td: Select files and folders to jam.
        ;td
          ;input(type "submit", value "download");
        ==
      ==
      ;*  (folder-hierarchy desk)
    ==
  ==
++  folder-hierarchy
  |=  =desk
  ^-  marl
  %+  turn  (desk-to-hierarchy:hc desk)
  |=  [pat=path dir=? dep=@]
  =/  tpath=tape  (spud pat)
  ^-  manx
  ;tr
    ;td
      ;table
        ;tr
          ;td
            ;+  ?:  dir
                  ;input
                    =id        tpath
                    =type      "checkbox"
                    =class     (path-to-classes:hc pat dir)
                    =onchange  "checkboxDir(this.id)";
                ;input
                  =id        tpath
                  =type      "checkbox"
                  =name      "path"
                  =value     tpath
                  =class     (path-to-classes:hc pat dir);
          ==
          ;td(width (a-co:co (mul 20 dep)));
          ;td
            ;+  ?.  =(0 dep)
                  (resource-icon:img dir)
                ;p
                  ;strong: %
                ==
          ==
          ;td
            ;label(for tpath)
              ;+  ?:  =(0 dep)  ;/  (trip desk)
                  ?:  dir  ;/  (trip (rear pat))
                  ;/  (file-name:par pat)
            ==
          ==
        ==
      ==
    ==
  ==
--
