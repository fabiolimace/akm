#!/bin/sh

#
# Saves metadata in `meta` folder.
#
# Usage:
#
#     apwm-save-meta.sh FILE
#

. "`dirname "$0"`/apkm-common.sh";

file="${1}"
require_file "${file}"

main() {

    local file="${1}"
    
    local uuid=`path_uuid "${file}"`;
    local meta=`make_meta "${file}"`;
    
    local path # Path relative to base directory
    local name # File name without extension
    local hash # File hash
    local crdt # Create date
    local updt # Update date
    local tags # Comma separated values
    
    local uuid="`path_uuid "${file}"`"
    local path="${file}"
    local name="`basename -s ".md" "${file}"`"
    local hash="`file_hash "${file}"`"
    local crdt="`now`"
    local updt="`now`"
    local tags="`list_tags "${file}"`"
    
    if [ -f "${meta}" ];
    then
        crdt=`grep -E "^crdt=" "${meta}" | head -n 1 | sed "s/^crdt=//"`;
    fi;
    
    cat > "${meta}" <<EOF
uuid=${uuid}
path=${path}
name=${name}
hash=${hash}
crdt=${crdt}
updt=${updt}
tags=${tags}
EOF

}

main "${file}";

