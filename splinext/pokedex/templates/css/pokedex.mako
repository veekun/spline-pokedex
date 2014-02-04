/*** General ***/

/* Pokémon sprite link grid */
a.dex-icon-link { display: inline-block; border: 1px solid transparent; }
a.dex-icon-link:hover { border: 1px solid #bfd3f1; background: #e6eefa; }
a.dex-icon-link.selected { border: 1px solid #95b7ea; background: #bfd4f2; }
a.dex-box-link { display: inline-block; margin: 0.25em; border: 1px solid transparent; }
a.dex-box-link:hover { border: 1px solid #bfd3f1; background: #e6eefa; }
a.dex-box-link.selected { border: 1px solid #95b7ea; background: #bfd4f2; }

/* Cool three-column layout */
.dex-column-container { clear: both; overflow: hidden /* float context */; margin-top: 1em; }
.dex-column { float: left; width: 32.666%; margin-left: 1%; }
.dex-column:first-child { margin-left: 0; }
.dex-column-2x { float: left; width: 66.333%; margin-left: 1%; }
.dex-column-2x:first-child { margin-left: 0; }
.dex-column2 { float: left; width: 49%; margin-left: 1%; }
.dex-column2:first-child { margin-left: 0; }

/* Type damage colors */
.dex-damage-taken-0   { font-weight: bold; color: #66c; }
.dex-damage-taken-25  { font-weight: bold; color: #6cc; }
.dex-damage-taken-50  { font-weight: bold; color: #6c6; }
.dex-damage-taken-100 { font-weight: bold; color: #999; }
.dex-damage-taken-200 { font-weight: bold; color: #c66; }
.dex-damage-taken-400 { font-weight: bold; color: #c6c; }
.dex-damage-dealt-0   { font-weight: bold; color: #66c; }
.dex-damage-dealt-25  { font-weight: bold; color: #c6c; }
.dex-damage-dealt-50  { font-weight: bold; color: #c66; }
.dex-damage-dealt-100 { font-weight: bold; color: #999; }
.dex-damage-dealt-200 { font-weight: bold; color: #6c6; }
.dex-damage-dealt-400 { font-weight: bold; color: #6cc; }
.dex-damage-score-good { font-weight: bold; color: #4c4; }
.dex-damage-score-bad  { font-weight: bold; color: #c44; }
.dex-damage-score-eh   { font-weight: bold; color: #ccc; }

/* Move priorities, used most prominently in the move table */
.dex-priority-fast { font-weight: bold; color: green; }
.dex-priority-slow { font-weight: bold; color: red; }

/* Nature-affected stats */
.dex-nature-buff { font-weight: bold; color: #e65858; }
.dex-nature-nerf { font-weight: bold; color: #5875e6; }

/* Links to Pokémon search */
dd .dex-subtle-search-link { visibility: hidden; }
dd:hover .dex-subtle-search-link { visibility: visible; }


/*** General tables ***/

/* Columns woo */
/* nb: these columns *include* cell padding */
col.dex-col-icon        { width: 40px; }
col.dex-col-name        { width: 10em; }
col.dex-col-link        { width: 16px; }
col.dex-col-max-exp     { width: 7em; }
col.dex-col-ability     { width: 8em; }
col.dex-col-gender      { width: 7em; }
col.dex-col-egg-group   { width: 7em; }
col.dex-col-height      { width: 5em; }
col.dex-col-weight      { width: 6em; }
col.dex-col-species     { width: 8em; }
col.dex-col-color       { width: 7em; }
col.dex-col-habitat     { width: 9em; }
col.dex-col-stat        { width: 3em; }
col.dex-col-stat-total  { width: 4em; }
col.dex-col-stat-name   { width: 10em; }
col.dex-col-stat-bar    { width: auto; }
col.dex-col-stat-pctile { width: 5em; }
col.dex-col-stat-result { width: 5em; }
col.dex-col-effort      { width: 8em; }
col.dex-col-type        { width: 40px; /* badges are 32px wide */ }
col.dex-col-type2       { width: 80px; }
col.dex-col-version     { width: 3.5em; }  /* two versions (32px < 33px == 3em) plus 0.17em padding < 3.5em */
col.dex-col-encounter-name { width: 10em; }
col.dex-col-encounter-version { width: 12em; }

/* Generic Pokémon and move lists; originally used for a Pokémon's moves, or a move's Pokémon */
table.dex-pokemon-pokemon-moves { width: 100%; }
table.dex-pokemon-moves td { padding: 0.33em; vertical-align: middle; text-align: center; }
table.dex-pokemon-moves th { padding: 0.33em 0.17em; text-align: center; }
table.dex-pokemon-moves tr.header-row { border-top: 2px solid #668dcc; }
table.dex-pokemon-moves tr.subheader-row th { padding: 0.17em 0.33em; text-align: left; }
table.dex-pokemon-moves tr.conquest-subheader-row th { text-align: center; }
table.dex-pokemon-moves td.egg { padding: 0 /* egg sprite consumes a lot of space, so let it extend into padding */; }
table.dex-pokemon-moves td.icon { padding: 0 /* icons consume a lot of space, so let em extend into padding */; }
table.dex-pokemon-moves td.name { white-space: nowrap; }
table.dex-pokemon-moves td.max-exp { text-align: right; }
table.dex-pokemon-moves td.effect { font-size: 0.8em; text-align: left; }
table.dex-pokemon-moves td.effect p { margin: 0; }
table.dex-pokemon-moves td.tutored { white-space: nowrap; }
table.dex-pokemon-moves .no-tutor { visibility: hidden; }
table.dex-pokemon-moves td.type2 { text-align: left; }
table.dex-pokemon-moves td.ability { font-size: 0.75em; padding: 0.25em; white-space: nowrap; }
table.dex-pokemon-moves td.egg-group { font-size: 0.75em; padding: 0.25em; }
table.dex-pokemon-moves td.stat { text-align: right; }
table.dex-pokemon-moves td.stat-range { text-align: center /* Conquest - Range is always one digit and looks awkward shoved to the side */; }
table.dex-pokemon-moves td.size { text-align: right; }
table.dex-pokemon-moves td.color { text-align: left; }
table.dex-pokemon-moves td.species { }
table.dex-pokemon-moves td.effort { font-size: 0.75em; padding: 0.25em; text-align: left; }
table.dex-pokemon-moves tr.better-move-type:nth-child(2n) td.type,
table.dex-pokemon-moves tr.better-move-type:nth-child(2n) td.type2,
table.dex-pokemon-moves tr.better-move-stat-physical:nth-child(2n) td.stat-attack,
table.dex-pokemon-moves tr.better-move-stat-special:nth-child(2n) td.stat-special-attack,
table.dex-pokemon-moves tr.better-move-stat:nth-child(2n) td.class,
table.dex-pokemon-moves tr.perfect-link:nth-child(2n) td.max-link { background: #afcfaf; }
table.dex-pokemon-moves tr.better-move-type:nth-child(2n+1) td.type,
table.dex-pokemon-moves tr.better-move-type:nth-child(2n+1) td.type2,
table.dex-pokemon-moves tr.better-move-stat-physical:nth-child(2n+1) td.stat-attack,
table.dex-pokemon-moves tr.better-move-stat-special:nth-child(2n+1) td.stat-special-attack,
table.dex-pokemon-moves tr.better-move-stat:nth-child(2n+1) td.class,
table.dex-pokemon-moves tr.perfect-link:nth-child(2n+1) td.max-link { background: #c0d8c0; }

/* "Sorting" Pokémon search results by evolution chain */
table.dex-pokemon-moves tr.fake-result td { opacity: 0.25; }
table.dex-pokemon-moves tr.chain-divider { border-top: 2px solid #b4c7e6; }
table.dex-pokemon-moves tr.evolution-depth-0 td.name { text-align: left; }
table.dex-pokemon-moves tr.evolution-depth-1 td.name { padding-left: 1em; text-align: left; }
table.dex-pokemon-moves tr.evolution-depth-2 td.name { padding-left: 2em; text-align: left; }
table.dex-pokemon-moves tr.evolution-depth-3 td.name { padding-left: 3em; text-align: left; }

/* JavaScript filtering/sorting */
.js-dex-pokemon-moves-extras { margin-bottom: 0.25em; text-align: right; }
.js-dex-pokemon-moves-options { display: inline-block; position: relative; margin-bottom: 0.25em; }
.js-dex-pokemon-moves-options .title { font-size: 0.8em; padding: 0.33em 0.5em; background: #cfdcf0; border-radius: 0.5em; }
.js-dex-pokemon-moves-options .title img { margin-right: 0.33em; }
.js-dex-pokemon-moves-options .body { display: none; position: absolute; right: 0; width: 16em; padding: 0.33em; border: 1px solid #668dcc; text-align: left; background: white; box-shadow: 0.125em 0.125em 0.25em rgba(0, 0, 0, 0.5); }
.js-dex-pokemon-moves-options:hover .title { background: #3173ce; color: white; border-radius: 0; border-top-left-radius: 0.5em; border-top-right-radius: 0.5em; }
.js-dex-pokemon-moves-options:hover .body { display: block; }
.js-dex-pokemon-moves-options:hover .body label { display: block; }
table.dex-pokemon-moves tr.js-dex-pokemon-moves-controls .js-label { font-size: 0.67em; }
table.dex-pokemon-moves tr.js-dex-pokemon-moves-controls:hover { background: transparent; }
table.dex-pokemon-moves tr.js-dex-pokemon-moves-controls td:hover { cursor: pointer; background: #e6eefa; }
table.dex-pokemon-moves tr.js-dex-pokemon-moves-controls td.js-not-a-button:hover { cursor: default; background: transparent; }
table.dex-pokemon-moves tr.js-dex-pokemon-moves-controls td.js-sorted-by { background: #f0efe6; }
table.dex-pokemon-moves tr:nth-child(2n) td.js-sorted-by { background: #f0efe6; }
table.dex-pokemon-moves tr:nth-child(2n+1) td.js-sorted-by { background: #f6f4ea; }


/*** Individual pages -- shared ***/

/* Prev/current/next header */
#dex-header { overflow: hidden; /* new float context */ text-align: center; line-height: 24px; /* keep buttons at least 24px tall */ }
#dex-header-prev { float: left;  text-align: left; }
#dex-header-next { float: right; text-align: right; }
#dex-header-prev, #dex-header-next { width: 15em; min-height: 24px; margin: 0; }
#dex-header-prev img, #dex-header-next img { vertical-align: middle; }
#dex-header ul.inline-menu {  line-height: 1.2; }
#dex-header + h1 { margin-top: 0.25em; }

/* Header sublinks, e.g. pokemon | flavor | locations */
ul.inline-menu { text-align: middle; }
ul.inline-menu > li { display: inline; }
ul.inline-menu > li:after { content: ' | '; }
ul.inline-menu > li:last-child:after { content: none; }

/* Top section, with the portrait and stuff on the right side */
.dex-page-portrait { float: left; width: 15em; min-height: 10em; padding-bottom: 1em; text-align: center; }
.dex-page-portrait p { margin: 0.25em 0; line-height: 1; }
.dex-page-beside-portrait:after { display: block; clear: both; content: ""; }
p#dex-page-name { font-size: 2em; margin: 0.12em 0; }
#dex-pokemon-forme { font-size: 1.25em; font-weight: bold; }
#dex-pokemon-portrait-sprite { height: 200px; width: 22em; margin: -35px -3em -35px -4em; padding: 7px; line-height: 200px; vertical-align: middle; text-align: center; background: url(${h.static_uri('pokedex', 'images/sprite-frame-x-y.png')}) center center no-repeat; }

.dex-warrior-portrait { min-width: 176px; margin: auto 0.33em; }
#dex-pokemon-conquest-portrait-sprite { height: 128px; width: 128px; margin: 0.33em auto; padding: 7px; line-height: 128px; vertical-align: middle; text-align: center; background: url(${h.static_uri('pokedex', 'images/sprite-frame-conquest.png')}) center center no-repeat; }
.dex-warrior-portrait-sprite { height: 168px; width: 176px; margin: 0.33em 0; padding: 4px 0; background: url(${h.static_uri('pokedex', 'images/sprite-frame-conquest-warrior.png')}) center center no-repeat; }

/* List of types with damage (or whatever) below */
ul.dex-type-list { overflow: hidden /* new float context */; margin-bottom: 2em; }
ul.dex-type-list li { display: inline-block; text-align: center; padding: 0.125em; }
ul.dex-type-list li img { display: block; margin-bottom: 0.25em; }

/* Size comparison -- used by Pokémon and flavor */
.dex-size { height: 120px; padding-bottom: 2.5em /* for -value */; overflow: hidden /* new float context */}
.dex-size img { clip: 8px; position: absolute; bottom: 0; image-rendering: optimizeSpeed; image-rendering: -moz-crisp-edges; image-rendering: -webkit-optimize-contrast; image-rendering: -o-crisp-edges; -ms-interpolation-mode: nearest-neighbor; }
.dex-size input[type='text'] { text-align: right; }
.dex-size .dex-size-trainer,
.dex-size .dex-size-pokemon { display: block; position: relative; float: left; height: 100%; width: 50%; text-align: left; }
.dex-size .dex-size-trainer { text-align: right; }
.dex-size .dex-size-pokemon { text-align: left; }
.dex-size .dex-size-trainer img { right: 0.25em; }
.dex-size .dex-size-pokemon img { left: 0.25em; }
.dex-size .js-dex-size-raw { display: none; }
.dex-size .dex-size-value { position: absolute; height: 2em; margin: 0; line-height: 1; padding: 0.25em; bottom: -2.5em; }
.dex-size .dex-size-trainer .dex-size-value { right: 0.25em; }
.dex-size .dex-size-pokemon .dex-size-value { left: 0.25em; }

/* Conquest misc. */
table.dex-warriors td.warrior-icon { padding: 0 0.33em; }
table.dex-warriors td.max-link { width: 3em; }
.warrior-icon-small { border: 1px black solid; }
.warrior-icon-big { margin: 1px auto; }


/*** Individual pages ***/

/* Pokémon page -- ability list */
dl.pokemon-abilities p { margin: 0; padding: 0; }

/* Pokémon page -- grid of compatible breeding partners */
ul.dex-pokemon-compatibility { max-height: 136px /* four rows of icons plus borders */; }
ul.inline.dex-pokemon-compatibility { overflow: auto; }

/* Pokémon page -- wild held items */
table.dex-pokemon-held-items { width: 100%; }
table.dex-pokemon-held-items .versions { width: 48px /* three versions */; padding-right: 0.5em; }
table.dex-pokemon-held-items .rarity { width: 4em; padding-right: 0.5em; text-align: right; }
table.dex-pokemon-held-items tr.new-version { border-top: 1px dotted #c0c0c0; }
table.dex-pokemon-held-items tbody tr:first-child.new-version { border-top: none; }

/* Pokémon page -- evolution chain table */
table.dex-evolution-chain { width: 100%; table-layout: fixed; border-collapse: separate; border-spacing: 0.5em; empty-cells: hide; }
table.dex-evolution-chain td { padding: 0.5em; vertical-align: middle; border: 1px solid #d8d8d8; background: #f0f0f0; }
table.dex-evolution-chain td:hover { border: 1px solid #bfd3f1; background: #e6eefa; }
table.dex-evolution-chain td.selected { border: 1px solid #95b7ea; background: #bfd4f2; }
.dex-evolution-chain-method { display: block; overflow: hidden; font-size: 0.8em; line-height: 1.25em; }
.dex-evolution-chain-pokemon { padding-top: 8px /* bump icon up a bit */; display: block; font-weight: bold; }
.dex-evolution-chain-pokemon img,
.dex-evolution-chain-pokemon .sprite-icon { float: left; margin-top: -8px /* fills link's top padding */; margin-right: 0.33em; }

/* Pokémon page -- stats table */
table.dex-pokemon-stats { width: 100%; }
table.dex-pokemon-stats th label { display: block; text-align: right; font-weight: normal; color: #2457a0; }
table.dex-pokemon-stats th input { text-align: left; }
table.dex-pokemon-stats .dex-pokemon-stats-bar-container { background: #f8f8f8; }
table.dex-pokemon-stats .dex-pokemon-stats-bar { padding: 0.33em; border: 1px solid #d8d8d8; background: #f0f0f0; }
table.dex-pokemon-stats td.dex-pokemon-stats-pctile { text-align: right; }
table.dex-pokemon-stats td.dex-pokemon-stats-result { text-align: right; }

/* Pokémon page -- simple-encounters list */
.dex-simple-encounters-method { margin-bottom: 0.5em; }
dl.dex-simple-encounters dd img { vertical-align: bottom; }
dl.dex-simple-encounters ul { display: inline; }
dl.dex-simple-encounters ul li { display: inline; }
dl.dex-simple-encounters ul li:after { content: '; '; }
dl.dex-simple-encounters ul li:last-child:after { content: ''; }

/* Pokémon page -- Pokéathlon performance */
.dex-pokeathlon-stats { display: inline-block; }
.dex-pokeathlon-stats p { text-align: center; }
.dex-pokeathlon-stats dt { width: 7em; }
.dex-pokeathlon-stats dd { padding-left: 7.5em; width: 80px; }

/* Pokémon page -- cry */
/* Mozilla's player changes its height proportionate to its width by default or something */
audio.cry { width: 100%; height: 35px; }

/* Pokémon flavor -- color */
.dex-color-black,
.dex-color-blue,
.dex-color-brown,
.dex-color-gray,
.dex-color-green,
.dex-color-pink,
.dex-color-purple,
.dex-color-red,
.dex-color-white,
.dex-color-yellow { display: inline-block; height: 1em; width: 1em; border: 1px solid #606060; vertical-align: middle; }
.dex-color-black    { background: black; }
.dex-color-blue     { background: blue; }
.dex-color-brown    { background: brown; }
.dex-color-gray     { background: gray; }
.dex-color-green    { background: green; }
.dex-color-pink     { background: pink; }
.dex-color-purple   { background: purple; }
.dex-color-red      { background: red; }
.dex-color-white    { background: white; }
.dex-color-yellow   { background: yellow; }

/* Pokémon flavor page -- tables of sprites */
table.dex-pokemon-flavor-sprites td { vertical-align: middle /* sprites aren't always the same height within a row */; }
table.dex-pokemon-flavor-sprites td.dex-pokemon-flavor-no-sprite { text-align: center; }

/* Pokémon flavor page -- RBY sprite needs doublesizin' */
.dex-pokemon-flavor-rby-back img { width: 64px; image-rendering: optimizeSpeed; image-rendering: -moz-crisp-edges; image-rendering: -webkit-optimize-contrast; image-rendering: -o-crisp-edges; -ms-interpolation-mode: nearest-neighbor; }

/* Pokémon flavor page -- flavor text */
dl.dex-flavor-text dt { width: 96px /* enough for 5 versions and padding*/; }
dl.dex-flavor-text dd { padding-left: 96px; margin-left: .5em; }
dl.dex-flavor-text dt.dex-flavor-generation { width: auto; text-align: left; margin: 0;padding: 0; }
dl.dex-flavor-text dt.dex-flavor-generation + dd { padding-left: 32px; }
dl.dex-pokemon-flavor-text dt { width: 64px /* enough for 3 versions and padding */; }
dl.dex-pokemon-flavor-text dd { padding-left: 64px; }

/* Pokémon flavor page -- client-resize Sugimori art */
p.dex-sugimori img { max-width: 100%; }

/* Move page -- flags list */
ul.dex-move-flags .markdown { font-size: 0.8em; font-style: italic; color: #404040; }
ul.dex-move-flags .markdown p { margin-bottom: 0.33em; }
ul.dex-move-flags li.disabled a { font-weight: normal; color: #c0c0c0; }
ul.dex-move-flags li.disabled a:hover { color: #ce3131; }

/* Location page and Pokémon location page -- entire bigass table */
table.dex-encounters td { padding-left: 0.5em; padding-right: 0.5em; vertical-align: top; }
table.dex-encounters td.location { vertical-align: top; }
table.dex-encounters th.location { vertical-align: top; text-align: left; }
.dex-location-area { font-size: 0.8em; font-style: italic; color: black; }
.dex-encounter-condition-group { padding: 0.5em 0; }
.dex-encounter-condition-group + .dex-encounter-condition-group { border-top: 1px solid #404040; }
.dex-encounter-conditions + .dex-encounter-conditions { margin-top: 0.5em; }
.dex-encounter-conditions .dex-encounter-icon { float: left; width: 24px; height: 24px; line-height: 24px; text-align: center; overflow: hidden;}
.dex-encounter-conditions .dex-encounter-icon img { vertical-align: middle; }
.dex-encounter-conditions .dex-encounter-rarity { float: right; }
.dex-encounter-conditions .dex-rarity-bar { position: relative; overflow: auto; font-size: 0.83em; height: 1em; line-height: 1; margin-top: 0.25em; background: #e8e8e8; border: 1px solid #96bbf2; }
.dex-encounter-conditions .dex-rarity-bar-fill { height: 100%; background: #96bbf2; }
.dex-encounter-conditions .dex-rarity-bar-fills { float: left; height: 100%; background: #96bbf2; }
.dex-encounter-conditions .dex-rarity-bar-fills + .dex-rarity-bar-fills { margin-left: -1px; border-left: 1px solid #b3cef6; }
.dex-encounter-conditions .dex-rarity-bar-fills:hover { background: #668dcc; }
.dex-encounter-conditions .dex-rarity-bar-value { position: absolute; height: 100%; top: 0; right: 0; color: #808080; vertical-align: bottom; }

/* Item page -- pocket list at the top */
ul#dex-item-pockets { text-align: center; }
ul#dex-item-pockets li { display: inline-block; }
ul#dex-item-pockets li img { padding: 4px; }

/* Conquest Pokémon page -- move dl */
dl.dex-conquest-pokemon-move dt { float: none; clear: none; width: auto; text-align: right; margin-left: 1em; margin-right: 0; display: inline-block; vertical-align: middle; }
dl.dex-conquest-pokemon-move dd { padding-left: 0; display: inline-block; vertical-align: middle;}
dl.dex-conquest-pokemon-move dd:after { display: none; }
dl.dex-conquest-pokemon-move dd p { margin: 0; }
dl.dex-conquest-pokemon-move dt.dex-cpm-name,
dl.dex-conquest-pokemon-move dt.dex-cpm-type,
dl.dex-conquest-pokemon-move dt.dex-cpm-range { display: none; }
dd.dex-cpm-type, dd.dex-cpm-range { margin: auto 1px auto 0; }
/* Make the name pretend to be a dt */
dd.dex-cpm-name { width: 11.5em; text-align: right; padding-left: 0; }
dl.dex-conquest-pokemon-move dd.dex-cpm-name:after { display: inline; content: ':'; visibility: visible; }

/* Conquest move page -- range diagram */
.dex-conquest-move-range { float: right; margin-right: 1.5em; margin-left: 0.5em; }

/* Conquest warrior page -- skill list */
dt.dex-warrior-skill-rank { width: 2em; margin-right: 0; }
dt.dex-warrior-skill-rank + dt.dex-warrior-skill-name { width: 9.5em; clear: none }


/*** Lists ***/

table.dex-ability-list td { padding: 0.33em 0.5em; }
table.dex-ability-list p { margin: 0; padding: 0; }

table.dex-nature-list td { padding: 0.33em 1em 0.33em 0.75em; }
table.dex-nature-list td.flavor { text-align: right; }

table.dex-type-chart td { text-align: center; vertical-align: middle; }
table.dex-type-chart td.dex-damage-dealt-100 { color: #e0e0e0; }
/* Hover colors clash; dim the 100% color a bit less on hover */
table.dex-type-chart.striped-rows tr td.js-hover.dex-damage-dealt-100,
table.dex-type-chart.striped-rows tr:hover td.dex-damage-dealt-100 { color: #aaa; }


/*** Searches ***/

/* Custom table and custom list display */
.no-js .js-instructions { display: none; }
.dex-search-display-columns ul.js-dex-search-column-picker { column-count: 2; -moz-column-count: 2; -webkit-column-count: 2; }
.no-js .dex-column.dex-search-display-list { margin-left: 33.666%; }
.dex-search-display-list-reference dl { overflow: auto; max-height: 24em; }
/* Only show the table/list controls when the right display mode is selected */
body.js .dex-column-container .dex-search-display-columns { display: none; }
body.js .dex-column-container .dex-search-display-list    { display: none; }
body.js .dex-column-container .dex-search-display-list-reference { display: none; }
body.js .dex-column-container.js-dex-search-display-table .dex-search-display-columns { display: block; }
body.js .dex-column-container.js-dex-search-display-list  .dex-search-display-list    { display: block; }
body.js .dex-column-container.js-dex-search-display-list  .dex-search-display-list-reference { display: block; }
/* Style the js sortables */
.dex-search-display-columns ul.checked { float: left; width: 48%; margin: 0 1%; border: 1px solid #bfd3f1; }
.dex-search-display-columns ul.unchecked { margin: 0 1% 0 51%; }
.dex-search-display-columns ul.checked li,
.dex-search-display-columns ul.unchecked li { padding: 0.33em 0.5em; cursor: move; }
.dex-search-display-columns ul.checked li label,
.dex-search-display-columns ul.unchecked li label { cursor: move; }
.dex-search-display-columns ul.checked li { background: #e6eefa; }
.dex-search-display-columns ul.unchecked li { background: #f4f4f4; color: #606060; }
.dex-search-display-columns ul.checked input,
.dex-search-display-columns ul.unchecked input { display: none; }

/* Pokémon search -- showing a list */
.dex-pokemon-search-list { line-height: 1.33; font-family: monospace; }
.dex-pokemon-search-list a { font-weight: normal; }

/* Pokémon search -- move versions */
table#dex-pokemon-search-move-versions td { padding-right: 2em; }

/* Move search -- category list */
.dex-move-search-categories { overflow: auto; max-height: 15em; }


/*** Gadgets ***/

/* Pokéball performance results */
table.dex-capture-rates td { vertical-align: middle; }
table.dex-capture-rates th.item { text-align: left; }
table.dex-capture-rates td.chance { text-align: right; }
table.dex-capture-rates td.condition { font-size: 0.8em; font-style: italic; }
table.dex-capture-rates td.expected-attempts { text-align: right; padding-right: 1em /* title is wide; offset a bit */; }
table.dex-capture-rates tr.inactive td { color: #909090; }
div.dex-capture-rate-graph { display: inline-block; position: relative; width: 10em; height: 1.3em; background: #79cc66; }
div.dex-capture-rate-graph-bar { float: left; height: 100%; }
p.dex-capture-rate-legend span { padding: 0.25em; }
.wobble0 { background: #cc6666; }
.wobble1 { background: #d88c8c; }
.wobble2 { background: #e5b2b2; }
.wobble3 { background: #f2d9d9; }
.wobble4 { background: #79cc66; }
table.dex-capture-rates tr.inactive div.dex-capture-rate-graph { opacity: 0.25; }

/* Pokéball performance -- HP bar for HP-remaining input */
.dex-hp-bar { display: inline-block; height: 3px; width: 48px; margin: 0.25em; padding: 6px 2px 7px 16px /* 4px of extra vertical padding for click space */; vertical-align: middle; background: url(${h.static_uri('pokedex', 'images/hp-bar.png')}) center left no-repeat; }
.dex-hp-bar .dex-hp-bar-bar { width: 100%; height: 100%; }
.dex-hp-bar .dex-hp-bar-bar.green  { background-color: #18c31f; }
.dex-hp-bar .dex-hp-bar-bar.yellow { background-color: #d7ac00; }
.dex-hp-bar .dex-hp-bar-bar.red    { background-color: #be2821; }

/* Pokémon comparison */
ul.dex-compare-pokemon-version-list { display: inline-block; }
ul.dex-compare-pokemon-version-list li { display: inline-block; padding: 0 0.5em; }

table.dex-compare-pokemon { width: 100%; margin-top: 0.5em; table-layout: fixed; }
form + table.dex-compare-pokemon { margin-top: 0; }
table.dex-compare-pokemon col.labels { width: 13em; }
table.dex-compare-pokemon .dex-compare-suggestions th { padding: 0.5em; vertical-align: bottom; text-align: left; }
table.dex-compare-pokemon .header-row input[type='text'] { width: 95%; }
table.dex-compare-pokemon td { line-height: 1.33; }
table.dex-compare-pokemon tbody th { text-align: left; }
table.dex-compare-pokemon tr.subheader-row th { padding: 0.33em 0.5em; font-weight: bold; }

table.dex-compare-pokemon tr.size td,
table.dex-compare-pokemon tr.size th { height: 96px; line-height: 96px; text-align: left; vertical-align: bottom; }
table.dex-compare-pokemon tr.size td { text-align: center; }
table.dex-compare-pokemon tr.size th { text-align: left; }
table.dex-compare-pokemon tr.size img { vertical-align: bottom; image-rendering: optimizeSpeed; image-rendering: -moz-crisp-edges; image-rendering: -webkit-optimize-contrast; image-rendering: -o-crisp-edges; -ms-interpolation-mode: nearest-neighbor; }
table.dex-compare-pokemon tr.dex-compare-list td { text-align: center; vertical-align: top; }
table.dex-compare-pokemon tr.dex-compare-relative td { font-size: 1.5em; padding-right: 3%; text-align: right; font-weight: bold; }
table.dex-compare-pokemon tr.dex-compare-flavor-text td { text-align: center; }
table.dex-compare-pokemon tr.dex-compare-hidden-ability td { text-align: center; font-style: italic; }
table.dex-compare-pokemon.dex-compare-pokemon-moves td { text-align: center; }
table.dex-compare-pokemon.dex-compare-pokemon-moves th.versions { text-align: left; }

/* Stat calculator */
.dex-col-stat-calc-labels { width: 8em; }
.dex-col-stat-calc { width: 4em; }
table.dex-stat-calculator { margin-bottom: 2em; }
table.dex-stat-calculator tbody th { text-align: right; vertical-align: baseline; }
table.dex-stat-calculator tbody tr.subheader-row th { text-align: left; }
table.dex-stat-calculator td { text-align: center; }
table.dex-stat-calculator td,
table.dex-stat-calculator th { line-height: 1.33; }
table.dex-stat-calculator td.impossible { text-decoration: underline; color: darkred; }
table.dex-stat-calculator td.-possible-genes { padding-left: 1em; padding-right: 1em; text-align: left; vertical-align: top; /* need this because the graph has no text, so 'baseline' pushes it way up */ }
table.dex-stat-calculator td .-valid-range { font-size: 0.8em; line-height: 2em; }
p.dex-stat-calculator-protip { font-size: 0.8em; padding-left: 1em; line-height: 1.33; text-align: left; font-style: italic; color: #606060; }
p.dex-stat-calculator-clipboard { margin-left: 4em; margin-right: 4em; padding: 0.5em 1em; font-family: monospace; background: #e8e8e8; }

div.dex-stat-graph { overflow: hidden; height: 1.5em; margin: 0 0 0.33em; border: 1px solid #c0c0c0; background: white; border-radius: 2px; }
div.dex-stat-graph div.point,
div.dex-stat-graph div.pointless { float: left; height: 1.5em; width: 0.5em; }
div.dex-stat-graph div.point { background: #c0c0c0; }

div.dex-stat-vertical-graph { width: 1.5em; margin: 0 auto; border: 1px solid #c0c0c0; background: white; border-radius: 2px; }
div.dex-stat-vertical-graph div.point,
div.dex-stat-vertical-graph div.pointless { width: 1.5em; height: 0.5em; }
div.dex-stat-vertical-graph div.point { background: #c0c0c0; }

/* Who's that Pokémon */
#js-dex-wtp { position: relative; width: 50em; height: 32em; margin: 2em auto; border: 1px solid #d0d0d0; background: #e8e8e8; }
/* Use the class on this element to toggle the game state; by default everything is hidden */
#js-dex-wtp                 #js-dex-wtp-loading  { display: none; }
#js-dex-wtp.state-loading   #js-dex-wtp-loading  { display: block; }
#js-dex-wtp                 #js-dex-wtp-options  { display: none; }
#js-dex-wtp.state-off       #js-dex-wtp-options  { display: block; }
#js-dex-wtp                 #js-dex-wtp-thinking { display: none; }
#js-dex-wtp.state-thinking  #js-dex-wtp-thinking { display: block; }
#js-dex-wtp                 #js-dex-wtp-board    { display: none; }
#js-dex-wtp.state-playing   #js-dex-wtp-board    { display: block; }
#js-dex-wtp.state-answering #js-dex-wtp-board    { display: block; }
#js-dex-wtp                 #js-dex-wtp-result   { display: none; }
#js-dex-wtp.state-answering #js-dex-wtp-result   { display: block; }
/* Starting options dialog thing */
#js-dex-wtp-options p.intro { font-size: 1.5em; margin: 0.67em; text-align: center; }
#js-dex-wtp-options ul.dex-column2 li { font-size: 1.5em; margin: 0.5em 2em; }
#js-dex-wtp-options p.go { position: absolute; left: 1em; bottom: 1em; right: 1em; text-align: center; }
#js-dex-wtp-options #js-dex-wtp-start { font-size: 2em; padding: 0.33em 2em; }
/* Questions */
#js-dex-wtp-thinking { font-size: 2em; height: 100%; width: 100%; line-height: 16em; color: #808080; text-align: center; vertical-align: middle; }
#js-dex-wtp-board { height: 75%; }
#js-dex-wtp-board .question { height: 61%; padding: 5% 1em; text-align: center; }
#js-dex-wtp-board .answer { font-size: 1.25em; height: 33%; padding: 0 3em; text-align: center; }
#js-dex-wtp-result { height: 15%; padding: 5% 3em; text-align: center; }


/*** Static pages ***/

/* Big lookup box above the Pokédex instructions */
#big-pokedex-lookup { font-size: 2em; text-align: center; }
#big-pokedex-lookup input { font-size: 1em; }


/*** Cheat codes ***/

/* Cheat code unlock page */
#dex-cheat-unlocked { overflow: hidden /* float containment */; width: 60%; margin: auto; margin-top: 10em; }
#dex-cheat-unlocked .dex-cheat-unlocked-left { float: left; }
#dex-cheat-unlocked .dex-cheat-unlocked-right { float: right; }
#dex-cheat-unlocked .dex-cheat-unlocked-line1 { font-size: 48px; font-weight: bold; text-align: center; text-transform: uppercase; }
#dex-cheat-unlocked .dex-cheat-unlocked-line2 { font-size: 34px; font-weight: bold; text-align: center; text-transform: uppercase; }
#dex-cheat-list { margin-top: 1em; margin-bottom: 5em; text-align: center; }
#dex-cheat-list li { display: inline; padding: 0.5em 1em; }
#dex-cheat-list li.this-cheat { font-weight: bold; }

/* obdurate cheat code */
p.dex-obdurate { margin: .5em 0 1.1em; line-height: 1.1; white-space: nowrap; font-size: 8px; }


/*** CSS spriting ***/
/* Versions */

/* Generations */

/* Pokémon icons */
span.sprite-icon { display: inline-block; height: 32px; width: 40px; background: url(${h.static_uri('pokedex', 'images/css-sprite-pokemon-icons.png')}) no-repeat; vertical-align: middle; }
span.sprite-icon-1{background-position:0px 0px;} span.sprite-icon-2{background-position:-40px 0px;} span.sprite-icon-3{background-position:-80px 0px;} span.sprite-icon-4{background-position:-120px 0px;} span.sprite-icon-5{background-position:-160px 0px;} span.sprite-icon-6{background-position:-200px 0px;} span.sprite-icon-7{background-position:-240px 0px;} span.sprite-icon-8{background-position:-280px 0px;} span.sprite-icon-9{background-position:-320px 0px;} span.sprite-icon-10{background-position:-360px 0px;} span.sprite-icon-11{background-position:-400px 0px;} span.sprite-icon-12{background-position:-440px 0px;} span.sprite-icon-13{background-position:-480px 0px;} span.sprite-icon-14{background-position:-520px 0px;} span.sprite-icon-15{background-position:-560px 0px;} span.sprite-icon-16{background-position:-600px 0px;} span.sprite-icon-17{background-position:-640px 0px;} span.sprite-icon-18{background-position:-680px 0px;} span.sprite-icon-19{background-position:-720px 0px;} span.sprite-icon-20{background-position:-760px 0px;} span.sprite-icon-21{background-position:-800px 0px;} span.sprite-icon-22{background-position:-840px 0px;} span.sprite-icon-23{background-position:-880px 0px;} span.sprite-icon-24{background-position:-920px 0px;} span.sprite-icon-25{background-position:-960px 0px;} span.sprite-icon-26{background-position:0px -32px;} span.sprite-icon-27{background-position:-40px -32px;} span.sprite-icon-28{background-position:-80px -32px;} span.sprite-icon-29{background-position:-120px -32px;} span.sprite-icon-30{background-position:-160px -32px;} span.sprite-icon-31{background-position:-200px -32px;} span.sprite-icon-32{background-position:-240px -32px;} span.sprite-icon-33{background-position:-280px -32px;} span.sprite-icon-34{background-position:-320px -32px;} span.sprite-icon-35{background-position:-360px -32px;} span.sprite-icon-36{background-position:-400px -32px;} span.sprite-icon-37{background-position:-440px -32px;} span.sprite-icon-38{background-position:-480px -32px;} span.sprite-icon-39{background-position:-520px -32px;} span.sprite-icon-40{background-position:-560px -32px;} span.sprite-icon-41{background-position:-600px -32px;} span.sprite-icon-42{background-position:-640px -32px;} span.sprite-icon-43{background-position:-680px -32px;} span.sprite-icon-44{background-position:-720px -32px;} span.sprite-icon-45{background-position:-760px -32px;} span.sprite-icon-46{background-position:-800px -32px;} span.sprite-icon-47{background-position:-840px -32px;} span.sprite-icon-48{background-position:-880px -32px;} span.sprite-icon-49{background-position:-920px -32px;} span.sprite-icon-50{background-position:-960px -32px;} span.sprite-icon-51{background-position:0px -64px;} span.sprite-icon-52{background-position:-40px -64px;} span.sprite-icon-53{background-position:-80px -64px;} span.sprite-icon-54{background-position:-120px -64px;} span.sprite-icon-55{background-position:-160px -64px;} span.sprite-icon-56{background-position:-200px -64px;} span.sprite-icon-57{background-position:-240px -64px;} span.sprite-icon-58{background-position:-280px -64px;} span.sprite-icon-59{background-position:-320px -64px;} span.sprite-icon-60{background-position:-360px -64px;} span.sprite-icon-61{background-position:-400px -64px;} span.sprite-icon-62{background-position:-440px -64px;} span.sprite-icon-63{background-position:-480px -64px;} span.sprite-icon-64{background-position:-520px -64px;} span.sprite-icon-65{background-position:-560px -64px;} span.sprite-icon-66{background-position:-600px -64px;} span.sprite-icon-67{background-position:-640px -64px;} span.sprite-icon-68{background-position:-680px -64px;} span.sprite-icon-69{background-position:-720px -64px;} span.sprite-icon-70{background-position:-760px -64px;} span.sprite-icon-71{background-position:-800px -64px;} span.sprite-icon-72{background-position:-840px -64px;} span.sprite-icon-73{background-position:-880px -64px;} span.sprite-icon-74{background-position:-920px -64px;} span.sprite-icon-75{background-position:-960px -64px;} span.sprite-icon-76{background-position:0px -96px;} span.sprite-icon-77{background-position:-40px -96px;} span.sprite-icon-78{background-position:-80px -96px;} span.sprite-icon-79{background-position:-120px -96px;} span.sprite-icon-80{background-position:-160px -96px;} span.sprite-icon-81{background-position:-200px -96px;} span.sprite-icon-82{background-position:-240px -96px;} span.sprite-icon-83{background-position:-280px -96px;} span.sprite-icon-84{background-position:-320px -96px;} span.sprite-icon-85{background-position:-360px -96px;} span.sprite-icon-86{background-position:-400px -96px;} span.sprite-icon-87{background-position:-440px -96px;} span.sprite-icon-88{background-position:-480px -96px;} span.sprite-icon-89{background-position:-520px -96px;} span.sprite-icon-90{background-position:-560px -96px;} span.sprite-icon-91{background-position:-600px -96px;} span.sprite-icon-92{background-position:-640px -96px;} span.sprite-icon-93{background-position:-680px -96px;} span.sprite-icon-94{background-position:-720px -96px;} span.sprite-icon-95{background-position:-760px -96px;} span.sprite-icon-96{background-position:-800px -96px;} span.sprite-icon-97{background-position:-840px -96px;} span.sprite-icon-98{background-position:-880px -96px;} span.sprite-icon-99{background-position:-920px -96px;} span.sprite-icon-100{background-position:-960px -96px;} span.sprite-icon-101{background-position:0px -128px;} span.sprite-icon-102{background-position:-40px -128px;} span.sprite-icon-103{background-position:-80px -128px;} span.sprite-icon-104{background-position:-120px -128px;} span.sprite-icon-105{background-position:-160px -128px;} span.sprite-icon-106{background-position:-200px -128px;} span.sprite-icon-107{background-position:-240px -128px;} span.sprite-icon-108{background-position:-280px -128px;} span.sprite-icon-109{background-position:-320px -128px;} span.sprite-icon-110{background-position:-360px -128px;} span.sprite-icon-111{background-position:-400px -128px;} span.sprite-icon-112{background-position:-440px -128px;} span.sprite-icon-113{background-position:-480px -128px;} span.sprite-icon-114{background-position:-520px -128px;} span.sprite-icon-115{background-position:-560px -128px;} span.sprite-icon-116{background-position:-600px -128px;} span.sprite-icon-117{background-position:-640px -128px;} span.sprite-icon-118{background-position:-680px -128px;} span.sprite-icon-119{background-position:-720px -128px;} span.sprite-icon-120{background-position:-760px -128px;} span.sprite-icon-121{background-position:-800px -128px;} span.sprite-icon-122{background-position:-840px -128px;} span.sprite-icon-123{background-position:-880px -128px;} span.sprite-icon-124{background-position:-920px -128px;} span.sprite-icon-125{background-position:-960px -128px;} span.sprite-icon-126{background-position:0px -160px;} span.sprite-icon-127{background-position:-40px -160px;} span.sprite-icon-128{background-position:-80px -160px;} span.sprite-icon-129{background-position:-120px -160px;} span.sprite-icon-130{background-position:-160px -160px;} span.sprite-icon-131{background-position:-200px -160px;} span.sprite-icon-132{background-position:-240px -160px;} span.sprite-icon-133{background-position:-280px -160px;} span.sprite-icon-134{background-position:-320px -160px;} span.sprite-icon-135{background-position:-360px -160px;} span.sprite-icon-136{background-position:-400px -160px;} span.sprite-icon-137{background-position:-440px -160px;} span.sprite-icon-138{background-position:-480px -160px;} span.sprite-icon-139{background-position:-520px -160px;} span.sprite-icon-140{background-position:-560px -160px;} span.sprite-icon-141{background-position:-600px -160px;} span.sprite-icon-142{background-position:-640px -160px;} span.sprite-icon-143{background-position:-680px -160px;} span.sprite-icon-144{background-position:-720px -160px;} span.sprite-icon-145{background-position:-760px -160px;} span.sprite-icon-146{background-position:-800px -160px;} span.sprite-icon-147{background-position:-840px -160px;} span.sprite-icon-148{background-position:-880px -160px;} span.sprite-icon-149{background-position:-920px -160px;} span.sprite-icon-150{background-position:-960px -160px;} span.sprite-icon-151{background-position:0px -192px;} span.sprite-icon-152{background-position:-40px -192px;} span.sprite-icon-153{background-position:-80px -192px;} span.sprite-icon-154{background-position:-120px -192px;} span.sprite-icon-155{background-position:-160px -192px;} span.sprite-icon-156{background-position:-200px -192px;} span.sprite-icon-157{background-position:-240px -192px;} span.sprite-icon-158{background-position:-280px -192px;} span.sprite-icon-159{background-position:-320px -192px;} span.sprite-icon-160{background-position:-360px -192px;} span.sprite-icon-161{background-position:-400px -192px;} span.sprite-icon-162{background-position:-440px -192px;} span.sprite-icon-163{background-position:-480px -192px;} span.sprite-icon-164{background-position:-520px -192px;} span.sprite-icon-165{background-position:-560px -192px;} span.sprite-icon-166{background-position:-600px -192px;} span.sprite-icon-167{background-position:-640px -192px;} span.sprite-icon-168{background-position:-680px -192px;} span.sprite-icon-169{background-position:-720px -192px;} span.sprite-icon-170{background-position:-760px -192px;} span.sprite-icon-171{background-position:-800px -192px;} span.sprite-icon-172{background-position:-840px -192px;} span.sprite-icon-173{background-position:-880px -192px;} span.sprite-icon-174{background-position:-920px -192px;} span.sprite-icon-175{background-position:-960px -192px;} span.sprite-icon-176{background-position:0px -224px;} span.sprite-icon-177{background-position:-40px -224px;} span.sprite-icon-178{background-position:-80px -224px;} span.sprite-icon-179{background-position:-120px -224px;} span.sprite-icon-180{background-position:-160px -224px;} span.sprite-icon-181{background-position:-200px -224px;} span.sprite-icon-182{background-position:-240px -224px;} span.sprite-icon-183{background-position:-280px -224px;} span.sprite-icon-184{background-position:-320px -224px;} span.sprite-icon-185{background-position:-360px -224px;} span.sprite-icon-186{background-position:-400px -224px;} span.sprite-icon-187{background-position:-440px -224px;} span.sprite-icon-188{background-position:-480px -224px;} span.sprite-icon-189{background-position:-520px -224px;} span.sprite-icon-190{background-position:-560px -224px;} span.sprite-icon-191{background-position:-600px -224px;} span.sprite-icon-192{background-position:-640px -224px;} span.sprite-icon-193{background-position:-680px -224px;} span.sprite-icon-194{background-position:-720px -224px;} span.sprite-icon-195{background-position:-760px -224px;} span.sprite-icon-196{background-position:-800px -224px;} span.sprite-icon-197{background-position:-840px -224px;} span.sprite-icon-198{background-position:-880px -224px;} span.sprite-icon-199{background-position:-920px -224px;} span.sprite-icon-200{background-position:-960px -224px;} span.sprite-icon-201{background-position:0px -256px;} span.sprite-icon-202{background-position:-40px -256px;} span.sprite-icon-203{background-position:-80px -256px;} span.sprite-icon-204{background-position:-120px -256px;} span.sprite-icon-205{background-position:-160px -256px;} span.sprite-icon-206{background-position:-200px -256px;} span.sprite-icon-207{background-position:-240px -256px;} span.sprite-icon-208{background-position:-280px -256px;} span.sprite-icon-209{background-position:-320px -256px;} span.sprite-icon-210{background-position:-360px -256px;} span.sprite-icon-211{background-position:-400px -256px;} span.sprite-icon-212{background-position:-440px -256px;} span.sprite-icon-213{background-position:-480px -256px;} span.sprite-icon-214{background-position:-520px -256px;} span.sprite-icon-215{background-position:-560px -256px;} span.sprite-icon-216{background-position:-600px -256px;} span.sprite-icon-217{background-position:-640px -256px;} span.sprite-icon-218{background-position:-680px -256px;} span.sprite-icon-219{background-position:-720px -256px;} span.sprite-icon-220{background-position:-760px -256px;} span.sprite-icon-221{background-position:-800px -256px;} span.sprite-icon-222{background-position:-840px -256px;} span.sprite-icon-223{background-position:-880px -256px;} span.sprite-icon-224{background-position:-920px -256px;} span.sprite-icon-225{background-position:-960px -256px;} span.sprite-icon-226{background-position:0px -288px;} span.sprite-icon-227{background-position:-40px -288px;} span.sprite-icon-228{background-position:-80px -288px;} span.sprite-icon-229{background-position:-120px -288px;} span.sprite-icon-230{background-position:-160px -288px;} span.sprite-icon-231{background-position:-200px -288px;} span.sprite-icon-232{background-position:-240px -288px;} span.sprite-icon-233{background-position:-280px -288px;} span.sprite-icon-234{background-position:-320px -288px;} span.sprite-icon-235{background-position:-360px -288px;} span.sprite-icon-236{background-position:-400px -288px;} span.sprite-icon-237{background-position:-440px -288px;} span.sprite-icon-238{background-position:-480px -288px;} span.sprite-icon-239{background-position:-520px -288px;} span.sprite-icon-240{background-position:-560px -288px;} span.sprite-icon-241{background-position:-600px -288px;} span.sprite-icon-242{background-position:-640px -288px;} span.sprite-icon-243{background-position:-680px -288px;} span.sprite-icon-244{background-position:-720px -288px;} span.sprite-icon-245{background-position:-760px -288px;} span.sprite-icon-246{background-position:-800px -288px;} span.sprite-icon-247{background-position:-840px -288px;} span.sprite-icon-248{background-position:-880px -288px;} span.sprite-icon-249{background-position:-920px -288px;} span.sprite-icon-250{background-position:-960px -288px;} span.sprite-icon-251{background-position:0px -320px;} span.sprite-icon-252{background-position:-40px -320px;} span.sprite-icon-253{background-position:-80px -320px;} span.sprite-icon-254{background-position:-120px -320px;} span.sprite-icon-255{background-position:-160px -320px;} span.sprite-icon-256{background-position:-200px -320px;} span.sprite-icon-257{background-position:-240px -320px;} span.sprite-icon-258{background-position:-280px -320px;} span.sprite-icon-259{background-position:-320px -320px;} span.sprite-icon-260{background-position:-360px -320px;} span.sprite-icon-261{background-position:-400px -320px;} span.sprite-icon-262{background-position:-440px -320px;} span.sprite-icon-263{background-position:-480px -320px;} span.sprite-icon-264{background-position:-520px -320px;} span.sprite-icon-265{background-position:-560px -320px;} span.sprite-icon-266{background-position:-600px -320px;} span.sprite-icon-267{background-position:-640px -320px;} span.sprite-icon-268{background-position:-680px -320px;} span.sprite-icon-269{background-position:-720px -320px;} span.sprite-icon-270{background-position:-760px -320px;} span.sprite-icon-271{background-position:-800px -320px;} span.sprite-icon-272{background-position:-840px -320px;} span.sprite-icon-273{background-position:-880px -320px;} span.sprite-icon-274{background-position:-920px -320px;} span.sprite-icon-275{background-position:-960px -320px;} span.sprite-icon-276{background-position:0px -352px;} span.sprite-icon-277{background-position:-40px -352px;} span.sprite-icon-278{background-position:-80px -352px;} span.sprite-icon-279{background-position:-120px -352px;} span.sprite-icon-280{background-position:-160px -352px;} span.sprite-icon-281{background-position:-200px -352px;} span.sprite-icon-282{background-position:-240px -352px;} span.sprite-icon-283{background-position:-280px -352px;} span.sprite-icon-284{background-position:-320px -352px;} span.sprite-icon-285{background-position:-360px -352px;} span.sprite-icon-286{background-position:-400px -352px;} span.sprite-icon-287{background-position:-440px -352px;} span.sprite-icon-288{background-position:-480px -352px;} span.sprite-icon-289{background-position:-520px -352px;} span.sprite-icon-290{background-position:-560px -352px;} span.sprite-icon-291{background-position:-600px -352px;} span.sprite-icon-292{background-position:-640px -352px;} span.sprite-icon-293{background-position:-680px -352px;} span.sprite-icon-294{background-position:-720px -352px;} span.sprite-icon-295{background-position:-760px -352px;} span.sprite-icon-296{background-position:-800px -352px;} span.sprite-icon-297{background-position:-840px -352px;} span.sprite-icon-298{background-position:-880px -352px;} span.sprite-icon-299{background-position:-920px -352px;} span.sprite-icon-300{background-position:-960px -352px;} span.sprite-icon-301{background-position:0px -384px;} span.sprite-icon-302{background-position:-40px -384px;} span.sprite-icon-303{background-position:-80px -384px;} span.sprite-icon-304{background-position:-120px -384px;} span.sprite-icon-305{background-position:-160px -384px;} span.sprite-icon-306{background-position:-200px -384px;} span.sprite-icon-307{background-position:-240px -384px;} span.sprite-icon-308{background-position:-280px -384px;} span.sprite-icon-309{background-position:-320px -384px;} span.sprite-icon-310{background-position:-360px -384px;} span.sprite-icon-311{background-position:-400px -384px;} span.sprite-icon-312{background-position:-440px -384px;} span.sprite-icon-313{background-position:-480px -384px;} span.sprite-icon-314{background-position:-520px -384px;} span.sprite-icon-315{background-position:-560px -384px;} span.sprite-icon-316{background-position:-600px -384px;} span.sprite-icon-317{background-position:-640px -384px;} span.sprite-icon-318{background-position:-680px -384px;} span.sprite-icon-319{background-position:-720px -384px;} span.sprite-icon-320{background-position:-760px -384px;} span.sprite-icon-321{background-position:-800px -384px;} span.sprite-icon-322{background-position:-840px -384px;} span.sprite-icon-323{background-position:-880px -384px;} span.sprite-icon-324{background-position:-920px -384px;} span.sprite-icon-325{background-position:-960px -384px;} span.sprite-icon-326{background-position:0px -416px;} span.sprite-icon-327{background-position:-40px -416px;} span.sprite-icon-328{background-position:-80px -416px;} span.sprite-icon-329{background-position:-120px -416px;} span.sprite-icon-330{background-position:-160px -416px;} span.sprite-icon-331{background-position:-200px -416px;} span.sprite-icon-332{background-position:-240px -416px;} span.sprite-icon-333{background-position:-280px -416px;} span.sprite-icon-334{background-position:-320px -416px;} span.sprite-icon-335{background-position:-360px -416px;} span.sprite-icon-336{background-position:-400px -416px;} span.sprite-icon-337{background-position:-440px -416px;} span.sprite-icon-338{background-position:-480px -416px;} span.sprite-icon-339{background-position:-520px -416px;} span.sprite-icon-340{background-position:-560px -416px;} span.sprite-icon-341{background-position:-600px -416px;} span.sprite-icon-342{background-position:-640px -416px;} span.sprite-icon-343{background-position:-680px -416px;} span.sprite-icon-344{background-position:-720px -416px;} span.sprite-icon-345{background-position:-760px -416px;} span.sprite-icon-346{background-position:-800px -416px;} span.sprite-icon-347{background-position:-840px -416px;} span.sprite-icon-348{background-position:-880px -416px;} span.sprite-icon-349{background-position:-920px -416px;} span.sprite-icon-350{background-position:-960px -416px;} span.sprite-icon-351{background-position:0px -448px;} span.sprite-icon-352{background-position:-40px -448px;} span.sprite-icon-353{background-position:-80px -448px;} span.sprite-icon-354{background-position:-120px -448px;} span.sprite-icon-355{background-position:-160px -448px;} span.sprite-icon-356{background-position:-200px -448px;} span.sprite-icon-357{background-position:-240px -448px;} span.sprite-icon-358{background-position:-280px -448px;} span.sprite-icon-359{background-position:-320px -448px;} span.sprite-icon-360{background-position:-360px -448px;} span.sprite-icon-361{background-position:-400px -448px;} span.sprite-icon-362{background-position:-440px -448px;} span.sprite-icon-363{background-position:-480px -448px;} span.sprite-icon-364{background-position:-520px -448px;} span.sprite-icon-365{background-position:-560px -448px;} span.sprite-icon-366{background-position:-600px -448px;} span.sprite-icon-367{background-position:-640px -448px;} span.sprite-icon-368{background-position:-680px -448px;} span.sprite-icon-369{background-position:-720px -448px;} span.sprite-icon-370{background-position:-760px -448px;} span.sprite-icon-371{background-position:-800px -448px;} span.sprite-icon-372{background-position:-840px -448px;} span.sprite-icon-373{background-position:-880px -448px;} span.sprite-icon-374{background-position:-920px -448px;} span.sprite-icon-375{background-position:-960px -448px;} span.sprite-icon-376{background-position:0px -480px;} span.sprite-icon-377{background-position:-40px -480px;} span.sprite-icon-378{background-position:-80px -480px;} span.sprite-icon-379{background-position:-120px -480px;} span.sprite-icon-380{background-position:-160px -480px;} span.sprite-icon-381{background-position:-200px -480px;} span.sprite-icon-382{background-position:-240px -480px;} span.sprite-icon-383{background-position:-280px -480px;} span.sprite-icon-384{background-position:-320px -480px;} span.sprite-icon-385{background-position:-360px -480px;} span.sprite-icon-386{background-position:-400px -480px;} span.sprite-icon-387{background-position:-440px -480px;} span.sprite-icon-388{background-position:-480px -480px;} span.sprite-icon-389{background-position:-520px -480px;} span.sprite-icon-390{background-position:-560px -480px;} span.sprite-icon-391{background-position:-600px -480px;} span.sprite-icon-392{background-position:-640px -480px;} span.sprite-icon-393{background-position:-680px -480px;} span.sprite-icon-394{background-position:-720px -480px;} span.sprite-icon-395{background-position:-760px -480px;} span.sprite-icon-396{background-position:-800px -480px;} span.sprite-icon-397{background-position:-840px -480px;} span.sprite-icon-398{background-position:-880px -480px;} span.sprite-icon-399{background-position:-920px -480px;} span.sprite-icon-400{background-position:-960px -480px;} span.sprite-icon-401{background-position:0px -512px;} span.sprite-icon-402{background-position:-40px -512px;} span.sprite-icon-403{background-position:-80px -512px;} span.sprite-icon-404{background-position:-120px -512px;} span.sprite-icon-405{background-position:-160px -512px;} span.sprite-icon-406{background-position:-200px -512px;} span.sprite-icon-407{background-position:-240px -512px;} span.sprite-icon-408{background-position:-280px -512px;} span.sprite-icon-409{background-position:-320px -512px;} span.sprite-icon-410{background-position:-360px -512px;} span.sprite-icon-411{background-position:-400px -512px;} span.sprite-icon-412{background-position:-440px -512px;} span.sprite-icon-413{background-position:-480px -512px;} span.sprite-icon-414{background-position:-520px -512px;} span.sprite-icon-415{background-position:-560px -512px;} span.sprite-icon-416{background-position:-600px -512px;} span.sprite-icon-417{background-position:-640px -512px;} span.sprite-icon-418{background-position:-680px -512px;} span.sprite-icon-419{background-position:-720px -512px;} span.sprite-icon-420{background-position:-760px -512px;} span.sprite-icon-421{background-position:-800px -512px;} span.sprite-icon-422{background-position:-840px -512px;} span.sprite-icon-423{background-position:-880px -512px;} span.sprite-icon-424{background-position:-920px -512px;} span.sprite-icon-425{background-position:-960px -512px;} span.sprite-icon-426{background-position:0px -544px;} span.sprite-icon-427{background-position:-40px -544px;} span.sprite-icon-428{background-position:-80px -544px;} span.sprite-icon-429{background-position:-120px -544px;} span.sprite-icon-430{background-position:-160px -544px;} span.sprite-icon-431{background-position:-200px -544px;} span.sprite-icon-432{background-position:-240px -544px;} span.sprite-icon-433{background-position:-280px -544px;} span.sprite-icon-434{background-position:-320px -544px;} span.sprite-icon-435{background-position:-360px -544px;} span.sprite-icon-436{background-position:-400px -544px;} span.sprite-icon-437{background-position:-440px -544px;} span.sprite-icon-438{background-position:-480px -544px;} span.sprite-icon-439{background-position:-520px -544px;} span.sprite-icon-440{background-position:-560px -544px;} span.sprite-icon-441{background-position:-600px -544px;} span.sprite-icon-442{background-position:-640px -544px;} span.sprite-icon-443{background-position:-680px -544px;} span.sprite-icon-444{background-position:-720px -544px;} span.sprite-icon-445{background-position:-760px -544px;} span.sprite-icon-446{background-position:-800px -544px;} span.sprite-icon-447{background-position:-840px -544px;} span.sprite-icon-448{background-position:-880px -544px;} span.sprite-icon-449{background-position:-920px -544px;} span.sprite-icon-450{background-position:-960px -544px;} span.sprite-icon-451{background-position:0px -576px;} span.sprite-icon-452{background-position:-40px -576px;} span.sprite-icon-453{background-position:-80px -576px;} span.sprite-icon-454{background-position:-120px -576px;} span.sprite-icon-455{background-position:-160px -576px;} span.sprite-icon-456{background-position:-200px -576px;} span.sprite-icon-457{background-position:-240px -576px;} span.sprite-icon-458{background-position:-280px -576px;} span.sprite-icon-459{background-position:-320px -576px;} span.sprite-icon-460{background-position:-360px -576px;} span.sprite-icon-461{background-position:-400px -576px;} span.sprite-icon-462{background-position:-440px -576px;} span.sprite-icon-463{background-position:-480px -576px;} span.sprite-icon-464{background-position:-520px -576px;} span.sprite-icon-465{background-position:-560px -576px;} span.sprite-icon-466{background-position:-600px -576px;} span.sprite-icon-467{background-position:-640px -576px;} span.sprite-icon-468{background-position:-680px -576px;} span.sprite-icon-469{background-position:-720px -576px;} span.sprite-icon-470{background-position:-760px -576px;} span.sprite-icon-471{background-position:-800px -576px;} span.sprite-icon-472{background-position:-840px -576px;} span.sprite-icon-473{background-position:-880px -576px;} span.sprite-icon-474{background-position:-920px -576px;} span.sprite-icon-475{background-position:-960px -576px;} span.sprite-icon-476{background-position:0px -608px;} span.sprite-icon-477{background-position:-40px -608px;} span.sprite-icon-478{background-position:-80px -608px;} span.sprite-icon-479{background-position:-120px -608px;} span.sprite-icon-480{background-position:-160px -608px;} span.sprite-icon-481{background-position:-200px -608px;} span.sprite-icon-482{background-position:-240px -608px;} span.sprite-icon-483{background-position:-280px -608px;} span.sprite-icon-484{background-position:-320px -608px;} span.sprite-icon-485{background-position:-360px -608px;} span.sprite-icon-486{background-position:-400px -608px;} span.sprite-icon-487{background-position:-440px -608px;} span.sprite-icon-488{background-position:-480px -608px;} span.sprite-icon-489{background-position:-520px -608px;} span.sprite-icon-490{background-position:-560px -608px;} span.sprite-icon-491{background-position:-600px -608px;} span.sprite-icon-492{background-position:-640px -608px;} span.sprite-icon-493{background-position:-680px -608px;} span.sprite-icon-494{background-position:-720px -608px;} span.sprite-icon-495{background-position:-760px -608px;} span.sprite-icon-496{background-position:-800px -608px;} span.sprite-icon-497{background-position:-840px -608px;} span.sprite-icon-498{background-position:-880px -608px;} span.sprite-icon-499{background-position:-920px -608px;} span.sprite-icon-500{background-position:-960px -608px;} span.sprite-icon-501{background-position:0px -640px;} span.sprite-icon-502{background-position:-40px -640px;} span.sprite-icon-503{background-position:-80px -640px;} span.sprite-icon-504{background-position:-120px -640px;} span.sprite-icon-505{background-position:-160px -640px;} span.sprite-icon-506{background-position:-200px -640px;} span.sprite-icon-507{background-position:-240px -640px;} span.sprite-icon-508{background-position:-280px -640px;} span.sprite-icon-509{background-position:-320px -640px;} span.sprite-icon-510{background-position:-360px -640px;} span.sprite-icon-511{background-position:-400px -640px;} span.sprite-icon-512{background-position:-440px -640px;} span.sprite-icon-513{background-position:-480px -640px;} span.sprite-icon-514{background-position:-520px -640px;} span.sprite-icon-515{background-position:-560px -640px;} span.sprite-icon-516{background-position:-600px -640px;} span.sprite-icon-517{background-position:-640px -640px;} span.sprite-icon-518{background-position:-680px -640px;} span.sprite-icon-519{background-position:-720px -640px;} span.sprite-icon-520{background-position:-760px -640px;} span.sprite-icon-521{background-position:-800px -640px;} span.sprite-icon-522{background-position:-840px -640px;} span.sprite-icon-523{background-position:-880px -640px;} span.sprite-icon-524{background-position:-920px -640px;} span.sprite-icon-525{background-position:-960px -640px;} span.sprite-icon-526{background-position:0px -672px;} span.sprite-icon-527{background-position:-40px -672px;} span.sprite-icon-528{background-position:-80px -672px;} span.sprite-icon-529{background-position:-120px -672px;} span.sprite-icon-530{background-position:-160px -672px;} span.sprite-icon-531{background-position:-200px -672px;} span.sprite-icon-532{background-position:-240px -672px;} span.sprite-icon-533{background-position:-280px -672px;} span.sprite-icon-534{background-position:-320px -672px;} span.sprite-icon-535{background-position:-360px -672px;} span.sprite-icon-536{background-position:-400px -672px;} span.sprite-icon-537{background-position:-440px -672px;} span.sprite-icon-538{background-position:-480px -672px;} span.sprite-icon-539{background-position:-520px -672px;} span.sprite-icon-540{background-position:-560px -672px;} span.sprite-icon-541{background-position:-600px -672px;} span.sprite-icon-542{background-position:-640px -672px;} span.sprite-icon-543{background-position:-680px -672px;} span.sprite-icon-544{background-position:-720px -672px;} span.sprite-icon-545{background-position:-760px -672px;} span.sprite-icon-546{background-position:-800px -672px;} span.sprite-icon-547{background-position:-840px -672px;} span.sprite-icon-548{background-position:-880px -672px;} span.sprite-icon-549{background-position:-920px -672px;} span.sprite-icon-550{background-position:-960px -672px;} span.sprite-icon-551{background-position:0px -704px;} span.sprite-icon-552{background-position:-40px -704px;} span.sprite-icon-553{background-position:-80px -704px;} span.sprite-icon-554{background-position:-120px -704px;} span.sprite-icon-555{background-position:-160px -704px;} span.sprite-icon-556{background-position:-200px -704px;} span.sprite-icon-557{background-position:-240px -704px;} span.sprite-icon-558{background-position:-280px -704px;} span.sprite-icon-559{background-position:-320px -704px;} span.sprite-icon-560{background-position:-360px -704px;} span.sprite-icon-561{background-position:-400px -704px;} span.sprite-icon-562{background-position:-440px -704px;} span.sprite-icon-563{background-position:-480px -704px;} span.sprite-icon-564{background-position:-520px -704px;} span.sprite-icon-565{background-position:-560px -704px;} span.sprite-icon-566{background-position:-600px -704px;} span.sprite-icon-567{background-position:-640px -704px;} span.sprite-icon-568{background-position:-680px -704px;} span.sprite-icon-569{background-position:-720px -704px;} span.sprite-icon-570{background-position:-760px -704px;} span.sprite-icon-571{background-position:-800px -704px;} span.sprite-icon-572{background-position:-840px -704px;} span.sprite-icon-573{background-position:-880px -704px;} span.sprite-icon-574{background-position:-920px -704px;} span.sprite-icon-575{background-position:-960px -704px;} span.sprite-icon-576{background-position:0px -736px;} span.sprite-icon-577{background-position:-40px -736px;} span.sprite-icon-578{background-position:-80px -736px;} span.sprite-icon-579{background-position:-120px -736px;} span.sprite-icon-580{background-position:-160px -736px;} span.sprite-icon-581{background-position:-200px -736px;} span.sprite-icon-582{background-position:-240px -736px;} span.sprite-icon-583{background-position:-280px -736px;} span.sprite-icon-584{background-position:-320px -736px;} span.sprite-icon-585{background-position:-360px -736px;} span.sprite-icon-586{background-position:-400px -736px;} span.sprite-icon-587{background-position:-440px -736px;} span.sprite-icon-588{background-position:-480px -736px;} span.sprite-icon-589{background-position:-520px -736px;} span.sprite-icon-590{background-position:-560px -736px;} span.sprite-icon-591{background-position:-600px -736px;} span.sprite-icon-592{background-position:-640px -736px;} span.sprite-icon-593{background-position:-680px -736px;} span.sprite-icon-594{background-position:-720px -736px;} span.sprite-icon-595{background-position:-760px -736px;} span.sprite-icon-596{background-position:-800px -736px;} span.sprite-icon-597{background-position:-840px -736px;} span.sprite-icon-598{background-position:-880px -736px;} span.sprite-icon-599{background-position:-920px -736px;} span.sprite-icon-600{background-position:-960px -736px;} span.sprite-icon-601{background-position:0px -768px;} span.sprite-icon-602{background-position:-40px -768px;} span.sprite-icon-603{background-position:-80px -768px;} span.sprite-icon-604{background-position:-120px -768px;} span.sprite-icon-605{background-position:-160px -768px;} span.sprite-icon-606{background-position:-200px -768px;} span.sprite-icon-607{background-position:-240px -768px;} span.sprite-icon-608{background-position:-280px -768px;} span.sprite-icon-609{background-position:-320px -768px;} span.sprite-icon-610{background-position:-360px -768px;} span.sprite-icon-611{background-position:-400px -768px;} span.sprite-icon-612{background-position:-440px -768px;} span.sprite-icon-613{background-position:-480px -768px;} span.sprite-icon-614{background-position:-520px -768px;} span.sprite-icon-615{background-position:-560px -768px;} span.sprite-icon-616{background-position:-600px -768px;} span.sprite-icon-617{background-position:-640px -768px;} span.sprite-icon-618{background-position:-680px -768px;} span.sprite-icon-619{background-position:-720px -768px;} span.sprite-icon-620{background-position:-760px -768px;} span.sprite-icon-621{background-position:-800px -768px;} span.sprite-icon-622{background-position:-840px -768px;} span.sprite-icon-623{background-position:-880px -768px;} span.sprite-icon-624{background-position:-920px -768px;} span.sprite-icon-625{background-position:-960px -768px;} span.sprite-icon-626{background-position:0px -800px;} span.sprite-icon-627{background-position:-40px -800px;} span.sprite-icon-628{background-position:-80px -800px;} span.sprite-icon-629{background-position:-120px -800px;} span.sprite-icon-630{background-position:-160px -800px;} span.sprite-icon-631{background-position:-200px -800px;} span.sprite-icon-632{background-position:-240px -800px;} span.sprite-icon-633{background-position:-280px -800px;} span.sprite-icon-634{background-position:-320px -800px;} span.sprite-icon-635{background-position:-360px -800px;} span.sprite-icon-636{background-position:-400px -800px;} span.sprite-icon-637{background-position:-440px -800px;} span.sprite-icon-638{background-position:-480px -800px;} span.sprite-icon-639{background-position:-520px -800px;} span.sprite-icon-640{background-position:-560px -800px;} span.sprite-icon-641{background-position:-600px -800px;} span.sprite-icon-642{background-position:-640px -800px;} span.sprite-icon-643{background-position:-680px -800px;} span.sprite-icon-644{background-position:-720px -800px;} span.sprite-icon-645{background-position:-760px -800px;} span.sprite-icon-646{background-position:-800px -800px;} span.sprite-icon-647{background-position:-840px -800px;} span.sprite-icon-648{background-position:-880px -800px;} span.sprite-icon-649{background-position:-920px -800px;} span.sprite-icon-650{background-position:-960px -800px;} span.sprite-icon-651{background-position:0px -832px;} span.sprite-icon-652{background-position:-40px -832px;} span.sprite-icon-653{background-position:-80px -832px;} span.sprite-icon-654{background-position:-120px -832px;} span.sprite-icon-655{background-position:-160px -832px;} span.sprite-icon-656{background-position:-200px -832px;} span.sprite-icon-657{background-position:-240px -832px;} span.sprite-icon-658{background-position:-280px -832px;} span.sprite-icon-659{background-position:-320px -832px;} span.sprite-icon-660{background-position:-360px -832px;} span.sprite-icon-661{background-position:-400px -832px;} span.sprite-icon-662{background-position:-440px -832px;} span.sprite-icon-663{background-position:-480px -832px;} span.sprite-icon-664{background-position:-520px -832px;} span.sprite-icon-665{background-position:-560px -832px;} span.sprite-icon-666{background-position:-600px -832px;} span.sprite-icon-667{background-position:-640px -832px;} span.sprite-icon-668{background-position:-680px -832px;} span.sprite-icon-669{background-position:-720px -832px;} span.sprite-icon-670{background-position:-760px -832px;} span.sprite-icon-671{background-position:-800px -832px;} span.sprite-icon-672{background-position:-840px -832px;} span.sprite-icon-673{background-position:-880px -832px;} span.sprite-icon-674{background-position:-920px -832px;} span.sprite-icon-675{background-position:-960px -832px;} span.sprite-icon-676{background-position:0px -864px;} span.sprite-icon-677{background-position:-40px -864px;} span.sprite-icon-678{background-position:-80px -864px;} span.sprite-icon-679{background-position:-120px -864px;} span.sprite-icon-680{background-position:-160px -864px;} span.sprite-icon-681{background-position:-200px -864px;} span.sprite-icon-682{background-position:-240px -864px;} span.sprite-icon-683{background-position:-280px -864px;} span.sprite-icon-684{background-position:-320px -864px;} span.sprite-icon-685{background-position:-360px -864px;} span.sprite-icon-686{background-position:-400px -864px;} span.sprite-icon-687{background-position:-440px -864px;} span.sprite-icon-688{background-position:-480px -864px;} span.sprite-icon-689{background-position:-520px -864px;} span.sprite-icon-690{background-position:-560px -864px;} span.sprite-icon-691{background-position:-600px -864px;} span.sprite-icon-692{background-position:-640px -864px;} span.sprite-icon-693{background-position:-680px -864px;} span.sprite-icon-694{background-position:-720px -864px;} span.sprite-icon-695{background-position:-760px -864px;} span.sprite-icon-696{background-position:-800px -864px;} span.sprite-icon-697{background-position:-840px -864px;} span.sprite-icon-698{background-position:-880px -864px;} span.sprite-icon-699{background-position:-920px -864px;} span.sprite-icon-700{background-position:-960px -864px;} span.sprite-icon-701{background-position:0px -896px;} span.sprite-icon-702{background-position:-40px -896px;} span.sprite-icon-703{background-position:-80px -896px;} span.sprite-icon-704{background-position:-120px -896px;} span.sprite-icon-705{background-position:-160px -896px;} span.sprite-icon-706{background-position:-200px -896px;} span.sprite-icon-707{background-position:-240px -896px;} span.sprite-icon-708{background-position:-280px -896px;} span.sprite-icon-709{background-position:-320px -896px;} span.sprite-icon-710{background-position:-360px -896px;} span.sprite-icon-711{background-position:-400px -896px;} span.sprite-icon-712{background-position:-440px -896px;} span.sprite-icon-713{background-position:-480px -896px;} span.sprite-icon-714{background-position:-520px -896px;} span.sprite-icon-715{background-position:-560px -896px;} span.sprite-icon-716{background-position:-600px -896px;} span.sprite-icon-717{background-position:-640px -896px;} span.sprite-icon-718{background-position:-680px -896px;}
