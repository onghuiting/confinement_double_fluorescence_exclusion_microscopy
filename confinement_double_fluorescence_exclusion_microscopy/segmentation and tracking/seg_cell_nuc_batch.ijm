

// This macro is for segmentation of nucleus, cell and cell body in batch.
//
// Written by hui ting, 24 July 2023.


pathname = getDirectory("Select your input folder");
list = getFileList(pathname);
total_files = list.length;

for (ifile = 0; ifile < total_files; ifile++) {

  if (endsWith(list[ifile], "rectangle_roi.tif")){

filename_roi = list[ifile];
filename_channel_mask = replace(list[ifile], "_rectangle_roi.tif", "_channel_mask.tif");
filename_out = replace(list[ifile], "_rectangle_roi.tif", "_");

//////////////////////////////////  Segment nucleus  /////////////////////////////////////////////

open(pathname+filename_roi);
rename(filename_roi);
run("Select None");
run("Duplicate...", "title=c3 duplicate channels=3");

run("Median...", "radius=2 stack");
run("Subtract Background...", "rolling=50 stack");
run("Z Project...", "projection=[Average Intensity]");
imageCalculator("Subtract create stack", "c3","AVG_c3");

run("Auto Threshold", "method=Intermodes white stack use_stack_histogram");

run("Analyze Particles...", "size=200-Infinity pixel show=Masks stack");
run("Invert LUT");

run("Options...", "iterations=5 count=1 black pad do=Close stack");

open(pathname+filename_channel_mask);
rename("channel mask");

selectWindow("Mask of Result of c3");
run("Restore Selection");
setBackgroundColor(0, 0, 0);
run("Clear", "stack");
run("Select None");
rename("nuc");


//////////////////////////////////  Segment cell using GFP channel  /////////////////////////////////////////////

selectWindow(filename_roi);
run("Duplicate...", "title=c2 duplicate channels=2");
run("Median...", "radius=2 stack");
run("Subtract Background...", "rolling=50 stack");
run("Z Project...", "projection=[Average Intensity]");
imageCalculator("Subtract create stack", "c2","AVG_c2");

run("Auto Threshold", "method=Huang2 white stack use_stack_histogram"); // with protrusion (8)
//run("Auto Threshold", "method=Huang white stack use_stack_histogram"); // without protrusion (19)
//run("Auto Threshold", "method=Triangle white stack use_stack_histogram"); // lower threshold (6)

run("Analyze Particles...", "size=100-Infinity pixel show=Masks stack");
run("Invert LUT");
rename("cell_GFP");


//////////////////////////////////  Final cell, nuc, cell body  /////////////////////////////////////////////


imageCalculator("OR create stack", "cell_GFP","nuc");
setThreshold(100, 65535);
run("Analyze Particles...", "size=350-Infinity pixel show=Masks stack");
run("Invert LUT");

run("Options...", "iterations=5 count=1 black pad do=Close stack");
run("Restore Selection");
setBackgroundColor(0, 0, 0);
run("Clear", "stack");
run("Select None");
rename("cell");

imageCalculator("Subtract create stack", "cell","nuc");
saveAs("Tiff", pathname+filename_out+"cell_body.tif");

selectWindow("cell");
saveAs("Tiff", pathname+filename_out+"cell.tif");

selectWindow("nuc");
saveAs("Tiff", pathname+filename_out+"nuc.tif");

run("Close All");

  }
}





