const loadJQuery = () => {
    const script = document.createElement('script');
    script.src = 'https://code.jquery.com/jquery-3.6.0.min.js';
    script.onload = () => {
        // Load all resources in parallel
        Promise.all([
            $.getScript('https://unpkg.com/swiper/swiper-bundle.min.js'),
            $.getScript('https://cdn.jsdelivr.net/npm/markdown-it/dist/markdown-it.min.js'),
            $.getScript('https://cdn.jsdelivr.net/npm/markdown-it-attrs/markdown-it-attrs.browser.min.js'),
            $('<link/>', { rel: 'stylesheet', href: 'https://unpkg.com/swiper/swiper-bundle.min.css' }).appendTo('head')
        ]).then(() => {
            initializeSwiper();
        });
    };
    document.head.appendChild(script);
};

// Initialize Swiper
const initializeSwiper = () => {
    $(document).ready(function () {
        if (typeof noteDataArray === 'undefined') {
            console.error(`'noteDataArray' is not defined`);
            return;
        }
        window.parent.noteDataArray = noteDataArray;

        const $noteContainer = $('.Hazuki-note');
        if (!$noteContainer.length) return;

        if (noteDataArray.length === 1) {
            $noteContainer.addClass('single-note-mode');
        }

        // Construct Swiper container
        const $swiper = $('<div>', { class: 'swiper' })
            .append($('<div>', { class: 'swiper-wrapper' }))
            .append($('<div>', { class: 'swiper-pagination' }))
            .append($('<div>', { class: 'swiper-button-prev' }))
            .append($('<div>', { class: 'swiper-button-next' }));
        $noteContainer.append($swiper);

        // Initialize Swiper
        const swiper = new Swiper('.swiper', {
            direction: 'horizontal',
            pagination: {
                el: '.swiper-pagination',
                clickable: true,
            },
            navigation: {
                nextEl: '.swiper-button-next',
                prevEl: '.swiper-button-prev',
                enabled: false
            }
        });

        // Append items to Swiper
        noteDataArray.forEach((noteData, index) => {
            const swiperSlide = $('<div>', { class: 'swiper-slide' });
            swiperSlide.append(constructSingleNoteContent(noteData));
            swiper.appendSlide(swiperSlide);
        });

        // Function to construct single note content
        function constructSingleNoteContent(noteData) {
            const $container = $('<div>', { class: 'single-note' });

            // Source
            $('<div>', {
                class: 'note-block',
                'data-label': 'source',
                text: noteData.source
            }).appendTo($container);

            // Original Text
            $('<div>', {
                class: 'note-block',
                'data-label': 'original text',
                html: noteData.originalText
            }).appendTo($container);

            // Notes
            if (noteData.notes !== '') {
                $('<div>', {
                    class: 'note-block',
                    'data-label': 'notes',
                    html: noteData.notes
                }).appendTo($container);
            }

            // Tags
            if (noteData.tags !== '') {
                const $tagContainer = $('<div>', {
                    class: 'note-block',
                    'data-label': 'tags'
                });

                const colors = ['rgb(79, 125, 192)', 'rgb(94, 162, 94)', 'rgb(245, 130, 32)', 'rgba(196, 21, 27)'];
                let currentColorIndex = 0;
                noteData.tags.split(',').forEach(tagString => {
                    if (tagString.trim().length > 0) {
                        $('<div>', {
                            class: 'note-tag',
                            text: tagString.trim(),
                            css: { '--color-tag': colors[currentColorIndex] }
                        }).appendTo($tagContainer);
                        currentColorIndex = (currentColorIndex + 1) % colors.length;
                    }
                });
                $tagContainer.appendTo($container);
            }

            return $container;
        }

        // Auto resize iframe height
        const $iframe = $(window.frameElement);
        $iframe.css({ width: '100%', border: 'none' });
        function adjustIframeHeight() {
            $iframe.height(document.body.scrollHeight + 20);
        }
        adjustIframeHeight();  // Initial adjustment
        $(window).on('resize', adjustIframeHeight);
    });
};

// Start loading scripts
loadJQuery();