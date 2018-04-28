<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako" />

<%! from splinext.pokedex import i18n %>
<%def name="title()">
${_(u'{name} - Kingdoms - Pokémon Conquest').format(name=c.kingdom.name)}
</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li><a href="${url(controller='dex_conquest', action='kingdoms_list')}">${_(u'Kingdoms')}</a></a>
    <li>${c.kingdom.name}</li>
</ul>
</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_kingdom.name.lower())}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${c.prev_kingdom.name}
    </a>
    <a href="${url.current(name=c.next_kingdom.name.lower())}" id="dex-header-next" class="dex-box-link">
        ${c.next_kingdom.name}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${c.kingdom.name}
</div>

${h.h1(_('Essentials'))}

## Portrait block
<div class="dex-page-portrait">
    <p id="dex-page-name">${c.kingdom.name}</p>
    <p id="dex-page-types">${h.pokedex.type_link(c.kingdom.type)}</p>
</div>

<div class="dex-page-beside-portrait">
<p>Under construction</p>
</div>
