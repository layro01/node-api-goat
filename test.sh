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

# Set the location of the Agent Server.
export AGENT_SERVER_URL="https://localhost:10010/iast/as/v1"

# Set a unique identifier for this run (based on the folder name and timestamp).
export BUILD_TAG=$(basename "$PWD")-$(date +%Y-%m-%d_%H-%M-%S)
echo "Using BUILD_TAG: ${BUILD_TAG}"

# Ping Veracode Interactive Agent Server to make sure it's alive.
status_code=$(curl --write-out %{http_code} --silent --output /dev/null --insecure ${AGENT_SERVER_URL})
if [[ "$status_code" -ne 200 ]]; then
  echo "ERROR: Veracode Interactive Agent Server not available at ${AGENT_SERVER_URL} (Status code: ${status_code})."
  exit 1
fi;

# Send session_start event to Agent Server and save off the session_id returned in an environment variable.
SESSION_ID=$(curl -H "Content-Type:application/json" -H "x-iast-event:session_start" --silent --insecure -X POST -d "{\"BUILD_TAG\":\"${BUILD_TAG}\"}" ${AGENT_SERVER_URL}/events | jq -r '.session_id')
echo "Using session_id: ${SESSION_ID}"

# Download the latest version of the IAST Agent from the Agent Server.
[ -d .iast ] || mkdir .iast
pushd .iast > /dev/null
curl --insecure -sSL ${AGENT_SERVER_URL}/downloads | sh
popd

# Run the tests.
LD_LIBRARY_PATH=$PWD/.iast npm run test-iast

# (Optional) Send session_stop event to Agent Server.
curl -H "Content-Type:application/json" -H "x-iast-event:session_stop" -H "x-iast-session-id:${SESSION_ID}" --silent --output /dev/null --insecure -X POST ${AGENT_SERVER_URL}/events

# Print the Veracode Interactive Summary Report to the console.
curl -H "Accept:text/plain" --insecure -X GET ${AGENT_SERVER_URL}/results?session_id=${SESSION_ID}

# Give the report URL for this run (denoted by the BUILD_TAG).
echo
echo "View the Veracode Interactive Summary Report at this URL: ${AGENT_SERVER_URL}/results?session_tag=${BUILD_TAG}"
