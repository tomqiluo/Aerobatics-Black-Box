# Object Animation to CSV exporter - Blender (EDITED)
 Export the selected objects position and rotation to CSV over the active timeline in Blender (also the camera-plane bounding box pixel coordinates).

# Use
Install and select the object you wish to export.
Go to File > Export > Animation Export Bbox (.csv) 

# Notes
1.  Must name bounding box object "BoundBox_Object" in Blender
2.  Must name camera "Camera" in Blender
3.  File output fromat is: 
| Location: x, y, z | Rotation (°): x, y ,z | Bounding Box Vertex Pixel Coordinates: (x, y), (x, y), (x, y), (x, y), ... |
