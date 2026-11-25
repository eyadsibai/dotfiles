// Sort Play (github.com/hoeci/sort-play): sorts and filters playlists, albums and artist
// pages by play count, release date and more. Pinned to a verified commit SHA so Spotify
// never executes unreviewed upstream commits from `main`.
fetch("https://raw.githubusercontent.com/hoeci/sort-play/c875111bdfe224ec6b6df458301a851d3eeee85a/sort-play.js")
    .then(res => res.text())
    .then(content => new Blob([content], { type: "application/javascript" }))
    .then(URL.createObjectURL)
    .then(url => import(url))
