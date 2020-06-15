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
FORMATS=( doc )
# TODO: Change to below... but tonight the pdfs are taking too long, they should be backed up 
#       but not stored in git
# FORMATS=( doc pdf )




function cleanup() {
  rm -f "${tmplogfile:-NOTEMPLOGFILE}"
}
trap cleanup EXIT

function unzip_docx() {
  local srcfile="$(greadlink -f "${1}")"
  local tgtdir="${srcfile//.docx/_docx}"
  if [ -d "$tgtdir" ]; then
    rm -r "$tgtdir"
  fi
  mkdir -p "$tgtdir"
  pushd "$tgtdir"
  unzip "$srcfile"
  popd
}

function export_file() {
  local format="${3:-doc}"
  local srcfile="${1//edit*/export?format=$format}"
  if [ "$format" == "doc" ]; then
    format=docx
  fi
  local tgtfile="$PAGE_DB/$2.$format"
  wget "$srcfile" -O "$tgtfile"
  # if [ "$format" == "docx" ]; then
  #   unzip_docx "$tgtfile"
  #   # rm "$tgtfile"
  # fi
}

function script_main() {
  cd "$PAGE_DB"
  while IFS="" read -r line || [[ -n "$line" ]]; do
    if $(echo $line | grep -v '^\s*#' > /dev/null); then
      for fmt in "${FORMATS[@]}"; do
        srcfile=$(echo $line | cut -f1 -d \|)
        tgtfile=$(echo $line | cut -f2 -d \|)
        export_file "$srcfile" "$tgtfile" "$fmt" > "$tmplogfile" && \
          echo -e "$(date): '$srcfile' backed up to '$tgtfile' successfully'" | tee -a $LOGFILE || \
          echo -e "$(date): '$srcfile' FAILED to back up to '$tgtfile'" | tee -a $LOGFILE && ((error_count+=1))
      done
    fi
  done < <( cat "$SOURCE_FILE" | sed '/^\s*$/d')
}

usage() {
  echo "USAGE: $0"
  echo "  Using the list of files in $SOURCE_FILE, backup all gdocs files"
  #TODO: Better documentation
}

if [[ "$1" == "-h" ]] || [[ "$1" = "-help" ]] || [[ "$1" == "--help" ]]; then
  usage
  exit 255
fi

error_count=0
script_main
if [ $error_count -eq 0 ]; then
  echo "$(date): All files backed up successfully" | tee -a $LOGFILE
  trap - EXIT
  cleanup
  exit 0
else
  echo "$(date): Not all files backed up successfully, see log at $tmplogfile" | tee -a $LOGFILE
  trap - EXIT
  exit $error_count
fi


# vim: ft=sh
