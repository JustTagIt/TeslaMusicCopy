#Copyright 2015, Josh Mackey


# $PSScriptRoot is a variable holding the same directory as the script.
$dryrun = $false # If set to $true, will output normally but not actually copy/convert files.
$destinationRoot = $PSScriptRoot # Set to where you want the songs to be copied to.
$iTunesMusicLibrary = $env:USERPROFILE + '\Music\iTunes\iTunes Music Library.xml' # path to iTunes's Music Library file.
$ffmpeg = $PSScriptRoot + 'ffmpeg' # Path to ffmpeg so lossless can be converted to FLAC.


<# Do not modify below this line #>

Function CopySong($filePath, $destination, $isLossless)
{   
    If ($dryrun -eq $false) 
    {
        New-Item -ItemType Directory -Path $destination -Force > $null
    }

    If ($isLossless)
    {
    
        $toPath = $destination + $separator + [System.IO.Path]::GetFileNameWithoutExtension($filePath) + ".flac" 
        $tempFile = [System.IO.Path]::GetTempFileName() + ".flac"
        if (Test-Path -LiteralPath $toPath) 
        {
            Write-Host "     Exists, skipping $toPath"
        }
        else
        {
            Write-Host "     Converting $toPath"
            If ($dryrun -eq $false) 
            {
                & $ffmpeg -hide_banner -i $filePath $tempFile 2> $null
                Copy-Item -LiteralPath  $tempFile -Destination $toPath
                Remove-Item $tempFile
            }
        }
    } 
    else
    {
        $toPath = $toDirectory + [System.IO.Path]::DirectorySeparatorChar + [System.IO.Path]::GetFileName($filePath)
        if (Test-Path -LiteralPath $toPath) 
        {
            Write-Host "     Exists, skipping $toPath"
        }
        else
        {
            Write-Host "     Copying $toPath"
            If ($dryrun -eq $false) 
            {
                Copy-Item -LiteralPath  $filePath -Destination $toPath -Force
            }
        }
    }
    return $toPath
}

$separator = [System.IO.Path]::DirectorySeparatorChar
$libraryXml = [xml](Get-Content $iTunesMusicLibrary)
$libraryPath = [System.Uri]::UnescapeDataString($libraryXml.plist.dict.ChildNodes[$libraryXml.plist.dict.key.IndexOf('Music Folder') * 2 + 1].InnerText)
$libraryPath = $libraryPath.Substring("file://localhost/".Length)
$playlists = $libraryXml.plist.dict.ChildNodes[$libraryXml.plist.dict.key.IndexOf('Playlists') * 2 + 1]
$tracksXml = $libraryXml.plist.dict.ChildNodes[$libraryXml.plist.dict.key.IndexOf('Tracks') * 2 + 1]
$tracks = @{}

$count = 0;
$totalCount = $tracksXml.dict.Count;

foreach ($song in $tracksXml.dict)
{   
    $count++
    $id = $song.ChildNodes[$song.key.IndexOf('Track ID') * 2 + 1].InnerText    
    $type = $song.ChildNodes[$song.key.IndexOf('Kind') * 2 + 1].InnerText
    $path = [System.Uri]::UnescapeDataString($song.ChildNodes[$song.key.IndexOf('Location') * 2 + 1].InnerText)
    $path = $path.Substring("file://localhost/".Length)

    Write-Host "Processing $count of $totalCount"

    $toDirectory = $destinationRoot + [System.IO.Path]::GetDirectoryName($path.Substring($libraryPath.length + "Music".length + 1))
    $newPath = CopySong $path $toDirectory ($type -eq "Apple Lossless audio file")

    $tracks.Add($id, @{ path = $path; newPath = $newPath; isLossless = ($type -eq "Apple Lossless audio file")})
}

Write-Host "Copying Playlists..."
$playlistRoot = $destinationRoot + "Playlists" + $separator

Write-Host "Clearing old playlists..."
if ($dryrun -eq $false) 
{
    gci $playlistRoot | Remove-Item -Recurse
}

foreach ($playlist in $playlists.dict)
{
    if ($playlist.key.Contains("Distinguished Kind") -eq $false -and $playlist.key.Contains("Master") -eq $false)
    {
        $name = $playlist.ChildNodes[$playlist.key.IndexOf('Name') * 2 + 1].InnerText        
        $toDirectory = $playlistRoot + $name
        foreach ($song in $playlist.array.dict)
        {
            $toPath = $toDirectory + $separator + [System.IO.Path]::GetFileName($tracks[$song.LastChild.InnerText].path)
            Write-Host "     Copying $toPath"
            If ($dryrun -eq $false) 
            {
                New-Item -ItemType Directory -Path $toDirectory -Force > $null                
                Copy-Item -LiteralPath  $tracks[$song.LastChild.InnerText].newPath -Destination $toPath -Force
            }            
        }
    }
}
