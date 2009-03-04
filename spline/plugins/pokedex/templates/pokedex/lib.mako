<%def name="type_icon(type)">
${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='chrome/types/%s.png' % type.name), alt=type.name)}
</%def>

<%def name="version_icons(*versions)">
% for version in versions:
<%
    # Convert string to version if necessary
    if isinstance(version, basestring):
        version = c.dexlib.version(version)
%>\
${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='versions/%s.png' % version.name.lower()), alt=version.name)}\
% endfor
</%def>

<%def name="generation_icon(generation)">
<%
    # Convert string to generation if necessary
    if isinstance(generation, int):
        generation = c.dexlib.generation(generation)
%>
${h.HTML.img(src=h.url_for(controller='dex', action='images', image_path='versions/generation-%d.png' % generation.id), alt=generation.name)}
</%def>
