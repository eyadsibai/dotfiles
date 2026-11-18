// Sort Play (github.com/hoeci/sort-play): sorts and filters playlists, albums and artist
// pages by play count, release date and more. This is its sort-play-loader.mjs: only a
// loader, which fetches the current code at every start, so there's nothing here to update.
fetch("https://raw.githubusercontent.com/hoeci/sort-play/main/sort-play.js")
    .then(res => res.text())
    .then(content => new Blob([content], { type: "application/javascript" }))
    .then(URL.createObjectURL)
    .then(url => import(url))
