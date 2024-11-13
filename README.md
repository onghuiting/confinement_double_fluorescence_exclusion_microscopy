# confinement_double_fluorescence_exclusion_microscopy
ImageJ macros and Matlab scripts implementing: double fluorescence exclusion microscopy for tracking nuclear morphological changes during confined migration.

If you use the macros and scripts, please cite the paper: 
Li, Yixuan, et al. "Confinement-Sensitive Volume Regulation Dynamics Via High-Speed Nuclear Morphological Measurements." PNAS.

For enquiries, please contact:  bieawh@nus.edu.sg, yli@u.nus.edu, mbioht@nus.edu.sg

# Part 1: correct intensity 

(1) get_background_profile_batch_4ch_2.ijm

(2) correct_intensity_batch_4chmask_2.ijm

(3) generate_height_map_stack_batch_4ch_2.ijm

# Part 2: segmentation and tracking

(1) seg_cell_nuc_batch.ijm

(2) track_nuc_batch.ijm

# Part 3: calibrate gfp and get nucleus volume

(1) main_nuc_volume_area.m
