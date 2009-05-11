/*** General ***/

/* Table columns */
col.dex-col-stat-name   { width: 10em; }
col.dex-col-stat-bar    { width: auto; }
col.dex-col-stat-result { width: 5em; }

/* Cool three-column layout */
.dex-column-container { clear: both; overflow: hidden /* float context */; }
.dex-column { float: left; width: 33%; }
.dex-column-2x { float: left; width: 66%; }

/* Type damage */
.dex-damage-0   { font-weight: bold; color: #44c; }
.dex-damage-25  { font-weight: bold; color: #4cc; }
.dex-damage-50  { font-weight: bold; color: #4c4; }
.dex-damage-100 { font-weight: bold; color: #999; }
.dex-damage-200 { font-weight: bold; color: #c44; }
.dex-damage-400 { font-weight: bold; color: #c4c; }

/* Size comparison */
.dex-size { height: 120px; }
.dex-size img { clip: 8px; vertical-align: bottom; }

/*** Pokemon pages ***/
#dex-pokemon-portrait { float: left; width: 15em; text-align: center; }
#dex-pokemon-name { font-size: 2em; }
#dex-pokemon-portrait-sprite { margin: 0.33em; padding: 7px; background: url(/dex/media/chrome/sprite-frame.png) center center no-repeat; }

ul#dex-pokemon-damage-taken { overflow: hidden /* new float context */; }
ul#dex-pokemon-damage-taken li { display: inline-block; text-align: center; padding: 0.125em; }
ul#dex-pokemon-damage-taken li img { display: block; margin-bottom: 0.25em; }

table.dex-evolution-chain { width: 100%; table-layout: fixed; border-collapse: separate; border-spacing: 0.5em; }
table.dex-evolution-chain td { empty-cells: hide; padding: 0.5em; vertical-align: middle; border: 1px solid #d8d8d8; background: #f0f0f0; }
.dex-evolution-chain-pokemon, .dex-evolution-chain-method { display: block; }
.dex-evolution-chain-pokemon img { float: left; margin: -16px 0; padding: 1em 0; /* center with two lines of text */ padding-right: 0.33em; }

table.dex-pokemon-stats { width: 100%; }
table.dex-pokemon-stats th label { display: block; text-align: right; font-weight: normal; color: #2457a0; }
table.dex-pokemon-stats th input { text-align: left; }
table.dex-pokemon-stats .dex-pokemon-stats-bar-container { background: #f8f8f8; }
table.dex-pokemon-stats .dex-pokemon-stats-bar { padding: 0.33em; border: 1px solid #d8d8d8; background: #f0f0f0; }
table.dex-pokemon-stats td.dex-pokemon-stats-result { text-align: right; }

table.dex-encounters th.version { width: 8em; }
table.dex-encounters td { vertical-align: middle; }
table.dex-encounters td.location { vertical-align: top; }
table.dex-encounters td.icon { height: 24px; width: 24px; padding-left: 2em; vertical-align: middle; text-align: center; }
.dex-location-area { font-size: 0.8em; font-style: italic; }
.dex-rarity-bar { position: relative; font-size: 0.75em; height: 1em; line-height: 1; margin-top: 0.25em; background: #e8e8e8; border: 1px solid #96bbf2; }
.dex-rarity-bar-fill { height: 100%; background: #96bbf2; }
.dex-rarity-bar-value { position: absolute; height: 100%; top: 0; right: 0; color: #808080; vertical-align: bottom; }

th { vertical-align: middle; }
.vertical-text { -moz-transform: rotate(-90deg); }

