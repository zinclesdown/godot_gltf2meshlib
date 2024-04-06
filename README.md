![GLTF2MeshLib](addons/gltf2meshlib/gltf2meshlib.svg)

# GLTF2MeshLib

This plugin allows you to import gltf/glb models as MeshLibrary, which saves a lot of time compared to manual importing.

In the manual case, you would need to create an inherited scene of the gltf scene, reparent all mesh nodes (otherwise only the first mesh will be exported), and manually "export as MeshLibrary".

With this plugin, you can simply drag and drop gltf/glb files into the editor, select "GLTF To MeshLibrary" in the import settings, and it will automatically import your gltf/glb as a MeshLibrary. This allows you to see instant changes after any modification of the gltf file.

In my case, I used models made with Blockbench, exported as gltf, and imported into Godot with this plugin, and it seems to work fine as I expected. I am using Godot 4.3.

If you encounter any problems, or if you have any suggestions, please let me know in the Issues.

## Installation

you can simply install this plugin in Godot's built-in asset library.
If you prefers manual installation, you can download the zip file from the release page, and extract it to the root folder of your project.

## Contributors

This plugin is made by Zincles with help of many cool people( but I havent asked them if they are okay with me listing their names here, sorry :p )

## License

License under MIT License.
