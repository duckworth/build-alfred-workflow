#!/usr/bin/env bash

set -euo pipefail
set -o noglob

WORKFLOW_DIR="$1"
EXCLUDE_PATTERNS="$2"

abort() {
	echo $1 >&2
	exit 1
}

check_info_plist() {
	INFO_PLIST=""
	if [[ -r "$WORKFLOW_DIR/info.plist" ]]; then
		INFO_PLIST="$WORKFLOW_DIR/info.plist"
	elif [[ -r "info.plist" ]]; then
		INFO_PLIST="info.plist"
	else
		abort "Missing file info.plist"
	fi
}

check_workflow_dir() {
	[[ -d $WORKFLOW_DIR ]] || abort "Missing directory $WORKFLOW_DIR"
}

workflow_files() {
	for file in info.plist icon.png LICENSE README README.md; do
		[[ -f $file ]] && echo $file
	done
}

exclude_args() {
	echo "$EXCLUDE_PATTERNS" | xargs -n 1 -I{} echo "--exclude {}"
}

clean() {
	rm -f $OUTPUT_FILE
}

zip_dir() {
	local dir=$1
	pushd $dir >/dev/null
		zip --symlinks \
			$OUTPUT_FILE \
			$(find .) \
			$(exclude_args)
	popd >/dev/null
}

zip_files() {
	zip \
		$OUTPUT_FILE \
		$@ \
		$(exclude_args)
}

set_output() {
	local name=$1
	local value=$2
	echo "${name}=${value}" >> $GITHUB_OUTPUT
}


check_info_plist
check_workflow_dir

OUTPUT_FILE="${PWD}/$(/extract_name.py $INFO_PLIST)"

clean
zip_dir $WORKFLOW_DIR
zip_files $(workflow_files)
set_output workflow_file "$(basename $OUTPUT_FILE)"
