let canvas = document.getElementById("canvas2d");

let context = canvas.getContext("2d");

function getScreenW() {
  return context.canvas.width;
}

function getScreenH() {
  return context.canvas.height;
}

function clearRect(x, y, width, height) {
  context.clearRect(x, y, width, height);
}

function setFillStyle(r, g, b) {
  context.fillStyle = `rgb(${r}, ${g}, ${b})`;
}

function fillRect(x, y, width, height) {
  context.fillRect(x, y, width, height);
}

function fillRect2(x, y, width, height, radians) {
  context.save();
  context.translate(x, y);
  context.rotate(radians);
  context.fillRect(-width / 2, -height / 2, width, height);
  context.restore();
}

export default {
  getScreenW,
  getScreenH,
  clearRect,
  setFillStyle,
  fillRect,
  fillRect2,
  context,
  element: canvas
};
