#!/bin/bash
# SPDX-License-Identifier: MIT
# The image's license manifest: every installed package with its version, its
# licenses (the License fields of its machine-readable copyright file) and
# where it comes from. Each package's full terms are in
# /usr/share/doc/<package>/copyright.
set -euo pipefail

OUT=/usr/share/doc/citronics-image/licenses.txt
mkdir -p "$(dirname "$OUT")"
{
	echo "# Licenses of the software in this image"
	echo "#"
	echo "# One line per installed package: name, version, licenses, homepage."
	echo "# The full copyright and license terms of each package are in"
	echo "# /usr/share/doc/<package>/copyright."
	echo
	dpkg-query -W -f '${binary:Package}\t${Version}\t${Homepage}\n' | sort | \
	while IFS=$'\t' read -r pkg version homepage; do
		name=${pkg%%:*}
		file=/usr/share/doc/$name/copyright
		if [ -f "$file" ]; then
			licenses=$(sed -n 's/^License: *\([^ ].*\)$/\1/p' "$file" | sort -u | paste -sd ';' - | sed 's/;/; /g')
			[ -n "$licenses" ] || licenses="see $file"
		else
			licenses="NO COPYRIGHT FILE"
		fi
		printf '%s\t%s\t%s\t%s\n' "$pkg" "$version" "$licenses" "${homepage:--}"
	done
} > "$OUT"
echo "License manifest: $(grep -vc '^#\|^$' "$OUT") packages, $(grep -c 'NO COPYRIGHT FILE' "$OUT" || true) without a copyright file"
