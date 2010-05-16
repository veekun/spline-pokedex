var pokedex_gadgets = {
    ////// HP-remaining textboxes with little drawn HP bars, for pokeball gadget
    // Create the initial hp bar, and hide by default.  this == textbox
    'init_hp_bar': function() {
        var $this = $(this);
        var $hp = $('<div class="dex-hp-bar"><div class="dex-hp-bar-bar"></div></div>');
        $hp.css('display', 'none');
        $hp.click(pokedex_gadgets.click_hp_bar);
        $this.after($hp);

        $this.keyup(function() {
            pokedex_gadgets.update_hp_bar($(this));
        });

        // Also update now; default is 100, so show it
        pokedex_gadgets.update_hp_bar($this);
    },

    // When a flagged textbox changes, this handler fires and updates the hp bar
    'update_hp_bar': function($textbox) {
        var $hp = $textbox.siblings('.dex-hp-bar').eq(0);
        if (! $hp.length) {
            // Can't find it!  Bail!
            return;
        }

        var value = parseInt($textbox.val());
        if (! value || value < 0 || value > 100) {
            // Either zero or bogus; hide the thing
            $hp.css('display', 'none');
            return;
        }

        // Show the bar
        $hp.css('display', '');

        // Calculate the bar width explicitly rather than as a percentage, to
        // take care of rounding up.  Bar is 48 pixels wide.
        var $hp_bar = $hp.find('.dex-hp-bar-bar');
        var bar_width = Math.ceil(value * 48 / 100);
        $hp_bar.css('width', bar_width + 'px');

        // Fix the color
        $hp_bar.removeClass('green yellow red');
        if (bar_width <= 12)
            $hp_bar.addClass('red');
        else if (bar_width <= 24)
            $hp_bar.addClass('yellow');
        else
            $hp_bar.addClass('green');
    },

    // Handle a click on the hp bar: adjust the textbox accordingly
    'click_hp_bar': function(e) {
        var $this = $(this);
        var bar_position = e.clientX - $this.offset().left;
        // Bar has 16px of decoration on the left...
        bar_position -= 16;

        // Bar is 48px wide
        if (bar_position < 1)
            bar_position = 1;
        else if (bar_position > 48)
            bar_position = 48;

        // Update the textbox, then have it update us
        var $textbox = $this.siblings('.js-dex-dynamic-hp-bar');
        $textbox.val(Math.floor(bar_position / 48 * 100));
        pokedex_gadgets.update_hp_bar($textbox);
    },
};

// Initialize hp bars onload
$(function() {
    $('.js-dex-dynamic-hp-bar').each(pokedex_gadgets.init_hp_bar);
});
