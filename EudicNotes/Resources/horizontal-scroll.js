document.addEventListener('DOMContentLoaded', () => {
    const images = [];

    // Define the base HTML structure with comments for guidance
    const baseHtml = `
        <div class="horizontal-scroll-album">
            <div class="horizontal-scroll-album__content">
                <div class="v-swipe">
                    <div class="v-swipe__wrap">
                        <!-- Repeat this block for each image -->
                    </div>
                </div>
            </div>
            <div class="horizontal-scroll-album__nav">
                <div class="horizontal-scroll-album__nav__prev"></div>
                <div class="horizontal-scroll-album__nav__next"></div>
            </div>
            <div class="horizontal-scroll-album__indicator">
                <!-- Repeat this block for each image -->
            </div>
        </div>
    `;

    // Use DOMParser to convert the string to a DOM node
    const parser = new DOMParser();
    const doc = parser.parseFromString(baseHtml, 'text/html');
    const album = doc.querySelector('.horizontal-scroll-album');
    const swipeWrap = album.querySelector('.v-swipe__wrap');
    const indicator = album.querySelector('.horizontal-scroll-album__indicator');

    // Populate the swipe and indicators
    images.forEach(src => {
        const swipeItem = document.createElement('div');
        swipeItem.className = 'v-swipe__item';
        swipeItem.innerHTML = `
            <div class="horizontal-scroll-album__pic">
                <img src="${src}">
            </div>
        `;
        swipeWrap.appendChild(swipeItem);

        const dot = document.createElement('div');
        dot.className = 'horizontal-scroll-album__indicator__dot';
        indicator.appendChild(dot);
    });

    // Append the album to the document body
    document.body.appendChild(album);
});

document.addEventListener('DOMContentLoaded', function () {
    const wrap = document.querySelector('.v-swipe__wrap');
    const items = document.querySelectorAll('.v-swipe__item');
    const prevButton = document.querySelector('.horizontal-scroll-album__nav__prev');
    const nextButton = document.querySelector('.horizontal-scroll-album__nav__next');
    const bullets = document.querySelectorAll('.horizontal-scroll-album__indicator__dot');

    let currentIndex = 0;

    function updateNavigation() {
        bullets.forEach((bullet, index) => {
            if (index === currentIndex) {
                bullet.classList.add('is-active');
            } else {
                bullet.classList.remove('is-active');
            }
        });

        prevButton.classList.toggle('disabled', currentIndex === 0);
        nextButton.classList.toggle('disabled', currentIndex === items.length - 1);
    }

    prevButton.addEventListener('click', () => {
        if (currentIndex > 0) {
            currentIndex--;
            wrap.style.transform = `translateX(-${currentIndex * 100}%)`;
            updateNavigation();
        }
    });

    nextButton.addEventListener('click', () => {
        if (currentIndex < items.length - 1) {
            currentIndex++;
            wrap.style.transform = `translateX(-${currentIndex * 100}%)`;
            updateNavigation();
        }
    });

    updateNavigation(); // Initialize navigation state
});