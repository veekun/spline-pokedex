<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! from splinext.pokedex import i18n %>\

<%def name="title()">
${_("%s pocket - Items") % (c.item_pocket.name)}
</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li><a href="${url(controller='dex', action='items_list')}">${_("Items")}</a></li>
    <li>${_("%s pocket") % (c.item_pocket.name)}</li>
</ul>
</%def>

## Menu sort of thing
<ul id="dex-item-pockets">
    % for pocket in c.item_pockets:
    <li>
        <a href="${url(controller='dex', action='item_pockets', pocket=pocket.identifier)}">
            ${dexlib.pokedex_img("item-pockets/{1}{0}.png".format(pocket.identifier, 'selected/' if pocket == c.item_pocket else ''), title=pocket.name)}
        </a>
    </li>
    % endfor
</ul>

<h1>${(c.item_pocket.name)}</h1>

<table class="striped-rows">
<tr class="header-row">
    % if c.item_pocket.identifier == u'berries':
    <th>${_("Num")}</th>
    % endif
    <th>${_("Item")}</th>
    <th>Effect</th>
</tr>
% for category in c.item_pocket.categories:
% if category.name:
<tr class="subheader-row">
    <th colspan="999">${category.name}</th>
</tr>
% endif
% for item in category.items:
<tr>
    % if c.item_pocket.identifier == u'berries':
    % if item.berry:
    <td>${item.berry.id}</td>
    % else:
    <td>?</td>
    % endif
    % endif
    <td>${dexlib.item_link(item)}</td>
    <td>
        % if item.short_effect:
        ${item.short_effect}
        % endif
    </td>
</tr>
% endfor
% endfor
</table>
