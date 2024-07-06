function extractNotesIframe() {
    const parentDocument = window.parent.document;
    const iframeDocument = document;

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

    // Get the note container
    const noteContainer = iframeDocument.querySelector('.Hazuki-note');
    if (!noteContainer) {
        console.error('No Hazuki-note element found inside the iframe');
        return;
    }
    const noteContent = noteContainer.innerHTML;

    // Create a new div element to replace the iframe
    const newNoteContainer = parentDocument.createElement('div');
    newNoteContainer.className = 'Hazuki-note';
    newNoteContainer.innerHTML = noteContent;

    // Replace the iframe with the new div element
    iframe.parentNode.replaceChild(newNoteContainer, iframe);
}

document.addEventListener('DOMContentLoaded', () => {
    // Check if the script is running inside an iframe
    if (window.frameElement) {
        extractNotesIframe();
    }
});

const replacementMap = {
    highlightText: {
        'highlight blue': ['+', '+'],
        'highlight green': ['[', ']'],
        'highlight red': ['<', '>'],
    },
    oaldStyle: {
        'shcut': ['*', '*'],
        'prefix': ['!', '!'],
        'cf': ['@', '@'], 'geo': ['_', '_'],
        'def': ['&', '&'], 'ndv': ['{', '}']
    }
};

// Use a regular expression to globally replace the markers
function transformText(text, map) {
    for (const [className, [open, close]] of Object.entries(map)) {
        const regex = new RegExp(`\\${open}(.*?)\\${close}`, 'g');
        text = text.replace(regex, (match, content) => {
            if (className === 'shcut' || className === 'def') {
                // Find the index where English ends and Chinese begins
                const transitionIndex = content.search(/[\u4e00-\u9fff]/);
                if (transitionIndex !== -1) {
                    let englishPart = content.substring(0, transitionIndex);
                    let chinesePart = content.substring(transitionIndex);
                    return `<span class="${className}">${englishPart}<span class="OALECD-chn">${chinesePart}</span></span>`;
                } else {
                    // No Chinese characters found, treat all as English
                    return `<span class="${className}">${content}</span>`;
                }
            } else {
                // General case for all other classes
                return `<span class="${className}">${content}</span>`;
            }
        });
    }
    return text;
}

document.addEventListener('DOMContentLoaded', () => {
    const noteContainer = document.querySelector('.Hazuki-note');
    if (!noteContainer.hasChildNodes()) {
        generateNotes();
    }
});

function generateNotes() {
    if (!noteDataArray) {
        console.error('No NodeDataArray found');
        return;
    }

    const notesContainer = document.querySelector('.Hazuki-note');
    if (!notesContainer) {
        console.error('No Hazuki-note element found');
        return;
    }

    if (noteDataArray.length === 1) {
        console.log('Single NoteData found');
        notesContainer.appendChild(generateSingleNote(noteDataArray[0]));
    } else {
        console.log('Multiple NoteData found');

        const stylesheet = document.createElement('link');
        stylesheet.rel = 'stylesheet';
        stylesheet.href = 'horizontal-scroll.css';
        document.head.appendChild(stylesheet);

        const script = document.createElement('script');
        script.src = 'horizontal-scroll.js';
        document.body.appendChild(script);

        script.onload = () => {
            notesContainer.appendChild(constructScrollContainer());
            noteDataArray.forEach(noteData => {
                attendItem(generateSingleNote(noteData));
            });
            addSwipeListeners();
        }
    }
}

function generateSingleNote(noteData) {
    const noteContainer = document.createElement('div');
    noteContainer.className = 'note-container';

    const source = document.createElement('div');
    source.className = 'note-block';
    source.setAttribute('data-label', 'source');
    source.textContent = noteData.source;
    noteContainer.appendChild(source);

    const originalText = document.createElement('div');
    originalText.className = 'note-block';
    originalText.setAttribute('data-label', 'original text');
    var formattedOriginalText = noteData.originalText;
    formattedOriginalText = transformText(formattedOriginalText, replacementMap.highlightText);
    originalText.innerHTML = formattedOriginalText.replace(/\n/g, "<br>");;
    noteContainer.appendChild(originalText);

    const noteText = document.createElement('div');
    noteText.className = 'note-block';
    noteText.setAttribute('data-label', 'notes');
    var formattedNote = noteData.notes;
    Object.values(replacementMap).forEach((map) => {
        formattedNote = transformText(formattedNote, map);
    });
    noteText.innerHTML = formattedNote.replace(/\n/g, "<br>");;
    noteContainer.appendChild(noteText);

    const tagContainer = document.createElement('div');
    tagContainer.className = 'note-tags';
    noteData.tags.split(' ').forEach(tagString => {
        if (tagString.trim().length > 0) { // Ensures that the string isn't just spaces
            const tag = document.createElement('div');
            tag.className = 'note-tag';
            tag.textContent = tagString.slice(1); // Remove leading '#' and set text
            tagContainer.appendChild(tag);
        }
    });
    noteContainer.appendChild(tagContainer);

    return noteContainer;
}

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