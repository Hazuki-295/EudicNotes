const replacementMap = {
    highlightText: {
        name: 'highlightText',
        map: {
            'highlight red': ['<', '>'],
            'highlight green': ['[', ']'],
            'highlight blue': ['+', '+']
        }
    },
    oald: {
        name: 'oald',
        map: {
            'shcut': ['*', '*'],
            'prefix': ['!', '!'],
            'pv': ['^', '^'],
            'def': ['&', '&'], 'cf': ['@', '@'],
            'geo': ['_', '_'], 'ndv': ['{', '}']
        }
    },
    lm5pp: {
        name: 'lm5pp',
        map: {
            'ACTIV': null,
            'lm5pp_POS': null,
            'lm5pp_POS phr': null
        }
    }
};

// Use a regular expression to globally replace the markers
function transformText(text, dict) {
    if (dict.name === 'lm5pp') {
        /* LDOCE Style */
        const posRegex = /\b(verb|noun|adjective|adverb|preposition|conjunction|pronoun)\b/;
        text = text.replace(posRegex, '<span class="lm5pp_POS">$1</span>');

        const phrRegex = /\b(Phrasal Verb)\b/;
        text = text.replace(phrRegex, '<span class="lm5pp_POS phr">$1</span>');

        const idiomRegex = /\b(Idioms)\b/;
        text = text.replace(idiomRegex, '<span class="idiom">$1</span>');

        const slashRegex = /(?<![<A-Za-z.])\/[A-Za-z.-]+(\s+[A-Za-z.-]+)*/g; // not inside </span>, not words that separated by '/'
        text = text.replace(slashRegex, '<span class="ACTIV">$&</span>');
    } else {
        /* Other Styles */
        for (const [className, [open, close]] of Object.entries(dict.map)) {
            const regex = new RegExp(`\\${open}(.*?)\\${close}`, 'g');
            text = text.replace(regex, (match, content) => {
                if (dict.name === 'oald' && (className === 'shcut' || className === 'def')) {
                    // Find the index where English ends and Chinese begins
                    const transitionIndex = content.search(/[⟨\u4e00-\u9fff]/);
                    if (transitionIndex !== -1) {
                        let englishPart = content.substring(0, transitionIndex);
                        let chinesePart = content.substring(transitionIndex);
                        content = `${englishPart}<span class="OALECD-chn">${chinesePart}</span>`;
                    }
                } else if (dict.name === 'oald' && className === 'cf') {
                    content = content.replace(/\$(z|pvarr|sep)/g, function (match) {
                        switch (match) {
                            case '$z': return '<span class="z">|</span>';
                            case '$pvarr': return '<span class="pvarr">⇿</span>';
                            case '$sep': return '<span class="sep">,</span>';
                            default:
                                return match; // Just in case there's a no-match scenario
                        }
                    });
                }
                return `<span class="${className}">${content}</span>`;
            });
        }
    }
    return text;
}

document.addEventListener('DOMContentLoaded', () => {
    const noteContainer = document.querySelector('.Hazuki-note');
    if (!noteContainer.hasChildNodes()) {
        generateNotes();
    }

    // Check if the script is running inside an iframe
    if (window.frameElement) {
        extractNotesIframe();
    }
});

function generateNotes() {
    if (!noteDataArray) {
        console.error('No NodeDataArray found');
        return;
    }

    const noteContainer = document.querySelector('.Hazuki-note');
    if (!noteContainer) {
        console.error('No Hazuki-note element found');
        return;
    }

    if (noteDataArray.length === 1) {
        console.log('Single NoteData found');
        noteContainer.appendChild(generateSingleNote(noteDataArray[0]));
    } else {
        console.log('Multiple NoteData found');

        noteContainer.appendChild(constructScrollContainer());
        noteDataArray.forEach((noteData, index) => {
            attendItem(generateSingleNote(noteData), index);
        });
        addSwipeListeners(noteContainer);
    }
}

function generateSingleNote(noteData) {
    const noteContainer = document.createElement('div');
    noteContainer.className = 'note-container';

    // Source
    const source = document.createElement('div');
    source.className = 'note-block';
    source.setAttribute('data-label', 'source');
    source.textContent = noteData.source;
    noteContainer.appendChild(source);

    // Original Text
    const originalText = document.createElement('div');
    originalText.className = 'note-block';
    originalText.setAttribute('data-label', 'original text');
    var formattedOriginalText = noteData.originalText;
    if (noteData.wordPhrase !== '') {
        const regex = new RegExp(`\\b${noteData.wordPhrase}\\b`, 'gi');
        formattedOriginalText = formattedOriginalText.replace(regex, '+$&+');
    }
    formattedOriginalText = transformText(formattedOriginalText, replacementMap.highlightText);
    originalText.innerHTML = formattedOriginalText.replace(/\n/g, "<br>");
    noteContainer.appendChild(originalText);

    // Notes
    if (noteData.notes !== '') {
        const noteText = document.createElement('div');
        noteText.className = 'note-block';
        noteText.setAttribute('data-label', 'notes');
        var formattedNote = noteData.notes;
        Object.entries(replacementMap).forEach(([key, dict]) => {
            formattedNote = transformText(formattedNote, dict);
        });
        noteText.innerHTML = formattedNote.replace(/\n/g, "<br>");;
        noteContainer.appendChild(noteText);
    }

    // Tags
    if (noteData.tags !== '') {
        const tagContainer = document.createElement('div');
        tagContainer.className = 'note-block';
        tagContainer.setAttribute('data-label', 'tags');

        const colors = ['rgb(79, 125, 192)', 'rgb(94, 162, 94, 0.9)', 'rgb(245, 130, 32, 0.9)', 'rgba(196, 21, 27, 0.8)'];
        let currentColorIndex = 0;
        noteData.tags.split(',').forEach(tagString => {
            if (tagString.trim().length > 0) { // Ensures that the string isn't just spaces
                const tag = document.createElement('div');
                tag.className = 'note-tag';
                tag.textContent = tagString.trim().slice(1); // Remove leading '#' and set text
                tag.style.setProperty('--color-tag', colors[currentColorIndex]);
                currentColorIndex = (currentColorIndex + 1) % colors.length;
                tagContainer.appendChild(tag);
            }
        });
        noteContainer.appendChild(tagContainer);
    }

    return noteContainer;
}

function extractNotesIframe() {
    const iframe = window.frameElement;

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

    // Export the noteDataArray to the parent window
    window.parent.noteDataArray = noteDataArray;

    // Get the note container
    const noteContainer = iframeDocument.querySelector('.Hazuki-note');
    if (!noteContainer) {
        console.error('No Hazuki-note element found inside the iframe');
        return;
    }

    // Create a new note container and insert it into the parent document
    const newNoteContainer = parentDocument.createElement('div');
    newNoteContainer.className = 'Hazuki-note';
    newNoteContainer.innerHTML = noteContainer.innerHTML;
    iframe.parentNode.appendChild(newNoteContainer);

    // Reattach swipe listeners
    if (newNoteContainer.querySelector('.v-swipe')) {
        addSwipeListeners(newNoteContainer);
    }

    // Hide the iframe
    iframe.style.display = 'none';
}