import json
import logging
import os
import signal
import sys

import stanza

import spacy
from spacy import displacy

from flask import Flask, abort, render_template, request, send_from_directory
from flask_cors import CORS

# Initialize the Flask app
app = Flask(__name__, static_folder='static')

# Enable CORS for all routes
CORS(app)

# Define the logging filter class
class SuppressStatusEndpointLoggingFilter(logging.Filter):
    def filter(self, record):
        return '/status' not in record.getMessage()

# Add the filter to the logger
logging.getLogger('werkzeug').addFilter(SuppressStatusEndpointLoggingFilter())

default_input = 'The quick brown fox jumped over the lazy dog.'

def get_input_data():
    # Priority: 1. Query parameter 'input' 2. POST data 3. Default input
    input_data = (request.args.get('input') or
                  request.form.get('input') or
                  request.data.decode())
    if not input_data:
        input_data = default_input
    return input_data

@app.route('/status', methods=['HEAD'])
def status():
    return '', 200

@app.route('/<path:path>')
def static_file(path):
    if path in ['stanza-brat.css', 'stanza-brat.js', 'stanza-parseviewer.js', 'loading.gif',
                'favicon.png', 'stanza-logo.png']:
        return send_from_directory('static/corenlp', path)
    elif path == 'index.html':
        return send_from_directory('static/corenlp', 'stanza-brat.html')
    else:
        abort(403)

@app.route('/spaCy', methods=['GET', 'POST'])
def spacy_request():
    input_data = get_input_data()
    doc = nlp_spacy(input_data)
    
    svg = displacy.render(doc, style="dep")
    svg_merged = displacy.render(doc, style="dep", options={"collapse_phrases": True})
    svg_data = {
    'deps-merged': ('Dependency (Merge Phrases)', svg_merged),
    'deps': ('Dependency', svg)
    }
    return render_template('spacy_results.html', svg_data=svg_data)

@app.route('/CoreNLP', methods=['GET'])
def index():
    return static_file('index.html')

@app.route('/CoreNLP', methods=['POST'])
def annotate():
    text = list(request.form.keys())[0]
    doc = nlp_corenlp(text)

    annotated_sentences = []
    for sentence in doc.sentences:
        tokens = []
        deps = []
        for word in sentence.words:
            tokens.append({'index': word.id, 'word': word.text, 'lemma': word.lemma, 'pos': word.xpos, 'upos': word.upos, 'feats': word.feats, 'ner': word.parent.ner if word.parent.ner is None or word.parent.ner == 'O' else word.parent.ner[2:]})
            deps.append({'dep': word.deprel, 'governor': word.head, 'governorGloss': sentence.words[word.head-1].text,
                'dependent': word.id, 'dependentGloss': word.text})
        annotated_sentences.append({'basicDependencies': deps, 'tokens': tokens})
        if hasattr(sentence, 'constituency') and sentence.constituency is not None:
            annotated_sentences[-1]['parse'] = str(sentence.constituency)

    return json.dumps({'sentences': annotated_sentences})

def handle_signal(sig, frame):
    signal_name = {
        signal.SIGINT: "SIGINT (Interrupt from keyboard)",
        signal.SIGTERM: "SIGTERM (Termination signal)",
    }.get(sig, f"Unknown signal ({sig})")
    
    print(f"Received {signal_name}. Exiting...")
    sys.exit(0)
    
# Setup signal handlers for graceful shutdown.
signal.signal(signal.SIGINT, handle_signal)  # Handles Ctrl+C
signal.signal(signal.SIGTERM, handle_signal)  # Handles termination signals

if __name__ == '__main__':
    nlp_spacy = spacy.load('en_core_web_sm')
    nlp_corenlp = stanza.Pipeline('en', download_method=None)
    app.run(debug=True, use_reloader=False, port=8000)
