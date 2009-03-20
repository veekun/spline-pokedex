/*** General ***/

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



th { vertical-align: middle; }
.vertical-text { -moz-transform: rotate(-90deg); }

