#!/bin/bash

# Use the following options to configure the IAST Agent.
# export IASTAGENT_LOGGING_STDERR_LEVEL=info # or debug
# export IASTAGENT_LOGGING_FILE_ENABLED=true
# export IASTAGENT_LOGGING_FILE_PATHNAME=./iastdebug.txt
# export IASTAGENT_LOGGING_FILE_LEVEL=info # or debug
# export IASTAGENT_ANNOTATIONHANDLER_JSONFILE_ENABLED=true
# export IASTAGENT_ANNOTATIONHANDLER_JSONFILE_PATHNAME=./iastoutput.ndjson
# export IASTAGENT_ANNOTATIONHANDLER_JSONFILE_LEVEL=info # or debug
export IASTAGENT_REMOTE_ENDPOINT_HTTP_ENABLED=true
export IASTAGENT_REMOTE_ENDPOINT_HTTP_LOCATION=localhost
export IASTAGENT_REMOTE_ENDPOINT_HTTP_PORT=10010

# Set NODE_PATH to use a local version of the IAST Agent already on your system.
# export NODE_PATH="/path/to/iast/agent/binary"

if [[ -z ${NODE_PATH+x} && ! -r agent_linux64.node ]]; then 
    echo "NODE_PATH is unset and no IAST Agent in current directory, downloading latest version..."
    curl -sSL https://s3.us-east-2.amazonaws.com/app.veracode-iast.io/iast-ci.sh | sh
fi

if [ -z ${NODE_PATH+x} ]; then
    echo "Loading IAST Agent from current directory '$PWD'"
    LD_LIBRARY_PATH=$PWD mocha --require ./agent_linux64.node test/*.js
else 
    echo "Loading IAST Agent from '$NODE_PATH'."
    LD_LIBRARY_PATH=$NODE_PATH mocha --require agent_linux64.node test/*.js
fi
