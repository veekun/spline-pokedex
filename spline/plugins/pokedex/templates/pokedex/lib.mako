<%def name="pokedex_img(src, **attr)">\
${h.HTML.img(src=h.url_for(controller='dex', action='media', path=src), **attr)}\
</%def>

<%def name="type_icon(type)">${pokedex_img('chrome/types/%s.png' % type.name, alt=type.name)}</%def>

<%def name="version_icons(*versions)">
% for version in versions:
<%
    # Convert string to version if necessary
    if isinstance(version, basestring):
        version = h.pokedex.version(version)
%>\
${pokedex_img('versions/%s.png' % version.name.lower(), alt=version.name)}\
% endfor
</%def>

<%def name="generation_icon(generation)">
<%
    # Convert string to generation if necessary
    if isinstance(generation, int):
        generation = h.pokedex.generation(generation)
%>\
${pokedex_img('versions/generation-%d.png' % generation.id, alt=generation.name)}\
</%def>
