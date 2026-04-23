#!/bin/bash
#===----------------------------------------------------------------------
#
# This source file is part of the Swift Collections open source project
#
# Copyright (c) 2026 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See https://swift.org/LICENSE.txt for license information
#
#===----------------------------------------------------------------------

set -euo pipefail

base=$(git rev-parse --show-toplevel)
compiler="$base/Utils/Debugger/formatter_bytecode.py"

for formatter in "$base/Utils/Debugger/Formatters"/*.py; do
  type_name=$(basename "$formatter" .py)

  # Find the corresponding Swift source file under Sources/
  swift_file=$(find "$base/Sources" -name "${type_name}.swift" | head -1)
  if [[ -z "$swift_file" ]]; then
    echo "Warning: No Swift source file found for ${type_name}, skipping" >&2
    continue
  fi

  # Derive the module name from the first path component under Sources/
  rel_path="${swift_file#"$base/Sources/"}"
  module=$(cut -d/ -f1 <<< "$rel_path")

  # Output file sits next to the source file
  target="$(dirname "$swift_file")/${type_name}+Formatter.swift"

  echo "Compiling ${type_name} (module: ${module}) -> ${target}"

  # Add header(license), and document this script's invocation.
  cp "$base/Utils/Debugger/HEADER.swift" "$target"
  echo "// Generated with: $0" "$@" >> "$target"
  echo >> "$target"

  python3 "$compiler" --compile \
    --format swift \
    --type-name "^(${module}|Collections(Internal)?)[.]${type_name}<.+>$" \
    --append --output "$target" \
    "$formatter"
done
