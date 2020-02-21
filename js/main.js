import getWebGLEnv from "./webgl.js";

let canvas = document.getElementById("canvas-webgl");
var memory;

let env = {
  ...getWebGLEnv(canvas, () => memory),
  consoleLogS: (ptr, len) => {
    const bytes = new Uint8Array(memory.buffer, ptr, len);
    let s = "";
    for (const b of bytes) {
      s += String.fromCharCode(b);
    }
    console.log(s);
  }
};

fetch("snake-game.wasm")
  .then(response => response.arrayBuffer())
  .then(bytes => WebAssembly.instantiate(bytes, { env }))
  .then(results => results.instance)
  .then(instance => {
    memory = instance.exports.memory;
    instance.exports.onInit();

    const SHOULD_QUIT = instance.exports.QUIT;

    // Timestep based on the Gaffer on Games post, "Fix Your Timestep"
    //    https://www.gafferongames.com/post/fix_your_timestep/
    const MAX_DELTA = new Float64Array(
      memory.buffer,
      instance.exports.MAX_DELTA_SECONDS,
      1
    )[0];
    const TICK_DELTA = new Float64Array(
      memory.buffer,
      instance.exports.TICK_DELTA_SECONDS,
      1
    )[0];
    let prevTime = performance.now();
    let tickTime = 0.0;
    let accumulator = 0.0;

    function step(currentTime) {
      let delta = (currentTime - prevTime) / 1000; // Delta in seconds
      if (delta > MAX_DELTA) {
        delta = MAX_DELTA; // Try to avoid spiral of death when lag hits
      }
      prevTime = currentTime;

      accumulator += delta;

      while (accumulator >= TICK_DELTA) {
        instance.exports.update(tickTime, TICK_DELTA);
        accumulator -= TICK_DELTA;
        tickTime += TICK_DELTA;
      }

      // Where the render is between two timesteps.
      // If we are halfway between frames (based on what's in the accumulator)
      // then alpha will be equal to 0.5
      const alpha = accumulator / TICK_DELTA;

      instance.exports.render(alpha);

      const shouldQuit = new Uint8Array(
        memory.buffer,
        instance.exports.shouldQuit,
        1
      )[0];
      if (shouldQuit !== SHOULD_QUIT) {
        window.requestAnimationFrame(step);
      }
    }

    canvas.addEventListener("mousemove", ev => {
      const rect = canvas.getBoundingClientRect();
      instance.exports.onMouseMove(ev.x - rect.left, ev.y - rect.top);
    });

    const onResize = () => {
      canvas.width = window.innerWidth - 0.02 * window.innerWidth;
      canvas.height = window.innerHeight - 0.04 * window.innerHeight;
      instance.exports.onResize();
    };
    onResize();
    window.addEventListener("resize", onResize);
    new ResizeObserver(onResize).observe(document.body);

    window.requestAnimationFrame(step);
  });
