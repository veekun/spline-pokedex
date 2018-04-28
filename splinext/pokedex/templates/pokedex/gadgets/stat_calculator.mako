<%inherit file="/base.mako" />
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>
<%! from splinext.pokedex import i18n %>\

<%def name="title()">${_(u"Stat calculator")}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li>${_(u"Gadgets")}</li>
    <li>${_(u"Stat calculator")}</li>
</ul>
</%def>

<p>${_(u"WHIRLWIND EXPLANATION: Pokémon have a fixed, permanent score from 0 to 31 for each stat that affects how good that stat can ever get.")}</p>
<p>${_(u"This calculator will figure out that score (called a \"gene\" or, more obtusely, an \"IV\") for you, so you can discard the <em>unworthy</em>.  It's more accurate for higher-level Pokémon, so it's helpful to go into a level 100 wifi battle with someone and check your Pokémon's stats from there.") | n}</p>

<h1>Stat calculator</h1>

${h.form(url.current(), method=u'GET')}
<input type="hidden" name="shorten" value="1">
<dl class="standard-form">
    ${lib.field(u'pokemon', tabindex=100)}
    ${lib.field(u'nature', tabindex=100)}
    ${lib.field(u'hint', tabindex=100)}
    ${lib.field(u'hp_type', tabindex=100)}
</dl>

<%
    if c.results:
        num_data_columns = c.num_data_points + c.prompt_for_more
    else:
        num_data_columns = 1
%>\
<table class="dex-stat-calculator striped-rows">
<col>
% if c.results:
<col>
% endif
% for i in range(num_data_columns):
<colgroup>
    <col class="dex-col-stat-calc">
    <col class="dex-col-stat-calc">
</colgroup>
% endfor
<col>
<thead>
    <tr class="header-row">
        <th>
            % if c.results:
            ${dexlib.pokemon_link(c.pokemon, content=h.literal(u"{0}<br>{1}").format( \
                dexlib.pokemon_form_image(c.pokemon.default_form, prefix=u'icons'), \
                c.pokemon.name))}
            % endif
        </th>
        % if c.results:
        <th>Base<br>stats</th>
        % endif
        % for i in range(num_data_columns):
        <th>Stats</th>
        <th>Effort</th>
        % endfor
        % if c.results:
        <th>Possible genes (IVs)</th>
        % endif
    </tr>
    <tr class="subheader-row">
        <th
        % if c.results:
            colspan="2"
        % endif
        >
            <button type="submit" tabindex="100">${_(u"Crunch numbers")}</button>
        </th>
        % for i in range(num_data_columns):
        <th colspan="2">
            Level ${lib.literal_field(c.form.level[i], size=3, tabindex=200 + (len(c.stats) + 1) * (i * 3))}
        </th>
        % endfor
        % if c.results:
        <th></th>
        % endif
    </tr>
</thead>
<tbody>
    % for stat in c.stats:
    <tr
    >
        <th>
            ${stat.name}
          % if c.form.nature.data and not c.form.nature.data.is_neutral:
            % if c.form.nature.data.increased_stat == stat:
            <div class="dex-nature-buff">${_(u"+10%")}</div>
            % elif c.form.nature.data.decreased_stat == stat:
            <div class="dex-nature-nerf">${_(u"−10%")}</div>
            % endif
          % endif
        </th>
        % if c.results:
        <td>${c.form.pokemon.data.base_stat(stat, u'?')}</td>
        % endif
        % for i in range(num_data_columns):
        <td>
            ${lib.literal_field(c.form.stat[i][stat], size=3, tabindex=200 + (len(c.stats) + 1) * (i * 3 + 1))}
            % if c.results and i < c.num_data_points and c.form.level[i].data in c.valid_range[stat]:
            <div class="-valid-range
                % if c.form.nature.data and not c.form.nature.data.is_neutral:
                % if c.form.nature.data.increased_stat == stat:
                dex-nature-buff
                % elif c.form.nature.data.decreased_stat == stat:
                dex-nature-nerf
                % endif
                % endif
            ">
                <% min_stat, max_stat = c.valid_range[stat][ c.form.level[i].data ] %>\
                % if min_stat == max_stat:
                ${min_stat}
                % else:
                ${min_stat}–${max_stat}
                % endif
            </div>
            % endif
        </td>
        <td>${lib.literal_field(c.form.effort[i][stat], size=3, tabindex=200 + (len(c.stats) + 1) * (i * 3 + 2))}</td>
        % endfor

        % if c.results:
        % if c.results[stat]:
        <td class="-possible-genes">
            ## Pretty graphs!
            <div class="dex-stat-graph">
            % for gene in xrange(32):
                % if gene in c.valid_genes[stat]:
                <div class="point" style="background: ${c.stat_graph_chunk_color(gene)};"></div>
                % else:
                <div class="pointless"></div>
                % endif
            % endfor
            </div>
            <div>${c.results[stat]}</div>
        </td>
        % else:
        <td class="impossible">impossible</td>
        % endif
        % endif
    </tr>
    % endfor
</tbody>
</table>

% if c.results:
% if c.exact:
<p>Congratulations, you've narrowed your Pokémon's stats down exactly!</p>
<p>
    This ${c.form.pokemon.data.name}'s
    <a href="${url(controller='dex', action='moves', name=c.hidden_power.name.lower())}">${c.hidden_power.name}</a>
    inflicts ${dexlib.type_link(c.hidden_power_type)} damage,
    with ${c.hidden_power_power} power.
</p>
% endif
% if all(c.results.values()):
% if not c.exact:
<p>
    Hmm, I need more information to figure out your Pokémon's genes exactly.  Try raising it to level ${c.next_useful_level} and entering its new stats. <br>
    Remember: if your Pokémon battles at all, you'll need to track the effort it gains.  Consider saving your game and using Rare Candy instead.
</p>
% endif
<p>${_(u"And for your copy/pasting pleasure:")}</p>
<p class="dex-stat-calculator-clipboard">
    ${c.results[c.stats[0]]} ${_(u"HP")};
    ${c.results[c.stats[1]]}/${c.results[c.stats[2]]} ${_(u"Physical")};
    ${c.results[c.stats[3]]}/${c.results[c.stats[4]]} ${_(u"Special")};
    ${c.results[c.stats[5]]} ${_(u"Speed")}
</p>
% else:  # not all(values)
<p>${_(u"Uh-oh.  The set of stats you gave is totally impossible. Better double-check against your game.")}</p>
<p>${_(u"The most common problem is effort; if a Pokémon has been trained at all, it'll have some effort accumulated.  This affects its stats, and there's no way to know how much effort it has unless you've been keeping track.  Sorry.")}</p>
<p>${_(u"If you're desperate, you could try the effort-lowering berries (Pomeg et al.), which will reduce effort in a given stat by 10 at a time.  Drop every stat's effort until it won't drop any further, then try again.")}</p>
% endif
% else:  # not c.results
<p class="dex-stat-calculator-protip">
    ${_(u"\"Stats\" are your Pokémon's actual stats, from the Summary screen in-game.")}
</p>
<p class="dex-stat-calculator-protip">
    ${_(u"\"Effort\" is accumulated as your Pokémon battles.")} <br>
    ${_(u"If you don't know what this is, and your Pokémon has EVER battled or eaten a vitamin, this calculator CANNOT work.  Using Rare Candy is okay, though.")}
</p>
% endif  # c.results

<p>
    <button type="reset">${_(u"Reset")}</button> ${_(u"or")}
    <a href="${url.current()}"><img src="${h.static_uri('spline', 'icons/eraser.png')}" alt=""> ${_(u"start over")}</a>
</p>
${h.end_form()}
