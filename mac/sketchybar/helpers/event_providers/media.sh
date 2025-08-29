media-control stream | \
    while IFS= read -r line; do \
        jq -r 'if .diff == false then
            "\(now | strftime("%H:%M:%S")) (\(.payload.bundleIdentifier
            )) \(.payload.title) - \(.payload.artist) - \(.payload.artworkData)"
        else
            empty
        end' <<< "$line"; \
    done
