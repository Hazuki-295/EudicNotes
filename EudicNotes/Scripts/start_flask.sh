#!/bin/zsh

# Setup environment
SCRIPT_PATH=$(dirname "$0")
CONDA_ENV=NLP

# Set application paths
FLASK_SERVER="$SCRIPT_PATH/nlp.py"
EUDICNOTES_APP_PATH="/Applications/EudicNotes/EudicNotes.app"

# Log file
LOG_FILE="$SCRIPT_PATH/log/flask_eudicnotes.log"

log_message() {
    local message="$1"
    local msg_type="${2:-Script}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$msg_type] $message" >> $LOG_FILE
}

# Start Flask server and log its output
start_flask() {
    source "$HOME/.zshrc" && conda activate "$CONDA_ENV" && python "$FLASK_SERVER" 2>&1 | tee -a "$LOG_FILE" &
    FLASK_PID=$!
    log_message "Flask server started with PID $FLASK_PID." "Flask"
}

# Open EudicNotes app
open_eudicnotes() {
    open -a "$EUDICNOTES_APP_PATH" && sleep 1
    EUDICNOTES_PID=$(pgrep -fx "$EUDICNOTES_APP_PATH/Contents/MacOS/EudicNotes")
    log_message "EudicNotes app opened with PID $EUDICNOTES_PID." "EudicNotes"
}

# Check if EudicNotes is running
is_eudicnotes_running() {
    pgrep -fx "$EUDICNOTES_APP_PATH/Contents/MacOS/EudicNotes" > /dev/null
}

# Terminate Flask server
terminate_flask() {
    if [[ -n "$FLASK_PID" ]]; then
        kill "$FLASK_PID" && log_message "Flask server with PID $FLASK_PID terminated." "Flask"
    fi
}

# Main execution flow
main() {
    setup_environment
    log_message "-------------------"
    log_message "Script execution started."
    start_flask
    open_eudicnotes

    while true; do
        if ! is_eudicnotes_running; then
            log_message "EudicNotes is not running. Terminating Flask server..." "Flask"
            terminate_flask
            break
        fi
        sleep 5
    done

    log_message "Script execution completed."
}

main "$@"