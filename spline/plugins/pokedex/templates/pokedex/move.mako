<%inherit file="/base.mako"/>

<%def name="title()">${c.move.name} – Move #${c.move.id}</%def>

<h1>Essentials</h1>

<div id="dex-page-portrait">
    <p id="dex-page-name">${c.move.name}</p>
    <p id="dex-page-types">
        ${h.pokedex.type_link(c.move.type)}
        ${h.pokedex.damage_class_icon(c.move.damage_class)}
    </p>
    <p>${h.pokedex.generation_icon(c.move.generation)}</p>
</div>

<div id="dex-page-beside-portrait">
<h2>Summary</h2>
<p>${h.literal(c.move.short_effect.as_html)}</p>
</div>

<h2>Damage Dealt</h2>
<ul id="dex-page-damage">
    % for type, damage_factor in sorted(c.type_efficacies.items(), \
                                        key=lambda x: x[0].name):
    <li class="dex-damage-dealt-${damage_factor}">
        ${h.pokedex.type_link(type)} ${h.pokedex.type_efficacy_label[damage_factor]}
    </li>
    % endfor
</ul>
</div>

<div class="dex-column-container">
<div class="dex-column">
    <h2>Stats</h2>
    <dl>
        <dt>Power</dt>
        % if c.move.damage_class.name == 'None':
        <dd>n/a</dd>
        % else:
        <dd>${c.move.power}</dd>
        % endif
        <dt>Accuracy</dt>
        <dd>
            ${c.move.accuracy}%
            % if c.move.accuracy != 100 and c.move.damage_class.name != 'None':
            ≈ ${"%.1f" % (c.move.power * c.move.accuracy / 100.0)} power
            % endif
        </dd>
        <dt>PP</dt>
        <dd>${c.move.pp}, up to ${c.move.pp * 8/5} with <a href="${url(controller='dex', action='items', name='pp up')}">PP Up</a></dd>
        <dt>Target</dt>
        <dd><abbr title="${c.move.target.description}">${c.move.target.name}</abbr></dd>
        <dt>Effect chance</dt>
        <dd>${c.move.effect_chance or 'n/a'}</dd>
        <dt>Priority</dt>
        % if c.move.priority > 0:
        <dd><span class="dex-priority-fast">${c.move.priority}</span> (fast)</dd>
        % elif c.move.priority < 0:
        <dd><span class="dex-priority-slow">${c.move.priority}</span> (slow)</dd>
        % else:
        <dd>${c.move.priority} (normal)</dd>
        % endif
    </dl>
</div>

<div class="dex-column">
    <h2>Flags</h2>

</div>

<div class="dex-column">
    <h2>Names</h2>
    <dl>
        % for foreign_name in c.move.foreign_names:
        <dt>${foreign_name.language.name}</dt>
        % if foreign_name.language.name == 'Japanese':
        <dd>${foreign_name.name} (${h.pokedex.romanize(foreign_name.name)})</dd>
        % else:
        <dd>${foreign_name.name}</dd>
        % endif
        % endfor
    </dl>

    <h2>Machines</h2>
    <dl>
      % for generation, machine_number in sorted(c.machines.items(), \
                                                 key=lambda (k, v): k.id):
        <dt>${h.pokedex.generation_icon(generation)}</dt>
        % if not machine_number:
        <dd>Not a TM</dd>
        % elif machine_number > 100:
        <dd>HM${"%02d" % (machine_number - 100)}</dd>
        % else:
        <dd>TM${"%02d" % machine_number}</dd>
        % endif
      % endfor
    </dl>
</div>
</div>


<h1>Effect</h1>
<div class="dex-effect">
${h.literal(c.move.effect.as_html)}
</div>
