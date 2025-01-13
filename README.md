# Gamemaker 3D Chunk

> This repo also contain [Frustum culling script](https://github.com/callmeEthan/Gamemaker_frustum_culling)

A system I designed in Gamemaker, made to render larger map with camera view culling. It has multiple function:

- World map are devided into chunks. Each chunk are also subdivided into smaller chunk (You can set the level of subdivide, default is 3, minimum is 1 for no subdivide at all).  
- Frustum AABB intersection check are used to determine which chunk is visible, and if they are closer to the camera, smaller chunk are displayed intead.
- Model need to be add on each subdivide level individually. This way you can add model with different level of detail, or skip some.
- To reduce draw call as much as possible, vertex buffer are build on a whole row, then use vertex_submit_ext() to render visible chunk only.
### Pro:
> compare to render every chunk/model individually

- Efficient view culling
- Less draw call

### Con:

- Not performance free (depend on the map size, not enough subdivide can increase performance cost exponentially)
- Memory cost can increase exponentially due to having multiple model
- All model are expected to have the same texture, using a texture atlas is recommended
- Model are static, but can be transformed via vertex shader

## Screenshot
![alt text](https://github.com/callmeEthan/Gamemaker_3Dchunk_culling/blob/main/README/preview_1.gif?raw=true)
![alt text](https://github.com/callmeEthan/Gamemaker_3Dchunk_culling/blob/main/README/preview_2.gif?raw=true)
