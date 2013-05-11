Four
====

Four is a lightweight OpenGL rendering engine for Lubyk. It provides a
basic abstraction layer for compositional GLSL shader programming and
rendering.

Below, a quick tour of four is provided, more details can be found in
the library's reference documentation generated from the Lua
files. Basic knowledge of OpenGL and 3D real-time rendering is
assumed.


Quick theory of operations
--------------------------

Four works under an implicit OpenGL rendering context. Setting up the
OpenGL context is left to the client of the library. Currently it
needs at least an OpenGL 3.2 context. New rendering backends
(e.g. OpenGL ES) can be added by implementing the `Renderer.lua`
interface; `RendererGL32.lua` can be used as a blueprint.

To get something rendered on the screen the following steps must be taken.

1. Create a renderer object `renderer` with the appropriate backend 
   (defaults to OpenGL 3.2).
2. Make sure there's a corresponding valid OpenGL context. 
3. Invoke `renderer:render(cam, {obj})` where `cam` is a camera object 
   and `obj` a renderable. 

A *renderable* is any object with two mandatory fields, `geometry` and
`effect` respectively referencing a `Geometry` and `Effect` object;
more on this in the following sections.

A minimal example drawing a tri-colored triangle can be found in
[`test/minimal.lua`](test/minimal.lua), run it with:

    luajit minimal.lua 


Mathematical conventions
------------------------

The following conventions are used throughout the library.

* In 3D space we assume a 
  [right-handed](http://mathworld.wolfram.com/Right-HandedCoordinateSystem.html)
  coordinate system.
* Angles are always given in radians. 
* In 2D space positive angles determine counter clockwise rotations. 
* In 3D space positive angles determine rotations directed according to the 
  [right-hand](http://mathworld.wolfram.com/Right-HandRule.html) rule. 


Basic graphics data types
-------------------------

Four provides data types and functions for vectors `V2`, `V3`, `V4`,
4x4 matrices `M4`, and quaternions `Quat`. Even though these types are
implemented as Lua arrays use them as abstract, immutable, types.

There is no special type for color values but the `Color` module
provides convenience constructor and accessors to specify colors in
the HSVA or RGBA color spaces. The resulting colors are stored as RGBA
intensities in `V4` values.


Transforms
----------

A `Transform` object is a convenience mutable object to orient an
object in 3D space. It decomposes an `M4` matrix into scaling,
rotation and translation components (applied in this order) available
through these keys:

* `scale`, the `V3` value defining the scaling component.
* `rot`, the `Quat` value defining the orientation component. 
* `pos`, the `V3` value defining the translation component. 
* `matrix`, the `M4` matrix resulting from scaling, rotating and translating
   according to `scale`, `rot` and `pos`.

The `scale`, `rot` and `pos` keys can be set directly; this
automatically updates `matrix` and *vice-versa*.

Transform objects can be attached to renderables and cameras via their 
`transform` key.


Buffers
-------

A `Buffer` object holds 1D to 4D integer or float vectors in a linear
Lua array (future versions of four should also allow to wrap a
malloc'd C pointer).

Buffers are used to specify vertex data and texture data. The important 
`Buffer` keys are:

* `dim`, the vector dimension.
* `scalar_type`, the vector's element type, defines how the 
  data will be stored on the GPU. 

The following code defines a buffer with three 3D vertices. 

```lua
local vs = four.Buffer { dim = 3, scalar_type = four.Buffer.FLOAT } 
vs:push3D(-0.8, -0.8, 0.0)
vs:push3D( 0.8, -0.8, 0.0)
vs:pushV3(four.V3(0.0,  0.8, 0.0))

assert(vs:length() == 3) 
assert(vs:scalar_length() == 9)
```

By default a buffer's data is disposed once it is uploaded on the GPU
by the renderer. This can be prevented by setting the `disposable` key
to `false`. In that case also consider setting the `update` key to an
appropriate value.

**WARNING** Buffer indexing is one-based for now. Four will rapidly
change to zero-based indexing for buffers because OpenGL indexes are
zero-based and having to deal with the two forms simultaneously
is error-prone. 

Geometries
----------

A `Geometry` object gathers vertex data buffers, an index buffer and a
primitive --- lines, triangles, triangle strips, etc. 

The index buffer indexes **with zero-based indices** into vertex data
buffers. Along with the primitive this specifies renderable geometry
for the GPU.

The important `Geometry` keys are:

* `data`, table of named buffer objects all of the same length
  defining per vertex data. The key names are used to bind to 
  the corresponding vertex shader inputs.
* `primitive`, indicates how the index buffer should be interpreted to
  specify the geometry. For example with `Geometry.TRIANGLES`,
  the indices in the `index` buffer are taken three by three to define
  triangles. 
* `index`, a buffer of **unsigned** ints or bytes of any dimension, 
  indexing with zero-based indices into the buffers of `data` to define 
  the actual sequence of primitives. 

The following function returns a `Geometry` object for a colored
triangle located in clip space:

```lua
function triangle () -- Geometry object for a triangle inside clip space
  local vs = Buffer { dim = 3, scalar_type = Buffer.FLOAT } 
  local cs = Buffer { dim = 4, scalar_type = Buffer.FLOAT }
  local is = Buffer { dim = 3, scalar_type = Buffer.UNSIGNED_INT }
  
  vs:push3D(-0.8, -0.8, 0.0)      -- Vertices
  vs:push3D( 0.8, -0.8, 0.0)
  vs:push3D( 0.0,  0.8, 0.0)

  cs:pushV4(four.Color.red ())    -- Vertices' colors
  cs:pushV4(four.Color.green ())
  cs:pushV4(four.Color.blue ())

  is:push3D(0, 1, 2)              -- Index for a single triangle

  return Geometry { primitive = Geometry.TRIANGLES, 
                    index = is, data = { vertex = vs, color = cs}}
end
```

To access the geometry's data in a vertex shader the GLSL code must
declare variables whose names match the keys of the `data` table:

```glsl
in vec3 vertex; // vertex buffer 
in vec3 color;  // color buffer
```

Note that once a geometry object was rendered its buffer structure ---
that is the buffer objects used --- cannot change, the underlying data
in the buffers may, however, change.


Effects
-------

An effect object defines a configuration of the GPU for rendering a
geometry object. The important keys of an effect are:

* `vertex`, the vertex shader.
* `geometry`, the geometry shader (optional).
* `fragment`, the fragment shader. 
* `default_uniforms`, a key/value table defining default values for uniforms. 
* `uniforms`, a uniform lookup function invoked to get uniform values. 


Shaders fields `vertex`, `geometry` and `fragment` are either
`Effect.Shader` objects or a list thereof. An `Effect.Shader` object
only wraps a piece of GLSL code, for example `Effect.Shader(src)` is a
shader object with the GLSL code `src`.

The following effect colors geometry specified in clip space.
```lua
local effect = Effect -- Colors the triangle
{
  vertex = Effect.Shader [[
    in vec3 vertex;
    in vec3 color;
    out vec4 v_color;
    void main()
    {
      v_color = vec4(color, 1.0);
      gl_Position = vec4(vertex, 1.0);
    }]],
  
   fragment = Effect.Shader [[
     in vec4 v_color;
     out vec4 color;
     void main() { color = v_color; }
   ]]
}
```

If a shader field holds a table of shader objects, those are
concatenated to form the shader source, this allows to define and
reuse shader functions from other modules.


### Uniforms lookup

Shaders may declare uniforms variables. When an effect `e` is used the
actual value bound to the uniform is determined as follows. Given an
uniform named `u`:

```glsl
uniform vec4 u;
```

the function call `e.uniform(e, cam, r, "u")` is invoked where `e` is
the effect, `cam` the current camera, `r` the renderable. If the
function returns `nil`, the result of `e.default_uniforms["u"]` is
used.

The default implementation of `e.uniform` is `return r["u"]`, that is
it looks for a corresponding key in the renderable.

TODO document the map from lua types to GLSL types.

### Special uniforms values

The effect module defines a few special uniform values. These
values are dynamically computed by the renderer according to the
current camera and renderable (or other parameters). 

For example the special uniform value `Effect.MODEL_TO_CLIP`
automatically holds the matrix for transforming from model space to
clip space according to the current renderable transform, camera
transform and projection.

Here is a typical vertex shader transforming vertices from model space
to clip space:
```lua
local effect = Effect 
{
  default_uniforms = { m2c = Effect.MODEL_TO_CLIP } 
  vertex = Effect.Shader [[ 
    uniform mat4 m2c;
    in vec3 vertex; 
    void main () { gl_Position = m2c * vec4(vertex, 1.0); } 
  ]]
}
```

Renderables
-----------

A renderable can be any object. To be rendered by the renderer it must
at least have an `effect` and a `geometry` object, otherwise it is
simply ignored. The following keys are interpreted by the renderer:

* `geometry`, the geometry object to render. 
* `effect`, the effect with which `geometry` should be rendered. 
* `transform` (optional), a transform object defining a transform to 
  apply to `geometry`, in other words, a world transform.  
* `instance_count`, the number of instances to render. 
* `visible` (optional), if present and `false` disables the rendering
  of the renderable.
 

Camera
------

A `Camera` object defines a view volume of world space. Only those
object that are part of the view volume are rendered. The important
keys:

* `transform` defines the location and orientation of the camera. The
  default transform lies at the origin and looks down the z-axis. 
* `range`, a `V2` value defining the near and far clip plane as a distance
  along the forward vector from the current point of view.
* `fov`, the horizontal field of view. 
* `aspect`, the camera width/height ratio.

The following code defines a camera located at `cam_pos` and looking
at the point `cam_target`.

```lua
local cam_pos = V3(-3, 5, 5) 
local cam_target = V3(1, 1, 1) 
local cam_rot = Quat.rotMap(-V3.oz(), V3.unit(cam_target - cam_pos))
local cam = Camera { transform = Transform { pos = cam_pos, rot = cam_rot }}
```

TODO implement and use lookat.

Multipass rendering and opacity partitionning
---------------------------------------------

Given a renderer, a camera `cam` and a list of renderables `rs`, a frame 
is rendered with: 
```lua
renderer:render(cam, rs) 
```
To minimize GPU configuration changes, the renderables in `rs` are sorted 
and rendered according to the effect they use. 

Renderables can be rendered with multiple pass. In fact an effect can
be either an effect as defined above or a list of effects. In general
this results in a tree structure. The depth-first order traversal of
this tree defines a number of passes. The renderer start by rendering
the first pass of each renderable, then the second pass etc.

In each pass effects are partitionned into opaque and non-opaque
effects according to the `opaque` boolean attribute of an effect. 
Renderables with opaque effects are rendered before the ones
with non-opaque effects.

TODO examples

Troubleshooting tips
--------------------

TODO expand and improve

### Nothing is drawn

For a renderable `r` verify the following 

* `assert(r.visible == nil or r.visible)`
* `assert(r.effect)`
* `assert(r.geometry)`
* `assert(r.geometry.index.type == UNSIGNED_INT ||
          r.geometry.index.type == UNSIGNED_BYTE)`

### GL error: invalid enum

Ensure that `geometry.primitive`, `buffer.type` is not `nil`.
