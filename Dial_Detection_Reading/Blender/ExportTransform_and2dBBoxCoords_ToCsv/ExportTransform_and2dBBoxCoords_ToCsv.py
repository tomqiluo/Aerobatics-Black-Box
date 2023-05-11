"""
EC 464 Senior Design Project II
Boston University
Max Bakalos

Code to put the Location, Rotation, & Camera-Plane Bounding Box Pixel Coordinates for each frame into a CSV file


Sources adapted for this code: _-_-_-_-_-_-_-

CSV Animation Exporter:
https://github.com/ludvigStrom/Object-Animation-to-CSV-exporter---Blender

Camera-View 2D Vertex Extraction:
https://blender.stackexchange.com/a/1257
https://www.programcreek.com/python/?code=oscurart%2FBlenderAddons%2FBlenderAddons-master%2Fold%2Foscurart_auto_render_border.py
https://blender.stackexchange.com/a/1313


Notes: _-_-_-_-_-_-_-
1.  Must name bounding box object "BoundBox_Object" in Blender
2.  Must name camera "Camera" in Blender

"""

import bpy
from math import degrees
from bpy_extras.object_utils import world_to_camera_view    # for object coordinates

bl_info = {
    "name": "Export Dial Needle Rotation & Bounding-Box To CSV file",
    "author": "Max Bakalos (& Ludvig Ström)",
    "version": (1, 1),
    "blender": (2, 80, 0),
    "location": "File > Export > Selected Animation Bbox (.csv)",
    "warning": 'Must be named "BoundBox_Object" & "Camera" in Blender',
    "description": "Selected object transform & bounding box camera coords for each frame",
    "category": "Import-Export",
    "wiki_url": ""
}


def write_some_data(context, filepath):
    print("Exporting CSV animation...")
    
    selection = context.selected_objects    # selected objects
    scene = context.scene                   # scene
    startFrame = scene.frame_start          # start frame
    endFrame = scene.frame_end              # end frame
    currentFrame = scene.frame_current      # current frame

    # Get Resolution of Rendered Image _-_-_-_-_-
    # % of chosen resolution from render format options
    render_scale = scene.render.resolution_percentage / 100
    # Render resolution = (chosen resolution) * (% of chosen resolution)
    render_size = (
        int(scene.render.resolution_x * render_scale),
        int(scene.render.resolution_y * render_scale),
    )

    # Get vetrices of Bounding Box Object from POV of Camera _-_-_-_-_-
    #obj_bbx = bpy.data.objects['BoundBox_Object']   # bounding-box object
    cam = bpy.data.objects['Camera']                # camera
    
    # Open CSV file for writing
    f = open(filepath, 'w', encoding='utf-8')

    # Selected Object Number
    sel_obj_ind = 0

    # for each selected object . . .
    for sel in selection:
        # Print out object index
        sel_obj_ind += 1
        print("Object #%d", sel_obj_ind)

        # CREATE SUB-OBJECT VARIABLES _-_-_-_-_-_-_-_-
        # Bounding-Box
        bbox = sel.children[0]                  # 1st child object of Dial is the Bounding-Box
        # Needle (Pointer)
        needle = sel.children[1].children[0]    # 2nd child object (gauge)'s 1st child object is the Needle

        # for each frame . . .
        for i in range(endFrame-startFrame+1):

            # DIAL & FRAME INFORMATION _-_-_-_-_-_-_-_-

            frame = i + startFrame      # get frame index
            scene.frame_set(frame)      # go to that frame

            # Write Selected Object Number & Frame Index to CSV file
            f.write( "%i, %i, " % (sel_obj_ind, frame) )


            # NEEDLE (POINTER) ROTATION _-_-_-_-_-_-_-_-

            rot = needle.rotation_euler # get rotation of needle in selected object

            # Write Rotation to CSV file 
            f.write( "%f, %f, %f" % (degrees(rot.x), degrees(rot.y), degrees(rot.z)) )


            # BOUNDING-BOX VERTICES' COORDINATES FROM CAMERA POV _-_-_-_-_-_-_-_-

            # Get vertices & transform them to the correct position by their rotation & translation (matrix_world)
            verts = ((bbox.matrix_world @ vert.co) for vert in bbox.data.vertices)
            # Get camera-plane coordinates
            coords_2d = [world_to_camera_view(scene, cam, coord) for coord in verts]

            # Write Vertices to CSV file _-_-_-_-_-
            # Order: 0 bottom left, 1 bottom right, 2 top left, 3 top right
            # # for each vertex . . .
            # for x, y, distance_to_lens in coords_2d:
            #     # Append the vertex to the end of the csv line (round the pixel positions)
            #     f.write( ", %f, %f" % (round(render_size[0]*x), round(render_size[1]*y)) )

            # Format Bounding Box for MATLAB
            # [x, y, width, height], where (x,y) is the top left corner and (width,height) are the distances to the bottom right corner
            frame_height_y = round(render_size[1])                  # total height of frame
            top_left_x = round(render_size[0]*coords_2d[2][0])      # x (top left)
            top_left_y = round(render_size[1]*coords_2d[2][1])      # y (top left)
            top_left_y = frame_height_y - top_left_y                # CORRECTED y (top left) <(0,0) at the top left of frame>
            bottom_right_x = round(render_size[0]*coords_2d[1][0])  # x (bottom right)
            bottom_right_y = round(render_size[1]*coords_2d[1][1])  # y (bottom right)
            bottom_right_y = frame_height_y - bottom_right_y        # CORRECTED y (bottom right) <(0,0) at the top left of frame>
            bbox_width_x =  bottom_right_x - top_left_x             # width
            bbox_height_y = bottom_right_y - top_left_y             # height

            f.write( ", %f, %f" % (top_left_x, top_left_y) )
            f.write( ", %f, %f" % (bbox_width_x, bbox_height_y) )

            f.write("\n")

    # Close the CSV file
    f.close()
    # Go back to the frame the user was on before the code started
    scene.frame_set(currentFrame)

    return {'FINISHED'}


# ExportHelper is a helper class, defines filename and
# invoke() function which calls the file selector.
from bpy_extras.io_utils import ExportHelper
from bpy.props import StringProperty, BoolProperty, EnumProperty
from bpy.types import Operator


class ExportTransformToCsvBbox(Operator, ExportHelper):
    bl_idname = "export.transform_to_csv_bbox"  # important since its how bpy.ops.import_test.some_data is constructed
    bl_label = "Export Selected Animation Bbox (.csv)"

    # ExportHelper mixin class uses this
    filename_ext = ".csv"

    filter_glob: StringProperty(
        default="*.csv",
        options={'HIDDEN'},
        maxlen=255,  # Max internal buffer length, longer would be clamped.
    )

    def execute(self, context):
        return write_some_data(context, self.filepath)


# Only needed if you want to add into a dynamic menu
def menu_func_export(self, context):
    self.layout.operator(ExportTransformToCsvBbox.bl_idname, text="Selected Animation Bbox (.csv)")


def register():
    bpy.utils.register_class(ExportTransformToCsvBbox)
    bpy.types.TOPBAR_MT_file_export.append(menu_func_export)


def unregister():
    bpy.utils.unregister_class(ExportTransformToCsvBbox)
    bpy.types.TOPBAR_MT_file_export.remove(menu_func_export)


if __name__ == "__main__":
    register()

    # test call
    #bpy.ops.export.transform_to_csv_bbox('INVOKE_DEFAULT')
