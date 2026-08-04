(function () {
  "use strict";

  function compileShader(gl, type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      throw new Error(gl.getShaderInfoLog(shader) || "Shader compilation failed.");
    }
    return shader;
  }

  function createProgram(gl) {
    const vertexSource = `
      attribute vec3 a_position;
      attribute vec3 a_normal;
      attribute vec3 a_color;
      uniform mat4 u_view_projection;
      varying vec3 v_normal;
      varying vec3 v_color;
      void main() {
        v_normal = a_normal;
        v_color = a_color;
        gl_Position = u_view_projection * vec4(a_position, 1.0);
      }
    `;
    const fragmentSource = `
      precision mediump float;
      varying vec3 v_normal;
      varying vec3 v_color;
      void main() {
        vec3 normal = normalize(v_normal);
        vec3 light_direction = normalize(vec3(-0.48, 0.82, 0.34));
        float diffuse = max(dot(normal, light_direction), 0.0);
        float light = 0.42 + diffuse * 0.72;
        vec3 color = v_color * light;
        gl_FragColor = vec4(pow(color, vec3(0.94)), 1.0);
      }
    `;
    const program = gl.createProgram();
    gl.attachShader(program, compileShader(gl, gl.VERTEX_SHADER, vertexSource));
    gl.attachShader(program, compileShader(gl, gl.FRAGMENT_SHADER, fragmentSource));
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      throw new Error(gl.getProgramInfoLog(program) || "Shader linking failed.");
    }
    return program;
  }

  function perspective(fieldOfView, aspect, near, far) {
    const f = 1 / Math.tan(fieldOfView / 2);
    const rangeInverse = 1 / (near - far);
    return new Float32Array([
      f / aspect, 0, 0, 0,
      0, f, 0, 0,
      0, 0, (near + far) * rangeInverse, -1,
      0, 0, near * far * rangeInverse * 2, 0,
    ]);
  }

  function lookAt(eye, target, up) {
    let zx = eye[0] - target[0];
    let zy = eye[1] - target[1];
    let zz = eye[2] - target[2];
    let length = Math.hypot(zx, zy, zz) || 1;
    zx /= length; zy /= length; zz /= length;
    let xx = up[1] * zz - up[2] * zy;
    let xy = up[2] * zx - up[0] * zz;
    let xz = up[0] * zy - up[1] * zx;
    length = Math.hypot(xx, xy, xz) || 1;
    xx /= length; xy /= length; xz /= length;
    const yx = zy * xz - zz * xy;
    const yy = zz * xx - zx * xz;
    const yz = zx * xy - zy * xx;
    return new Float32Array([
      xx, yx, zx, 0,
      xy, yy, zy, 0,
      xz, yz, zz, 0,
      -(xx * eye[0] + xy * eye[1] + xz * eye[2]),
      -(yx * eye[0] + yy * eye[1] + yz * eye[2]),
      -(zx * eye[0] + zy * eye[1] + zz * eye[2]),
      1,
    ]);
  }

  function multiply(first, second) {
    const output = new Float32Array(16);
    for (let column = 0; column < 4; column += 1) {
      for (let row = 0; row < 4; row += 1) {
        output[column * 4 + row] =
          first[row] * second[column * 4] +
          first[4 + row] * second[column * 4 + 1] +
          first[8 + row] * second[column * 4 + 2] +
          first[12 + row] * second[column * 4 + 3];
      }
    }
    return output;
  }

  class MountainRenderer {
    constructor(canvas, onCanvasClick) {
      this.canvas = canvas;
      this.gl = canvas.getContext("webgl", { antialias: true, alpha: false });
      if (!this.gl) {
        throw new Error("WebGL unavailable.");
      }
      this.onCanvasClick = onCanvasClick;
      this.program = createProgram(this.gl);
      this.vertexCount = 0;
      this.yaw = -0.52;
      this.pitch = 0.35;
      this.distance = 190;
      this.drag = null;
      this.buffers = {
        position: this.gl.createBuffer(),
        normal: this.gl.createBuffer(),
        color: this.gl.createBuffer(),
      };
      this.locations = {
        position: this.gl.getAttribLocation(this.program, "a_position"),
        normal: this.gl.getAttribLocation(this.program, "a_normal"),
        color: this.gl.getAttribLocation(this.program, "a_color"),
        viewProjection: this.gl.getUniformLocation(this.program, "u_view_projection"),
      };
      this.bindEvents();
      this.gl.enable(this.gl.DEPTH_TEST);
      this.gl.enable(this.gl.CULL_FACE);
      this.gl.cullFace(this.gl.BACK);
      this.render = this.render.bind(this);
      requestAnimationFrame(this.render);
    }

    bindEvents() {
      this.canvas.addEventListener("pointerdown", (event) => {
        this.canvas.setPointerCapture(event.pointerId);
        this.drag = { x: event.clientX, y: event.clientY, moved: 0 };
      });
      this.canvas.addEventListener("pointermove", (event) => {
        if (!this.drag) return;
        const dx = event.clientX - this.drag.x;
        const dy = event.clientY - this.drag.y;
        this.drag.x = event.clientX;
        this.drag.y = event.clientY;
        this.drag.moved += Math.abs(dx) + Math.abs(dy);
        this.yaw -= dx * 0.008;
        this.pitch = Math.max(0.08, Math.min(1.1, this.pitch + dy * 0.006));
      });
      this.canvas.addEventListener("pointerup", () => {
        if (this.drag && this.drag.moved < 5 && this.onCanvasClick) {
          this.onCanvasClick();
        }
        this.drag = null;
      });
      this.canvas.addEventListener("pointercancel", () => {
        this.drag = null;
      });
      this.canvas.addEventListener("wheel", (event) => {
        event.preventDefault();
        this.distance = Math.max(120, Math.min(260, this.distance + event.deltaY * 0.10));
      }, { passive: false });
    }

    setMesh(mesh) {
      const gl = this.gl;
      const entries = [
        [this.buffers.position, this.locations.position, mesh.positions],
        [this.buffers.normal, this.locations.normal, mesh.normals],
        [this.buffers.color, this.locations.color, mesh.colors],
      ];
      entries.forEach(([buffer, location, data]) => {
        gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
        gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW);
        gl.enableVertexAttribArray(location);
        gl.vertexAttribPointer(location, 3, gl.FLOAT, false, 0, 0);
      });
      this.vertexCount = mesh.positions.length / 3;
    }

    resize() {
      const pixelRatio = Math.min(window.devicePixelRatio || 1, 2);
      const width = Math.max(1, Math.round(this.canvas.clientWidth * pixelRatio));
      const height = Math.max(1, Math.round(this.canvas.clientHeight * pixelRatio));
      if (this.canvas.width !== width || this.canvas.height !== height) {
        this.canvas.width = width;
        this.canvas.height = height;
      }
      this.gl.viewport(0, 0, width, height);
      return width / height;
    }

    render() {
      const gl = this.gl;
      const aspect = this.resize();
      gl.clearColor(0.93, 0.91, 0.875, 1);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
      if (this.vertexCount > 0) {
        const horizontal = Math.cos(this.pitch) * this.distance;
        const targetHeight = 40;
        const eye = [
          Math.sin(this.yaw) * horizontal,
          targetHeight + Math.sin(this.pitch) * this.distance,
          Math.cos(this.yaw) * horizontal,
        ];
        const projection = perspective(Math.PI / 4.4, aspect, 0.1, 500);
        const view = lookAt(eye, [0, targetHeight, 0], [0, 1, 0]);
        gl.useProgram(this.program);
        gl.uniformMatrix4fv(this.locations.viewProjection, false, multiply(projection, view));
        gl.drawArrays(gl.TRIANGLES, 0, this.vertexCount);
      }
      requestAnimationFrame(this.render);
    }
  }

  window.MountainRenderer = MountainRenderer;
})();
