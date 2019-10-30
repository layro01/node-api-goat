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

#node -r ./agent_nodejs_linux64 app/server.js
node -r ../../iast-dev/out/agent/Debug/nodejs/agent_nodejs_darwin64 app/server.js