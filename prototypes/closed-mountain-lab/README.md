# Closed Mountain Lab

This is a standalone, dependency-free WebGL prototype. It does not import or
modify Paint Mountain gameplay code.

Open `index.html` directly in a modern browser. Click the mountain, press
Space, or use the `새 지형 만들기` button to generate another seeded object.
Drag to orbit and use the mouse wheel to zoom.

Each generated object consists of:

- one triangulated, faceted top surface with peaks, ridges, valleys, terraces,
  and steep slopes;
- one continuous irregular perimeter;
- side-wall triangles joining every perimeter edge to a shared base; and
- a bottom cap.

The generator counts every undirected mesh edge and reports the object as
closed only when every edge belongs to exactly two triangles.
