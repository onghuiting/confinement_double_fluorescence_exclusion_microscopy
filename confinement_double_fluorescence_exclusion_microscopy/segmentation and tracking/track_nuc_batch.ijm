

// This Fiji macro is for tracking nucleus masks in batch.
// This Fiji macro runs the Jython script (runTrackmate_mask_batch.py) using Jython.jar.
// The Jython script was adapted from (https://imagej.net/plugins/trackmate/scripting) and (https://forum.image.sc/t/label-image-detector-trackmate-v7/60047/5).
//
// Please put Jython.jar to C:\Fiji 2023\plugins\jars\ and restart Fiji.
// Please put runTrackmate_mask_batch.py into input folder.
//
// Please go to update sites and activate "Trackmate" and all components of "Trackmate". Restart Fiji.
//
// Written by hui ting, 4 July 2023.


///////////////////////////////////////////////////////////////////////////////////////////////////

// The parameters below are set for data with pixel_size = 0.2305798 micrometer per pixel and
// time interval between two frames = 7 minutes. Please edit if necessary.
max_frame_gap = "2";           // in frames (int)
linking_max_dist = "100.0";    // in pixels (float)
gap_closing_max_dist = "15.0"; // in pixels (float)
min_frames = "100";            // in frames (int)

parameters = max_frame_gap+" "+linking_max_dist+" "+gap_closing_max_dist+" "+min_frames;

///////////////////////////////////////////////////////////////////////////////////////////////////


pathname = getDirectory("Select your input folder");

list = getFileList(pathname);
total_files = list.length;

run("Set Measurements...", "min redirect=None decimal=4");

for (ifile = 0; ifile < total_files; ifile++) {

	if (endsWith(list[ifile], "_nuc.tif")){
	    	
    filename_cell = replace(list[ifile],"_nuc.tif","_cell.tif");	
    filename_cb = replace(list[ifile],"_nuc.tif","_cell_body.tif");
    filename_out = replace(list[ifile], "_nuc.tif", "_");	

open(pathname+list[ifile]);
rename(list[ifile]);
Stack.getDimensions(width, height, channels, slices, frames);
frames2 = maxOf(frames,slices);
Stack.setDimensions(channels, 1, frames2);

runMacro(pathname+"runTrackmate_mask_batch.py",parameters);
run("glasbey on dark");
saveAs("Tiff", pathname+filename_out+"nuc_label.tif");
selectWindow(list[ifile]);
close();

/////////////////////////    label cell and cell body    ////////////////////////////////////

roiManager("reset");
open(pathname+filename_cell);
rename("cell_mask");
setThreshold(100, 255);
run("Analyze Particles...", "size=0-Infinity pixel clear add stack");

selectWindow(filename_out+"nuc_label.tif");
run("Duplicate...", "title=nuc_label duplicate");
roiManager("Show None");
roiManager("Measure");

nuc_L = Table.getColumn("Max");

selectWindow("cell_mask");
roiManager("Show None");
total_rois = roiManager("count");

for (c_roi = 0; c_roi < total_rois; c_roi++) {

roiManager("Select", c_roi);
setColor(nuc_L[c_roi]);
run("Fill", "slice");

}

run("glasbey on dark");
run("Select None");

imageCalculator("Subtract create stack", "cell_mask","nuc_label");
saveAs("Tiff", pathname+filename_out+"cell_body_label.tif");

selectWindow("cell_mask");
saveAs("Tiff", pathname+filename_out+"cell_label.tif");

run("Close All");
run("Clear Results");
roiManager("reset");

	}
	
}








