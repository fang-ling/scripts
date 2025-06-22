# MIT License
#
# Copyright (c) 2025-2025 Fang Ling
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Color codes
GREEN=$(tput setaf 2) # Green
RED=$(tput setaf 1)   # Red
NC=$(tput sgr0)       # No Color

# Function to get the digest using OpenSSL
get_openssl_digest() {
    local FILE="$1"
    local ALGORITHM="$2"
    
    case "$ALGORITHM" in
        md5)
            openssl dgst -md5 "$FILE" | sed 's/^.* //'
            ;;
        sha1)
            openssl dgst -sha1 "$FILE" | sed 's/^.* //'
            ;;
        sha256)
            openssl dgst -sha256 "$FILE" | sed 's/^.* //'
            ;;
        sha3-512)
            openssl dgst -sha3-512 "$FILE" | sed 's/^.* //'
            ;;
        *)
            echo "Unsupported algorithm: $ALGORITHM" >&2
            exit 1
            ;;
    esac
}

# Function to extract the digest from the digest file
get_stored_digest() {
    local FILE="$1"
    local ALGORITHM="$2"
    FOLDER="$3"
    local DIGEST_FILE="$FOLDER/$FILE"

    case "$ALGORITHM" in
        md5)
            DIGEST_FILE="$DIGEST_FILE.md5"
            ;;
        sha1)
            DIGEST_FILE="$DIGEST_FILE.sha1"
            ;;
        sha256)
            DIGEST_FILE="$DIGEST_FILE.sha256"
            ;;
        sha3-512)
            DIGEST_FILE="$DIGEST_FILE.sha3-512"
            ;;
        *)
            echo "Unsupported algorithm: $ALGORITHM" >&2
            exit 1
            ;;
    esac

    if [ -f "$DIGEST_FILE" ]; then
        grep -o -E '[0-9a-fA-F]{32,128}' "$DIGEST_FILE" | head -n 1
    else
        echo "Digest file not found: $DIGEST_FILE" >&2
        exit 1
    fi
}

# Check if the correct number of arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <algorithm> <folder1> [folder2 ...]"
    exit 1
fi

ALGORITHM="$1"
shift

# Verify each file in the specified folders
for FOLDER in "$@"; do
    if [ -d "$FOLDER" ]; then
        for FILE in "$FOLDER"/*; do
            if [ -f "$FILE" ]; then
                case "$FILE" in
                    *.md5|*.sha1|*.sha256|*.sha3-512) continue ;;
                esac

                # Get file size using wc
                FILE_SIZE=$(wc -c < "$FILE" | tr -d ' ') # in bytes

                # Record start time
                START_TIME=$(date +%s%N) # nanoseconds

                STORED_DIGEST=$(get_stored_digest "$(basename "$FILE")" "$ALGORITHM" "$FOLDER")
                CALCULATED_DIGEST=$(get_openssl_digest "$FILE" "$ALGORITHM")

                # Record end time
                END_TIME=$(date +%s%N) # nanoseconds
                DURATION=$((END_TIME - START_TIME))

                # Calculate speed (mb/s)
                if [ "$FILE_SIZE" -gt 0 ]; then
                    SPEED=$(echo "scale=5; $FILE_SIZE / 1000 / 1000 / ($DURATION / 1000000000)" | bc)
                else
                    SPEED="N/A"
                fi

                if [ "$STORED_DIGEST" == "$CALCULATED_DIGEST" ]; then
                    echo "$ALGORITHM check ${GREEN}passed${NC} for \"$FILE\" at $SPEED MB/s."
                else
                    echo "$ALGORITHM check ${RED}failed${NC} for \"$FILE\" at $SPEED MB/s."
                    echo "Stored: $STORED_DIGEST"
                    echo "Calculated: $CALCULATED_DIGEST"
                fi
            fi
        done
    else
        echo "Directory not found: $FOLDER"
    fi
done
