# TeslaMusicCopy
Copies and converts an iTunes library to a flash drive.

## Instructions
If this is your first time running a powershell script, please change your `ExecutionPolicy` to `Unrestricted` by running the following: `Set-ExecutionPolicy RemoteSigned`

See https://technet.microsoft.com/en-us/library/ee176961.aspx for more details.

Before running, please update the variables at the top of the script for your own usage.
````
# $PSScriptRoot is a variable holding the same directory as the script.
$dryrun = $true # If set to $true, will output normally but not actually copy/convert files.
$destinationRoot = $PSScriptRoot # Set to where you want the songs to be copied to.
$iTunesMusicLibrary = $env:USERPROFILE + '\Music\iTunes\iTunes Music Library.xml' # path to iTunes's Music Library file.
$ffmpeg = $PSScriptRoot + 'ffmpeg' # Path to ffmpeg so lossless can be converted to FLAC.
````

If you copy the script and ffmpeg to a flash drive, you only need to update the $iTunesMusicLibrary if its not in the default location.
