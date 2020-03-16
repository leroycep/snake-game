# Snake Game

## Dependencies

For building:

- zig (`master` branch

For running the game in browser:

- A development web server, like `livereload` or [`simple-http-server`][]
- An up to date web browser

To run it on desktop:

- Install SDL
- run `zig build run`

[`simple-http-server`]: https://github.com/TheWaWaR/simple-http-server

## Usage

To build the WASM, use zig build:

```
$ zig build wasm
```

To run the game, start the web server and navigate to the page in you browser:

```
$ cd ./zig-cache/www
$ livereload
[I 200215 23:06:51 server:296] Serving on http://127.0.0.1:35729
[I 200215 23:06:51 handlers:62] Start watching changes
[I 200215 23:06:51 handlers:64] Start detecting changes
```

And in this case, I would navigate to `http://127.0.0.1:35729`.

We need this server because web browsers will not run WASM unless it is served
from a server with the appropriate mime type.

## Notes

WebGL bindings generator was based on the generator in [oxid](https://github.com/dbandstra/oxid/).
