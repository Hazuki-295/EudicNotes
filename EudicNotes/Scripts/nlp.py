import os
import signal
import socket
import subprocess
import sys
import time

import spacy
from spacy import displacy

from flask import Flask, request, render_template
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

app = Flask(__name__)

def read_svg(filename):
    with open(filename, 'r', encoding='utf-8') as file:
        return file.read()
    
def write_svg(filename, content):
    with open(filename, 'w', encoding='utf-8') as file:
        file.write(content)

class spaCyDriver:
    def __init__(self, model='en_core_web_sm'):
        self.nlp = spacy.load(model)
        self.svg_dir = os.path.join(app.root_path, 'static', 'spacy', 'svg')
        self.svg_filenames = self.setup_svg_paths()

    def setup_svg_paths(self):
        os.makedirs(self.svg_dir, exist_ok=True)
        return {
            'dependency_tree': os.path.join(self.svg_dir, 'dependency_tree.svg'),
            'dependency_tree_merged': os.path.join(self.svg_dir, 'dependency_tree_merged.svg')
        }

    def process_input(self, input_data):
        doc = self.nlp(input_data)
        svg = displacy.render(doc, style="dep")
        svg_merged = displacy.render(doc, style="dep", options={"collapse_phrases": True})
    
        write_svg(self.svg_filenames['dependency_tree'], svg)
        write_svg(self.svg_filenames['dependency_tree_merged'], svg_merged)

class CoreNLPDriver():
    def __init__(self):
        self.driver = self.initialize_driver()
        self.setup_corenlp_interface()

    def initialize_driver(self):
        options = Options()
        options.add_argument("--headless")
        options.add_argument("window-size=1920,1080")
        return webdriver.Chrome(options=options)

    def setup_corenlp_interface(self):
        """Sets up the CoreNLP web interface for usage."""
        self.driver.get('https://corenlp.run/')

        # Setup annotators
        self.driver.find_element(By.CSS_SELECTOR, '[data-option-array-index="2"]').click()
        self.driver.find_element(By.CLASS_NAME, 'chosen-choices').click()
        self.driver.find_element(By.CSS_SELECTOR, '[data-option-array-index="4"]').click()
        
        self.annotators = {'pos': 'Part-of-Speech',
                'deps': 'Basic Dependencies',
                'deps2': 'Enhanced++ Dependencies',
                'parse': 'Constituency Parse'}
        
        self.text_box = self.driver.find_element(By.ID, 'text')
        self.submit_button = self.driver.find_element(By.ID, "submit")
        self.loading_element = self.driver.find_element(By.ID, "loading")

    def process_input(self, input_data):
        """Processes the input text through the CoreNLP interface."""
        try:
            self.text_box.clear()
            self.text_box.send_keys(input_data)
            self.submit_button.click()
        except Exception as e:
            print(f"Error during processing: {e}")
            self.reinitialize_session()
        
        # Wait for the response to be generated
        WebDriverWait(self.driver, 10).until(EC.invisibility_of_element_located(self.loading_element))
        
        results = {}
        for key, label in self.annotators.items():
            try:
                element = self.driver.find_element(By.ID, key)
                outer_html = element.get_attribute('outerHTML')
                results[key] = (label, outer_html)
            except Exception as e:
                results[key] = (label, f"Error: {e}")
        return results
    
    def reinitialize_session(self):
        print("Reinitializing session...")
        self.close()
        self.driver = self.initialize_driver()
        self.setup_corenlp_interface()
        
    def close(self):
        self.driver.quit()

def cleanup_resources():
    print("Cleaning up resources...")
    core_nlp_driver.close()

def handle_signal(sig, frame):
    signal_name = {
        signal.SIGINT: "SIGINT (Interrupt from keyboard)",
        signal.SIGTERM: "SIGTERM (Termination signal)",
    }.get(sig, f"Unknown signal ({sig})")
    
    print(f"\nReceived {signal_name}. Exiting...")
    cleanup_resources()
    sys.exit(0)

# Setup signal handlers for graceful shutdown.
signal.signal(signal.SIGINT, handle_signal)  # Handles Ctrl+C
signal.signal(signal.SIGTERM, handle_signal)  # Handles termination signals

default_input = 'The quick brown fox jumped over the lazy dog.'

def get_input_data():
    # Priority: 1. Query parameter 'input' 2. POST data 3. Default input
    input_data = (request.args.get('input') or
                  request.form.get('input') or
                  request.data.decode())
    if not input_data:
        input_data = default_input
    return input_data

@app.route('/spaCy', methods=['GET', 'POST'])
def spacy_request():
    input_data = get_input_data()
    spacy_driver.process_input(input_data)
    svg_data = {
    'deps-merged': ('Dependency (Merge Phrases)', read_svg(spacy_driver.svg_filenames['dependency_tree_merged'])),
    'deps': ('Dependency', read_svg(spacy_driver.svg_filenames['dependency_tree']))
    }
    return render_template('spacy_results.html', svg_data=svg_data)

@app.route('/CoreNLP', methods=['GET', 'POST'])
def core_nlp_request():
    input_data = get_input_data()
    results = core_nlp_driver.process_input(input_data)
    return render_template('corenlp_results.html', results=results)

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

def kill_process_on_port(port):
    try:
        subprocess.run(f"lsof -ti:{port} | xargs kill -9", shell=True, check=True)
        print(f"Killed process on port {port}.")
        return True
    except subprocess.CalledProcessError:
        print(f"Could not kill process on port {port}.")
        return False

def run_app_with_retry(app, port, delay=5):
    while True:
        if is_port_in_use(port):
            if kill_process_on_port(port):
                time.sleep(delay)  # Give some time for the port to be freed
        else:
            try:
                app.run(debug=True, use_reloader=False, port=port)
                break  # App started successfully
            except Exception as e:
                print(f"Failed to start app on port {port}. Error: {e}")
                time.sleep(delay)  # Wait before retrying

if __name__ == '__main__':
    spacy_driver = spaCyDriver()
    core_nlp_driver = CoreNLPDriver()
    run_app_with_retry(app, 8000)
