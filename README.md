# LumiApp
Apple Foundation Program - The Uniques 🦄
Ignite the human mind through entertaining and rewarding activities.

You pick a film, a song or a book, enjoy it, and mark it as done to earn points. A 3D globe turns greener, country by country, as you explore the world's culture, as such Lumi offers two ways of visualising your progress (total points and the globe) 

Lumi suggests things for their cultural value (award winners, classics, landmark songs), not for their popularity. However you also have the possibility to look up any work you like.

---- API keys used 

Both keys live in Lumi-Info.plist:

Where to get them
MBXAccessToken: Mapbox public token (starts with pk.). Needed for the globe.	account.mapbox.com → Tokens
TMDBToken	TMDB API Key (32 characters) or API Read Access Token (long). Both work.	themoviedb.org → Settings → API
Without a TMDB key, films are still listed, but with a placeholder instead of the poster, story and rating, and trailers are unavailable.
A value starting with PASTE (for example PASTE_YOUR_TMDB_KEY_HERE) is treated as "no key".    
Music (Apple), books (Open Library) need no key.
Do not publish your own keys. Keep them out of public repositories, or replace them with placeholders before sharing. Restrict your Mapbox token to this app's bundle identifier in your Mapbox account.

Everything is stored on the device (no account, no backend).
