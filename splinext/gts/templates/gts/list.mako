<%inherit file="/base.mako" />

<%def name="title()">Stored Pokémon</%def>

% for savefile in c.savefiles:
<div class="gts-pokemon">
    % if savefile.structure.ivs.is_egg:
    ${h.pokedex.pokedex_img("heartgold-soulsilver/egg.png", class_='icon')}
    % else:
    ${h.pokedex.pokedex_img("heartgold-soulsilver/{0}{1}.png".format(
            'shiny/' if savefile.is_shiny else '',
            savefile.structure.national_id),
        class_='icon')}
    % endif
    <div class="header">
        <div class="name">
            % if savefile.structure.ivs.is_nicknamed:
            “${savefile.structure.nickname}”
            % else:
            ## XXX pokemon name
            ${savefile.structure.nickname}
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
            % if savefile.structure.alternate_form:
            ~ ${savefile.structure.alternate_form}
            % endif
        </div>
        <div class="personality">
            ${savefile.structure.personality}<br>
            ${u"0x{0:08x}".format(savefile.structure.personality)}
        </div>
    </div>

    <p>
        Original trainer:
        ${savefile.structure.original_trainer_name}
        ${u'♂' if savefile.structure.original_trainer_gender == 'male' else u'♀'}
        <img src="${h.static_uri('spline', "flags/{0}.png".format(savefile.structure.original_country))}" alt="${savefile.structure.original_country}">,
        ID ${savefile.structure.original_trainer_id}
        <span class="secret-id">/ ${savefile.structure.original_trainer_secret_id}</span>
    </p>
    <p>
        % if savefile.structure.date_egg_received == savefile.structure.date_met:
        Born and hatched on ${savefile.structure.date_egg_received}
        % elif savefile.structure.date_egg_received:
        Born on ${savefile.structure.date_egg_received};
        hatched on ${savefile.structure.date_met})
        % else:
        [${savefile.structure.dppt_pokeball} ${savefile.structure.hgss_pokeball}]
        Caught on ${savefile.structure.date_met}
        at level ${savefile.structure.met_at_level}
        % endif

        at place number ${savefile.structure.dp_met_location_id}
        or maybe ${savefile.structure.dp_egg_location_id}
        orrrr ${savefile.structure.pt_met_location_id}
        or???? ${savefile.structure.pt_egg_location_id}
        ${h.pokedex.pokedex_img("versions/{0}.png".format(savefile.structure.original_version))}

        ps was a ${savefile.structure.encounter_type}
        % if savefile.structure.fateful_encounter:
        also fateful
        % endif
    </p>

    <h2>Stats</h2>
    <dl>
        <dt>Experience</dt>
        <dd>${savefile.structure.exp}</dd>
        <dt>Happiness</dt>
        <dd>${savefile.structure.happiness}</dd>
        <dt>Held item</dt>
        <dd>${savefile.structure.held_item_id}</dd>
        <dt>Ability</dt>
        <dd>${savefile.structure.ability_id}</dd>
        <dt>Pokérus</dt>
        <dd>${savefile.structure.pokerus}</dd>
        <dt>Markings</dt>
        <dd>
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
        </dd>
        <dt>Shiny leaves</dt>
        <dd>
            % if savefile.structure.shining_leaves.crown:
            ${h.pokedex.pokedex_img('chrome/leaf-crown.png', alt='Leaf Crown', title='Leaf Crown')}
            % else:
            <ul class="gts-pokemon-leaves">
                % for leaf_n in range(1, 6):
                <li>
                    % if savefile.structure.shining_leaves['leaf' + str(leaf_n)]:
                    ${h.pokedex.pokedex_img('chrome/shiny-leaf.png', alt='Shiny Leaf', title='Shiny Leaf')}
                    % endif
                </li>
                % endfor
            </ul>
            % endif
        </dd>
        <dt>Ribbons</dt>
        <dd>
            <ul class="gts-pokemon-ribbons">
            % for region, ribbon_container in ('hoenn',  savefile.structure.hoenn_ribbons), \
                                              ('sinnoh', savefile.structure.sinnoh_ribbons), \
                                              ('sinnoh', savefile.structure.sinnoh_contest_ribbons):
                % for ribbon in reversed(ribbon_container.__attrs__):
                % if ribbon_container[ribbon]:
                <li>${h.pokedex.pokedex_img("ribbons/{0}/{1}.png".format(region, ribbon.replace(u'_', u'-')), alt=ribbon.replace(u'_', u' ').title(), title=ribbon.replace(u'_', u' ').title())}</li>
                % endif
                % endfor
            % endfor
            </ul>
        </dd>
    </dl>

    <div class="dex-column-container gts-pokemon-columns">
    <div class="dex-column">
        <table>
        <thead>
            <tr class="header-row">
                <th>Stat</th>
                <th>Gene</th>
                <th>Exp</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <th>HP</th>
                <td>${savefile.structure.ivs.iv_hp}</td>
                <td>${savefile.structure.effort_hp}</td>
            </tr>
            <tr>
                <th>Attack</th>
                <td>${savefile.structure.ivs.iv_attack}</td>
                <td>${savefile.structure.effort_attack}</td>
            </tr>
            <tr>
                <th>Defense</th>
                <td>${savefile.structure.ivs.iv_defense}</td>
                <td>${savefile.structure.effort_defense}</td>
            </tr>
            <tr>
                <th>Special Attack</th>
                <td>${savefile.structure.ivs.iv_special_attack}</td>
                <td>${savefile.structure.effort_special_attack}</td>
            </tr>
            <tr>
                <th>Special Defense</th>
                <td>${savefile.structure.ivs.iv_special_defense}</td>
                <td>${savefile.structure.effort_special_defense}</td>
            </tr>
            <tr>
                <th>Speed</th>
                <td>${savefile.structure.ivs.iv_speed}</td>
                <td>${savefile.structure.effort_speed}</td>
            </tr>
        </tbody>
        </table>
    </div>
    <div class="dex-column">
        <table>
        <thead>
            <tr class="header-row">
                <th>move_id</th>
                <th>pp</th>
                <th>pp_ups</th>
            </tr>
        </thead>
        <tbody>
            % for i in range(1, 5):
            <tr>
                <td>${savefile.structure['move' + str(i) + '_id']}</td>
                <td>${savefile.structure['move' + str(i) + '_pp']}</td>
                <td>${savefile.structure['move' + str(i) + '_pp_ups']}</td>
            </tr>
            % endfor
        </tbody>
        </table>
    </div>
    <div class="dex-column">
        <table>
        <thead>
            <tr class="header-row">
                <th></th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            % for contest_stat in ('beauty', 'cool', 'cute', 'smart', 'tough'):
            <tr>
                <th>${contest_stat}</th>
                <td>${savefile.structure['contest_' + contest_stat]}</td>
            </tr>
            % endfor
        </tbody>
        </table>
    </div>
    </div>
</div>
% endfor
