<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="lib.mako" />
<%! from splinext.pokedex import i18n %>\

<%def name="title()">${_("Natures")}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li>${_("Natures")}</li>
</ul>
</%def>

${h.h1(_('Nature list'))}

<p>
    % if c.sort_order == u'stat':
    <a href="${url.current()}"><img src="${h.static_uri('spline', 'icons/sort-alphabet.png')}"> ${_("Sort by name")}</a>
    % else:
    <a href="${url.current(sort=u'stat')}"><img src="${h.static_uri('spline', 'icons/sort-rating.png')}"> ${_("Sort by stat")}</a>
    % endif
</p>

<table class="dex-nature-list striped-rows">
<colgroup span="1"></colgroup> <!-- name -->
<colgroup span="2"></colgroup> <!-- stats -->
<colgroup span="2"></colgroup> <!-- flavors -->
<thead>
    <tr class="header-row">
        <th>${_("Name")}</th>
        <th>${_("+10%")}</th>
        <th>${_("-10%")}</th>
        <th>${_("Likes flavor")}</th>
        <th>${_("Hates flavor")}</th>
    </tr>
</thead>
<tbody>
% for nature in c.natures:
    <tr>
        <td><a href="${url(controller='dex', action='natures', name=nature.name.lower())}">${nature.name}</a></td>

        % if nature.increased_stat == nature.decreased_stat:
        <td>${_(u"—")}</td>
        <td>${_(u"—")}</td>
        % else:
        <td>${nature.increased_stat.name}</td>
        <td>${nature.decreased_stat.name}</td>
        % endif

        % if nature.likes_flavor == nature.hates_flavor:
        <td class="flavor">${_(u"—")}</td>
        <td class="flavor">${_(u"—")}</td>
        % else:
        <td class="flavor">
            ${nature.likes_flavor.flavor}:
            ${dexlib.pokedex_img("contest-types/{1}/{0}.png".format(nature.likes_flavor.identifier, c.game_language.identifier), alt=nature.likes_flavor.name)}
        </td>
        <td class="flavor">
            ${nature.hates_flavor.flavor}:
            ${dexlib.pokedex_img("contest-types/{1}/{0}.png".format(nature.hates_flavor.identifier, c.game_language.identifier), alt=nature.hates_flavor.name)}
        </td>
        % endif
    </tr>
% endfor
</tbody>
</table>

${h.h1(_('Characteristics'))}

<p>Your Pokémon's characteristic tells you which of its genes is highest, and which digit that gene's value ends with.</p>

<table class="dex-nature-list striped-rows">
    <thead>
        <tr class="header-row">
            <th></th>
          % for mod5 in range(5):
            <th>Ends with ${mod5} or ${mod5 + 5}</th>
          % endfor
        </tr>
    </thead>
    <tbody>
      % for stat, characteristics in sorted(c.characteristics.items(), key=lambda kv: kv[0].id):
        <tr>
            <th>${stat.name}</th>
          % for mod5 in range(5):
            <td>${characteristics[mod5]}</td>
          % endfor
        </tr>
      % endfor
    </tbody>
</table>
