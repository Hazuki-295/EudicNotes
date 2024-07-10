function constructScrollContainer() {
    /* Create the scroll container */
    const scrollContainer = document.createElement('div');
    scrollContainer.className = 'horizontal-scroll-notes';

    /* Create the content div */
    const content = document.createElement('div');
    content.className = 'horizontal-scroll-notes__content';

    const swipe = document.createElement('div');
    swipe.className = 'v-swipe';

    const swipeWrap = document.createElement('div');
    swipeWrap.className = 'v-swipe__wrap';

    swipe.appendChild(swipeWrap);
    content.appendChild(swipe);
    scrollContainer.appendChild(content);

    /* Create the navigation div */
    const nav = document.createElement('div');
    nav.className = 'horizontal-scroll-notes__nav';

    const prev = document.createElement('div');
    prev.className = 'horizontal-scroll-notes__nav__prev';

    const next = document.createElement('div');
    next.className = 'horizontal-scroll-notes__nav__next';

    nav.appendChild(prev);
    nav.appendChild(next);
    scrollContainer.appendChild(nav);

    /* Create the indicator div */
    const indicator = document.createElement('div');
    indicator.className = 'horizontal-scroll-notes__indicator';

    scrollContainer.appendChild(indicator);

    /* Return the scroll container */
    return scrollContainer;
}

function attendItem(itemContent) {
    // Append the item to the swipe wrap
    const swipeWrap = document.querySelector('.v-swipe__wrap');
    const item = document.createElement('div');
    item.className = 'v-swipe__item';
    item.appendChild(itemContent);
    swipeWrap.appendChild(item);

    // Create a new dot in the indicator
    const indicator = document.querySelector('.horizontal-scroll-notes__indicator');
    const dot = document.createElement('div');
    dot.className = 'horizontal-scroll-notes__indicator__dot';
    indicator.appendChild(dot);
}

function addSwipeListeners(noteContainer) {
    const content = noteContainer.querySelector('.horizontal-scroll-notes__content');
    const items = noteContainer.querySelectorAll('.v-swipe__item');
    const prevButton = noteContainer.querySelector('.horizontal-scroll-notes__nav__prev');
    const nextButton = noteContainer.querySelector('.horizontal-scroll-notes__nav__next');
    const bullets = noteContainer.querySelectorAll('.horizontal-scroll-notes__indicator__dot');

    let currentIndex = 0;

    function updateNavigation() {
        bullets.forEach((bullet, index) => {
            bullet.classList.toggle('is-active', index === currentIndex);
        });

        prevButton.classList.toggle('disabled', currentIndex === 0);
        nextButton.classList.toggle('disabled', currentIndex === items.length - 1);
    }

    function scrollToIndex(index) {
        content.scrollLeft = index * content.offsetWidth;
    }

    prevButton.addEventListener('click', () => {
        if (currentIndex > 0) {
            currentIndex--;
            scrollToIndex(currentIndex);
            updateNavigation();
        }
    });

    nextButton.addEventListener('click', () => {
        if (currentIndex < items.length - 1) {
            currentIndex++;
            scrollToIndex(currentIndex);
            updateNavigation();
        }
    });

    content.addEventListener('scroll', () => {
        const scrollLeft = content.scrollLeft;
        const itemWidth = content.offsetWidth;
        const newIndex = Math.round(scrollLeft / itemWidth);

        if (newIndex !== currentIndex) {
            currentIndex = newIndex;
            updateNavigation();
        }
    });

    updateNavigation(); // Initialize navigation state
}