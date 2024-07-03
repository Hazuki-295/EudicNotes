document.addEventListener("DOMContentLoaded", function () {
    const iframe = window.frameElement;
    if (iframe) {
        const resizeObserver = new ResizeObserver(() => {
            iframe.style.height = document.body.scrollHeight + 'px';
        });

        resizeObserver.observe(document.body);
    }
});