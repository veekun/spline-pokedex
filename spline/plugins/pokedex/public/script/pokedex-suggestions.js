var pokedex_suggestions = {
    /*** Pokédex lookup suggestions */
    'previous_input':   "",    // don't double request the same string
    '$lookup_element':  null,  // where the dropdown box is right now
    'request':          null,  // ajax request, for canceling
    'page_height':      8,     // number of elements pgup/pgdn should scroll
    'initialized':      false, // has initialize run?

    // Use a wrapper to set a small delay on the ajax request; otherwise we'll
    // ping the server after every keypress, even if the user wasn't finished
    // typing
    'timeout':         null,
    'change_wrapper': function(e) {
        // Cancel any pending request
        if (pokedex_suggestions.timeout)
            window.clearTimeout(pokedex_suggestions.timeout);

        // The actual handler will also clear this timeout
        pokedex_suggestions.timeout = window.setTimeout(
            function() { pokedex_suggestions.change(e) },
            250
        );
    },

    // Handle typing in a suggestion textbox: fire off a request for matching
    // page names
    'change': function(e) {
        // Clear double-request timeout
        pokedex_suggestions.timeout = null;

        var $suggest_box = $('#dex-suggestions');
        var el = e.target;
        var input = el.value;

        // Don't request for the same input twice.  This happens if the user
        // pressed a navigation key, ctrl-c, overtyped a letter with the same
        // letter, etc.  If the user switched textboxes, the blur code will
        // have cleared the previous input, so having a single global is ok.
        if (input == pokedex_suggestions.previous_input) return;
        pokedex_suggestions.previous_input = input;

        // Hide the list of suggestions if there's not enough input
        if ($suggest_box.length && input.length < 2) {
            pokedex_suggestions.hide();
            return;
        }

        // Cancel any running request, or we might get a bunch of responses in
        // the wrong order
        if (pokedex_suggestions.request)
            pokedex_suggestions.request.abort();

        // Construct request URL
        var url = "/dex/suggest?prefix=" + encodeURIComponent(input);
        var type;
        if (pokedex_suggestions.$lookup_element.is(".js-dex-suggest-pokemon"))
            url += ";type=pokemon";
        else if (pokedex_suggestions.$lookup_element.is(".js-dex-suggest-move"))
            url += ";type=move";

        // Might be embedded from elsewhere...
        if (window.__veekun_url_prefix)
            url = window.__veekun_url_prefix + url;

        // Perform request, saving the request object in case we need to cancel
        // it later
        pokedex_suggestions.request = $.ajax({
            type: "GET",
            url: url,
            dataType: "jsonp",
            error: function(foo, bar, quux) {
                pokedex_suggestions.request = null;
            },
            success: function(res) {
                pokedex_suggestions.request = null;
                if (res[0] != el.value) return;

                // Clear the suggestion box
                $suggest_box.children().remove();
                $suggest_box.scrollTop(0);

                var suggestions = res[1];
                var normalized_input = res[5];
                var len = normalized_input.length;
                for (var i in suggestions) {
                    var suggestion = suggestions[i];
                    var metadata = res[4][i];

                    var $suggestion_el = $('<li></li>');
                    $suggestion_el.addClass('dex-suggestion-' + metadata.type);

                    // Wrap whatever the user typed in bold/underlines
                    var typed_index = metadata.indexed_name.toLowerCase()
                                              .indexOf(normalized_input.toLowerCase());
                    if (typed_index != -1) {
                        var $typed_part = $('<span class="typed"></span>')
                        $typed_part.text(suggestion.substr(typed_index, len));

                        $suggestion_el.text(suggestion.substr(0, typed_index));
                        $suggestion_el.append($typed_part);
                        $suggestion_el.append(suggestion.substr(typed_index + len));
                    }

                    if (metadata.image) {
                        $suggestion_el.css('background-image', "url(" + metadata.image + ")");
                    }

                    // Add country flag if not English
                    if (metadata.language && metadata.language != 'us') {
                        $suggestion_el.prepend('<img src="' + metadata.language_icon + '"'
                                             + ' alt="[' + metadata.language + ']"> ');
                    }

                    $suggest_box.append($suggestion_el);
                }

                if (suggestions.length) {
                    $suggest_box.css('visibility', 'visible');
                }
                else {
                    $suggest_box.css('visibility', 'hidden');
                }

                pokedex_suggestions.move_results();
            }
        });
    },

    // Handle keypresses in a suggest box.  Used to detect navigation keys and
    // move the selection within the menu as appropriate
    'keydown': function(e) {
        var $lookup = $(e.target);
        var $previous_element = pokedex_suggestions.$lookup_element;
        pokedex_suggestions.$lookup_element = $lookup;

        // If a letter was pressed it should be handled normally
        if (e.keyCode == 32 || e.keyCode >= 48)  // printable
            return;

        var $suggest_box = $('#dex-suggestions');
        if (!$suggest_box.length) return;
        var $selected = $suggest_box.find('.selected');

        // If we're using a different lookup element than before, we've gotta
        // move the result list
        if ($lookup != $previous_element) {
            pokedex_suggestions.move_results();
        }


        // Number of lines to scroll in the case of up/down/pgup/pgdn
        var lines = (e.keyCode == 33 || e.keyCode == 34)  // pgup; pgdn
                  ? pokedex_suggestions.page_height
                  : 1;

        // Handle keypress
        if (e.keyCode == 27) {  // esc
            pokedex_suggestions.hide();
        }
        // These four cases are used for moving the selection highlight up
        // and down the fake listbox
        else if (e.keyCode == 33 || e.keyCode == 38) {  // pgup; up
            // If the suggestion list isn't visible, show it
            if ($suggest_box.css('visibility') == "hidden") {
                $suggest_box.css('visibility', 'visible');
                return;
            }

            // Select the previous suggestion, defaulting to the last
            var $prev = $selected;
            if ($selected.length) {
                for (var i = 0; i < lines; i++) {
                    $prev = $prev.prev();
                }

                // Don't jump from second into the void
                if (! $prev.length && ! $selected.is(':first-child'))
                    $prev = $suggest_box.children(':first-child');
            }
            else {
                $prev = $suggest_box.children(':last-child');
            }

            $selected.removeClass('selected');
            $prev.addClass('selected');

            // Make the selection visible and prevent normal editor control
            if ($prev.length) {
                pokedex_suggestions.scroll_into_view($prev);
                e.preventDefault();
            }
        }
        else if (e.keyCode == 34 || e.keyCode == 40) {  // pdgn; down
            // If the suggestion list isn't visible, show it
            if ($suggest_box.css('visibility') == "hidden") {
                $suggest_box.css('visibility', 'visible');
                return;
            }

            // Select the next suggestion, defaulting to the first
            var $next = $selected;
            if ($selected.length) {
                for (var i = 0; i < lines; i++) {
                    $next = $next.next();
                }

                // Don't jump from second-to-last into the void
                if (! $next.length && ! $selected.is(':last-child'))
                    $next = $suggest_box.children(':last-child');
            }
            else {
                $next = $suggest_box.children(':first-child');
            }

            $selected.removeClass('selected');
            $next.addClass('selected');

            // Make the selection visible and prevent normal editor control
            if ($next.length) {
                pokedex_suggestions.scroll_into_view($next);
                e.preventDefault();
            }
        }
        // Select the highlighted entry if there be one, otherwise submit
        else if (e.keyCode == 13 || e.keyCode == 14) {  // return; enter
            // If the suggestion list isn't visible, do nothing special
            if ($suggest_box.css('visibility') == "hidden"
                || ! $selected.length)
            {
                return;
            }

            // Otherwise, populate target lookup box...
            var new_input = pokedex_suggestions.get_lookup_input($selected);
            $lookup.val(new_input);
            pokedex_suggestions.previous_input = new_input;  // prevent ajaxing again

            // ...and kill submit
            e.preventDefault();

            pokedex_suggestions.hide();
        }
    },

    // User clicked on one of the suggestions.  Works just like pressing Enter
    'click_suggestion': function(e) {
        var $target = $(e.target);
        var $selected = $target.closest('li');

        pokedex_suggestions.$lookup_element.val(
            pokedex_suggestions.get_lookup_input($selected)
        );
        pokedex_suggestions.hide();
    },

    'scroll_into_view': function($el) {
        var $parent = $el.parent();
        // jQuery apparently relies on reading CSS for position(), which
        // doesn't work so well when I use em.  Use offsetTop directly instead
        var top = $el[0].offsetTop;
        var bottom = top + $el.outerHeight();

        // If the bottom of the element is below the viewport of the parent,
        // scroll down
        var min_scroll = bottom - $parent.innerHeight();
        if ($parent.scrollTop() < min_scroll)
            $parent.scrollTop(min_scroll);

        // If the top of the element is above the viewport of the parent,
        // scroll up.  Do this second so that an element taller than the
        // viewport has its top visible
        var max_scroll = top;
        if ($parent.scrollTop() > max_scroll)
            $parent.scrollTop(max_scroll);
    },

    'move_results': function() {
        var $suggest_box = $('#dex-suggestions');
        if (!$suggest_box.length) return;
        if (!pokedex_suggestions.$lookup_element) return;

        var $lookup = pokedex_suggestions.$lookup_element;
        var position = $lookup.offset();

        $suggest_box.css({
            'top':  (position.top + $lookup.outerHeight()) + 'px',
            'left':  position.left + 'px',
            'width': $lookup.outerWidth() + 'px'
        });
    },

    'hide': function() {
        $('#dex-suggestions').css('visibility', 'hidden');
    },

    // Returns appropriate input for the lookup box, given a suggestion <li>
    'get_lookup_input': function($suggestion) {
        return $suggestion.text();
    },

    // Set up the whole suggestion engine
    'initialize': function() {
        var $suggest_box = $('<ul id="dex-suggestions"></ul>');
        $suggest_box.css('visibility', 'hidden');
        $suggest_box.mousedown(pokedex_suggestions.click_suggestion);
        $('body').append($suggest_box);

        // Attach events to all lookup boxes
        $(".js-dex-suggest")
            .attr("autocomplete", "off")
            .keyup(pokedex_suggestions.change_wrapper)
            .keydown(pokedex_suggestions.keydown)
            .blur(function(){ window.setTimeout(pokedex_suggestions.hide, 10) });

        $(document).resize(pokedex_suggestions.move_results);
        pokedex_suggestions.move_results();

        pokedex_suggestions.initialized = true;
    },


    "IE is retarded and doesn't support trailing commas in lists": null
};


$(pokedex_suggestions.initialize);
