<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>

<%def name="title()">Pokémon Search 2.0</%def>

<style type="text/css">
.search-criterion { position: relative; border-radius: 1em; padding: 1em; margin: 1em 0; background: #f0f0f0; -moz-box-shadow: 1px 1px 3px #d0d0d0; }
.search-criterion input { margin: 0.25em; }
.search-criterion h6 { float: left; width: 9em; font-size: 1.33em; font-family: "Bookman Old Style", "Serifa BT", "URW Bookman L", "itc bookman", times, serif; font-weight: normal; }
.search-criterion .-values { margin-left: 12em; padding-left: 1em; }
.search-criterion .-values ul.-table-multi-select { }
.search-criterion .-values ul.-table-multi-select li { display: inline-block; vertical-align: top; }
.search-criterion .-values ul.-table-multi-select li label { display: block; width: 10em; margin: 0.25em 0; padding: 0.33em 0.5em; -moz-border-radius: 0.33em; }
.search-criterion .-values ul.-table-multi-select li label:hover { outline: 1px solid #aaa; -moz-outline-radius: 0.33em; outline-offset: -1px; }
.search-criterion .-values ul.-table-multi-select li label.-checked { background: hsl(216, 40%, 90%); }
.search-criterion .-values ul.-option-select { margin-top: 1em; }
.search-criterion .-values ul.-option-select li label { display: block; xwidth: 30em; margin: 0.25em 0; padding: 0 0.5em; }
.search-criterion .-values ul.-option-select li label:hover { outline: 1px solid #aaa; outline-offset: -1px; }
.search-criterion .-values ul.-option-select li label.-checked { background: hsl(216, 20%, 90%); }

/* javascript nonsense */

.search-criterion.-collapsed {
    display: inline-block;
    margin: 0.5em;
    width: 12em;
}
.search-criterion.-collapsed .-values {
    display: none;
}
.search-criterion > .js-toggle-collapsing {
    display: none;
    position: absolute;
    top: 0;
    right: 0;
    width: 24px;
    height: 24px;
    background: url(/static/spline/icons/minus.png) no-repeat center center;
    background-color: hsl(0, 30%, 80%);
    border-radius: 0 1em 0 1em;
    cursor: pointer;
}
.search-criterion.-collapsed > .js-toggle-collapsing {
    bottom: 0;
    right: 0;
    height: auto;
    width: 24px;
    background-image: url(/static/spline/icons/plus.png);
    background-color: hsl(120, 30%, 80%);
    border-radius: 0 1em 1em 0;
}
.search-criterion:hover > .js-toggle-collapsing {
    display: block;
}

.js-thinking { display: none; position: relative; height: 22px; width: 160px; margin: 1em auto; }
.js-thinking .-label { position: absolute; top: 0; bottom: 0; left: 0; right: 0; line-height: 22px; text-align: center; text-shadow: 0 0 3px white; }
.js-thinking img { -moz-animation-duration: 1.5s; -moz-animation-name: spinnaz; -moz-animation-iteration-count: infinite; -moz-animation-timing-function: linear; }
@-moz-keyframes spinnaz {
    from { -moz-transform: rotate(0deg); margin-left: 0; opacity: 0.0; }
    33% { opacity: 1.0; }
    67% { opacity: 1.0; }
    to { -moz-transform: rotate(720deg); margin-left: 138px; opacity: 0.0; }
}


/* TODO TODO TODO */
ul#results { margin: 1em 0; }
ul#results > li { display: inline-block; }

<%
    type_colors = [
        ('grass',     'e5efe9'),
        ('fire',      'efe7e5'),
        ('ground',    'f0ebe4'),
        ('poison',    'ebe5ef'),
        ('electric',  'efefe5'),
        ('water',     'e3edf1'),
        ('rock',      'e8eaec'),
        ('flying',    'e5ebef'),
        ('ice',       'e5eeef'),
        ('normal',    'eaeaea'),
        ('bug',       'eaefe5'),
        ('ghost',     'e8e5ef'),
        ('fighting',  'eee6e6'),
        ('dragon',    'e7e5ef'),
        ('psychic',   'eee5ef'),
        ('dark',      'eceae8'),
        ('steel',     'e8ecec'),
    ]
%>

    a.dex-plaque { position: relative; display: inline-block; width: 16em; height: 7em; margin: 32px 0.5em 0.5em; color: #606060; border: 1px solid #f0f0f0; background: #f0f0f0; font-weight: normal; }
    a.dex-plaque .-header { position: relative; height: 1.33em; padding: 0.33em; background: #f8f8f8; }
    a.dex-plaque .-header .-datum-id { display: inline-block; width: 2em; line-height: 1.33; font-family: monospace; vertical-align: middle; color: #c1c0c0; }
    a.dex-plaque .-header .-datum-name { position: relative; z-index: 1; display: inline-block; font-size: 1.33em; line-height: 1; font-family: serif; vertical-align: middle; color: black; }
    a.dex-plaque .-footprint { position: absolute; bottom: 0; right: 0; display: none; }
    a.dex-plaque .-datum-type { padding: 0.33em; }
    a.dex-plaque .-datum-ability { padding: 0 0.45em; font-size: 0.8em; }
    a.dex-plaque .-datum-ability li { display: inline-block; }
    a.dex-plaque .-datum-ability li:after { content: ','; }
    a.dex-plaque .-datum-ability li:last-child:after { content: none; }
    a.dex-plaque .-datum-ability .-hidden { font-style: italic; color: #522060; }
    a.dex-plaque .-datum-stats { clear: both; word-spacing: -1em; text-align: center; }
    a.dex-plaque .-datum-stats li { display: inline-block; width: 16%; }
    a.dex-plaque .-datum-stats .-label { display: none; }
    a.dex-plaque .-portrait { position: absolute; bottom: 0; right: 0; opacity: 0.4; overflow: hidden; }
    a.dex-plaque .-portrait img { margin-bottom: -40px; }

    a.dex-plaque { -moz-transition-property: border-color, background-color; -moz-transition-duration: 0.5s; }
    a.dex-plaque:hover { border-color: #e2eaef; background-color: #ecf1f4; }
    a.dex-plaque .-header { -moz-transition-property: background-color; -moz-transition-duration: 0.5s; }
    a.dex-plaque:hover .-header { background-color: #f5f8fa; }
    a.dex-plaque .-portrait { -moz-transition-property: opacity; -moz-transition-duration: 0.5s; -moz-transition-duration: 0.5s; -moz-transition-timing-function: ease-in-out; }
    a.dex-plaque:hover .-portrait { opacity: 1.0 !important; }
    a.dex-plaque .-portrait img { -moz-transition-property: margin-bottom; -moz-transition-duration: 0.5s; -moz-transition-timing-function: ease-out; }
    a.dex-plaque:hover .-portrait img { margin-bottom: -16px; }
</style>
<script type="text/javascript" src="http://ajax.aspnetcdn.com/ajax/jquery.templates/beta1/jquery.tmpl.min.js"></script>
<script id="tmpl-plaque" type="text/x-jquery-tmpl">
<%text>
    <a href="/dex/pokemon/${name}" class="dex-plaque
        dex-plaque-${type[0]}1
        {{if type[1]}}
        dex-plaque-${type[1]}2
        {{/if}}
    ">
        <div class="-header">
            <div class="-datum-id">${id}</div>
            <div class="-datum-name">${name}</div>
            <div class="-portrait">
                <img src="/dex/media/pokemon/main-sprites/black-white/${id}.png" alt="${name}">
            </div>
        </div>
        <div class="-datum-type">
            {{each type}}
            <img src="/dex/media/types/en/${$value}.png">
            {{/each}}
        </div>
        <ul class="-datum-ability">
            {{each ability}}
            <li>${$value.ability}</li>
            {{/each}}
        </ul>
        <ul class="-datum-ability">
            <li class="-hidden">
                {{if hidden_ability}}
                ${hidden_ability}
                {{/if}}
            </li>
        </ul>
        <ul class="-datum-stats">
            <li>${$data['base-stats']['hp']}</li>
            <li>${$data['base-stats']['attack']}</li>
            <li>${$data['base-stats']['defense']}</li>
            <li>${$data['base-stats']['special-attack']}</li>
            <li>${$data['base-stats']['special-defense']}</li>
            <li>${$data['base-stats']['speed']}</li>
        </ul>
    </a>
</%text>
</script>
<script type="text/javascript">
"use strict";
function VeekunRadSearch($form, $results) {
    this.$form = $form;
    this.$results = $results;
    this.$current_menu = null;

    this.setup();
}

VeekunRadSearch.prototype = {
    update_results: function(data) {
        var self = this;
        var $container = this.$results;

        // TODO should this be called update_results when it kinda assumes the results are already cleared?
        // TODO create a custom jq queue for this, so we can clear it when running a search
        var more_data;
        var MAX_RESULTS_BLOCK = 50;
        if (data.length > MAX_RESULTS_BLOCK) {
            more_data = data.splice(MAX_RESULTS_BLOCK, data.length - MAX_RESULTS_BLOCK);
        }

        var fragment = document.createDocumentFragment();
        $.each(data, function() {
            var $li = $('<li></li>');
            $li.append($('#tmpl-plaque').tmpl(this));
            fragment.appendChild($li[0]);
        });

        $container.append(fragment);

        if (more_data) {
            setTimeout(function() { self.update_results(more_data) }, 50);
        }
    },

    run_search: function() {
        var self = this;
        this.$results.empty();
        // XXX this should be localized to the results div
        // also, make it prettier than a toggle goddamn
        $('.js-thinking').show();
        $.ajax({
            url: '/dex/api/pokemon',
            // XXX don't include stuff that has no real data
            data: this.$form.serialize() + '&__fetch__=type&__fetch__=base-stats&__fetch__=name&__fetch__=id&__fetch__=ability',
            dataType: 'json',
            success: function(data) { self.update_results(data) },
            complete: function() {
                // XXX
                $('.js-thinking').hide();
            },
        });
    },


    /* UI */
    setup: function() {
        var self = this;

        // XXX hide the results stuff if it's empty...

        // Set up collapsible criteria blocks
        this.$form.find('section.search-criteria-group').append($('<div/>').addClass('js-active-criteria'));
        this.$form.find('.search-criterion')
            .each(function() { self.deactivate_criterion($(this)) })
            .prepend(
                $('<div/>', { "class": 'js-toggle-collapsing', click: function() { self.toggle_criterion($(this).closest('.search-criterion')) } })
            );

        // XXX be more specific
        // Handle submit button
        this.$form.find('button').click(function(ev) {
            ev.preventDefault();
            self.run_search();
        });

        // Checkbox and radio button highlight effect
        var $decorated_checkables = this.$form
            .find('ul.-table-multi-select, ul.-option-select')
            .find(':checkbox, :radio');
        var sync_checked_class = function() {
            $(this).closest('label').toggleClass('-checked', $(this).is(':checked'));
        };
        $decorated_checkables.click(function(ev) {
            var $this = $(this);
            if ($this.is(':radio')) {
                // A click on me could uncheck a sibling, so everyone needs updating
                $this.closest('ul').find(':radio').each(sync_checked_class);
            }
            else {
                $this.each(sync_checked_class);
            }
        });
        $decorated_checkables.each(sync_checked_class);

        //this.run_search();
    },

    toggle_criterion: function($criterion) {
        if ($criterion.hasClass('-collapsed')) {
            this.activate_criterion($criterion);
        }
        else {
            this.deactivate_criterion($criterion);
        }
    },
    activate_criterion: function($criterion) {
        $criterion.find('input').removeAttr('disabled');
        $criterion.removeClass('-collapsed');

    },
    deactivate_criterion: function($criterion) {
        $criterion.addClass('-collapsed');
        $criterion.find('input').attr('disabled', true);

    },
};


var rad_search;
$(function() {
    rad_search = new VeekunRadSearch($('#ye-forme'), $('#results'));
});
</script>

BIG TODO: pokemon renderer!  that was the point here, oops.

actually needs doing before commit:
- deal with blank stuff
- aw man, stats.
- aw man, abilities.
- include all the things existing search does
- make multiple arguments and side arguments work
- move the scattered bits into a class or two
- clean up all the commented-out and todo stuff, move css and js out of here, etc etc


required next step:
- explanatory text for fields and the special things they ask for
- make it work without js
- use history api


polish:
- handle server failure
- handle user error; bad api args.  some problems documented in the api itself
- better algorithm for when to search.  any change in criteria should queue a re-search.  a click to dismiss a criterion, /while a search is queued/, should immediately search.
- only link the name
- make other display types work
- custom rendering for entities, so types get their sprites, etc.


improvements:
- derived values: stat total, type efficacy, how to learn move x
    - hold up: are individual stats a derived value?  OMG
- checkboxes and a button for going to the comparer
- remember current sort/display as defaults?
- replace these stupid dropdowns.  buttons should "add" when clicked (and have a + on hover...), and show a regular in-page full-width search doodad.  fade them in or whatever.
- fade out pokemon when only adding a new filter
- evo chain sorting, oh dear!


major improvements:
- grouping
- custom table/plaque data
- smart eagerloading, at last
- optimize request when possible

## full pokemon search
## pokemon browser

some other thoughts
- the idea here was to make something more like a pokemon browser.  have I done that?  could I do it better?
    - might help to have a browse "mode".  start with all pokemon, only multi-choice criteria are shown, and you just click one (?  maybe enforce OR?) to filter to those.  grouping might be more appropriate here too
- how can I compact the pokemon pages, or present them more efficiently for what different people need?



more recent concerns:
- need an api/lookup that can look up anything and return a different query response depending on what it was.  maybe accept multiple lookups too.
- need a lookup per class, so the ability thing etc. can work.  or make the above general and awesome enough.
- probably should accept a json post to api methods as well

crucial for this page to work:
- know when a block has no "real" data.  indicate this to the user, and don't send it along.
- do the collapsing/hiding thing per block
- make the plaques a bit bigger, less cramped, more informative, less laggy
- do the no-js version: the querying needs to work server-side, and the page needs to load correctly.  then you can do the url thing

some specific ui cleverness i want:
- table should include columns for criteria you specified
- moves should show how they're learned i guess??

<form id="ye-forme">

<p>What would you like to search for?</p>


    <h3>Essentials</h3>
        <%def name="render_criterion(key)">
        <% prop = c.api_query.locus.prop_index[key] %>
        <div class="search-criterion">
            <h6>${prop.name}</h6>
            <div class="-values">
                ${caller.body()}
            </div>
        </div>
        </%def>
<%def name="render_criterion_range(name)">
${h.text(name, id=None, placeholder='3-7, <6, >9, 11+')}
</%def>

<%def name="render_criterion_text(name)">
${h.text(name, id=None)}
</%def>
<%def name="render_criterion_text_mode(name)">
<ul class="-option-select">
    ## TODO icons here?
    ## TODO check the right thing
    <li><label>${h.radio(name, id=None, value='substring', checked=True)} Match substring: <kbd>ariz</kbd> finds Charizard</label></li>
    <li><label>${h.radio(name, id=None, value='wildcard')} Match wildcards: <kbd>Ch?riz*</kbd> finds Charizard</label></li>
    <li><label>${h.radio(name, id=None, value='exact')} Match exactly: <kbd>Charizard</kbd> finds Charizard</label></li>
</ul>
</%def>

<%def name="render_criterion_table_choice(name, table, column='identifier')">
<ul class="-table-multi-select">
    ## TODO orderby
    % for row in c.api_query.session.query(table):
    <li>
        <label>
            ${h.checkbox(name, id=None, value=getattr(row, column))}
            ${caller.body(row=row)}
        </label>
    </li>
    % endfor
</ul>
</%def>

<%def name="render_criterion_single_choice_mode(name)">
<ul class="-option-select">
    ## TODO icons here?
    ## TODO check the right thing
    <li><label>${h.radio(name, id=None, value='any', checked=True)} Any of these</label></li>
    <li><label>${h.radio(name, id=None, value='none')} None of these</label></li>
</ul>
</%def>
<%def name="render_criterion_multi_choice_mode(name)">
<ul class="-option-select">
    ## TODO icons here?
    ## TODO check the right thing
    <li><label>${h.radio(name, id=None, value='any', checked=True)} Any of these</label></li>
    <li><label>${h.radio(name, id=None, value='all')} All of these</label></li>
    <li><label>${h.radio(name, id=None, value='some')} Only these, and nothing else</label></li>
    <li><label>${h.radio(name, id=None, value='none')} None of these</label></li>
</ul>
</%def>

<%! import pokedex.db.tables as t %>
<%self:render_criterion key="id">
    ${render_criterion_range('id')}
</%self:render_criterion>

<%self:render_criterion key="name">
    ${render_criterion_text('name')}
    ${render_criterion_text_mode('name.match-type')}
</%self:render_criterion>

<%self:render_criterion key="growth-rate">
    <%self:render_criterion_table_choice name="growth-rate" table="${t.GrowthRate}" args="row">
        ${row.name}
    </%self:render_criterion_table_choice>
    ${render_criterion_single_choice_mode('growth-rate.match-type')}
</%self:render_criterion>

<%self:render_criterion key="generation">
    <%self:render_criterion_table_choice name="generation" table="${t.Generation}" args="row" column="id">
        ${h.pokedex.generation_icon(row)}
    </%self:render_criterion_table_choice>
    ${render_criterion_single_choice_mode('generation.match-type')}
</%self:render_criterion>

<%self:render_criterion key="type">
    <%self:render_criterion_table_choice name="type" table="${t.Type}" args="row">
        ${h.pokedex.type_link(row)}
    </%self:render_criterion_table_choice>
    ${render_criterion_multi_choice_mode('type.match-type')}
</%self:render_criterion>

<%self:render_criterion key="egg-group">
    <%self:render_criterion_table_choice name="egg-group" table="${t.EggGroup}" args="row">
        ${row.name}
    </%self:render_criterion_table_choice>
    ${render_criterion_multi_choice_mode('egg-group.match-type')}
</%self:render_criterion>

<%self:render_criterion key="base-stats">
    ## XXX all stats
    ## XXX average/total field?  and add to api if so
    % for stat in c.api_query.session.query(t.Stat):
    ${stat.name}: ${render_criterion_range('base-stats.' + stat.identifier)}
    % endfor
</%self:render_criterion>

<%self:render_criterion key="ability">
    ## XXX multiple
    ## XXX slot
    ## XXX lookup
    ## XXX should be lookup fields i suppose?
    ## XXX make the api actually work with those  :)
    ${render_criterion_text('ability')}
    ${render_criterion_text('ability')}
    ${render_criterion_text('ability')}
    <ul>
        <li>${h.checkbox('ability.slot', id=None, value='1')} Slot 1</li>
        <li>${h.checkbox('ability.slot', id=None, value='2')} Slot 2</li>
        <li>${h.checkbox('ability.slot', id=None, value='hidden')} Hidden</li>
    </ul>
    ${render_criterion_multi_choice_mode('ability.match-type')}
</%self:render_criterion>

<%self:render_criterion key="held-item">
    ## XXX multiple
    ## XXX rarity
    ## XXX lookup
    ## XXX should be lookup fields i suppose?
    ## XXX make the api actually work with those  :)
    ${render_criterion_text('held-item')}
    ${render_criterion_text('held-item')}
    ${render_criterion_text('held-item')}
    ${render_criterion_range('held-item.rarity')}
    ${render_criterion_multi_choice_mode('held-item.match-type')}
</%self:render_criterion>

(gender)

<%self:render_criterion key="evolution">
    <%def name="x(n)"><img src="/dex/media/pokemon/icons/${n}.png"></%def>
    <div class="dex-column-container">
        <div class="dex-column">
            <ul class="-option-select">
                <li><label>${h.checkbox('evolution.stage', id=None, value='baby')} ${x(172)} <span style="display: inline-block; width: 32px;"></span> Baby</label></li>
                <li><label>${h.checkbox('evolution.stage', id=None, value='basic')} ${x(25)} ${x(4)} Basic</label></li>
                <li><label>${h.checkbox('evolution.stage', id=None, value='stage1')} ${x(26)} ${x(5)} Stage 1</label></li>
                <li><label>${h.checkbox('evolution.stage', id=None, value='stage2')} <span style="display: inline-block; width: 32px;"></span> ${x(6)} Stage 2</label></li>
            </ul>
        </div>
        <div class="dex-column">
            <ul class="-option-select">
                <li><label>${h.checkbox('evolution.position', id=None, value='first')} ${x(1)} First</label></li>
                <li><label>${h.checkbox('evolution.position', id=None, value='middle')} ${x(2)} Middle</label></li>
                <li><label>${h.checkbox('evolution.position', id=None, value='last')} ${x(3)} Last</label></li>
                <li><label>${h.checkbox('evolution.position', id=None, value='only')} ${x(151)} Only</label></li>
            </ul>
        </div>
        <div class="dex-column">
            <ul class="-option-select">
                <li><label>${h.checkbox('evolution.fork', id=None, value='linear')} <span style="display: inline-block; width: 16px;"></span> ${x(43)} <span style="display: inline-block; width: 16px;"></span> Linear</label></li>
                <li><label>${h.checkbox('evolution.fork', id=None, value='branching')} <span style="display: inline-block; width: 16px;"></span> ${x(44)} <span style="display: inline-block; width: 16px;"></span> Branching</label></li>
                <li><label>${h.checkbox('evolution.fork', id=None, value='branched')} ${x(45)} ${x(182)} Branched</label></li>
            </ul>
        </div>
    </div>
</%self:render_criterion>

(in pokedex)
((pokedex number))

<%self:render_criterion key="base-happiness">
    ${render_criterion_range('base-happiness')}
</%self:render_criterion>

<%self:render_criterion key="base-experience">
    ${render_criterion_range('base-experience')}
</%self:render_criterion>

<%self:render_criterion key="capture-rate">
    ${render_criterion_range('capture-rate')}
</%self:render_criterion>

<%self:render_criterion key="hatch-counter">
    ${render_criterion_range('hatch-counter')}
</%self:render_criterion>

(height)
(weight)

(moves  D:)
</p>


<section class="search-criteria-group">
    <h3>Flavor</h3>
    <%self:render_criterion key="genus">
        ${render_criterion_text('genus')}
        ${render_criterion_text_mode('genus.match-type')}
    </%self:render_criterion>

    <%self:render_criterion key="color">
        <%self:render_criterion_table_choice name="color" table="${t.PokemonColor}" args="row">
            <span class="dex-color-${row.identifier}"></span> ${row.identifier}
        </%self:render_criterion_table_choice>
        ${render_criterion_single_choice_mode('color.match-type')}
    </%self:render_criterion>

    <%self:render_criterion key="habitat">
        <%self:render_criterion_table_choice name="habitat" table="${t.PokemonHabitat}" args="row">
            <img src="/dex/media/habitats/${row.identifier}.png">
        </%self:render_criterion_table_choice>
        ${render_criterion_single_choice_mode('habitat.match-type')}
    </%self:render_criterion>

    <%self:render_criterion key="shape">
        <%self:render_criterion_table_choice name="shape" table="${t.PokemonShape}" args="row">
            <img src="/dex/media/shapes/${row.identifier}.png">
        </%self:render_criterion_table_choice>
        ${render_criterion_single_choice_mode('shape.match-type')}
    </%self:render_criterion>
</section>


## let's try this without wtforms...
## need the following functionality:
## - showing the standard control
## - showing the option controls
## - showing sub-controls (stats, e.g.)
## - parsing all that garbage, (requiring 1 vs n), reporting errors, and operating on it
## - prefilling existing values...!

<p>I want to see:</p>
<ul>
    ## TODO give me iconsssszz
    <li><label>${h.radio('display', id=None, value='plaque')} Plaques</label></li>
    <li><label>${h.radio('display', id=None, value='table')} Table</label></li>
    <li><label>${h.radio('display', id=None, value='list')} List</label></li>
    ## XXX sprites OR ICONS.  OR something else.  let me pick a gen yo
    <li><label>${h.radio('display', id=None, value='sprites')} Sprites</label></li>
</ul>

<p>Sort by: welp virtually anything</p>

<button>
    Find things! <br>
    This is the button you want to push!
</button>

</form>

<h1>Results</h1>
<div class="-status">
    Nothing yet; you have to search for something!
</div>
<div class="js-thinking">
    <img src="/static/pokedex/images/big-great-ball.png">
    <div class="-label">...pondering...</div>
</div>
<ul id="results">
</ul>
