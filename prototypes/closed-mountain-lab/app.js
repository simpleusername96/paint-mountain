(function () {
  "use strict";

  const canvas = document.getElementById("mountain-canvas");
  const regenerateButton = document.getElementById("regenerate");
  const status = document.getElementById("mesh-status");
  const seedValue = document.getElementById("seed-value");
  const triangleValue = document.getElementById("triangle-value");
  const heightValue = document.getElementById("height-value");
  const errorMessage = document.getElementById("webgl-error");
  let renderer;

  function randomSeed() {
    const values = new Uint32Array(1);
    if (window.crypto && window.crypto.getRandomValues) {
      window.crypto.getRandomValues(values);
      return values[0];
    }
    return Math.floor(Math.random() * 0xffffffff) >>> 0;
  }

  function regenerate() {
    const mesh = window.MountainGenerator.generate(randomSeed());
    renderer.setMesh(mesh);
    seedValue.textContent = mesh.seed.toString(16).toUpperCase().padStart(8, "0");
    triangleValue.textContent = mesh.triangleCount.toLocaleString("ko-KR");
    heightValue.textContent = `${mesh.maximumHeight.toFixed(1)} m`;
    status.textContent = mesh.closed ? "닫힌 메시 생성됨" : "메시 경계 오류";
  }

  try {
    renderer = new window.MountainRenderer(canvas, regenerate);
    regenerateButton.addEventListener("click", regenerate);
    window.addEventListener("keydown", (event) => {
      if (event.code === "Space" && event.target.tagName !== "BUTTON") {
        event.preventDefault();
        regenerate();
      }
    });
    regenerate();
  } catch (error) {
    console.error(error);
    errorMessage.hidden = false;
    regenerateButton.disabled = true;
    status.textContent = "WebGL 초기화 실패";
  }
})();
