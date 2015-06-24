# downloadProgress
Download Progress - ios Interview

A sample app to download a list of files and download them optionally while showing their progress:

●	The app will only contain one screen.
●	Its right nav button bar will be “Refresh”, which when clicked will use this endpoint to retrieve the file list, which contains urls for the files and their names.

http://sidechats.appspot.com/codingtest/files/

●	The above response will be a JSON array, which each entry containing:
○	An unique identifier for the link.
○	The name of the file
○	The URL from which it can be downloaded (and may be other data).
○	Note: This endpoint may not always return the same results each time.
●	Display these items in a table
●	Each cell in the table view must contain:
○	The name of the file
○	The size of the the file if it is available locally
○	The progress of the download as the file is being downloaded.
○	If the file is NOT available locally, then do not show the size but instead show a size indicating whether the download is (active, paused, queued or black if none of these).
●	When the cell is clicked present the following options to the user:
○	Download/Resume - Clicking on this will download the file if it is not currently downloading (or paused).  If the file is already downloading then the download should be paused.   You may decide how and where you store the file locally (please explain your choices).   Note that the actual text here will depend on whether the download is currently happening or not (ie if the download is active, this will be “Download”, otherwise if download is queued or paused, it will be “Resume”).
○	Delete - Should delete the file locally (whether it has been downloaded or is in the middle of a download).
○	Cancel - Cancel this alert presented to the user.
●	The left button bar should be a “Sort” button - which will sort the files in the table either by the amount downloaded, file size or the file name (it will toggle between each of the three views - think of a way to show the “current ordering key” somehow.)

Considerations:
●	The downloads should be resumable when paused or even if the app has been killed and restarted.  You will need to store the current progress somewhere locally.
●	Multiple downloads can be happening at the same time (ie user clicked on each cell one at a time and selected download).
●	No more than 10 downloads should be happening at the same time.  The only way another download can start is when another download has been paused or if there less then 10 current downloads happening.  Make this a variable so we can alter this at compile time.
●	The user should be able to pause a download by selecting a cell.  If a download is paused the progress should be saved, and the next file in the list should begin to download.
●	If a download has been paused it should NOT be automatically started unless the user resumes it again.
