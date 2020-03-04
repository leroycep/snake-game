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

      if (!instance.exports.hasQuit()) {
        window.requestAnimationFrame(step);
      } else {
          const quitLabel = document.createElement("p");
          quitLabel.textContent = "You have quit, game is stopped. Refresh the page to restart the game.";
          document.querySelector(".container").prepend(quitLabel);
      }
    }
    window.requestAnimationFrame(step);

    canvas.addEventListener("mousemove", ev => {
      const rect = canvas.getBoundingClientRect();
      instance.exports.onMouseMove(ev.x - rect.left, ev.y - rect.top);
    });

    const ex = instance.exports;
    const codeMap = {
      KeyW: ex.SCANCODE_W,
      KeyA: ex.SCANCODE_A,
      KeyS: ex.SCANCODE_S,
      KeyD: ex.SCANCODE_D,
      ArrowLeft: ex.SCANCODE_LEFT,
      ArrowRight: ex.SCANCODE_RIGHT,
      ArrowUp: ex.SCANCODE_UP,
      ArrowDown: ex.SCANCODE_DOWN,
      Escape: ex.SCANCODE_ESCAPE
    };
    document.addEventListener("keydown", ev => {
      if (ev.defaultPrevented) {
        return;
      }
      const zigConst = codeMap[ev.code];
      if (zigConst !== undefined) {
        const zigCode = new Uint16Array(memory.buffer, zigConst, 1)[0];
        instance.exports.onKeyDown(zigCode);
      }
    });

    document.addEventListener("keyup", ev => {
      if (ev.defaultPrevented) {
        return;
      }
      const zigConst = codeMap[ev.code];
      if (zigConst !== undefined) {
        const zigCode = new Uint16Array(memory.buffer, zigConst, 1)[0];
        instance.exports.onKeyUp(zigCode);
      }
    });

    const onResize = () => {
      instance.exports.onResize();
    };
    onResize();
    window.addEventListener("resize", onResize);
    new ResizeObserver(onResize).observe(document.body);
  });
