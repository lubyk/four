# Four -- OpenGL rendering engine for Lubyk

Four is a lightweight OpenGL rendering engine for Lubyk. It provides a
basic abstraction layer for compositional GLSL shader programming and
rendering.

In the following a quick tour of four is provided. It assumes basic
knowledge of real-time rendering. More details can be found in the
library's reference documentation generated from the Lua files.



## Quick theory of operations

Four works under an implicit OpenGL rendering context. Setting up the
OpenGL context is left to the client of the library. Currently it
needs at least an OpenGL 3.2 context. New rendering backends
(e.g. OpenGL ES) may be added by implementing the `Renderer.lua`
interface; `RendererGL32.lua` can be used as a blueprint.

To get something onto the screen the following steps must be
performed.

1. Create a renderer object `renderer` with the appropriate backend 
   (defaults to OpenGL 3.2)
2. Make sure there's a corresponding valid OpenGL context. 
3. Invoke `renderer:render(cam, {obj})` where `cam` is a camera object 
   and `obj` a renderable. 

A renderable is any object with two mandatory fields, `geometry` and
`effect`. The `geometry` field must hold a `Geometry` object and
`effect` an `Effect` object. 

A minimal example can be found in `test/minimal.lua` if you run it as follows:

    luajit minimal.lua 

It should draw a tri-colored triangle. The following sections give you
more information about to the various data types involved in four's
usage.


## Mathematical conventions

The following conventions are used throughout the library.

* In 3D space we assume a 
  [right-handed](http://mathworld.wolfram.com/Right-HandedCoordinateSystem.html)
  coordinate system.
* Angles are always given in radians. 
* In 2D space positive angles determine counter clockwise rotations. 
* In 3D space positive angles determine rotations directed according to the 
  [right-hand](http://mathworld.wolfram.com/Right-HandRule.html) rule. 


## Basic graphics data types

Four provides data types and functions for vectors (`V2`, `V3`, `V4`),
4x4 matrices (`M4`) and quaternions (`Quat`). Even though these types
are implemented as Lua arrays the library encourages you to use them
as abstract, immutable, types.

There is no special type for color values but the `Color` module
allows to define colors as `V4` values. The module provides a few
convenience constructor/accessors to specify colors the HSVA or RGBA
color spaces but the result is always a V4 value storing RGBA values.


## Buffer objects

A `Buffer` object holds 1D to 4D int/float vectors in a linear Lua array
(future versions of four will allow to encapsulate malloc'd C pointers).

Buffers are used to specify vertex data and texture data. The most
important `Buffer` keys are:

* `dim`, the vector dimension, this influences the way elements 
  are accessed in the array and how shaders will view the data. 
* `scalar_type`, the vector's element type, defines how the 
  data will be stored on the GPU and how shaders will view the 
  data. 

The following code defines a buffer with three 3D vertices. 

    local vs = four.Buffer { dim = 3, scalar_type = four.Buffer.FLOAT } 
    vs:push3D(-0.8, -0.8, 0.0)
    vs:push3D( 0.8, -0.8, 0.0)
    vs:pushV3(four.V3(0.0,  0.8, 0.0))

    assert(vs:length() == 3) 
    assert(vs:scalar_length() == 9)

By default a buffer's data is disposed once it is uploaded on the GPU
by the renderer. This can be prevented by setting the `disposable` key
to `false`. In that case also consider setting the `update` key to an
appropriate value.


## Geometry objects

A `Geometry` object gathers vertex data buffers, an index buffer and a
primitive specification -- line, triange, triangle strip, etc. The
*zero-based* index buffer indexes into vertex data buffers and with
the primitive specification specifies renderable geometry for the GPU.

The most important `Geometry` keys are:

* `primitive`, indicates how the index buffer should be interpreted to
  specify the geometry. E.g. if `primitive` is `Geometry.TRIANGLES`,
  the indices in the `index` buffer are taken three by three to define
  the actual
* `index`, a `Buffer` of unsigned ints or bytes, indexing into the 
  buffers of `data` to define the actual sequence of primitives. 
  *WARNING* indices are zero-based while Buffer ones are not
  *this will be changed in the next version of four*, we will
  make Buffer zero-based.
* `data`, table of named `Buffer`s objects all of the same size
  defining per vertex data. Table key names are used to bind to 
  the corresponding vertex shader inputs.

The following functions returns a `Geometry` object for a colored
triangle located in clip space:

    function triangle () -- Geometry object for a triangle inside clip space
      local vs = Buffer { dim = 3, scalar_type = Buffer.FLOAT } 
      local cs = Buffer { dim = 4, scalar_type = Buffer.FLOAT }
      local is = Buffer { dim = 1, scalar_type = Buffer.UNSIGNED_INT }
  
      vs:push3D(-0.8, -0.8, 0.0)      -- Vertices
      vs:push3D( 0.8, -0.8, 0.0)
      vs:push3D( 0.0,  0.8, 0.0)

      cs:pushV4(four.Color.red ())    -- Vertices' colors
      cs:pushV4(four.Color.green ())
      cs:pushV4(four.Color.blue ())

      is:push3D(0, 1, 2)              -- Index for a single triangle

      return Geometry { primitive = Geometry.TRIANGLE, 
                        index = is, data = { vertex = vs, color = cs}}
    end

To access the geometry's data in a vertex shader the GLSL code should
declare variables whose names match the keys of the `data` table:

     in vec3 vertex; // vertex buffer 
     in vec3 color;  // color buffer

Note that once a geometry object was rendered its Buffer structure --
that is the buffer objects used -- cannot change, the underlying data
in the buffer may however change.


## Effects objects

An effect object defines a configuration of the GPU for rendering a
Geometry object. The most important keys of an effect are:

* `vertex`, the vertex shader.
* `geometry`, the geometry shader (optional).
* `fragment`, the fragment shader. 
* `default_uniforms`, a key/value table defining default values for uniforms. 
* `uniforms`, a uniform lookup function invoked before rendering a renderable 
   to get a uniform value. 

Shaders fields must hold either an `Effect.Shader` object or a list
(table) of `Effect.Shader` objects. `Effect.Shader(src)` returns a
shader fragment with GLSL code `src`. The following shader colors
geometry specified in clip space.


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
        }
      ]],
  
      fragment = Effect.Shader [[
        in vec4 v_color;
        out vec4 color;
        void main() { color = v_color; }
      ]]
    }

The effect module also defines a few special uniforms. These uniforms
are dynamically computed by the renderer according to the current
camera and renderable. For example a typical vertex shader needs to
transform vertices from model space to clip space:

    local effect = Effect 
    {
       default_uniforms = { m2c = Effect.MODEL_NORMAL_CAMERA } 
       vertex = Effect.Shader [[ 
          in vec3 vertex; 
          void main () { gl_Position = m2c * vec4(vertex, 1.0); } 
       ]]
    }

by setting `m2c`'s default value to `Effect.MODEL_TO_CLIP`, the
renderer will automatically setup the uniform `m2c` corresponding to
the current camera and renderable transform.


## Renderables

A renderable can be any object. It must at least have an `effect` and
a `geometry` object. The following keys are interpreted by the
renderer:

* `geometry`, the geometry object to render. 
* `effect`, the effect with which `geometry` should be rendered. 
* `transform` (optional), a `Transform` object defining a transform to 
  apply to `geometry`, in other words, a world transform.  
* `visible` (optional), if present and `false` disables the rendering
  of the renderable.


## Camera

TODO

## Uniform lookup

TODO

## Multipass and alpha

TODO

## Troubleshooting tips

TODO

* Nothing shows up for renderable `r` verify the following:
  assert(r.visible == nil or r.visible)
  assert(r.effect)
  assert(r.geometry)

 Very that you renderable `r` has not visible set to 
  `false`
* Nothing shows up, verify renderable has a `geometry` or `effect` field.
* GL error: invalid enum
** Is geometry.primitive, buffer.type, nil or something like this. 
* Renderable is missing a field effect or geometry 