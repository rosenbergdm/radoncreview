#! /usr/local/bin/bash
#
# dump_pages.sh
# Copyright (C) 2020 David Rosenberg <dmr@davidrosenberg.me>
# Exports the listed google docs pages to a specified directory in 
#   multiple formats.  Suitable for use as a cron job
# Distributed under terms of the MIT license.
#

LOGFILE=/var/log/radoncreview_dump_pages.log
PAGE_DB="$HOME/src/radoncreview/page_dumps"
tmplogfile="$(mktemp -t ror.dp)"
SOURCE_FILE="$PAGE_DB/source_files.txt"
FORMATS=( doc pdf )



function cleanup() {
  rm -f "${tmplogfile:-NOTEMPLOGFILE}"
}
# trap cleanup EXIT

function export_file() {
  local format="${3:-doc}"
  local srcfile="${1//edit*/export?format=$format}"
  if [ "$format" == "doc" ]; then
    format=docx
  fi
  local tgtfile="$PAGE_DB/$2.$format"
  wget "$srcfile" -O "$tgtfile"
}

function script_main() {
  cd "$PAGE_DB"
  while IFS="" read -r line || [[ -n "$line" ]]; do
    if $(echo $line | grep -v '^\s*#' > /dev/null); then
      #TODO: Also needs to handle blank lines
      for fmt in "${FORMATS[@]}"; do
        srcfile=$(echo $line | cut -f1 -d \|)
        tgtfile=$(echo $line | cut -f2 -d \|)
        export_file "$srcfile" "$tgtfile" "$fmt"
        sleep 10
      done
    fi
  done < "$SOURCE_FILE"
}

script_main


# vim: ft=sh
