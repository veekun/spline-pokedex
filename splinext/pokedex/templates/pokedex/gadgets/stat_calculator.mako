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
<dl class="standard-form">
    ${lib.field(u'pokemon')}
    ${lib.field(u'nature')}
    ${lib.field(u'hint')}
    ${lib.field(u'hp_type')}
</dl>

<table class="dex-stat-calculator striped-row-groups">
<col class="dex-col-stat-calc-labels">
<colgroup>
    % for stat in c.stats:
    <col class="dex-col-stat-calc">
    % endfor
</colgroup>
<thead>
    % if c.form.nature.data and not c.form.nature.data.is_neutral:
    <tr>
        <th></th>
        % for stat in c.stats:
        % if c.form.nature.data.increased_stat == stat:
        <th class="dex-nature-buff">${_(u"+10%")}</th>
        % elif c.form.nature.data.decreased_stat == stat:
        <th class="dex-nature-nerf">${_(u"−10%")}</th>
        % else:
        <th></th>
        % endif
        % endfor
    </tr>
    % endif
    <tr class="header-row">
        <th>
            % if c.results:
            ${h.pokedex.pokemon_link(c.pokemon, content=h.literal(u"{0}<br>{1}").format( \
                h.pokedex.pokemon_image(c.pokemon.form, prefix=u'icons'), \
                c.pokemon.full_name))}
            % endif
        </th>
        % for stat in c.stats:
        <th>${stat.name}</th>
        % endfor
    </tr>
    % if c.form.pokemon.data:
    <tr>
        <th>${_(u"Base stats")}</th>
        % for stat in c.stats:
        <td>${c.form.pokemon.data.stat(stat).base_stat}</td>
        % endfor
    </tr>
    % endif
</thead>
% for i in range(c.num_data_points + c.prompt_for_more):
<tbody>
    <tr class="subheader-row">
        <th colspan="${len(c.stats) + 1}">Level ${lib.literal_field(c.form.level[i], size=3)}</th>
    </tr>
    % if i == 0 and not c.results:
    <tr>
        <th></th>
        <td colspan="${len(c.stats)}" class="protip">
            ${_(u"Your Pokémon's actual stats, from the Summary screen in-game.")}
        </td>
    </tr>
    % endif
    <tr>
        <th>${_(u"Stats")}</th>
        % for field in c.form.stat[i]:
        <td>${lib.literal_field(field, size=3)}</td>
        % endfor
    </tr>

    % if c.results and i < c.num_data_points:
    <tr>
        <th>${_(u"Possible range")}</th>
        % for stat in c.stats:
        <td
            % if not c.form.nature.data or c.form.nature.data.is_neutral:
            <% pass %>\
            % elif c.form.nature.data.increased_stat == stat:
            class="dex-nature-buff"
            % elif c.form.nature.data.decreased_stat == stat:
            class="dex-nature-nerf"
            % endif
        >
            <% valid_range = c.valid_range[stat][ c.form.level[i].data ] %>\
            % if len(set(valid_range)) == 1:
            ${valid_range[0]}
            % else:
            ${valid_range[0]}–${valid_range[1]}
            % endif
        </td>
        % endfor
    </tr>
    % endif
</tbody>
<tbody>
    % if i == 0 and not c.results:
    <tr>
        <th></th>
        <td colspan="${len(c.stats)}" class="protip">
            ${_(u"Accumulated as your Pokémon battles.")} <br>
            ${_(u"If you don't know what this is, and your Pokémon has EVER battled or eaten a vitamin, this calculator CANNOT work.  Using Rare Candy is okay, though.")}
        </td>
    </tr>
    % endif
    <tr>
        <th>${_(u"Effort")}</th>
        % for field in c.form.effort[i]:
        <td>${lib.literal_field(field, size=3)}</td>
        % endfor
    </tr>
</tbody>
% endfor  ## range(len(c.form.stat))
% if c.results:
<tbody>
    % if 0:
    <tr>
        <th></th>
        <td colspan="${len(c.stats)}" class="protip">
            Your Pokémon's awesome-ness for each stat, from 0 to 31.
        </td>
    </tr>
    % endif
    <tr>
        <th>${_(u"Genes (IVs)")}</th>
        % for stat in c.stats:
        <td>
            % if c.results[stat]:
            ${c.results[stat]}
            % else:
            <span class="impossible">impossible</span>
            % endif
        </td>
        % endfor
    </tr>
    <tr>
        ## Pretty graphs!
        <th></th>
        % for stat in c.stats:
        <td>
            % if c.results[stat]:
            <div class="dex-stat-vertical-graph">
            % for gene in xrange(31, -1, -1):
                % if gene in c.valid_genes[stat]:
                <div class="point" style="background: ${c.stat_graph_chunk_color(gene)};"></div>
                % else:
                <div class="pointless"></div>
                % endif
            % endfor
            </div>
            % endif
        </td>
        % endfor
    </tr>
    % if c.exact:
    <tr>
        <th>${_(u"Hidden Power")}</th>
        <td colspan="${len(c.stats)}"> <p>
            ${h.pokedex.type_link(c.hidden_power_type)} damage,
            with ${c.hidden_power_power} power.
        </p> </td>
    </tr>
    % endif
    <tr>
        <td colspan="${len(c.stats) + 1}">
            % if all(c.results.values()):
            <p>${_(u"And for your copy/pasting pleasure:")}</p>
            <p class="clipboard">
                ${c.results[c.stats[0]]} ${_(u"HP")};
                ${c.results[c.stats[1]]}/${c.results[c.stats[2]]} ${_(u"Physical")};
                ${c.results[c.stats[3]]}/${c.results[c.stats[4]]} ${_(u"Special")};
                ${c.results[c.stats[5]]} ${_(u"Speed")}
            </p>
            % else:
            <p>${_(u"Uh-oh.  The set of stats you gave is totally impossible. Better double-check against your game.")}</p>
            <p>${_(u"The most common problem is effort; if a Pokémon has been trained at all, it'll have some effort accumulated.  This affects its stats, and there's no way to know how much effort it has unless you've been keeping track.  Sorry.")}</p>
            <p>${_(u"If you're desperate, you could try the effort-lowering berries (Pomeg et al.), which will reduce effort in a given stat by 10 at a time.  Drop every stat's effort until it won't drop any further, then try again.")}</p>
            % endif
        </td>
    </tr>
</tbody>
% endif
</table>

<p>
    <input type="hidden" name="shorten" value="1">
    <button type="submit">${_(u"Let's do this!")}</button>
</p>
<p>
    <button type="reset">${_(u"Reset")}</button> ${_(u"or")}
    <a href="${url.current()}"><img src="${h.static_uri('spline', 'icons/eraser.png')}" alt=""> ${_(u"start over")}</a>
</p>
${h.end_form()}
