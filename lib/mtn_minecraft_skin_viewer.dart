/// Minecraft Java Edition skin/cape atlas foundation.
///
/// R2 exports render-backend-independent decoded textures and pixel-space UV
/// mappings. 2D and 3D widget APIs will be introduced in later checkpoints.
library mtn_minecraft_skin_viewer;

export 'src/mtn_minecraft_skin_texture.dart'
    show MtnMinecraftSkinTexture, MtnMinecraftCapeTexture;
export 'src/mtn_minecraft_skin_uv.dart'
    show
        MtnMinecraftSkinModelType,
        MtnMinecraftSkinBodyPart,
        MtnMinecraftSkinLayer,
        MtnMinecraftSkinFace,
        MtnMinecraftSkinUvRect,
        MtnMinecraftSkinUvLayout,
        MtnMinecraftCapeUvLayout,
        mtnMinecraftBoxFace;
