#!/bin/bash

cd "$DERIVED_FILES_DIR"
HERE="`dirname "$0"`"

ruby -I"$HERE" "$HERE"/objc_generate_from_shorthand.rb "$INPUT_FILE_PATH"
