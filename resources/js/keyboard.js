$(document).ready(function () {
    // Enable Bootstrap tooltips if any matching elements exist
    if ($('[data-toggle="tooltip"]').length) {
        $('[data-toggle="tooltip"]').tooltip({ container: 'body' });
    }

    // Initialize keyboard plugin only on existing elements with .keyboard class
    const $keyboardElements = $('.keyboard');
    if ($keyboardElements.length) {
        $keyboardElements.keyboard({
            openOn: null,
            stayOpen: false,
            alwaysOpen: false,
            autoAccept: true,
            usePreview: false,
            initialFocus: true,
            rtl: true,
            layout: 'syriac-phonetic',
            hidden: function (event, keyboard, el) {
                // You may want to destroy here: keyboard.destroy();
            }
        });
    } else {
        console.warn("No .keyboard elements found to initialize.");
    }

    // Safely bind layout change buttons
    const $keyboardSelects = $('.keyboard-select');
    if ($keyboardSelects.length) {
        $keyboardSelects.click(function () {
            const keyboardID = '#' + $(this).data("keyboard-id");
            const kb = $(keyboardID).getkeyboard();

            if (!kb) {
                console.warn(`No keyboard initialized for: ${keyboardID}`);
                return;
            }

            // Set new layout
            kb.options.layout = this.id;

            // Reveal keyboard if layout changed or reopened too quickly
            const now = new Date().getTime();
            if (kb.last.layout !== kb.options.layout || (now - kb.last.eventTime) < 200) {
                kb.reveal();
            }
        });
    }

    // Font switcher for Syriac vs. default
    const $fontSwitchers = $('.swap-font');
    if ($fontSwitchers.length) {
        $fontSwitchers.on('click', function () {
            const selectedFont = $(this).data("font-id");
            if (!selectedFont) {
                console.warn("No font ID found on clicked .swap-font element.");
                return;
            }

            $('.selectableFont').not('.syr').css('font-family', selectedFont);
            $("*:lang(syr)").css('font-family', selectedFont);
        });
    }
});
