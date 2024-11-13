

# This script exports label maps of trackmate in batch.
# This Jython script was adapted from (https://imagej.net/plugins/trackmate/scripting) and (https://forum.image.sc/t/label-image-detector-trackmate-v7/60047/5)
#
# If error message pops up, comment line 139 and uncomment line 140.
#
# By hui ting, 27 June 2023.


import sys

from ij import IJ
from ij import WindowManager

from fiji.plugin.trackmate import Model
from fiji.plugin.trackmate import Settings
from fiji.plugin.trackmate import TrackMate
from fiji.plugin.trackmate import SelectionModel
from fiji.plugin.trackmate import Logger
from fiji.plugin.trackmate.detection import MaskDetectorFactory
from fiji.plugin.trackmate.tracking.jaqaman import SparseLAPTrackerFactory
from fiji.plugin.trackmate.gui.displaysettings import DisplaySettingsIO
from fiji.plugin.trackmate.action import AbstractTMAction
from fiji.plugin.trackmate.action import LabelImgExporter
import fiji.plugin.trackmate.visualization.hyperstack.HyperStackDisplayer as HyperStackDisplayer
import fiji.plugin.trackmate.features.FeatureFilter as FeatureFilter


# We have to do the following to avoid errors with UTF8 chars generated in 
# TrackMate that will mess with our Fiji Jython.
reload(sys)
sys.setdefaultencoding('utf-8')

# Get currently selected image
imp = WindowManager.getCurrentImage()
imp.show()

values = getArgument();
a = values.split();
max_frame_gap = int(a[0]);
linking_max_dist = float(a[1]);
gap_closing_max_dist = float(a[2]);
min_frames = int(a[3]);  


#----------------------------
# Create the model object now
#----------------------------

# Some of the parameters we configure below need to have
# a reference to the model at creation. So we create an
# empty model now.

model = Model()

# Send all messages to ImageJ log window.
model.setLogger(Logger.IJ_LOGGER)



#------------------------
# Prepare settings object
#------------------------

settings = Settings(imp)

# Configure detector - We use the Strings for the keys
settings.detectorFactory = MaskDetectorFactory()
settings.detectorSettings = {  
    'TARGET_CHANNEL' : 1,   
    'SIMPLIFY_CONTOURS' : True,
}  

# Configure spot filters - Classical filter on quality
#filter1 = FeatureFilter('QUALITY', -2000, True)
#settings.addSpotFilter(filter1)

#settings.addAllAnalyzers()

#filter2 = FeatureFilter('MEAN_INTENSITY_CH1', 500, True)
#settings.addSpotFilter(filter2)

# Configure tracker - We do not want to allow merges and fusions
settings.trackerFactory = SparseLAPTrackerFactory()
settings.trackerSettings = settings.trackerFactory.getDefaultSettings()
settings.trackerSettings['ALLOW_TRACK_SPLITTING'] = False
settings.trackerSettings['ALLOW_TRACK_MERGING'] = False
settings.trackerSettings['MAX_FRAME_GAP']  =  max_frame_gap                    # in frames
settings.trackerSettings['LINKING_MAX_DISTANCE']  = linking_max_dist           # in pixels
settings.trackerSettings['GAP_CLOSING_MAX_DISTANCE']  = gap_closing_max_dist   # in pixels


# Add ALL the feature analyzers known to TrackMate. They will 
# yield numerical features for the results, such as speed, mean intensity etc.
settings.addAllAnalyzers()

# Configure track filters - We want to get rid of spots that appear for less than
# 100 frames
filter2 = FeatureFilter('NUMBER_SPOTS', min_frames, True)              # in frames
settings.addTrackFilter(filter2)


#-------------------
# Instantiate plugin
#-------------------

trackmate = TrackMate(model, settings)

#--------
# Process
#--------

ok = trackmate.checkInput()
if not ok:
    sys.exit(str(trackmate.getErrorMessage()))

ok = trackmate.process()
if not ok:
    sys.exit(str(trackmate.getErrorMessage()))


#----------------
# Display results
#----------------

# A selection.
selectionModel = SelectionModel( model )

# Read the default display settings.
ds = DisplaySettingsIO.readUserDefault()

displayer =  HyperStackDisplayer( model, selectionModel, imp, ds )
displayer.render()
displayer.refresh()

exportSpotsAsDots = False
exportTracksOnly = True
lblImg = LabelImgExporter.createLabelImagePlus( trackmate, exportSpotsAsDots, exportTracksOnly, False )
# lblImg = LabelImgExporter.createLabelImagePlus( trackmate, exportSpotsAsDots, exportTracksOnly )
lblImg.show()

# Echo results with the logger we set at start:
# model.getLogger().log(str( model ) )



