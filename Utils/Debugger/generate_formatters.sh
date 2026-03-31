#!/bin/bash

set -euo pipefail

COMPILER_VERSION="f74f32b529c35531198621fd104cde5d2cf77e0c"

base=$(git rev-parse --show-toplevel)

# Download formatter_bytecode.py compiler to a temp file
compiler=$(mktemp /tmp/formatter_bytecode.XXXXXX)
trap 'rm -f "$compiler"' EXIT
curl -fsSL \
  "https://raw.githubusercontent.com/llvm/llvm-project/$COMPILER_VERSION/lldb/examples/python/formatter_bytecode.py" \
  -o "$compiler"

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
    --type-name "^${module}[.]${type_name}<.+>$" \
    --append --output "$target" \
    "$formatter"
done
