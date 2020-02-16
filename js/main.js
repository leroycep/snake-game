import { default as canvas } from "./canvas.js";

var memory;

let env = {
    ...canvas,
    consoleLogS: (ptr, len) => {
        const bytes = new Uint8Array(memory.buffer, ptr, len);
        let s = "";
        for (const b of bytes) {
            s += String.fromCharCode(b);
        }
        console.log(s);
    },
};

fetch("snake-game.wasm")
    .then(response => response.arrayBuffer())
    .then(bytes => WebAssembly.instantiate(bytes, { env }))
    .then(results => results.instance)
    .then(instance => {
        memory = instance.exports.memory;
        instance.exports.onInit();
    });
