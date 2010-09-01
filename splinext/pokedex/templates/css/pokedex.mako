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
.dex-nature-buff { font-weight: bold; color: green; }
.dex-nature-nerf { font-weight: bold; color: red; }

/* Links to Pokémon search */
dd .dex-subtle-search-link { visibility: hidden; }
dd:hover .dex-subtle-search-link { visibility: visible; }


/*** General tables ***/

/* Columns woo */
/* nb: these columns *include* cell padding */
col.dex-col-icon        { width: 32px; }
col.dex-col-name        { width: 10em; }
col.dex-col-link        { width: 16px; }
col.dex-col-max-exp     { width: 7em; }
col.dex-col-ability     { width: 8em; }
col.dex-col-gender      { width: 7em; }
col.dex-col-egg-group   { width: 7em; }
col.dex-col-height      { width: 5em; }
col.dex-col-weight      { width: 6em; }
col.dex-col-species     { width: 8em; }
col.dex-col-color       { width: 5em; }
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
table.dex-pokemon-moves { table-layout: fixed; }
table.dex-pokemon-pokemon-moves { width: 100%; }
table.dex-pokemon-moves td { padding: 0.33em; vertical-align: middle; text-align: center; }
table.dex-pokemon-moves th { padding: 0.33em 0.17em; text-align: center; }
table.dex-pokemon-moves tr.header-row { border-top: 2px solid #668dcc; }
table.dex-pokemon-moves tr.subheader-row th { padding: 0.17em 0.33em; text-align: left; }
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
table.dex-pokemon-moves td.size { text-align: right; }
table.dex-pokemon-moves td.color { }
table.dex-pokemon-moves td.species { }
table.dex-pokemon-moves td.effort { font-size: 0.75em; padding: 0.25em; text-align: left; }
table.dex-pokemon-moves tr.better-move-type:nth-child(2n) td.type,
table.dex-pokemon-moves tr.better-move-type:nth-child(2n) td.type2,
table.dex-pokemon-moves tr.better-move-stat-physical:nth-child(2n) td.stat-attack,
table.dex-pokemon-moves tr.better-move-stat-special:nth-child(2n) td.stat-special-attack,
table.dex-pokemon-moves tr.better-move-stat:nth-child(2n) td.class { background: #afcfaf; }
table.dex-pokemon-moves tr.better-move-type:nth-child(2n+1) td.type,
table.dex-pokemon-moves tr.better-move-type:nth-child(2n+1) td.type2,
table.dex-pokemon-moves tr.better-move-stat-physical:nth-child(2n+1) td.stat-attack,
table.dex-pokemon-moves tr.better-move-stat-special:nth-child(2n+1) td.stat-special-attack,
table.dex-pokemon-moves tr.better-move-stat:nth-child(2n+1) td.class { background: #c0d8c0; }

/* "Sorting" Pokémon search results by evolution chain */
table.dex-pokemon-moves tr.fake-result td { opacity: 0.25; }
table.dex-pokemon-moves tr.chain-divider { border-top: 2px solid #b4c7e6; }
table.dex-pokemon-moves tr.evolution-depth-0 td.name { text-align: left; }
table.dex-pokemon-moves tr.evolution-depth-1 td.name { padding-left: 1em; text-align: left; }
table.dex-pokemon-moves tr.evolution-depth-2 td.name { padding-left: 2em; text-align: left; }
table.dex-pokemon-moves tr.evolution-depth-3 td.name { padding-left: 3em; text-align: left; }

/* JavaScript filtering/sorting */
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
#dex-pokemon-portrait-sprite { height: 80px; width: 80px; margin: 0.33em auto; padding: 7px; line-height: 80px; vertical-align: middle; text-align: center; background: url(/dex/media/chrome/sprite-frame.png) center center no-repeat; }

/* List of types with damage (or whatever) below */
ul.dex-type-list { overflow: hidden /* new float context */; margin-bottom: 2em; }
ul.dex-type-list li { display: inline-block; text-align: center; padding: 0.125em; }
ul.dex-type-list li img { display: block; margin-bottom: 0.25em; }

/* Size comparison -- used by Pokémon and flavor */
.dex-size { height: 120px; padding-bottom: 2.5em /* for -value */; overflow: hidden /* new float context */}
.dex-size img { clip: 8px; position: absolute; bottom: 0; image-rendering: -moz-crisp-edges; -ms-interpolation-mode: nearest-neighbor; }
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


/*** Individual pages ***/

/* Pokémon page -- ability list */
dl.pokemon-abilities p { margin: 0; padding: 0; }

/* Pokémon page -- grid of compatible breeding partners */
ul.dex-pokemon-compatibility { max-height: 136px /* four rows of icons plus borders */; overflow: auto; }

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
.dex-evolution-chain-pokemon img { float: left; margin-top: -8px /* fills link's top padding */; padding-right: 0.33em; }

/* Pokémon page -- stats table */
table.dex-pokemon-stats { width: 100%; }
table.dex-pokemon-stats th label { display: block; text-align: right; font-weight: normal; color: #2457a0; }
table.dex-pokemon-stats th input { text-align: left; }
table.dex-pokemon-stats .dex-pokemon-stats-bar-container { background: #f8f8f8; }
table.dex-pokemon-stats .dex-pokemon-stats-bar { padding: 0.33em; border: 1px solid #d8d8d8; background: #f0f0f0; }
table.dex-pokemon-stats td.dex-pokemon-stats-pctile { text-align: right; }
table.dex-pokemon-stats td.dex-pokemon-stats-result { text-align: right; }

/* Pokémon page -- simple-encounters list */
.dex-simple-encounters-terrain { margin-bottom: 0.5em; }
dl.dex-simple-encounters dd img { vertical-align: bottom; }
dl.dex-simple-encounters ul { display: inline; }
dl.dex-simple-encounters ul li { display: inline; }
dl.dex-simple-encounters ul li:after { content: '; '; }
dl.dex-simple-encounters ul li:last-child:after { content: ''; }

/* Pokémon page -- cry */
/* Mozilla's player changes its height proportionate to its width by default or something */
audio.cry { width: 100%; height: 35px; }

/* Pokémon flavor page -- tables of sprites */
table.dex-pokemon-flavor-sprites td { vertical-align: middle /* sprites aren't always the same height within a row */; }
table.dex-pokemon-flavor-sprites td.dex-pokemon-flavor-no-sprite { text-align: center; }

/* Pokémon flavor page -- RBY sprite needs doublesizin' */
.dex-pokemon-flavor-rby-back img { width: 64px; image-rendering: -moz-crisp-edges; -ms-interpolation-mode: nearest-neighbor; }

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
table.dex-compare-pokemon col.labels { width: 10em; }
table.dex-compare-pokemon .dex-compare-suggestions th { padding: 0.5em; vertical-align: bottom; text-align: left; }
table.dex-compare-pokemon .header-row input[type='text'] { width: 95%; }
table.dex-compare-pokemon td { line-height: 1.33; }
table.dex-compare-pokemon tbody th { text-align: left; }
table.dex-compare-pokemon tr.subheader-row th { padding: 0.33em 0.5em; font-weight: bold; }

table.dex-compare-pokemon tr.size td,
table.dex-compare-pokemon tr.size th { height: 96px; line-height: 96px; text-align: left; vertical-align: bottom; }
table.dex-compare-pokemon tr.size td { text-align: center; }
table.dex-compare-pokemon tr.size th { text-align: left; }
table.dex-compare-pokemon tr.size img { vertical-align: bottom; image-rendering: -moz-crisp-edges; -ms-interpolation-mode: nearest-neighbor; }
table.dex-compare-pokemon tr.dex-compare-list td { text-align: center; vertical-align: top; }
table.dex-compare-pokemon tr.dex-compare-relative td { font-size: 1.5em; padding-right: 3%; text-align: right; font-weight: bold; }
table.dex-compare-pokemon tr.dex-compare-flavor-text td { text-align: center; }
table.dex-compare-pokemon.dex-compare-pokemon-moves td { text-align: center; }
table.dex-compare-pokemon.dex-compare-pokemon-moves th.versions { text-align: left; }

/* Stat calculator */
.dex-col-stat-calc { width: 6em; }
table.dex-stat-calculator {}
table.dex-stat-calculator td { text-align: center; }
table.dex-stat-calculator td.protip { font-size: 0.8em; line-height: 1.33; text-align: left;; font-style: italic; color: #606060; }

/* Who's that Pokémon */
/* Use the class on this element to toggle the game state; by default everything is hidden */
#js-dex-wtp {}
#js-dex-wtp                 #js-dex-wtp-start    { display: none; }
#js-dex-wtp.state-off       #js-dex-wtp-start    { display: block; }
#js-dex-wtp                 #js-dex-wtp-thinking { display: none; }
#js-dex-wtp.state-thinking  #js-dex-wtp-thinking { display: block; }
#js-dex-wtp                 #js-dex-wtp-board    { display: none; }
#js-dex-wtp.state-playing   #js-dex-wtp-board    { display: block; }
#js-dex-wtp.state-answering #js-dex-wtp-board    { display: block; }
#js-dex-wtp                 #js-dex-wtp-result   { display: none; }
#js-dex-wtp.state-answering #js-dex-wtp-result   { display: block; }


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
