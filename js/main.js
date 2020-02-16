import canvas from "./canvas.js";

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

        // Timestep based on the Gaffer on Games post, "Fix Your Timestep"
        //    https://www.gafferongames.com/post/fix_your_timestep/
        const MAX_DELTA = 0.25;
        const TICK_DELTA = (16 / 1000);
        let prevTime = new Date().getTime();
        let tickTime = 0.0;
        let accumulator = 0.0;

        function step() {
            const newTime = new Date().getTime();
            const delta = (newTime - prevTime) / 1000; // Delta in seconds
            if (delta > MAX_DELTA) {
                delta = MAX_DELTA; // Try to avoid spiral of death when lag hits
            }
            prevTime = newTime;

            accumulator += delta;

            while ( accumulator >= TICK_DELTA ) {
                instance.exports.update(tickTime, TICK_DELTA);
                accumulator -= TICK_DELTA;
                tickTime += TICK_DELTA;
            }

            // Where the render is between two timesteps.
            // If we are halfway between frames (based on what's in the accumulator)
            // then alpha will be equal to 0.5
            const alpha = accumulator / TICK_DELTA;

            instance.exports.render(alpha);
            window.requestAnimationFrame(step);

        }

        window.requestAnimationFrame(step);
    });
