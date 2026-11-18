// Spicy Lyrics (github.com/Spikerko/spicy-lyrics): word-by-word animated lyrics in place
// of Spotify's own lyrics view. This is its builds/spicy-lyrics.mjs: only a loader, which
// fetches the current release at every start, so there's nothing here to update.
import(`https://cdn.jsdelivr.net/gh/Spikerko/spicy-lyrics@main/builds/main/entrypoint.mjs?t=${Date.now()}`);
