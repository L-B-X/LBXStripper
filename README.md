# LBXStripper
Lua Reascript for Reaper to create custom channel strips

----------------------------
REQUIREMENTS:

A late version 5 - or Reaper 6 installation.

Julian Sader's Reascript API extension - you can get it from here: https://forum.cockos.com/showthread.php?t=212174

You should also install the latest SWS extension if you don't have that yet.  The latest SWS beta has a fix so the videoprocessor can be correctly handled in Stripper. 

----------------------------

IMPORTANT:  Currently - when used in a project - you must first save the project BEFORE trying to close Reaper.  Using the save dialog that pops up when you close Reaper may/will NOT save the Stripper data properly - and you may find you have to rebuild your strips when re-opening the project.  Just ensure the project is saved just before you try to close Reaper and all should be good.


Installation instructions:
Download both LBXCS_resources.zip and LBX Stripper.Lua files.  It seems best to download the RAW text format for the .lua file.  Some people report errors when downloading the file as it is.

Direct links to raw versions of main lua file and resource zip file:

https://raw.githubusercontent.com/L-B-X/LBXStripper/master/LBX%20Stripper.lua

https://github.com/L-B-X/LBXStripper/blob/master/LBXCS_resources.zip?raw=true

Create a folder in the reaper repository/Scripts folder called LBX
Within this folder unpack the LBXCS_resources zip file

Place the LBX Stripper.Lua file somewhere within the LBX folder

Open the LBX Stripper.Lua script in Reaper

If you get any errors opening the script - please try copying and pasting the code direct from Github into a new script in Reaper - as my last script (Chaos Engine) had some reports of the downloaded .lua file not working - even though the code was fine.  This may be a me not knowing how to use github thing (perhaps an encoding problem with the lua file on github).



Then...

Suss out how to use it until I have time to create more detailed instructions :)

This is a beta version.  More functionality will be added, things will change - I will try to keep all changes compatible with older versions - but in some cases this may not be possible - so bear in mind if you incorporate it into important projects.

Report any errors or ask any questions here:
http://forum.cockos.com/showthread.php?t=182233

You may get some indication on how things work in this video - but bear in mind this version was a very early alpha version - and things have changed somewhat since then.

https://www.youtube.com/watch?v=dFWRuXEQVDc&feature=youtu.be
