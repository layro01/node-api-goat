#!/bin/bash
ROOTDIR=`git rev-parse --show-toplevel`

case "$OSTYPE" in
  darwin*)
    PLATFORM=darwin64
    EXT=.dylib
    ;;
  linux*)
    PLATFORM=linux64
    EXT=.so
    ;;
  *)
    echo "Unknown operating system. Building on this system is not supported."
    exit 1;
    ;;
esac

# export IASTAGENT_LOGGING_STDERR_LEVEL=info
# export IASTAGENT_LOGGING_FILE_ENABLED=true
# export IASTAGENT_LOGGING_FILE_PATHNAME=iastdebug.txt
# export IASTAGENT_LOGGING_FILE_LEVEL=info
# export IASTAGENT_ANNOTATIONHANDLER_JSONFILE_ENABLED=true
# export IASTAGENT_ANNOTATIONHANDLER_JSONFILE_PATHNAME=iastoutput.ndjson
# export IASTAGENT_ANNOTATIONHANDLER_JSONFILE_LEVEL=info
export IASTAGENT_REMOTE_ENDPOINT_HTTP_ENABLED=true
export IASTAGENT_REMOTE_ENDPOINT_HTTP_LOCATION=localhost
export IASTAGENT_REMOTE_ENDPOINT_HTTP_PORT=10010
export AGENT_SERVER_URL="https://${IASTAGENT_REMOTE_ENDPOINT_HTTP_LOCATION}:${IASTAGENT_REMOTE_ENDPOINT_HTTP_PORT}/iast/as/v1"

# Set a unique identifier for this run (based on the folder name and timestamp)
export BUILD_TAG=$(basename "$PWD")-$(date +%Y-%m-%d_%H-%M-%S)
echo "Using BUILD_TAG: ${BUILD_TAG}"

# Ping Veracode Interactive Agent Server to make sure it's alive.
status_code=$(curl --write-out %{http_code} --silent --output /dev/null --insecure ${AGENT_SERVER_URL})
if [[ "$status_code" -ne 200 ]]; then
  echo "ERROR: Veracode Interactive Agent Server not available at ${AGENT_SERVER_URL} (Status code: ${status_code})."
  exit 1
fi;

# Send session_start event to Agent Server and save off the session_id returned.
SESSION_ID=$(curl -H "Content-Type:application/json" -H "x-iast-event:session_start" --silent --insecure -X POST -d "{\"BUILD_TAG\":\"${BUILD_TAG}\"}" ${AGENT_SERVER_URL}/events | jq -r '.session_id')
echo "Using session_id: ${SESSION_ID}"

# Run the application unit tests with the IAST Agent attached.
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

# Send session_stop event to Agent Server.
curl -H "Content-Type:application/json" -H "x-iast-event:session_stop" -H "x-iast-session-id:${SESSION_ID}" --silent --output /dev/null --insecure -X POST ${AGENT_SERVER_URL}/events

# Print the Veracode Interactive Summary Report to the console.
curl -H "Accept:text/plain" --insecure -X GET ${AGENT_SERVER_URL}/results?session_id=${SESSION_ID}

# Give the report URL for this run (denoted by the BUILD_TAG).
echo
echo "View the Veracode Interactive Summary Report at this URL: ${AGENT_SERVER_URL}/results?session_tag=${BUILD_TAG}"