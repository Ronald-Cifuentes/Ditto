<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title>Ditto clipboard extender</title>
<meta name="keywords" content="" />
<meta name="description" content="" />
<link href="default.css" rel="stylesheet" type="text/css" />
</head>

<body>
<?php $focusTab = "History"; ?>

<div id="wrapper">
    <div id="logo">
        <h1><a href="index.php">Ditto</a></h1>
        <h2><a href="https://sourceforge.net/projects/ditto-cp/files/Ditto/3.18.24.0/DittoSetup_3_18_24_0.exe/download"> &raquo;&nbsp;&nbsp;&nbsp;Clipboard Manager &raquo; 3.18.24.0</a></h2>
    </div>
    <div id="header">
        <div id="menu">
            <ul>
                <li class="<?php echo $focusTab === 'Index' ? 'current_page_item' : ''; ?>"><a href="index.php">Homepage</a></li>
                <li class="<?php echo $focusTab === 'Translate' ? 'current_page_item' : ''; ?>"><a href="http://sourceforge.net/apps/trac/ditto-cp/wiki/Translate">Translate</a></li>
                <li class="<?php echo $focusTab === 'Themes' ? 'current_page_item' : ''; ?>"><a href="http://sourceforge.net/apps/trac/ditto-cp/wiki/Current%20Themes">Themes</a></li>
                <li><a href="http://sourceforge.net/apps/trac/ditto-cp/wiki">Wiki</a></li>
                <li><a href="http://ditto-cp.sourceforge.net/Help">Help</a></li>
                <li class="<?php echo $focusTab === 'History' ? 'current_page_item' : ''; ?>"><a href="#changeHistory">Change History</a></li>
                <li class="last"><a href="http://sourceforge.net/forum/?group_id=84084">Forums</a></li>
                <li class="last"><b><a href="http://sourceforge.net/project/project_donations.php?group_id=84084">Donate</a></b></li>
            </ul>
        </div>
    </div>
</div>

<div id="page">
    <div id="content">
        <h1 class="title" id="changeHistory">Change History</h1>
        <div class="post">
            <h1 class="title">3.18.24.0 1-3-12</h1>
            <div class="entry">
                <ul>
                    <li>Fixed issue with pasting last 10 pastes through global shortcut keys</li>
                    <li>Fixed issue with chinese language files</li>
                    <li>Take the windows task bar into account when ensuring entire Ditto window is visible</li>
                    <li>Show correct shortcut key text in [Options - Keyboard Shortcuts] when Win is checked</li>
                </ul>
            </div>
            <div class="meta">
                <p class="byline"><a href="changeHistory.php" class="more">Full Change History</a></p>
            </div>
        </div>

        <div class="post">
            <h1 class="title">3.18.20.0 12-23-11</h1>
            <div class="entry">
                <ul>
                    <li>64bit build</li>
                    <li>Clip shortcut keys can be global (you don't need to open ditto for your clip shortcut keys to work). New check box on the clip properties window.</li>
                    <li>New shortcut key window (right click on icon - Global hot keys) so you can see what clips are available globally and was ditto able to register the shortcut key.</li>
                    <li>Updated icon</li>
                    <li>Removed draw rich text option (was finding this didn't work with office 2010 rtf text)</li>
                    <li>Fixed crash when viewing images through F3</li>
                    <li>Portable setting is now based off of the file "portable" not a setting in the config file</li>
                    <li>Backup the db when running an update script</li>
                    <li>Fixed crash when automatically closing ditto's window</li>
                    <li>Fixed issue with displaying chinease language</li>
                </ul>
            </div>
            <div class="meta">
                <p class="byline"><a href="changeHistory.php" class="more">Full Change History</a></p>
            </div>
        </div>

        <div class="post">
            <h1 class="title">3.17.00.17 12-23-10</h1>
            <div class="entry">
                <ul>
                    <li>Removed named paste, named paste items can be searched by entering /q text</li>
                    <li>Added add-in to set/remove read only flag on clip containing cf_hdrop items or just text of file names</li>
                    <li>Added add-in to remove all line feeds then paste the clip</li>
                    <li>Fixed issue with ditto taking focus back, happened when always on-top was selected</li>
                    <li>Reverted to previous method for setting the focus</li>
                    <li>Fixed issue where 'v' was pasted instead of the actual clip</li>
                    <li>Changed default method for tracking focus to polling</li>
                    <li>Sped up clip deletes, delete of the large clipboard data now happens in the background</li>
                    <li>Sped up filling of the list, only items in view are loaded</li>
                    <li>Save connected to the clipboard state to config settings</li>
                    <li>Search full cf_unicode clip data with /f in the search text ex) /f text</li>
                    <li>Include correct version of mfc and c++ runtime files</li>
                    <li>Removed auto update feature</li>
                </ul>
            </div>
            <div class="meta">
                <p class="byline"><a href="changeHistory.php" class="more">Full Change History</a></p>
            </div>
        </div>

        <div class="post">
            <h1 class="title">3.16.8.0 08-16-09</h1>
            <div class="entry">
                <ul>
                    <li>Added DittoUtil Addin, adds the ability to paste any clip type as text</li>
                    <li>Fixed SetFocus fix in ActivateTarget -- needed AttachThreadInput</li>
                    <li>Added the ability to create add-ins, called before an item is pasted</li>
                    <li>Fixed issue with getting the currently focused window when not using the hook dll</li>
                    <li>Updated italiano language file</li>
                    <li>Added option to paste from hot key, press multiple times to move the selection, release the modifer key (control, shift, alt) to paste</li>
                    <li>Fixed word wrap option to reload correctly</li>
                    <li>Fixed issues with loading cut copy buffer 3 correctly from config on restart</li>
                    <li>Check if key is up before sending key up command. This was causing problems if an app is listening to global key up commands</li>
                    <li>Updated to sqlite version 3.16.10</li>
                </ul>
            </div>
            <div class="meta">
                <p class="byline"><a href="changeHistory.php" class="more">Full Change History</a></p>
            </div>
        </div>

        <div class="post">
            <h1 class="title">3.16.5.0 03-23-08</h1>
            <div class="entry">
                <ul>
                    <li>Fixed SetFocus fix in ActivateTarget -- needed AttachThreadInput -- wait for window to gain focus</li>
                    <li>Added the ability to create add-ins, called before an item is pasted</li>
                    <li>Fixed issue with getting the currently focused window when not using the hook dll</li>
                    <li>Updated italiano language file</li>
                    <li>Added option to paste from hot key, press multiple times to move the selection, release the modifer key (control, shift, alt) to paste</li>
                    <li>Fixed word wrap option to reload correctly</li>
                    <li>Fixed issues with loading cut copy buffer 3 correctly from config on restart</li>
                    <li>Check if key is up before sending key up command. This was causing problems if an app is listening to global key up commands</li>
                    <li>Updated to sqlite version 3.16.10</li>
                </ul>
            </div>
            <div class="meta">
                <p class="byline"><a href="changeHistory.php" class="more">Full Change History</a></p>
            </div>
        </div>

        <div class="post">
            <h1 class="title">3.15.4.0 01-16-08</h1>
            <div class="entry">
                <ul>
                    <li>Fixed empty directory from being created in application data in stand alone version</li>
                    <li>Added themes (http://ditto-cp.wiki.sourceforge.net/Themes)</li>
                    <li>Updated to latest sqlite db version</li>
                    <li>When creating a new db auto vacuum is set. Or when doing a compact and repair.</li>
                </ul>
            </div>
            <div class="meta">
                <p class="byline"><a href="changeHistory.php" class="more">Full Change History</a></p>
            </div>
        </div>

    </div>

    <div id="sidebar">
        <h2><a href="https://sourceforge.net/projects/ditto-cp/files/Ditto/3.18.24.0/DittoSetup_3_18_24_0.exe/download">Download</a></h2>
        <ul>
            <li><a href="https://sourceforge.net/projects/ditto-cp/files/Ditto/3.18.24.0/DittoSetup_64bit_3_18_24_0.exe/download">Download 64bit</a></li>
            <li><a href="https://sourceforge.net/projects/ditto-cp/files/Ditto/3.18.24.0/DittoPortable_3_18_24_0.zip/download">Portable (zip file)</a></li>
            <li><a href="https://sourceforge.net/projects/ditto-cp/files/Ditto/3.18.24.0/DittoPortable_64bit_3_18_24_0.zip/download">Portable 64bit (zip file)</a></li>
            <li><a href="https://sourceforge.net/projects/ditto-cp/files/Ditto/3.18.24.0/DittoSource_3_18_24_0.zip/download">Source</a></li>
            <li><a href="https://sourceforge.net/project/screenshots.php?group_id=84084">Screenshot</a></li>
        </ul>

        <div>
            <img src="http://www2.clustrmaps.com/counter/index2.php?url=http://ditto-cp.sourceforge.net" style="border:0px;" alt="Locations of visitors to this page" title="Locations of visitors to this page" />
            <br /><br /><br /><br />
        </div>
    </div>
</div>

</body>
</html>
