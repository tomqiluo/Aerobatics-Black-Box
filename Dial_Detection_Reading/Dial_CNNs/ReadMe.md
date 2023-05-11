# Dial Convolutional Neural Networks

## Folder: Dial_Detection
This contains the code to train and test a CNN that finds the dials using a YOLOv2 object detector and transfer learning. The Blender CSV data and rendered frames can be combined with the read dataset gTruth to make a larger dataset.

## Folder: Dial_Reading
This contains the code to train and test the dial reader. It takes in image with bounding boxes and dial angles and cuts out the dials into their own images which it then uses with the needle angles to train a CNN. There is also code for modifying CNN architecture.

## Matlab Files: blender_CSV_Image_2_matlab_GroundTruth ...
these convert the CSV data exported from the Blender add-on and combine it with the rendered frames to create matlab groundTruth files. The most recent version is "blender_CSV_Image_2_matlab_GroundTruth_choice.m"