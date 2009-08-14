/*** General ***/

/* Pokémon sprite link grid */
a.dex-icon-link { display: inline-block; border: 1px solid transparent; }
a.dex-icon-link:hover { border: 1px solid #bfd3f1; background: #e6eefa; }
a.dex-icon-link.selected { border: 1px solid #95b7ea; background: #bfd4f2; }
a.dex-box-link { display: inline-block; margin: 0.25em; border: 1px solid transparent; }
a.dex-box-link:hover { border: 1px solid #bfd3f1; background: #e6eefa; }
a.dex-box-link.selected { border: 1px solid #95b7ea; background: #bfd4f2; }

/* Table columns */
col.dex-col-stat-name   { width: 10em; }
col.dex-col-stat-bar    { width: auto; }
col.dex-col-stat-pctile { width: 5em; }
col.dex-col-stat-result { width: 5em; }
col.dex-col-version     { width: 3.5em; }  /* two versions (32px < 33px == 3em) plus 0.17em padding < 3.5em */
col.dex-col-last-version{ border-right: 1px solid #b4c7e6; }

/* Cool three-column layout */
.dex-column-container { clear: both; overflow: hidden /* float context */; margin-top: 1em; }
.dex-column { float: left; width: 32.333%; margin-left: 1%; }
.dex-column:first-child { width: 33.333%; margin-left: 0; }
.dex-column-2x { float: left; width: 66.666%; }

/* Type damage */
.dex-damage-taken-0   { font-weight: bold; color: #44c; }
.dex-damage-taken-25  { font-weight: bold; color: #4cc; }
.dex-damage-taken-50  { font-weight: bold; color: #4c4; }
.dex-damage-taken-100 { font-weight: bold; color: #999; }
.dex-damage-taken-200 { font-weight: bold; color: #c44; }
.dex-damage-taken-400 { font-weight: bold; color: #c4c; }

.dex-damage-dealt-0   { font-weight: bold; color: #44c; }
.dex-damage-dealt-25  { font-weight: bold; color: #c4c; }
.dex-damage-dealt-50  { font-weight: bold; color: #c44; }
.dex-damage-dealt-100 { font-weight: bold; color: #999; }
.dex-damage-dealt-200 { font-weight: bold; color: #4c4; }
.dex-damage-dealt-400 { font-weight: bold; color: #4cc; }

/* Size comparison */
.dex-size { height: 120px; padding-bottom: 2.5em /* for -value */; overflow: hidden /* new float context */}
.dex-size img { clip: 8px; position: absolute; bottom: 0; image-rendering: -moz-crisp-edges; }
.dex-size input[type='text'] { text-align: right; }
.dex-size .dex-size-trainer,
.dex-size .dex-size-pokemon { display: block; position: relative; float: left; height: 100%; width: 50%; text-align: left; }
.dex-size .dex-size-trainer { text-align: right; }
.dex-size .dex-size-pokemon { text-align: left; }
.dex-size .dex-size-trainer img { right: 0.25em; }
.dex-size .dex-size-pokemon img { left: 0.25em; }
.dex-size .js-dex-size-raw { display: none; }
.dex-size .dex-size-value { position: absolute; height: 2em; padding: 0.25em; bottom: -2.5em; }
.dex-size .dex-size-trainer .dex-size-value { right: 0.25em; }
.dex-size .dex-size-pokemon .dex-size-value { left: 0.25em; }

/*** Individual pages ***/
#dex-page-portrait { float: left; width: 15em; min-height: 10em; padding-bottom: 1em; text-align: center; }
#dex-page-portrait p { margin: 0.25em 0; }
p#dex-page-name { font-size: 2em; margin: 0.12em 0; }
#dex-pokemon-forme { font-size: 1.25em; font-weight: bold; }
#dex-pokemon-portrait-sprite { margin: 0.33em; padding: 7px; background: url(/dex/media/chrome/sprite-frame.png) center center no-repeat; }

ul#dex-page-damage { overflow: hidden /* new float context */; margin-bottom: 2em; }
ul#dex-page-damage li { display: inline-block; text-align: center; padding: 0.125em; }
ul#dex-page-damage li img { display: block; margin-bottom: 0.25em; }

ul.dex-pokemon-compatibility { max-height: 136px /* four rows of icons plus borders */; overflow: auto; }

.dex-pokemon-item-rarity { display: inline-block; width: 3em; text-align: right; }

table.dex-evolution-chain { width: 100%; table-layout: fixed; border-collapse: separate; border-spacing: 0.5em; empty-cells: hide; }
table.dex-evolution-chain td { padding: 0.5em; vertical-align: middle; border: 1px solid #d8d8d8; background: #f0f0f0; }
table.dex-evolution-chain td:hover { border: 1px solid #bfd3f1; background: #e6eefa; }
table.dex-evolution-chain td.selected { border: 1px solid #95b7ea; background: #bfd4f2; }
.dex-evolution-chain-method { display: block; overflow: hidden; font-size: 0.8em; line-height: 1.25em; }
.dex-evolution-chain-pokemon { padding-top: 8px /* bump icon up a bit */; display: block; font-weight: bold; }
.dex-evolution-chain-pokemon img { float: left; margin-top: -8px /* fills link's top padding */; padding-right: 0.33em; }

table.dex-pokemon-stats { width: 100%; }
table.dex-pokemon-stats th label { display: block; text-align: right; font-weight: normal; color: #2457a0; }
table.dex-pokemon-stats th input { text-align: left; }
table.dex-pokemon-stats .dex-pokemon-stats-bar-container { background: #f8f8f8; }
table.dex-pokemon-stats .dex-pokemon-stats-bar { padding: 0.33em; border: 1px solid #d8d8d8; background: #f0f0f0; }
table.dex-pokemon-stats td.dex-pokemon-stats-pctile { text-align: right; }
table.dex-pokemon-stats td.dex-pokemon-stats-result { text-align: right; }

table.dex-encounters th.version { width: 8em; }
table.dex-encounters td { vertical-align: middle; }
table.dex-encounters td.location { vertical-align: top; }
table.dex-encounters td.icon { height: 24px; width: 24px; padding-left: 2em; vertical-align: middle; text-align: center; }
.dex-location-area { font-size: 0.8em; font-style: italic; }
.dex-rarity-bar { position: relative; font-size: 0.75em; height: 1em; line-height: 1; margin-top: 0.25em; background: #e8e8e8; border: 1px solid #96bbf2; }
.dex-rarity-bar-fill { height: 100%; background: #96bbf2; }
.dex-rarity-bar-value { position: absolute; height: 100%; top: 0; right: 0; color: #808080; vertical-align: bottom; }

table.dex-moves {;}
table.dex-moves td { padding: 0.33em; vertical-align: middle; text-align: center; }
table.dex-moves th { padding: 0.33em 0.17em; text-align: center; }
table.dex-moves tr.subheader-row th { padding: 0.17em 0.33em; text-align: left; }
table.dex-moves td.egg { padding: 0 /* egg sprite consumes a lot of space, so let it extend into padding */; }
table.dex-moves td.effect { font-size: 0.8em; text-align: left; }
table.dex-moves td.tutored { white-space: nowrap; }
table.dex-moves .no-tutor { visibility: hidden; }

.dex-pokemon-flavor-generation { position: absolute; line-height: 1.5; }
dl.dex-pokemon-flavor-text + .dex-pokemon-flavor-generation { padding-top: 1.5em; }
dl.dex-pokemon-flavor-text + .dex-pokemon-flavor-generation + dl.dex-pokemon-flavor-text { padding-top: 1.5em; }
dl.dex-pokemon-flavor-text dt { width: 5.5em; }
dl.dex-pokemon-flavor-text dd { padding-left: 6em; }

th { vertical-align: middle; }
.vertical-text { -moz-transform: rotate(-90deg); }

.dex-priority-fast { font-weight: bold; color: green; }
.dex-priority-slow { font-weight: bold; color: red; }
