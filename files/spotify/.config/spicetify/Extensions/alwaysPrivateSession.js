// A private session, always: what plays isn't shown to followers and doesn't feed
// recommendations. Spotify ends a private session by itself when it restarts and after
// some hours without playback, and has no setting to keep one, so this switches it back
// on whenever Spotify reports it off. Turning it off in the menu won't last either;
// to really leave it, take this file out of the list in 10-spotify.sh.
(async function alwaysPrivateSession() {
	while (!Spicetify?.Platform?.PrivateSessionAPI) {
		await new Promise((resolve) => setTimeout(resolve, 300));
	}
	const api = Spicetify.Platform.PrivateSessionAPI;

	// At most one attempt every ten seconds, so a Spotify that refuses can't be hammered
	let lastAttempt = 0;
	let pending = null;
	api.subscribeToPrivateSession((isPrivate) => {
		if (isPrivate || pending) return;
		const wait = Math.max(0, lastAttempt + 10000 - Date.now());
		pending = setTimeout(() => {
			pending = null;
			lastAttempt = Date.now();
			api.setPrivateSession(true).catch(() => {});
		}, wait);
	});
})();
