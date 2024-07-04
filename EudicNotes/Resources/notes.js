function extractNotesIframe() {
    // Get the iframe element
    const iframe = window.frameElement;

    if (!iframe) {
        console.error('No iframe element found');
        return;
    }

    const parentDocument = window.parent.document;
    const iframeDocument = iframe.contentDocument || iframe.contentWindow.document;

    // Insert stylesheets
    const stylesheets = iframeDocument.querySelectorAll('link[rel="stylesheet"]');
    stylesheets.forEach(sheet => {
        const newSheet = parentDocument.createElement('link');
        newSheet.rel = 'stylesheet';
        newSheet.href = sheet.href;
        parentDocument.head.appendChild(newSheet);
    });

    // Insert inline styles
    const inlineStyles = iframeDocument.querySelectorAll('style');
    inlineStyles.forEach(style => {
        const newStyle = document.createElement('style');
        newStyle.textContent = style.textContent;
        parentDocument.head.appendChild(newStyle);
    });

    // Insert scripts
    const scripts = iframeDocument.querySelectorAll('script');
    scripts.forEach(script => {
        const newScript = parentDocument.createElement('script');
        if (script.src) {
            newScript.src = script.src;
        } else {
            newScript.textContent = script.textContent;
        }
        parentDocument.body.appendChild(newScript);
    });

    // Extract the content from the div.notes-container inside the iframe
    const notesContainer = iframeDocument.querySelector('.notes-container');
    if (!notesContainer) {
        console.error('No .notes-container element found inside the iframe');
        return;
    }
    const notesContent = notesContainer.innerHTML;

    // Create a new div element to replace the iframe
    const newDiv = parentDocument.createElement('div');
    newDiv.className = 'notes-container';
    newDiv.innerHTML = notesContent;

    // Replace the iframe with the new div element
    iframe.parentNode.replaceChild(newDiv, iframe);
}

document.addEventListener("DOMContentLoaded", () => {
    extractNotesIframe();
});

function revertFormatting(selector) {
    // Define the mapping for class names to their respective replacement patterns
    const replacementMap = {
        /* Colorful fonts */
        'highlight blue': ['+', '+'],
        'highlight green': ['[', ']'],
        'highlight red': ['<', '>'],
        /* OALD Style */
        'shcut': ['*', '*'],
        'prefix': ['!', '!'],
        'cf': ['@', '@'], 'geo': ['_', '_'],
        'def': ['&', '&'], 'ndv': ['{', '}']
    };

    // Select the element based on the provided selector
    const originalElement = document.querySelector(selector);
    if (!originalElement) {
        console.error('Element not found for the given selector:', selector);
        return;
    }

    // Clone the original element to avoid altering it
    const clonedElement = originalElement.cloneNode(true);

    // Execute the replacement function on the cloned element
    replaceElements(clonedElement);

    // Function to replace the child elements with their original text format recursively
    function replaceElements(element) {
        // Iterate through the element's children first to handle nested elements
        element.childNodes.forEach(child => {
            if (child.nodeType === Node.ELEMENT_NODE) {
                replaceElements(child);
            }
        });

        // Root of the cloned element
        if (!element.parentNode) return;

        // Iterate through each class name in the replacement map
        for (const [classNames, symbols] of Object.entries(replacementMap)) {
            const classes = classNames.split(' ');
            if (classes.every(cls => element.classList.contains(cls))) {
                const textContent = element.textContent;
                const replacementText = `${symbols[0]}${textContent}${symbols[1]}`;
                const replacementNode = document.createTextNode(replacementText);
                element.parentNode.replaceChild(replacementNode, element);
                return;
            }
        }
    }

    // Return the text content of the cloned element
    return clonedElement.textContent.trim();
}