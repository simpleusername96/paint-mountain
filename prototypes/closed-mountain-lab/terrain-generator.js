(function () {
  "use strict";

  const TAU = Math.PI * 2;

  function mulberry32(seed) {
    let value = seed >>> 0;
    return function () {
      value += 0x6d2b79f5;
      let result = value;
      result = Math.imul(result ^ (result >>> 15), result | 1);
      result ^= result + Math.imul(result ^ (result >>> 7), result | 61);
      return ((result ^ (result >>> 14)) >>> 0) / 4294967296;
    };
  }

  function randomRange(random, minimum, maximum) {
    return minimum + (maximum - minimum) * random();
  }

  function smoothstep(value) {
    const clamped = Math.max(0, Math.min(1, value));
    return clamped * clamped * (3 - 2 * clamped);
  }

  function angularDistance(first, second) {
    const distance = Math.abs(first - second) % TAU;
    return Math.min(distance, TAU - distance);
  }

  function computeNormal(a, b, c) {
    const abx = b[0] - a[0];
    const aby = b[1] - a[1];
    const abz = b[2] - a[2];
    const acx = c[0] - a[0];
    const acy = c[1] - a[1];
    const acz = c[2] - a[2];
    const nx = aby * acz - abz * acy;
    const ny = abz * acx - abx * acz;
    const nz = abx * acy - aby * acx;
    const length = Math.hypot(nx, ny, nz) || 1;
    return [nx / length, ny / length, nz / length];
  }

  function addTriangle(indices, first, second, third) {
    indices.push(first, second, third);
  }

  function validateClosedMesh(indices) {
    const edgeCounts = new Map();
    for (let index = 0; index < indices.length; index += 3) {
      const triangle = [indices[index], indices[index + 1], indices[index + 2]];
      for (let edge = 0; edge < 3; edge += 1) {
        const a = triangle[edge];
        const b = triangle[(edge + 1) % 3];
        const key = a < b ? `${a}:${b}` : `${b}:${a}`;
        edgeCounts.set(key, (edgeCounts.get(key) || 0) + 1);
      }
    }
    return Array.from(edgeCounts.values()).every((count) => count === 2);
  }

  function buildShapeParameters(random) {
    const peaks = [];
    const peakCount = 3 + Math.floor(random() * 3);
    peaks.push({
      x: randomRange(random, -0.16, 0.16),
      z: randomRange(random, -0.30, -0.08),
      height: randomRange(random, 24, 34),
      spread: randomRange(random, 0.13, 0.21),
    });
    for (let index = 1; index < peakCount; index += 1) {
      peaks.push({
        x: randomRange(random, -0.58, 0.58),
        z: randomRange(random, -0.48, 0.42),
        height: randomRange(random, 10, 23),
        spread: randomRange(random, 0.08, 0.19),
      });
    }

    const valleys = Array.from({ length: 2 + Math.floor(random() * 2) }, () => ({
      angle: randomRange(random, 0, TAU),
      width: randomRange(random, 0.12, 0.24),
      depth: randomRange(random, 7, 15),
      start: randomRange(random, 0.22, 0.42),
    }));

    return {
      peaks,
      valleys,
      contourPhaseA: randomRange(random, 0, TAU),
      contourPhaseB: randomRange(random, 0, TAU),
      contourPhaseC: randomRange(random, 0, TAU),
      ridgePhase: randomRange(random, 0, TAU),
      ridgeCount: 3 + Math.floor(random() * 3),
      terraceMix: randomRange(random, 0.28, 0.46),
      terraceStep: randomRange(random, 3.6, 5.2),
    };
  }

  function contourRadius(theta, parameters) {
    const variation =
      Math.sin(theta * 2 + parameters.contourPhaseA) * 0.075 +
      Math.sin(theta * 3 + parameters.contourPhaseB) * 0.050 +
      Math.sin(theta * 7 + parameters.contourPhaseC) * 0.025;
    return 48 * (1 + variation);
  }

  function surfaceHeight(x, z, radialRatio, theta, parameters) {
    const normalizedX = x / 48;
    const normalizedZ = z / 48;
    const dome = 9 + 34 * Math.pow(Math.max(0, 1 - Math.pow(radialRatio, 1.75)), 0.58);
    let height = dome;

    parameters.peaks.forEach((peak) => {
      const dx = normalizedX - peak.x;
      const dz = normalizedZ - peak.z;
      height += peak.height * Math.exp(-(dx * dx + dz * dz) / peak.spread);
    });

    const ridge = Math.sin(theta * parameters.ridgeCount + parameters.ridgePhase);
    height += Math.max(0, ridge) * (1 - radialRatio) * 7.5;

    parameters.valleys.forEach((valley) => {
      const angleGap = angularDistance(theta, valley.angle);
      const angularCut = Math.exp(-(angleGap * angleGap) / valley.width);
      const radialCut = smoothstep((radialRatio - valley.start) / 0.20);
      height -= valley.depth * angularCut * radialCut * (0.35 + radialRatio * 0.65);
    });

    const terraced = Math.round(height / parameters.terraceStep) * parameters.terraceStep;
    height += (terraced - height) * parameters.terraceMix;
    return Math.max(6.5, height);
  }

  function expandFaceted(vertices, indices, random, baseY) {
    const positions = [];
    const normals = [];
    const colors = [];
    let maximumHeight = -Infinity;

    for (let index = 0; index < indices.length; index += 3) {
      const a = vertices[indices[index]];
      const b = vertices[indices[index + 1]];
      const c = vertices[indices[index + 2]];
      const normal = computeNormal(a, b, c);
      const isBottom = Math.abs(a[1] - baseY) < 0.001 &&
        Math.abs(b[1] - baseY) < 0.001 &&
        Math.abs(c[1] - baseY) < 0.001;
      const upwardness = Math.max(0, normal[1]);
      const facetVariation = randomRange(random, -0.035, 0.035);
      let color;
      if (isBottom) {
        color = [0.43, 0.44, 0.46];
      } else if (upwardness < 0.12) {
        color = [0.60 + facetVariation, 0.61 + facetVariation, 0.63 + facetVariation];
      } else {
        const lightness = 0.81 + upwardness * 0.12 + facetVariation;
        color = [lightness, lightness * 0.985, lightness * 0.955];
      }

      [a, b, c].forEach((vertex) => {
        positions.push(vertex[0], vertex[1], vertex[2]);
        normals.push(normal[0], normal[1], normal[2]);
        colors.push(color[0], color[1], color[2]);
        maximumHeight = Math.max(maximumHeight, vertex[1]);
      });
    }

    return {
      positions: new Float32Array(positions),
      normals: new Float32Array(normals),
      colors: new Float32Array(colors),
      maximumHeight,
    };
  }

  function generate(seed) {
    const random = mulberry32(seed);
    const parameters = buildShapeParameters(random);
    const ringCount = 20;
    const segmentCount = 56;
    const baseY = -14;
    const vertices = [[0, surfaceHeight(0, 0, 0, 0, parameters), 0]];
    const indices = [];

    function ringIndex(ring, segment) {
      return 1 + (ring - 1) * segmentCount + (segment % segmentCount);
    }

    for (let ring = 1; ring <= ringCount; ring += 1) {
      const radialRatio = ring / ringCount;
      for (let segment = 0; segment < segmentCount; segment += 1) {
        const theta = (segment / segmentCount) * TAU;
        const radius = contourRadius(theta, parameters) * radialRatio;
        const x = Math.cos(theta) * radius;
        const z = Math.sin(theta) * radius;
        vertices.push([x, surfaceHeight(x, z, radialRatio, theta, parameters), z]);
      }
    }

    for (let segment = 0; segment < segmentCount; segment += 1) {
      addTriangle(indices, 0, ringIndex(1, segment + 1), ringIndex(1, segment));
    }
    for (let ring = 1; ring < ringCount; ring += 1) {
      for (let segment = 0; segment < segmentCount; segment += 1) {
        const next = segment + 1;
        addTriangle(indices, ringIndex(ring, segment), ringIndex(ring, next), ringIndex(ring + 1, segment));
        addTriangle(indices, ringIndex(ring, next), ringIndex(ring + 1, next), ringIndex(ring + 1, segment));
      }
    }

    const bottomRingStart = vertices.length;
    for (let segment = 0; segment < segmentCount; segment += 1) {
      const top = vertices[ringIndex(ringCount, segment)];
      vertices.push([top[0], baseY, top[2]]);
    }
    const bottomCenter = vertices.length;
    vertices.push([0, baseY, 0]);

    for (let segment = 0; segment < segmentCount; segment += 1) {
      const next = (segment + 1) % segmentCount;
      const top = ringIndex(ringCount, segment);
      const topNext = ringIndex(ringCount, next);
      const bottom = bottomRingStart + segment;
      const bottomNext = bottomRingStart + next;
      addTriangle(indices, top, topNext, bottom);
      addTriangle(indices, topNext, bottomNext, bottom);
      addTriangle(indices, bottomCenter, bottom, bottomNext);
    }

    const closed = validateClosedMesh(indices);
    const faceted = expandFaceted(vertices, indices, random, baseY);
    return {
      seed,
      closed,
      triangleCount: indices.length / 3,
      maximumHeight: faceted.maximumHeight,
      positions: faceted.positions,
      normals: faceted.normals,
      colors: faceted.colors,
    };
  }

  window.MountainGenerator = { generate };
})();
