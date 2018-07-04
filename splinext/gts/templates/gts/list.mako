<%inherit file="/base.mako" />
<%namespace name="dexlib" file="/pokedex/lib.mako"/>

<%def name="title()">Stored Pokémon</%def>

% for savefile in c.savefiles:
<div class="gts-pokemon">
    % if savefile.structure.ivs.is_egg:
    ${h.pokedex.pokedex_img("main-sprites/heartgold-soulsilver/egg.png", class_='icon')}
    % else:
    ${h.pokedex.pokemon_form_image(savefile.species_form,
        prefix='main-sprites/heartgold-soulsilver' + ('/shiny' if savefile.is_shiny else ''),
        class_='icon')}
    % endif
    <div class="header">
        <div class="name">
            % if savefile.structure.ivs.is_nicknamed:
            “${savefile.structure.nickname}”
            % else:
            ${savefile.species.full_name}
            % endif
            <span class="gender ${savefile.structure.gender}">
                % if savefile.structure.gender == 'male':
                ♂
                % elif savefile.structure.gender == 'female':
                ♀
                % else:
                &empty;
                % endif
            </span>
        </div>
        <div class="personality">
            ${savefile.structure.personality}<br>
            ${u"0x{0:08x}".format(savefile.structure.personality)}
        </div>
    </div>

    ## Met stuff
    <p>
        Original trainer:
        ${savefile.structure.original_trainer_name}
        ${u'♂' if savefile.structure.original_trainer_gender == 'male' else u'♀'}
        <img src="${h.static_uri('spline', "flags/{0}.png".format(savefile.structure.original_country))}" alt="${savefile.structure.original_country}">,
        ID ${"%05d" % savefile.structure.original_trainer_id}
        <span class="secret-id">/ ${"%05d" % savefile.structure.original_trainer_secret_id}</span>
    </p>
    <p>
        ${h.pokedex.pokedex_img("items/%s.png" % h.pokedex.item_filename(savefile.pokeball),
                   alt=savefile.pokeball.name, title=savefile.pokeball.name)}
        % if savefile.structure.date_egg_received:
        Egg received on ${savefile.structure.date_egg_received} around ${savefile.egg_location.name}.
        Hatched on ${savefile.structure.date_met} around ${savefile.met_location.name} at level 1.
        % else:
        Encountered via ${savefile.structure.encounter_type}
        and caught on ${savefile.structure.date_met}
        around 
        ${h.pokedex.version_icons(savefile.structure.original_version)}
        ${savefile.met_location.name}
        at level ${savefile.structure.met_at_level}.
        % endif
    </p>

    ## Ribbons
    <ul class="gts-pokemon-ribbons">
    % for region, ribbon_container in ('hoenn',  savefile.structure.hoenn_ribbons), \
                                      ('sinnoh', savefile.structure.sinnoh_ribbons), \
                                      ('sinnoh', savefile.structure.sinnoh_contest_ribbons):
        % for ribbon in reversed(ribbon_container.keys()):
        % if ribbon_container[ribbon]:
        <li>${h.pokedex.pokedex_img("ribbons/{0}/{1}.png".format(region, ribbon.replace(u'_', u'-')), alt=ribbon.replace(u'_', u' ').title(), title=ribbon.replace(u'_', u' ').title())}</li>
        % endif
        % endfor
    % endfor
    </ul>

    ## Shiny leaves
    % if savefile.structure.shining_leaves.crown:
    <p>${h.pokedex.pokedex_img('chrome/leaf-crown.png', alt='Leaf Crown', title='Leaf Crown')}</p>
    % elif any(savefile.shiny_leaves):
    <ul class="gts-pokemon-leaves">
        % for leaf in savefile.shiny_leaves:
        <li>
            % if leaf:
            ${h.pokedex.pokedex_img('chrome/shiny-leaf.png', alt='Shiny Leaf', title='Shiny Leaf')}
            % endif
        </li>
        % endfor
    </ul>
    % endif

    <%! from pokedex import formulae %>\
    <div class="dex-column-container gts-pokemon-columns">
    <div class="dex-column">
        <ul class="classic-list">
            <li>Level ${savefile.level}: ${savefile.structure.exp} EXP</li>
            % if savefile.exp_to_next:
            <li>
                <div class="gts-bar-container">
                    <div class="gts-bar" style="width: ${savefile.progress_to_next * 100}%;">&nbsp;${savefile.exp_to_next} to level ${savefile.level + 1}</div>
                </div>
            </li>
            % endif
            <li>Has <a href="${url(controller='dex', action='abilities', name=savefile.ability.name.lower())}">${savefile.ability.name}</a></li>
            <li>
                % if savefile.held_item:
                Holding ${h.pokedex.item_link(savefile.held_item)}
                % else:
                Holding nothing
                % endif
            </li>
            <li>
                <div class="gts-bar-container">
                    <div class="gts-bar" style="width: ${savefile.structure.happiness / 255.0 * 100}%;">&nbsp;${savefile.structure.happiness} happiness</div>
                </div>
            </li>

            % if savefile.structure.fateful_encounter:
            <li class="fateful-encounter">fateful encounter</li>
            % endif
            % if savefile.structure.pokerus:
            <li>PokéRUS!  ${savefile.structure.pokerus}</li>
            % endif

            <li>
                <ul class="gts-pokemon-markings">
                    % if savefile.structure.markings.heart:
                    <li>&#x2665;</li>
                    % else:
                    <li>&#x2661;</li>
                    % endif
                    % if savefile.structure.markings.diamond:
                    <li>&#x25c6;</li>
                    % else:
                    <li>&#x25c7;</li>
                    % endif
                    % if savefile.structure.markings.triangle:
                    <li>&#x25b2;</li>
                    % else:
                    <li>&#x25b3;</li>
                    % endif
                    % if savefile.structure.markings.square:
                    <li>&#x25a0;</li>
                    % else:
                    <li>&#x25a1;</li>
                    % endif
                    % if savefile.structure.markings.star:
                    <li>&#x2605;</li>
                    % else:
                    <li>&#x2606;</li>
                    % endif
                    % if savefile.structure.markings.circle:
                    <li>&#x25cf;</li>
                    % else:
                    <li>&#x25cb;</li>
                    % endif
                </ul>
            </li>
        </ul>
    </div>
    <div class="dex-column">
        <table>
        <thead>
            <tr class="header-row">
                <th></th>
                <th>Base</th>
                <th>Gene</th>
                <th>Exp</th>
                <th>Calc</th>
            </tr>
        </thead>
        <tbody>
            % for stat_info in savefile.stats:
            <tr>
                <th>${stat_info.stat.name}</th>
                <td>${stat_info.base}</td>
                <td>
                    <div class="gts-bar-container">
                        <div class="gts-bar" style="width: ${stat_info.gene / 31.0 * 100}%;">&nbsp;${stat_info.gene}</div>
                    </div>
                </td>
                <td>
                    <div class="gts-bar-container">
                        <div class="gts-bar" style="width: ${stat_info.exp / 255.0 * 100}%;">&nbsp;${stat_info.exp}</div>
                    </div>
                </td>
                <td>${stat_info.calc}</td>
            </tr>
            % endfor
        </tbody>
        </table>
    </div>
    <div class="dex-column">
        <table>
        <thead>
            <tr class="header-row">
                <th colspan="2">Contest stats</th>
            </tr>
        </thead>
        <tbody>
            % for contest_stat in ('beauty', 'cool', 'cute', 'smart', 'tough'):
            <tr>
                <th>${h.pokedex.pokedex_img("contest-types/en/{0}.png".format(contest_stat))}</th>
                <td>
                    <div class="gts-bar-container">
                        <div class="gts-bar" style="width: ${savefile.structure['contest_' + contest_stat] / 255.0 * 100}%;">&nbsp;${savefile.structure['contest_' + contest_stat]}</div>
                    </div>
                </td>
            </tr>
            % endfor
            <tr>
                <th>Sheen</th>
                <td>
                    <div class="gts-bar-container">
                        <div class="gts-bar" style="width: ${savefile.structure.contest_sheen / 255.0 * 100}%;">&nbsp;${savefile.structure.contest_sheen}</div>
                    </div>
                </td>
            </tr>
        </tbody>
        </table>
    </div>
    </div>

    ## Moves
    <table class="dex-pokemon-moves striped-rows">
        ${dexlib.move_table_columns()}
        <thead>
            <tr class="header-row">
                ${dexlib.move_table_header()}
            </tr>
        </thead>
        <tbody>
            % for move, pp in zip(savefile.moves, savefile.move_pp):
            <tr>
                % if move:
                ${dexlib.move_table_row(move, pp_override=pp)}
                % else:
                ${dexlib.move_table_blank_row()}
                % endif
            </tr>
            % endfor
        </tbody>
    </table>

    <!-- Binary blob: ${ savefile.as_struct.encode('hex') } -->
</div>
% endfor
