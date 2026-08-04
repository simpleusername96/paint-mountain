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

  function buildShapeParameters(random, level) {
    const peaks = [];
    const peakCount = 1 + level;
    peaks.push({
      x: randomRange(random, -0.16, 0.16),
      z: randomRange(random, -0.30, -0.08),
      height: randomRange(random, 20, 27),
      spread: randomRange(random, 0.28, 0.38),
    });
    for (let index = 1; index < peakCount; index += 1) {
      peaks.push({
        x: randomRange(random, -0.58, 0.58),
        z: randomRange(random, -0.48, 0.42),
        height: randomRange(random, 7 + level, 13 + level * 1.4),
        spread: randomRange(random, 0.20, 0.34),
      });
    }

    const valleys = Array.from({ length: level }, () => ({
      angle: randomRange(random, 0, TAU),
      width: randomRange(random, 0.22, 0.36),
      depth: randomRange(random, 4 + level * 0.8, 7 + level * 1.4),
      start: randomRange(random, 0.22, 0.42),
    }));

    const waves = Array.from({ length: Math.max(0, level - 1) }, (_, index) => ({
      angularFrequency: 2 + index,
      radialFrequency: 1 + (index % 2),
      phase: randomRange(random, 0, TAU),
      amplitude: randomRange(random, 1.2, 2.0 + level * 0.35),
    }));

    return {
      peaks,
      valleys,
      waves,
      contourPhaseA: randomRange(random, 0, TAU),
      contourPhaseB: randomRange(random, 0, TAU),
      contourPhaseC: randomRange(random, 0, TAU),
      ridgePhase: randomRange(random, 0, TAU),
      ridgeCount: 2 + level,
      ridgeAmplitude: 2.6 + level * 1.0,
      terraceMix: randomRange(random, 0.16, 0.28),
      terraceStep: randomRange(random, 3.8, 5.0),
      smoothingBlend: 0.28 - level * 0.018,
      maximumGrade: 0.82 + level * 0.045,
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

    let strongestPeak = 0;
    let secondPeak = 0;
    parameters.peaks.forEach((peak) => {
      const dx = normalizedX - peak.x;
      const dz = normalizedZ - peak.z;
      const contribution = peak.height * Math.exp(-(dx * dx + dz * dz) / peak.spread);
      if (contribution > strongestPeak) {
        secondPeak = strongestPeak;
        strongestPeak = contribution;
      } else if (contribution > secondPeak) {
        secondPeak = contribution;
      }
    });
    height += strongestPeak + secondPeak * 0.24;

    const ridge = Math.sin(theta * parameters.ridgeCount + parameters.ridgePhase);
    height += Math.max(0, ridge) * (1 - radialRatio) * parameters.ridgeAmplitude;

    parameters.waves.forEach((wave) => {
      const angularWave = Math.sin(theta * wave.angularFrequency + wave.phase);
      const radialWave = Math.sin(radialRatio * Math.PI * wave.radialFrequency);
      height += angularWave * radialWave * wave.amplitude;
    });

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

  function buildTopEdges(indices) {
    const keys = new Set();
    const edges = [];
    for (let index = 0; index < indices.length; index += 3) {
      const triangle = [indices[index], indices[index + 1], indices[index + 2]];
      for (let edgeIndex = 0; edgeIndex < 3; edgeIndex += 1) {
        const first = triangle[edgeIndex];
        const second = triangle[(edgeIndex + 1) % 3];
        const minimum = Math.min(first, second);
        const maximum = Math.max(first, second);
        const key = `${minimum}:${maximum}`;
        if (!keys.has(key)) {
          keys.add(key);
          edges.push([minimum, maximum]);
        }
      }
    }
    return edges;
  }

  function regularizeTopSurface(vertices, topIndices, smoothingBlend, maximumGrade) {
    const edges = buildTopEdges(topIndices);
    const neighbors = Array.from({ length: vertices.length }, () => []);
    edges.forEach(([first, second]) => {
      neighbors[first].push(second);
      neighbors[second].push(first);
    });

    for (let pass = 0; pass < 4; pass += 1) {
      const nextHeights = vertices.map((vertex) => vertex[1]);
      for (let index = 0; index < vertices.length; index += 1) {
        if (neighbors[index].length === 0) continue;
        const average = neighbors[index].reduce(
          (sum, neighbor) => sum + vertices[neighbor][1],
          0
        ) / neighbors[index].length;
        nextHeights[index] += (average - nextHeights[index]) * smoothingBlend;
      }
      nextHeights.forEach((height, index) => {
        vertices[index][1] = Math.max(6.5, height);
      });
    }

    for (let pass = 0; pass < 96; pass += 1) {
      let changed = false;
      edges.forEach(([first, second]) => {
        const a = vertices[first];
        const b = vertices[second];
        const horizontalDistance = Math.hypot(a[0] - b[0], a[2] - b[2]);
        const allowedDifference = horizontalDistance * maximumGrade;
        if (a[1] - b[1] > allowedDifference) {
          a[1] = Math.max(6.5, b[1] + allowedDifference);
          changed = true;
        } else if (b[1] - a[1] > allowedDifference) {
          b[1] = Math.max(6.5, a[1] + allowedDifference);
          changed = true;
        }
      });
      if (!changed) break;
    }

    let measuredMaximumGrade = 0;
    edges.forEach(([first, second]) => {
      const a = vertices[first];
      const b = vertices[second];
      const horizontalDistance = Math.hypot(a[0] - b[0], a[2] - b[2]);
      measuredMaximumGrade = Math.max(
        measuredMaximumGrade,
        Math.abs(a[1] - b[1]) / Math.max(horizontalDistance, 0.0001)
      );
    });
    return measuredMaximumGrade;
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

  function generate(seed, requestedLevel) {
    const level = Math.max(1, Math.min(5, Math.round(Number(requestedLevel) || 1)));
    const random = mulberry32(seed);
    const parameters = buildShapeParameters(random, level);
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

    const maximumGrade = regularizeTopSurface(
      vertices,
      indices,
      parameters.smoothingBlend,
      parameters.maximumGrade
    );

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
      level,
      closed,
      featureCount: parameters.peaks.length + parameters.valleys.length + parameters.waves.length,
      triangleCount: indices.length / 3,
      maximumHeight: faceted.maximumHeight,
      maximumGrade,
      positions: faceted.positions,
      normals: faceted.normals,
      colors: faceted.colors,
    };
  }

  window.MountainGenerator = { generate };
})();
