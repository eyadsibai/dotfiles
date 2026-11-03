#!/usr/bin/env bash
# newsboat-yt-add.sh - Add a YouTube channel to newsboat
# Usage: newsboat-yt-add.sh <youtube-channel-url> [tag]
#
# Examples:
#   newsboat-yt-add.sh https://www.youtube.com/@3blue1brown
#   newsboat-yt-add.sh https://www.youtube.com/channel/UCxxxxxx youtube
#   newsboat-yt-add.sh https://www.youtube.com/@fireship youtube

set -euo pipefail

URL="${1:?Usage: newsboat-yt-add.sh <youtube-channel-url> [tag]}"
TAG="${2:-youtube}"
URLS_FILE="${HOME}/.newsboat/urls"

# Extract channel ID from the page
get_channel_id() {
    local url="$1"
    local html
    html=$(curl -sL --max-time 10 "$url")

    # Try to find channel ID in meta tags or canonical URL
    local channel_id
    channel_id=$(echo "$html" | grep -oP 'channel_id=\K[A-Za-z0-9_-]+' | head -1)

    if [ -z "$channel_id" ]; then
        channel_id=$(echo "$html" | grep -oP '"channelId":"?\K[A-Za-z0-9_-]+' | head -1)
    fi

    if [ -z "$channel_id" ]; then
        channel_id=$(echo "$html" | grep -oP 'channel/\K[A-Za-z0-9_-]+' | head -1)
    fi

    echo "$channel_id"
}

# Get channel name from the page
get_channel_name() {
    local url="$1"
    curl -sL --max-time 10 "$url" | grep -oP '<title>\K[^<]+' | sed 's/ - YouTube$//'
}

# Handle different URL formats
if [[ "$URL" =~ channel/([A-Za-z0-9_-]+) ]]; then
    CHANNEL_ID="${BASH_REMATCH[1]}"
elif [[ "$URL" =~ ^https?://.*youtube ]]; then
    CHANNEL_ID=$(get_channel_id "$URL")
else
    echo "Error: Not a recognized YouTube URL" >&2
    exit 1
fi

if [ -z "$CHANNEL_ID" ]; then
    echo "Error: Could not extract channel ID from $URL" >&2
    exit 1
fi

FEED_URL="https://www.youtube.com/feeds/videos.xml?channel_id=${CHANNEL_ID}"
CHANNEL_NAME=$(get_channel_name "$URL")
CHANNEL_NAME="${CHANNEL_NAME:-YouTube Channel}"

# Check if already subscribed
if grep -qF "$CHANNEL_ID" "$URLS_FILE" 2>/dev/null; then
    echo "Already subscribed: $CHANNEL_NAME ($CHANNEL_ID)"
    exit 0
fi

# Append to urls file
echo "${FEED_URL}  ${TAG}  \"~${CHANNEL_NAME}\"" >> "$URLS_FILE"
echo "Added: $CHANNEL_NAME"
echo "  Feed: $FEED_URL"
echo "  Tag:  $TAG"
echo ""
echo "Reload newsboat to see the new feed."
