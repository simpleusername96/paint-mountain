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
    const rangeAngle = randomRange(random, -0.34, 0.34);
    const rangeDirection = [Math.cos(rangeAngle), Math.sin(rangeAngle)];
    const rangePerpendicular = [-rangeDirection[1], rangeDirection[0]];
    const secondaryRidgeCount = 2 + level;
    // A broad, unbroken backbone keeps the object a mountain range instead of a crater.
    const ridges = [{
      x: randomRange(random, -0.05, 0.05),
      z: randomRange(random, -0.10, 0.02),
      angle: rangeAngle + randomRange(random, -0.10, 0.10),
      height: randomRange(random, 23, 29),
      lengthSpread: randomRange(random, 0.58, 0.78),
      widthSpread: randomRange(random, 0.10, 0.16),
    }];
    for (let index = 0; index < secondaryRidgeCount; index += 1) {
      const progress = (index + 1) / (secondaryRidgeCount + 1);
      const alongOffset = -0.62 + progress * 1.24 + randomRange(random, -0.07, 0.07);
      const crossOffset = randomRange(random, -0.10 - level * 0.012, 0.10 + level * 0.012);
      ridges.push({
        x: rangeDirection[0] * alongOffset + rangePerpendicular[0] * crossOffset,
        z: rangeDirection[1] * alongOffset + rangePerpendicular[1] * crossOffset,
        angle: rangeAngle + randomRange(random, -0.22 - level * 0.012, 0.22 + level * 0.012),
        height: randomRange(random, 15 + level * 0.6, 23 + level * 1.2),
        lengthSpread: randomRange(random, 0.24, 0.44),
        widthSpread: randomRange(random, 0.045, 0.095),
      });
    }

    // Basins are rare side features; they never replace or excavate the central backbone.
    const basinCount = level === 5 ? 2 : level >= 3 ? 1 : 0;
    const basins = Array.from({ length: basinCount }, (_, index) => {
      const firstIndex = Math.min(ridges.length - 2, 1 + index * 2);
      const first = ridges[firstIndex];
      const second = ridges[firstIndex + 1];
      const side = index % 2 === 0 ? 1 : -1;
      const centerX = (first.x + second.x) * 0.5 + rangePerpendicular[0] * 0.25 * side;
      const centerZ = (first.z + second.z) * 0.5 + rangePerpendicular[1] * 0.25 * side;
      return {
        x: centerX + randomRange(random, -0.06, 0.06),
        z: centerZ + randomRange(random, -0.06, 0.06),
        angle: rangeAngle + randomRange(random, -0.55, 0.55),
        depth: randomRange(random, 3.0, 5.0 + level * 0.25),
        lengthSpread: randomRange(random, 0.09, 0.16),
        widthSpread: randomRange(random, 0.09, 0.17),
      };
    });

    const passes = Array.from({ length: Math.max(0, level - 1) }, (_, index) => {
      const progress = (index + 1) / level;
      const alongOffset = -0.48 + progress * 0.96 + randomRange(random, -0.05, 0.05);
      const crossOffset = randomRange(random, -0.04, 0.04);
      return {
        x: rangeDirection[0] * alongOffset + rangePerpendicular[0] * crossOffset,
        z: rangeDirection[1] * alongOffset + rangePerpendicular[1] * crossOffset,
        angle: rangeAngle + Math.PI * 0.5 + randomRange(random, -0.22, 0.22),
        depth: randomRange(random, 2.6, 4.2 + level * 0.45),
        lengthSpread: randomRange(random, 0.14, 0.22),
        widthSpread: randomRange(random, 0.025, 0.050),
      };
    });

    const waves = Array.from({ length: Math.max(0, level - 1) }, (_, index) => ({
      angularFrequency: 2 + index,
      radialFrequency: 1 + (index % 2),
      phase: randomRange(random, 0, TAU),
      amplitude: randomRange(random, 1.2, 2.0 + level * 0.35),
    }));

    return {
      rangeAngle,
      ridges,
      basins,
      passes,
      waves,
      contourPhaseA: randomRange(random, 0, TAU),
      contourPhaseB: randomRange(random, 0, TAU),
      contourPhaseC: randomRange(random, 0, TAU),
      terraceMix: randomRange(random, 0.16, 0.28),
      terraceStep: randomRange(random, 3.8, 5.0),
      smoothingBlend: 0.28 - level * 0.018,
      maximumGrade: 0.82 + level * 0.045,
    };
  }

  function contourRadius(theta, parameters) {
    const relativeAngle = theta - parameters.rangeAngle;
    const longRadius = 58;
    const shortRadius = 43;
    const ellipseRadius = longRadius * shortRadius / Math.sqrt(
      Math.pow(shortRadius * Math.cos(relativeAngle), 2) +
      Math.pow(longRadius * Math.sin(relativeAngle), 2)
    );
    const variation =
      Math.sin(theta * 2 + parameters.contourPhaseA) * 0.075 +
      Math.sin(theta * 3 + parameters.contourPhaseB) * 0.050 +
      Math.sin(theta * 7 + parameters.contourPhaseC) * 0.025;
    return ellipseRadius * (1 + variation);
  }

  function orientedGaussian(x, z, feature) {
    const dx = x - feature.x;
    const dz = z - feature.z;
    const cosine = Math.cos(feature.angle);
    const sine = Math.sin(feature.angle);
    const along = dx * cosine + dz * sine;
    const across = -dx * sine + dz * cosine;
    return Math.exp(
      -(along * along / feature.lengthSpread + across * across / feature.widthSpread)
    );
  }

  function surfaceHeight(x, z, radialRatio, theta, parameters) {
    const normalizedX = x / 54;
    const normalizedZ = z / 54;
    const body = 8.5 + 18 * Math.pow(Math.max(0, 1 - Math.pow(radialRatio, 1.8)), 0.68);
    let height = body;

    const ridgeContributions = parameters.ridges.map((ridge) => {
      return ridge.height * orientedGaussian(normalizedX, normalizedZ, ridge);
    });
    ridgeContributions.sort((first, second) => second - first);
    height += (ridgeContributions[0] || 0) +
      (ridgeContributions[1] || 0) * 0.34 +
      (ridgeContributions[2] || 0) * 0.12;

    parameters.waves.forEach((wave) => {
      const angularWave = Math.sin(theta * wave.angularFrequency + wave.phase);
      const radialWave = Math.sin(radialRatio * Math.PI * wave.radialFrequency);
      height += angularWave * radialWave * wave.amplitude;
    });

    const interiorWeight = 1 - smoothstep((radialRatio - 0.72) / 0.22);
    parameters.basins.forEach((basin) => {
      height -= basin.depth * orientedGaussian(normalizedX, normalizedZ, basin) * interiorWeight;
    });
    parameters.passes.forEach((pass) => {
      height -= pass.depth * orientedGaussian(normalizedX, normalizedZ, pass) * interiorWeight;
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
    const centerHeight = vertices[0][1];
    const faceted = expandFaceted(vertices, indices, random, baseY);
    return {
      seed,
      level,
      closed,
      featureCount: parameters.ridges.length + parameters.basins.length +
        parameters.passes.length + parameters.waves.length,
      ridgeCount: parameters.ridges.length,
      basinCount: parameters.basins.length,
      triangleCount: indices.length / 3,
      maximumHeight: faceted.maximumHeight,
      centerHeight,
      maximumGrade,
      positions: faceted.positions,
      normals: faceted.normals,
      colors: faceted.colors,
    };
  }

  window.MountainGenerator = { generate };
})();
