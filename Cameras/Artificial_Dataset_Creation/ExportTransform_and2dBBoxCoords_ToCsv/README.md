# Object Animation to CSV exporter - Blender (EDITED)
 Export the selected objects position and rotation to CSV over the active timeline in Blender (also the camera-plane bounding box pixel coordinates).

# Versions
## OLD
"ExportTransform_and2dBBoxCoords_ToCsv__OLD.py" exports the location & all bounding box vertices
### Notes
1.  Must name bounding box object "BoundBox_Object" in Blender
2.  Must name camera "Camera" in Blender
3.  File output format is: 
| Location: x, y, z | Rotation (°): x, y ,z | Bounding Box Vertex Pixel Coordinates: (x, y), (x, y), (x, y), (x, y), ... |
### Use
Install and select the object you wish to export.
Go to File > Export > Animation Export Bbox (OLD) (.csv) 

## Current
"ExportTransform_and2dBBoxCoords_ToCsv.py" works with multiple dials
### Notes
1.  Must name camera "Camera" in Blender
2.  File output fromat is: 
| Object # | Frame # | Needle Angles (°): x, y, z | Bound-Box: x, y, width, height |
### Use
Install and select the object you wish to export.
Go to File > Export > Animation Export Bbox (.csv) 
