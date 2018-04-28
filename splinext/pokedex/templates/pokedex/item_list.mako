<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! from splinext.pokedex import i18n %>\

<%def name="title()">${_("Items")}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li>${_("Items")}</li>
</ul>
</%def>

<h1>${_("Items")}</h1>

<p>${_("Pick your pocket:")}</p>

<ul class="classic-list">
    % for pocket in c.item_pockets:
    <li>
        <a href="${url(controller='dex', action='item_pockets', pocket=pocket.identifier)}">
            ${dexlib.pokedex_img(u"item-pockets/{0}.png".format(pocket.identifier))}
            ${pocket.name}
        </a>
    </li>
    % endfor
</ul>


