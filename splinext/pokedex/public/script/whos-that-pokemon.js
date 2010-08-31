// who's that pokemon?
// it's eevee!

var whos_that_pokemon = {
    //// Utilities
    'set_state': function(state) {
        $('#js-dex-wtp').get(0).className = 'state-' + state;
    },


    //// User interaction
    // Ask the user a question
    'ask_question': function() {
        whos_that_pokemon.set_state('thinking');

        var $board = $('#js-dex-wtp-board');

        // Pick a Pokémon
        var pokemon = Math.floor(Math.random() * 493 + 1);  // XXX
        $board.data('answer', pokemon);

        // Create the question -- for now, just the cry.
        // Don't autoplay it!  Bind a "all loaded" event, so we can show the
        // 'play' pane before actually playing the sound
        var $el = $('<audio>');
        $el.one('loadeddata', whos_that_pokemon.ask_question_done);
        $el.attr({
            'src': '/dex/media/cries/' + pokemon + '.ogg',
            'controls': 'controls',

            'autobuffer': 'autobuffer',  // old
            'preload':    'auto',        // new
        });
        $board.find('.question').empty().append($el);

        // Be sure to clear the answer box
        $board.find('.answer input[name="pokemon"]').val('');
    },

    // Finish asking; runs after the media has loaded, and actually shows it
    'ask_question_done': function() {
        whos_that_pokemon.set_state('playing');
        $('#js-dex-wtp-board .question audio').each(function() { this.play(); });
    },

    // onsubmit handler for the answer form, so both the button and pressing
    // Enter work the same way
    'answer_question': function(e) {
        whos_that_pokemon.set_state('answering');

        var answer = $('#js-dex-wtp-board .answer input[name="pokemon"]').val();
        var correct = $('#js-dex-wtp-board').data('answer');

        if (answer == correct) {
            $('#js-dex-wtp-result .response').text('yes.  :3');
        }
        else {
            $('#js-dex-wtp-result .response').text('no, sorry  :(  correct answer is ' + correct);
        }

        // This is a real form, so uh, kill the submit
        e.preventDefault();
    },
};

// Onload setup
$(function() {
    whos_that_pokemon.set_state('off');

    // Bind the answer button
    $('#js-dex-wtp-board button[type="submit"]').click(whos_that_pokemon.answer_question);

    // Bind the button to begin the game!
    $('#js-dex-wtp-start, #js-dex-wtp-restart').click(function() {
        // XXX test for support of javascript, canvas, ogg (with canPlayType), etc

        whos_that_pokemon.ask_question();
    });
});
