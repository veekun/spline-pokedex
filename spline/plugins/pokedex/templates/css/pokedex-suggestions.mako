ul#dex-suggestions { position: absolute; max-height: 192px /* about eight entries */; overflow: auto; overflow-x: hidden; background: white; border: 1px solid #404040; }
ul#dex-suggestions li { height: 24px /* height of item icon; pokemon are cropped */; padding: 0 0.5em 0 36px; border: 1px solid transparent; line-height: 24px; vertical-align: middle; background-repeat: no-repeat; background-position: center left; }
ul#dex-suggestions li:hover { border: 1px solid #bfd3f1; background-color: #e6eefa; }
ul#dex-suggestions li.selected { border: 1px solid #95b7ea; background-color: #bfd4f2; }
ul#dex-suggestions li.dex-suggestion-pokemon { background-position: 0px -6px; }
ul#dex-suggestions li.dex-suggestion-item { background-position: 4px center; }
ul#dex-suggestions li .typed { font-weight: bold; text-decoration: underline; }
