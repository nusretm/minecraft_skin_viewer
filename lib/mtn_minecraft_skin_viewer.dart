/// Minecraft Java Edition skin/cape textures, UV, 2D and 3D widgets.
///
/// R2 texture data and pure-Dart UV meshes are shared between both viewers.
/// The 3D widget owns GPU resources internally; no renderer types are exposed.
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
export 'src/mtn_minecraft_skin_2d.dart'
    show
        MtnMinecraftSkinView,
        MtnMinecraftSkinHead,
        MtnMinecraftSkinPreview,
        MtnMinecraftCapePreview;
export 'src/mtn_minecraft_skin_mesh.dart' show MtnMinecraftSkinBoxMesh;
export 'src/mtn_minecraft_skin_pose_cape.dart'
    show MtnMinecraftCapeBoxMesh, MtnMinecraftSkinPose,
         MtnMinecraftSkinPoseFrame, MtnMinecraftSkinPivot;

export 'src/mtn_minecraft_skin_viewer_controller.dart'
    show MtnMinecraftSkinViewerController;
export 'src/mtn_minecraft_skin_viewer_3d.dart'
    show MtnMinecraftSkinViewer;
