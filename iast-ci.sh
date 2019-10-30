#!/usr/bin/env sh

#
#  Copyright (c) 2019 Veracode Inc
#

# For more verbose output, run with 'DEBUG=1 path/to/ci.sh'
# To force download of latest version, run with 'NOCACHE=1 path/to/iast-ci.sh'
# To change where archives are cached and extracted, run with 'CACHE_DIR=/where/you/want/them path/to/iast-ci.sh'
# These values may be stored in the environment and combined in any way you see fit.

CACHE_DIR=${CACHE_DIR:-/tmp}
DEBUG=${DEBUG:-0}
NOCACHE=${NOCACHE:-0}

main() {
  debug_runtime_options
  check_binaries
  check_architecture
  check_and_set_OS
  create_temp_folder
  check_and_set_latest_version || download_latest_version
  extract_latest_version
}

debug() {
  [ ${DEBUG} -ge 1 ] && echo "debug: $@" >&2
}

debug_runtime_options() {
  debug 'DEBUG is enabled'
  if [ ${NOCACHE} -eq 0 ]; then
    debug 'NOCACHE is 0 or unset; cache will be used normally'
  else
    debug 'NOCACHE set to non-zero; cache will be ignored'
  fi
  debug "CACHE_DIR is \"${CACHE_DIR}\"; archives will be saved and extracted into it"
}

check_binaries() {
  local rc=0
  for binary in curl date mktemp tar uname gzip; do
    if which $binary > /dev/null; then
      debug "check_binaries: checking for $binary: OK"
    else
      echo "$binary is required to continue, but could not be found on your system." >&2
      rc=1
    fi
  done
  if [ $rc != 0 ]; then
    exit $rc
  fi
}

check_architecture() {
  #
  # Only support 64 bit Linux | Darwin
  #
  local arch=$(uname -m)
  debug "check_architecture: architecture: ${arch}"
  if [ "z${arch}" != "zx86_64" ]; then
    debug "check_architecture: architecture is not x86_64"
    echo "error: SourceClear CI only supports x86_64, but your uname -m reported '${arch}'" >&2
    exit 1
  fi
}

check_and_set_OS() {
  local kernel=$(uname -s)
  debug "check_and_set_OS: kernel: ${kernel}"
  case ${kernel} in
    linux|Linux) OS=linux; PLATFORM=linux64; debug "check_and_set_OS: Linux Kernel OK" ;;
    darwin|Darwin) OS=macosx; PLATFORM=darwin64; debug "check_and_set_OS: Mac OS X Kernel OK" ;;
    *)
      debug "check_and_set_OS: Kernel not recognized"
      echo "error: SourceClear CI only supports Linux or Darwin, but your uname -s reported '${kernel}'" >&2
      exit 1;;
  esac
}

create_temp_folder() {
  FOLDER="$(mktemp -q -d -t iast.XXXXXX 2>/dev/null || mktemp -q -d)"
  debug "create_temp_folder: Using $FOLDER as temporary folder."
  cleanup() {
    C=$?
    debug "create_temp_folder: cleanup: cleaning up \"$FOLDER\""
    rm -rf "$FOLDER"
    trap - EXIT
    exit $C
  }
  trap cleanup EXIT INT
}

# Returns 0 if the latest version of .tar.gz appears to be present; otherwise 1.
check_and_set_latest_version() {
  debug "check_and_set_latest_version: checking latest version..."
  if curl -m30 -f -v -o "$FOLDER/version" https://s3.us-east-2.amazonaws.com/app.hailstone.io/LATEST_VERSION 2>"$FOLDER/curl-output"; then
    latest_version=$(cat "$FOLDER/version")
    debug "check_and_set_latest_version: retrieved LATEST_VERSION: $latest_version"
    if [ ${NOCACHE} -eq 0 -a -e "${CACHE_DIR}/iast-${latest_version}-${PLATFORM}.tar.gz" ]; then
      debug "check_and_set_latest_version: latest version already exists."
      return 0
    fi
    debug "check_and_set_latest_version: latest version does not exist and will be downloaded."
    return 1
  else
    debug "check_and_set_latest_version: retrieving LATEST_VERSION failed: $?"
    echo "warning: we were not able to retrieve LATEST_VERSION, and will therefore not used the locally cached agent" >&2
    echo "warning: curl provided the following output, which may be useful for debugging:" >&2
    cat "$FOLDER/curl-output" >&2
    latest_version="latest"
    return 1
  fi
}

download_latest_version() {
  local url="https://s3.us-east-2.amazonaws.com/app.hailstone.io/${latest_version}/$PLATFORM/agent.tar.gz"
  debug "download_latest_version: retrieving iast ${latest_version} for ${OS}/${PLATFORM} via ${url}..."
  local t0=$(date +%s)
  if curl -m 300 -f -v -o "$FOLDER/iast-${latest_version}-${PLATFORM}.tar.gz" "${url}" 2>"$FOLDER/curl-output"; then
    debug "download_latest_version: retrieved in $(( $(date +%s) - $t0 ))s."
    if [ ! -d "$CACHE_DIR" ]; then
      mkdir "$CACHE_DIR"
    fi
    mv "$FOLDER/iast-${latest_version}-${PLATFORM}.tar.gz" "${CACHE_DIR}"
  else
    debug "download_latest_version: retrieval failed: $?"
    echo "We were not able to download your installation package from ${url}." >&2
    echo "Curl provided the following output, which may be useful for debugging:" >&2
    cat "$FOLDER/curl-output" >&2
    exit 1
  fi
}

extract_latest_version() {
  # Check if the latest version is already extracted
  if [ ${NOCACHE} -eq 0 -a -d "${CACHE_DIR}/iast" -a -e "${CACHE_DIR}/iast/VERSION" ] \
    && [ "z$(cat "${CACHE_DIR}/iast/VERSION")" = "z${latest_version}" ]; then
    debug "extract_latest_version: latest version is already extracted; skipping."
    return 0
  else
    debug "extract_latest_version: latest version not extracted; continuing."
  fi

  # Check to make sure the archive exists.
  if [ ! -e "${CACHE_DIR}/iast-${latest_version}-${PLATFORM}.tar.gz" ]; then
    echo "error: extract_latest_version expected \"${CACHE_DIR}/iast-${latest_version}-${PLATFORM}.tar.gz\" to exist, but file is not found." >&2
    exit 1
  else
    debug "extract_latest_version: archive \"${CACHE_DIR}/iast-${latest_version}-${PLATFORM}.tar.gz\" found"
  fi

  rm -rf "${CACHE_DIR}/iast" || true

  if mkdir -p "${CACHE_DIR}/iast"; then
    debug "extract_latest_version: \"${CACHE_DIR}/iast\" created"
  else
    echo "error: extract_latest_version: failed to create target directory \"${CACHE_DIR}/iast\": $?" >&2
    exit 1
  fi

  debug "extract_latest_version: extracting iast..."
  local t0=$(date +%s)
  if tar --extract --file "${CACHE_DIR}/iast-${latest_version}-${PLATFORM}.tar.gz" -C "${CACHE_DIR}/iast"; then
    debug "extract_latest_version: extraction complete in $(( $(date +%s) - $t0 ))s."
  else
    debug "extract_latest_version: extraction failed: $?"
    echo "error: extract_latest_version: tar reported errors while extracting the iast package." >&2
    exit 1
  fi

  debug "extract_latest_version: copying iast to current folder..."
  if cp ${CACHE_DIR}/iast/* .; then
    debug "extract_latest_version: copied to current."
  else
    debug "extract_latest_version: copy to current failed: $?"
    echo "error: extract_latest_version: cp reported errors while copying the iast artifacts." >&2
    exit 1
  fi
}

main "$@"