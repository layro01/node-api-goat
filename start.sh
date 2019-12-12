#!/bin/sh

# These should be fine set at their default values.
# If we want a user to be able to set them, we could update the Jenkins Plugin so 
# they could be configured as necessary.
export IASTAGENT_LOGGING_STDERR_LEVEL=info
# export IASTAGENT_LOGGING_FILE_ENABLED=true
# export IASTAGENT_LOGGING_FILE_PATHNAME=iastdebug.txt
# export IASTAGENT_LOGGING_FILE_LEVEL=info
# export IASTAGENT_ANNOTATIONHANDLER_JSONFILE_ENABLED=true
# export IASTAGENT_ANNOTATIONHANDLER_JSONFILE_PATHNAME=iastoutput.ndjson
# export IASTAGENT_ANNOTATIONHANDLER_JSONFILE_LEVEL=info
# export IASTAGENT_REMOTE_ENDPOINT_HTTP_ENABLED=true
# export IASTAGENT_REMOTE_ENDPOINT_HTTP_LOCATION=$1
# export IASTAGENT_REMOTE_ENDPOINT_HTTP_PORT=$2

# Set NODE_PATH to use a local version of the IAST Agent already on your system.
export NODE_PATH="/mnt/c/iast/iast-dev/out/agent/Debug/universal"

if [ -z ${NODE_PATH+x} ]; then 
    echo "NODE_PATH is unset. Downloading latest IAST Agent to current directory..."
    curl -sSL https://s3.us-east-2.amazonaws.com/app.veracode-iast.io/iast-ci.sh | sh
    export MOCHA_OPTS="--require ./agent_linux64.node"
    LD_LIBRARY_PATH=$PWD npm test
else 
    echo "Loading IAST Agent from '$NODE_PATH'"
    export MOCHA_OPTS="--require agent_linux64.node"
    npm test
fi
