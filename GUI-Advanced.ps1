# ============================================================
#  Advanced ExifTool GUI Manager - FORENSICS EDITION v3.1
#  (c) JM Production - BlueTeam / OSINT / Criminology
#  Modern UI Redesign + PowerShell 5.1 Compatible
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Web

# ---------------- Modern Color Palette ----------------
$C_BG       = [System.Drawing.Color]::FromArgb(15, 17, 23)
$C_PANEL    = [System.Drawing.Color]::FromArgb(24, 27, 34)
$C_CARD     = [System.Drawing.Color]::FromArgb(31, 35, 44)
$C_INPUT    = [System.Drawing.Color]::FromArgb(18, 21, 27)
$C_BORDER   = [System.Drawing.Color]::FromArgb(45, 50, 62)
$C_FG       = [System.Drawing.Color]::FromArgb(228, 230, 235)
$C_MUTED    = [System.Drawing.Color]::FromArgb(139, 146, 160)
$C_ACCENT   = [System.Drawing.Color]::FromArgb(0, 217, 163)
$C_BLUE     = [System.Drawing.Color]::FromArgb(59, 130, 246)
$C_RED      = [System.Drawing.Color]::FromArgb(239, 68, 68)
$C_GREEN    = [System.Drawing.Color]::FromArgb(34, 197, 94)
$C_ORANGE   = [System.Drawing.Color]::FromArgb(245, 158, 11)
$C_PURPLE   = [System.Drawing.Color]::FromArgb(168, 85, 247)
$C_GRAY     = [System.Drawing.Color]::FromArgb(71, 85, 105)

# ---------------- ExifTool Path Check ----------------
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$exifToolPath = Join-Path $scriptDir "exiftool.exe"

if (-not (Test-Path -LiteralPath $exifToolPath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "exiftool.exe could not be found!`n`nPlace exiftool.exe and this script in the same folder.",
        "Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# ---------------- Safe Font Resolver ----------------
function Get-SafeFont($preferred, $fallback, $size, $style) {
    try {
        return (New-Object System.Drawing.Font($preferred, $size, $style))
    } catch {
        return (New-Object System.Drawing.Font($fallback, $size, $style))
    }
}

$FONT_UI      = "Segoe UI"
$FONT_UI_SEMI = "Segoe UI Semibold"
$FONT_MONO    = "Consolas"

# ============================================================
#  Helper Factory Functions
# ============================================================
function Get-LightenedColor($c, $amount = 30) {
    return [System.Drawing.Color]::FromArgb(
        [Math]::Min(255, [int]$c.R + $amount),
        [Math]::Min(255, [int]$c.G + $amount),
        [Math]::Min(255, [int]$c.B + $amount))
}
function Get-DarkenedColor($c, $amount = 30) {
    return [System.Drawing.Color]::FromArgb(
        [Math]::Max(0, [int]$c.R - $amount),
        [Math]::Max(0, [int]$c.G - $amount),
        [Math]::Max(0, [int]$c.B - $amount))
}

function New-Btn($text, $x, $y, $w, $h, $color) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.Size = New-Object System.Drawing.Size($w, $h)
    $b.Font = Get-SafeFont $FONT_UI_SEMI $FONT_UI 9 ([System.Drawing.FontStyle]::Bold)
    $b.BackColor = $color
    $b.ForeColor = [System.Drawing.Color]::White
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 0
    $b.FlatAppearance.MouseOverBackColor = (Get-LightenedColor $color 25)
    $b.FlatAppearance.MouseDownBackColor  = (Get-DarkenedColor  $color 20)
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.UseVisualStyleBackColor = $false

    try {
        $r = 6
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $r, $r, 180, 90)
        $path.AddArc($w - $r - 1, 0, $r, $r, 270, 90)
        $path.AddArc($w - $r - 1, $h - $r - 1, $r, $r, 0, 90)
        $path.AddArc(0, $h - $r - 1, $r, $r, 90, 90)
        $path.CloseAllFigures()
        $b.Region = New-Object System.Drawing.Region($path)
    } catch { }

    return $b
}

function New-Lbl($text, $x, $y, $w, $h, $bold = $false, $size = 9) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Location = New-Object System.Drawing.Point($x, $y)
    $l.Size = New-Object System.Drawing.Size($w, $h)
    $l.ForeColor = if ($bold) { $C_FG } else { $C_MUTED }
    $l.BackColor = [System.Drawing.Color]::Transparent
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $l.Font = Get-SafeFont $FONT_UI $FONT_UI $size $style
    return $l
}

function New-SectionHeader($text, $x, $y, $w) {
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point($x, $y)
    $p.Size = New-Object System.Drawing.Size($w, 26)
    $p.BackColor = [System.Drawing.Color]::Transparent

    $bar = New-Object System.Windows.Forms.Panel
    $bar.Location = New-Object System.Drawing.Point(0, 5)
    $bar.Size = New-Object System.Drawing.Size(4, 17)
    $bar.BackColor = $C_ACCENT
    $p.Controls.Add($bar)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $text
    $lbl.Location = New-Object System.Drawing.Point(13, 3)
    $lbl.Size = New-Object System.Drawing.Size(($w - 16), 22)
    $lbl.ForeColor = $C_FG
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $lbl.Font = Get-SafeFont $FONT_UI_SEMI $FONT_UI 10 ([System.Drawing.FontStyle]::Bold)
    $p.Controls.Add($lbl)

    return $p
}

function New-DarkTb($x, $y, $w, $h, $multiline = $false) {
    $t = New-Object System.Windows.Forms.TextBox
    $t.Location = New-Object System.Drawing.Point($x, $y)
    $t.Size = New-Object System.Drawing.Size($w, $h)
    $t.BackColor = $C_INPUT
    $t.ForeColor = $C_ACCENT
    $t.BorderStyle = "FixedSingle"
    $t.Font = Get-SafeFont $FONT_MONO $FONT_MONO 9.5 ([System.Drawing.FontStyle]::Regular)
    $t.Multiline = $multiline
    if ($multiline) {
        $t.ScrollBars = "Both"
        $t.WordWrap = $false
        $t.ReadOnly = $true
    }
    return $t
}

# ============================================================
#  Main Form
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Advanced ExifTool GUI - Forensics Edition v3.1"
$form.Size = New-Object System.Drawing.Size(1280, 840)
$form.StartPosition = "CenterScreen"
$form.BackColor = $C_BG
$form.ForeColor = $C_FG
$form.MinimumSize = New-Object System.Drawing.Size(1100, 750)
$form.Font = Get-SafeFont $FONT_UI $FONT_UI 9 ([System.Drawing.FontStyle]::Regular)

# ---------------- Status Bar ----------------
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusStrip.BackColor = $C_PANEL
$statusStrip.SizingGrip = $false
$lblStatus = New-Object System.Windows.Forms.ToolStripStatusLabel
$lblStatus.Text = "  *  Ready."
$lblStatus.ForeColor = $C_ACCENT
$lblStatus.Font = Get-SafeFont $FONT_UI_SEMI $FONT_UI 9 ([System.Drawing.FontStyle]::Bold)
[void]$statusStrip.Items.Add($lblStatus)
$form.Controls.Add($statusStrip)

# ---------------- Tabs ----------------
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(8, 8)
$tabs.Size = New-Object System.Drawing.Size(1250, 770)
$tabs.Font = Get-SafeFont $FONT_UI_SEMI $FONT_UI 9 ([System.Drawing.FontStyle]::Bold)
$tabs.DrawMode = "OwnerDrawFixed"
$tabs.SizeMode = "Fixed"
$tabs.ItemSize = New-Object System.Drawing.Size(140, 36)
$tabs.Padding = New-Object System.Drawing.Point(12, 6)
$tabs.Add_DrawItem({
    param($s, $e)
    if ($e.Index -lt 0) { return }
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $tab = $s.TabPages[$e.Index]
    $isSel = ($s.SelectedIndex -eq $e.Index)
    $bgColor = if ($isSel) { $C_BG } else { $C_PANEL }
    $fgColor = if ($isSel) { $C_ACCENT } else { $C_MUTED }

    $brushBg = New-Object System.Drawing.SolidBrush($bgColor)
    $g.FillRectangle($brushBg, $e.Bounds)

    $brushFg = New-Object System.Drawing.SolidBrush($fgColor)
    $font    = Get-SafeFont $FONT_UI_SEMI $FONT_UI 9.5 ([System.Drawing.FontStyle]::Bold)
    $sf      = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $rectF = New-Object System.Drawing.RectangleF(
        [float]$e.Bounds.X, [float]$e.Bounds.Y,
        [float]$e.Bounds.Width, [float]$e.Bounds.Height)

    $g.DrawString($tab.Text, $font, $brushFg, $rectF, $sf)

    if ($isSel) {
        $accentBrush = New-Object System.Drawing.SolidBrush($C_ACCENT)
        $g.FillRectangle($accentBrush, $e.Bounds.X + 24, $e.Bounds.Bottom - 3, $e.Bounds.Width - 48, 2)
        $accentBrush.Dispose()
    }

    $brushBg.Dispose()
    $brushFg.Dispose()
    $font.Dispose()
    $sf.Dispose()
})

$tabView     = New-Object System.Windows.Forms.TabPage; $tabView.Text     = "  Viewer  "
$tabEdit     = New-Object System.Windows.Forms.TabPage; $tabEdit.Text     = "  Edit  "
$tabAnalysis = New-Object System.Windows.Forms.TabPage; $tabAnalysis.Text = "  Analysis  "
$tabBulk     = New-Object System.Windows.Forms.TabPage; $tabBulk.Text     = "  Bulk Ops  "
$tabReport   = New-Object System.Windows.Forms.TabPage; $tabReport.Text   = "  Reports  "
$tabCase     = New-Object System.Windows.Forms.TabPage; $tabCase.Text     = "  Case  "

foreach ($t in @($tabView, $tabEdit, $tabAnalysis, $tabBulk, $tabReport, $tabCase)) {
    $t.BackColor = $C_BG
    $t.ForeColor = $C_FG
    [void]$tabs.Controls.Add($t)
}
$form.Controls.Add($tabs)

# ============================================================
#  TAB 1 : Viewer
# ============================================================
$tabView.Controls.Add((New-SectionHeader "File Queue" 10 8 400))

$txtFilter = New-Object System.Windows.Forms.TextBox
$txtFilter.Location = New-Object System.Drawing.Point(310, 12)
$txtFilter.Size = New-Object System.Drawing.Size(120, 24)
$txtFilter.BackColor = $C_INPUT
$txtFilter.ForeColor = $C_ACCENT
$txtFilter.BorderStyle = "FixedSingle"
$txtFilter.Font = Get-SafeFont $FONT_UI $FONT_UI 9 ([System.Drawing.FontStyle]::Regular)
$tabView.Controls.Add($txtFilter)
$tabView.Controls.Add((New-Lbl "[search]" 435 15 60 20 $false 8))

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 44)
$listBox.Size = New-Object System.Drawing.Size(400, 546)
$listBox.AllowDrop = $true
$listBox.Font = Get-SafeFont $FONT_UI $FONT_UI 9 ([System.Drawing.FontStyle]::Regular)
$listBox.BackColor = $C_INPUT
$listBox.ForeColor = $C_FG
$listBox.BorderStyle = "FixedSingle"
$listBox.SelectionMode = "MultiExtended"
$listBox.HorizontalScrollbar = $true
$listBox.IntegralHeight = $false
$tabView.Controls.Add($listBox)

$tabView.Controls.Add((New-SectionHeader "Preview" 425 8 240))
$tabView.Controls.Add((New-SectionHeader "File Info" 675 8 555))

$picPreview = New-Object System.Windows.Forms.PictureBox
$picPreview.Location = New-Object System.Drawing.Point(425, 40)
$picPreview.Size = New-Object System.Drawing.Size(240, 235)
$picPreview.BackColor = $C_INPUT
$picPreview.SizeMode = "Zoom"
$picPreview.BorderStyle = "FixedSingle"
$tabView.Controls.Add($picPreview)

$txtQuick = New-DarkTb 675 40 555 235 $true
$tabView.Controls.Add($txtQuick)

$tabView.Controls.Add((New-SectionHeader "Metadata Output" 425 285 805))

$txtOutput = New-DarkTb 425 315 805 275 $true
$tabView.Controls.Add($txtOutput)

$listBox.Add_DragEnter({
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
})
$listBox.Add_DragDrop({
    $files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    foreach ($p in $files) {
        if (Test-Path -LiteralPath $p -PathType Container) {
            Get-ChildItem -LiteralPath $p -Recurse -File |
                Select-Object -ExpandProperty FullName |
                ForEach-Object {
                    if ($listBox.Items -notcontains $_) { [void]$listBox.Items.Add($_) }
                }
        }
        else {
            if ($listBox.Items -notcontains $p) { [void]$listBox.Items.Add($p) }
        }
    }
    $lblStatus.Text = "  *  Loaded $($listBox.Items.Count) file(s)."
})

function Show-Preview($f) {
    try {
        if ($picPreview.Image) { $picPreview.Image.Dispose() }
        $img = [System.Drawing.Image]::FromFile($f)
        $picPreview.Image = $img
    }
    catch {
        if ($picPreview.Image) { $picPreview.Image.Dispose() }
        $picPreview.Image = $null
    }
    $fi = Get-Item -LiteralPath $f
    $txtQuick.Clear()
    $txtQuick.AppendText("PATH     : $f`r`n")
    $txtQuick.AppendText("SIZE     : $($fi.Length) bytes`r`n")
    $txtQuick.AppendText("CREATED  : $($fi.CreationTime)`r`n")
    $txtQuick.AppendText("MODIFIED : $($fi.LastWriteTime)`r`n")
    $txtQuick.AppendText("ACCESSED : $($fi.LastAccessTime)`r`n")
    $txtQuick.AppendText("EXT      : $($fi.Extension)`r`n")
    try {
        $md5 = (Get-FileHash -LiteralPath $f -Algorithm MD5).Hash
        $txtQuick.AppendText("MD5      : $md5`r`n")
    }
    catch {}
}

$listBox.Add_SelectedIndexChanged({
    if ($listBox.SelectedItem) {
        Show-Preview $listBox.SelectedItem
        $lblStatus.Text = "  *  Selected: $(Split-Path $listBox.SelectedItem -Leaf)"
    }
})

$btnViewMeta = New-Btn "View Metadata" 425 600 165 38 $C_BLUE
$btnViewMeta.Add_Click({
    if ($listBox.SelectedItem) {
        $out = & $exifToolPath -- "$($listBox.SelectedItem)"
        $txtOutput.Text = ($out -join "`r`n")
        $lblStatus.Text = "  *  Metadata loaded."
    }
})
$tabView.Controls.Add($btnViewMeta)

$btnRefreshQ = New-Btn "Refresh" 600 600 120 38 $C_GRAY
$btnRefreshQ.Add_Click({
    if ($listBox.SelectedItem) { Show-Preview $listBox.SelectedItem }
})
$tabView.Controls.Add($btnRefreshQ)

$btnRemoveAll = New-Btn "Strip All Metadata" 730 600 165 38 $C_RED
$btnRemoveAll.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $c = [System.Windows.Forms.MessageBox]::Show(
        "Strip ALL metadata from $($listBox.Items.Count) file(s)?", "Confirm",
        [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($c -eq [System.Windows.Forms.DialogResult]::Yes) {
        foreach ($f in $listBox.Items) {
            & $exifToolPath '-all=' -overwrite_original -- "$f" | Out-Null
        }
        $lblStatus.Text = "  *  Metadata stripped from all files."
    }
})
$tabView.Controls.Add($btnRemoveAll)

$btnClear = New-Btn "Clear List" 905 600 150 38 $C_GRAY
$btnClear.Add_Click({
    $listBox.Items.Clear()
    $txtOutput.Clear()
    $txtQuick.Clear()
    if ($picPreview.Image) { $picPreview.Image.Dispose(); $picPreview.Image = $null }
})
$tabView.Controls.Add($btnClear)

$btnOpenFolder = New-Btn "Open Folder" 1065 600 165 38 $C_PURPLE
$btnOpenFolder.Add_Click({
    if ($listBox.SelectedItem) {
        Start-Process explorer.exe "/select,`"$($listBox.SelectedItem)`""
    }
})
$tabView.Controls.Add($btnOpenFolder)

# ============================================================
#  TAB 2 : Edit Metadata
# ============================================================
$tabEdit.Controls.Add((New-SectionHeader "Metadata Editor - select a file in Viewer first" 10 8 900))

$fields = @(
    "Artist", "Copyright", "XPAuthor", "XPTitle",
    "XPSubject", "XPComment", "XPKeywords",
    "ImageDescription", "UserComment", "Software",
    "Make", "Model", "LensModel",
    "DateTimeOriginal", "CreateDate", "ModifyDate",
    "Rating", "Orientation",
    "GPSLatitude", "GPSLongitude", "GPSAltitude"
)

$inputBoxes = @{}
$y = 46
$col = 0
foreach ($tag in $fields) {
    $x = if ($col -eq 0) { 20 } else { 620 }
    $tabEdit.Controls.Add((New-Lbl "$tag" $x $y 190 20))

    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Location = New-Object System.Drawing.Point(($x + 200), $y)
    $tb.Size = New-Object System.Drawing.Size(340, 24)
    $tb.BackColor = $C_INPUT
    $tb.ForeColor = $C_ACCENT
    $tb.BorderStyle = "FixedSingle"
    $tb.Font = Get-SafeFont $FONT_UI $FONT_UI 9 ([System.Drawing.FontStyle]::Regular)
    $tabEdit.Controls.Add($tb)

    $inputBoxes[$tag] = $tb

    if ($col -eq 1) { $y += 30; $col = 0 } else { $col = 1 }
}

$btnLoadCur = New-Btn "Load Current Values" 20 690 180 38 $C_BLUE
$btnLoadCur.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem
    foreach ($tag in $inputBoxes.Keys) {
        $val = & $exifToolPath -s -s -s "-$tag" -- "$f" 2>$null
        if ($val) { $inputBoxes[$tag].Text = ($val -join " ") } else { $inputBoxes[$tag].Text = "" }
    }
    $lblStatus.Text = "  *  Loaded current metadata values."
})
$tabEdit.Controls.Add($btnLoadCur)

$btnApply = New-Btn "Apply To Selected" 210 690 220 38 $C_GREEN
$btnApply.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem
    $args = @()
    foreach ($tag in $inputBoxes.Keys) {
        $v = $inputBoxes[$tag].Text
        if (-not [string]::IsNullOrWhiteSpace($v)) { $args += "-$tag=$v" }
    }
    if ($args.Count -eq 0) { return }
    $args += "-overwrite_original"
    $args += "--"
    $args += $f
    & $exifToolPath @args | Out-Null
    $lblStatus.Text = "  *  Metadata applied."
    [System.Windows.Forms.MessageBox]::Show("Metadata updated!", "Success")
})
$tabEdit.Controls.Add($btnApply)

$btnClearFields = New-Btn "Clear Fields" 440 690 160 38 $C_GRAY
$btnClearFields.Add_Click({
    foreach ($tag in $inputBoxes.Keys) { $inputBoxes[$tag].Text = "" }
})
$tabEdit.Controls.Add($btnClearFields)

$btnClearTags = New-Btn "Delete These Tags" 610 690 240 38 $C_RED
$btnClearTags.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem
    $args = @()
    foreach ($tag in $inputBoxes.Keys) { $args += "-$tag=" }
    $args += "-overwrite_original"
    $args += "--"
    $args += $f
    & $exifToolPath @args | Out-Null
    [System.Windows.Forms.MessageBox]::Show("Tags removed.", "Success")
})
$tabEdit.Controls.Add($btnClearTags)

# ============================================================
#  TAB 3 : Analysis
# ============================================================
$tabAnalysis.Controls.Add((New-SectionHeader "Forensic Analysis - select a file in Viewer first" 10 8 900))

$txtForensic = New-DarkTb 10 55 1220 620 $true
$tabAnalysis.Controls.Add($txtForensic)

$btnHash = New-Btn "Hashes" 10 685 140 35 $C_BLUE
$btnHash.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem
    $txtForensic.Clear()
    $txtForensic.AppendText("=== HASH ANALYSIS ===`r`n$f`r`n`r`n")
    $fi = Get-Item -LiteralPath $f
    $txtForensic.AppendText("Size   : $($fi.Length) bytes`r`n")
    $txtForensic.AppendText("MD5    : $((Get-FileHash -LiteralPath $f -Algorithm MD5).Hash)`r`n")
    $txtForensic.AppendText("SHA1   : $((Get-FileHash -LiteralPath $f -Algorithm SHA1).Hash)`r`n")
    $txtForensic.AppendText("SHA256 : $((Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash)`r`n")
})
$tabAnalysis.Controls.Add($btnHash)

$btnMagic = New-Btn "Magic Number" 160 685 155 35 $C_ORANGE
$btnMagic.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem
    $txtForensic.Clear()
    $txtForensic.AppendText("=== MAGIC NUMBER / FILE TYPE VERIFICATION ===`r`n$f`r`n`r`n")

    $fi = Get-Item -LiteralPath $f
    $bytes = [System.IO.File]::ReadAllBytes($f)[0..15]
    $hex = ($bytes | ForEach-Object { $_.ToString("X2") }) -join " "
    $txtForensic.AppendText("First 16 bytes : $hex`r`n")
    $txtForensic.AppendText("Extension says : $($fi.Extension.ToLower())`r`n")

    $detected = "Unknown"
    $b0 = $bytes[0]; $b1 = $bytes[1]; $b2 = $bytes[2]; $b3 = $bytes[3]

    if ($b0 -eq 0xFF -and $b1 -eq 0xD8) { $detected = "JPEG image" }
    elseif ($b0 -eq 0x89 -and $b1 -eq 0x50 -and $b2 -eq 0x4E -and $b3 -eq 0x47) { $detected = "PNG image" }
    elseif ($b0 -eq 0x47 -and $b1 -eq 0x49 -and $b2 -eq 0x46) { $detected = "GIF image" }
    elseif ($b0 -eq 0x42 -and $b1 -eq 0x4D) { $detected = "BMP image" }
    elseif ($b0 -eq 0x25 -and $b1 -eq 0x50 -and $b2 -eq 0x44) { $detected = "PDF document" }
    elseif ($b0 -eq 0x50 -and $b1 -eq 0x4B -and $b2 -eq 0x03) { $detected = "ZIP / Office / JAR" }
    elseif ($b0 -eq 0x52 -and $b1 -eq 0x49 -and $b2 -eq 0x46) { $detected = "RIFF (WEBP/AVI/WAV)" }
    elseif ($b0 -eq 0x1A -and $b1 -eq 0x45 -and $b2 -eq 0xDF -and $b3 -eq 0xA3) { $detected = "Matroska / WebM" }
    elseif ($b0 -eq 0x4D -and $b1 -eq 0x5A) { $detected = "Windows PE (exe/dll)" }
    elseif ($b0 -eq 0x7F -and $b1 -eq 0x45 -and $b2 -eq 0x4C) { $detected = "ELF binary" }
    elseif ($b0 -eq 0x00 -and $b1 -eq 0x00 -and $b2 -eq 0x00) { $detected = "MP4 / HEIF / QuickTime" }

    $txtForensic.AppendText("Detected type  : $detected`r`n`r`n")

    if ($detected -ne "Unknown" -and $detected.ToLower() -notmatch $fi.Extension.Replace(".", "").ToLower()) {
        $txtForensic.AppendText("[!] MISMATCH - extension does NOT match actual content!`r`n")
        $txtForensic.AppendText("[!] Possible polyglot / hidden payload / masquerading file.`r`n")
    }
    else {
        $txtForensic.AppendText("[OK] Extension and detected type appear consistent.`r`n")
    }
})
$tabAnalysis.Controls.Add($btnMagic)

$btnEntropy = New-Btn "Entropy" 325 685 140 35 $C_PURPLE
$btnEntropy.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem
    $txtForensic.Clear()
    $txtForensic.AppendText("=== ENTROPY ANALYSIS ===`r`n$f`r`n`r`n")

    $bytes = [System.IO.File]::ReadAllBytes($f)
    $counts = New-Object 'int[]' 256
    foreach ($b in $bytes) { $counts[$b]++ }

    $len = $bytes.Length
    $entropy = 0.0
    foreach ($c in $counts) {
        if ($c -gt 0) {
            $p = $c / $len
            $entropy -= $p * [Math]::Log($p, 2)
        }
    }
    $txtForensic.AppendText("File size : $len bytes`r`n")
    $txtForensic.AppendText(("Entropy   : {0:N4} bits/byte (range 0-8)`r`n`r`n" -f $entropy))

    if ($entropy -gt 7.9) {
        $txtForensic.AppendText("[!] VERY HIGH entropy - likely encrypted or compressed data.`r`n")
    }
    elseif ($entropy -gt 7.5) {
        $txtForensic.AppendText("[~] HIGH entropy (expected for JPEG / MP4 / ZIP).`r`n")
    }
    elseif ($entropy -gt 4.0) {
        $txtForensic.AppendText("[OK] Normal range for images and documents.`r`n")
    }
    else {
        $txtForensic.AppendText("[~] LOW entropy - simple content (text / blank / small image).`r`n")
    }
})
$tabAnalysis.Controls.Add($btnEntropy)

$btnStrings = New-Btn "Strings" 475 685 140 35 $C_BLUE
$btnStrings.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem
    $txtForensic.Clear()
    $txtForensic.AppendText("=== STRINGS EXTRACTION ===`r`n$f`r`n`r`n")

    $bytes = [System.IO.File]::ReadAllBytes($f)
    $text = -join ($bytes | ForEach-Object {
        if ($_ -ge 32 -and $_ -le 126) { [char]$_ } else { ' ' }
    })

    $urls   = [regex]::Matches($text, 'https?://[^\s"'']{4,120}') | ForEach-Object { $_.Value } | Select-Object -Unique
    $emails = [regex]::Matches($text, '[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}') | ForEach-Object { $_.Value } | Select-Object -Unique
    $ips    = [regex]::Matches($text, '\b(?:\d{1,3}\.){3}\d{1,3}\b') | ForEach-Object { $_.Value } | Select-Object -Unique
    $b64    = [regex]::Matches($text, '[A-Za-z0-9+/]{40,}={0,2}') | ForEach-Object { $_.Value } | Select-Object -First 5

    $txtForensic.AppendText("--- URLs ---`r`n")
    if ($urls) { $urls | ForEach-Object { $txtForensic.AppendText("$($_)`r`n") } } else { $txtForensic.AppendText("(none)`r`n") }

    $txtForensic.AppendText("`r`n--- Emails ---`r`n")
    if ($emails) { $emails | ForEach-Object { $txtForensic.AppendText("$($_)`r`n") } } else { $txtForensic.AppendText("(none)`r`n") }

    $txtForensic.AppendText("`r`n--- IPs ---`r`n")
    if ($ips) { $ips | ForEach-Object { $txtForensic.AppendText("$($_)`r`n") } } else { $txtForensic.AppendText("(none)`r`n") }

    $txtForensic.AppendText("`r`n--- Base64-ish blobs (first 5) ---`r`n")
    if ($b64) { $b64 | ForEach-Object { $txtForensic.AppendText("$($_)`r`n") } } else { $txtForensic.AppendText("(none)`r`n") }
})
$tabAnalysis.Controls.Add($btnStrings)

$btnAppended = New-Btn "Appended Data" 625 685 165 35 $C_ORANGE
$btnAppended.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem
    $txtForensic.Clear()
    $txtForensic.AppendText("=== APPENDED / TRAILING DATA SCAN ===`r`n$f`r`n`r`n")

    $bytes = [System.IO.File]::ReadAllBytes($f)
    $len = $bytes.Length
    $ext = [System.IO.Path]::GetExtension($f).ToLower()
    $eofIdx = -1
    $eofTag = ""

    if ($ext -eq ".jpg" -or $ext -eq ".jpeg") {
        for ($i = $len - 2; $i -ge 0; $i--) {
            if ($bytes[$i] -eq 0xFF -and $bytes[$i + 1] -eq 0xD9) {
                $eofIdx = $i; $eofTag = "JPEG EOI (FF D9)"; break
            }
        }
    }
    elseif ($ext -eq ".png") {
        for ($i = $len - 8; $i -ge 0; $i--) {
            if ($bytes[$i] -eq 0x49 -and $bytes[$i + 1] -eq 0x45 -and $bytes[$i + 2] -eq 0x4E -and $bytes[$i + 3] -eq 0x44) {
                $eofIdx = $i + 7; $eofTag = "PNG IEND chunk"; break
            }
        }
    }
    elseif ($ext -eq ".gif") {
        for ($i = $len - 1; $i -ge 0; $i--) {
            if ($bytes[$i] -eq 0x3B) { $eofIdx = $i; $eofTag = "GIF trailer (3B)"; break }
        }
    }
    else {
        $txtForensic.AppendText("Format '$ext' not analyzed (JPEG / PNG / GIF only).`r`n")
        return
    }

    $txtForensic.AppendText("Total file size : $len bytes`r`n")
    if ($eofIdx -gt 0) {
        $trailing = $len - $eofIdx - 1
        $txtForensic.AppendText("EOF marker      : $eofTag at byte $eofIdx`r`n")
        $txtForensic.AppendText("Trailing bytes  : $trailing`r`n`r`n")

        if ($trailing -gt 16) {
            $txtForensic.AppendText("[!] SIGNIFICANT APPENDED DATA DETECTED!`r`n")
            $txtForensic.AppendText("    Possible steganography or appended payload.`r`n`r`n")
            $txtForensic.AppendText("First 64 bytes after EOF:`r`n")
            $tailEnd = [Math]::Min($eofIdx + 64, $len - 1)
            $tail = $bytes[($eofIdx + 1)..$tailEnd]
            $txtForensic.AppendText((($tail | ForEach-Object { $_.ToString("X2") }) -join " ") + "`r`n")
        }
        else {
            $txtForensic.AppendText("[OK] No significant trailing data.`r`n")
        }
    }
    else {
        $txtForensic.AppendText("[!] EOF marker not found - file may be truncated or corrupt.`r`n")
    }
})
$tabAnalysis.Controls.Add($btnAppended)

$btnAnti = New-Btn "Anti-Forensics" 800 685 165 35 $C_RED
$btnAnti.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem
    $txtForensic.Clear()
    $txtForensic.AppendText("=== ANTI-FORENSICS / METADATA-WIPE DETECTION ===`r`n$f`r`n`r`n")

    $flags = @()

    $hasExif  = & $exifToolPath -s -s -s -ExifVersion -- "$f"
    $hasMake  = & $exifToolPath -s -s -s -Make -- "$f"
    $hasModel = & $exifToolPath -s -s -s -Model -- "$f"
    $hasXMP   = & $exifToolPath -s -s -s -XMPToolkit -- "$f"
    $hasGPS   = & $exifToolPath -s -s -s -GPSLatitude -- "$f"

    if (-not $hasMake -and -not $hasModel) {
        $flags += "[!] No camera Make/Model - stripped OR downloaded from social media."
    }
    if ($hasExif -and -not $hasMake -and -not $hasModel -and -not $hasXMP) {
        $flags += "[!] EXIF block present but nearly empty - typical of metadata wipers."
    }

    $sw = & $exifToolPath -s -s -s -Software -- "$f"
    if ($sw) {
        foreach ($w in @("exiftool", "jhead", "mat2", "scrambled-exif", "ExifCleaner")) {
            if ($sw -match $w) { $flags += "[!] 'Software' tag mentions a metadata tool: $sw" }
        }
    }

    if (-not $hasGPS) {
        $flags += "[~] No GPS data (normal for most files, but relevant for location attribution)."
    }

    $fi = Get-Item -LiteralPath $f
    if ($fi.LastWriteTime -gt (Get-Date).AddDays(30)) {
        $flags += "[!] Modification date is in the FUTURE - clock manipulation or spoofing."
    }

    if ($flags.Count -eq 0) {
        $txtForensic.AppendText("No strong anti-forensics indicators.`r`n")
    }
    else {
        foreach ($fl in $flags) { $txtForensic.AppendText("$fl`r`n") }
    }
})
$tabAnalysis.Controls.Add($btnAnti)

$btnGpsMap = New-Btn "GPS + Map" 975 685 130 35 $C_GREEN
$btnGpsMap.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem
    $txtForensic.Clear()
    $txtForensic.AppendText("=== GPS EXTRACTION ===`r`n$f`r`n`r`n")

    $lat = & $exifToolPath -s -s -s -n -GPSLatitude -- "$f"
    $lon = & $exifToolPath -s -s -s -n -GPSLongitude -- "$f"
    $alt = & $exifToolPath -s -s -s -n -GPSAltitude -- "$f"

    if ($lat -and $lon) {
        $txtForensic.AppendText("Latitude  : $lat`r`n")
        $txtForensic.AppendText("Longitude : $lon`r`n")
        $txtForensic.AppendText("Altitude  : $alt m`r`n`r`n")
        $txtForensic.AppendText("Google Maps:`r`n")
        $txtForensic.AppendText("https://maps.google.com/?q=$lat,$lon`r`n`r`n")
        $txtForensic.AppendText("OpenStreetMap:`r`n")
        $txtForensic.AppendText("https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=17/$lat/$lon`r`n")
    }
    else {
        $txtForensic.AppendText("No GPS data found.`r`n")
    }
})
$tabAnalysis.Controls.Add($btnGpsMap)

$btnFullDump = New-Btn "Full Raw Dump" 1115 685 115 35 $C_BLUE
$btnFullDump.Add_Click({
    if (-not $listBox.SelectedItem) { return }
    $out = & $exifToolPath -a -G1 -s -- "$($listBox.SelectedItem)"
    $txtForensic.Text = ($out -join "`r`n")
})
$tabAnalysis.Controls.Add($btnFullDump)

# ============================================================
#  TAB 4 : Bulk Operations
# ============================================================
$tabBulk.Controls.Add((New-SectionHeader "Bulk Operations - applies to ALL files in Viewer queue" 10 8 800))

$btnStripGps = New-Btn "Strip GPS Only" 20 55 260 42 $C_RED
$btnStripGps.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    foreach ($f in $listBox.Items) {
        & $exifToolPath '-gps:all=' -overwrite_original -- "$f" | Out-Null
    }
    [System.Windows.Forms.MessageBox]::Show("GPS removed from $($listBox.Items.Count) file(s).")
})
$tabBulk.Controls.Add($btnStripGps)

$btnAnon = New-Btn "Anonymize All" 290 55 260 42 $C_RED
$btnAnon.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $name = [Microsoft.VisualBasic.Interaction]::InputBox("Anonymized author:", "Anonymize", "Anonymous")
    if (-not $name) { return }
    foreach ($f in $listBox.Items) {
        & $exifToolPath '-all=' -overwrite_original -- "$f" | Out-Null
        & $exifToolPath "-Artist=$name" "-Copyright=$name" -overwrite_original -- "$f" | Out-Null
    }
    [System.Windows.Forms.MessageBox]::Show("All files anonymized.")
})
$tabBulk.Controls.Add($btnAnon)

$btnCopyTpl = New-Btn "Copy From Template" 560 55 300 42 $C_GREEN
$btnCopyTpl.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($f in $listBox.Items) {
            & $exifToolPath -TagsFromFile "$($ofd.FileName)" -all:all -overwrite_original -- "$f" | Out-Null
        }
        [System.Windows.Forms.MessageBox]::Show("Metadata copied from template.")
    }
})
$tabBulk.Controls.Add($btnCopyTpl)

$btnKw = New-Btn "Add Keyword" 870 55 355 42 $C_BLUE
$btnKw.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $kw = [Microsoft.VisualBasic.Interaction]::InputBox("Keywords (comma separated):", "Keywords", "evidence,case-2025")
    if (-not $kw) { return }
    foreach ($f in $listBox.Items) {
        & $exifToolPath "-Keywords=$kw" -overwrite_original -- "$f" | Out-Null
    }
    [System.Windows.Forms.MessageBox]::Show("Keyword applied to all files.")
})
$tabBulk.Controls.Add($btnKw)

$btnTimeShift = New-Btn "Shift Dates (hours)" 20 115 260 42 $C_PURPLE
$btnTimeShift.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $hrs = [Microsoft.VisualBasic.Interaction]::InputBox("Shift by N hours (negative allowed):", "Time Shift", "0")
    if (-not $hrs -or $hrs -eq "0") { return }
    foreach ($f in $listBox.Items) {
        & $exifToolPath "-AllDates+=$($hrs):00:00" -overwrite_original -- "$f" | Out-Null
    }
    [System.Windows.Forms.MessageBox]::Show("Dates shifted by $hrs hour(s).")
})
$tabBulk.Controls.Add($btnTimeShift)

$btnRename = New-Btn "Rename to DateTimeOriginal" 290 115 300 42 $C_ORANGE
$btnRename.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $c = [System.Windows.Forms.MessageBox]::Show(
        "Rename ALL files using DateTimeOriginal?", "Confirm",
        [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($c -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    foreach ($f in $listBox.Items) {
        & $exifToolPath "-FileName<DateTimeOriginal" "-d" "%Y-%m-%d_%H-%M-%S%%-c.%%e" -overwrite_original -- "$f" | Out-Null
    }
    [System.Windows.Forms.MessageBox]::Show("Files renamed.")
})
$tabBulk.Controls.Add($btnRename)

$btnDup = New-Btn "Duplicate Finder (SHA256)" 600 115 300 42 $C_GRAY
$btnDup.Add_Click({
    if ($listBox.Items.Count -lt 2) { return }
    $lblStatus.Text = "  *  Hashing..."

    $hashes = @{}
    foreach ($f in $listBox.Items) {
        $h = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash
        if (-not $hashes.ContainsKey($h)) { $hashes[$h] = @() }
        $hashes[$h] += $f
    }

    $dups = $hashes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    if (-not $dups) {
        [System.Windows.Forms.MessageBox]::Show("No duplicates found.")
        return
    }

    $lines = @("=== DUPLICATE FILES (identical SHA256) ===", "")
    foreach ($d in $dups) {
        $lines += "SHA256: $($d.Key)"
        foreach ($p in $d.Value) { $lines += "    $p" }
        $lines += ""
    }
    $outPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "duplicates.txt"
    $lines -join "`r`n" | Out-File -FilePath $outPath -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("Duplicates saved to:`n$outPath")
})
$tabBulk.Controls.Add($btnDup)

$btnKml = New-Btn "Export GPS to KML" 910 115 315 42 $C_GREEN
$btnKml.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $sd = New-Object System.Windows.Forms.SaveFileDialog
    $sd.Filter = "KML (*.kml)|*.kml"
    $sd.FileName = "gps_pins.kml"
    if ($sd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
    [void]$sb.AppendLine('<kml xmlns="http://www.opengis.net/kml/2.2"><Document>')
    [void]$sb.AppendLine('<name>ExifTool GUI Forensics - GPS Pins</name>')

    foreach ($f in $listBox.Items) {
        $lat = & $exifToolPath -s -s -s -n -GPSLatitude -- "$f"
        $lon = & $exifToolPath -s -s -s -n -GPSLongitude -- "$f"
        if ($lat -and $lon) {
            $name = [System.Web.HttpUtility]::HtmlEncode((Split-Path $f -Leaf))
            $desc = [System.Web.HttpUtility]::HtmlEncode($f)
            $coordLine = "<Point><coordinates>" + $lon + "," + $lat + ",0</coordinates></Point></Placemark>"
            [void]$sb.AppendLine("<Placemark><name>$name</name>")
            [void]$sb.AppendLine("<description>$desc</description>")
            [void]$sb.AppendLine($coordLine)
        }
    }
    [void]$sb.AppendLine('</Document></kml>')
    $sb.ToString() | Out-File -FilePath $sd.FileName -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("KML saved: $($sd.FileName)")
})
$tabBulk.Controls.Add($btnKml)

# ============================================================
#  TAB 5 : Reports
# ============================================================
$tabReport.Controls.Add((New-SectionHeader "Reports - uses all files in the Viewer queue" 10 8 800))

$btnCsv = New-Btn "Export CSV" 20 55 200 45 $C_PURPLE
$btnCsv.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $sd = New-Object System.Windows.Forms.SaveFileDialog
    $sd.Filter = "CSV (*.csv)|*.csv"
    $sd.FileName = "metadata_report.csv"
    if ($sd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        (& $exifToolPath -csv -- @($listBox.Items)) | Out-File -FilePath $sd.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("CSV saved.")
    }
})
$tabReport.Controls.Add($btnCsv)

$btnJson = New-Btn "Export JSON" 230 55 200 45 $C_BLUE
$btnJson.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $sd = New-Object System.Windows.Forms.SaveFileDialog
    $sd.Filter = "JSON (*.json)|*.json"
    $sd.FileName = "metadata_report.json"
    if ($sd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        (& $exifToolPath -json -- @($listBox.Items)) | Out-File -FilePath $sd.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("JSON saved.")
    }
})
$tabReport.Controls.Add($btnJson)

$btnHtml = New-Btn "HTML Forensic Report" 440 55 300 45 $C_RED
$btnHtml.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $sd = New-Object System.Windows.Forms.SaveFileDialog
    $sd.Filter = "HTML (*.html)|*.html"
    $sd.FileName = "forensic_report.html"
    if ($sd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("<html><head><meta charset='utf-8'><title>Forensic Report</title>")
    [void]$sb.AppendLine("<style>")
    [void]$sb.AppendLine("body{font-family:Segoe UI;background:#0f1117;color:#e4e6eb;padding:20px}")
    [void]$sb.AppendLine("h1{color:#00d9a3}")
    [void]$sb.AppendLine("h2{color:#3b82f6;border-bottom:1px solid #2d323e}")
    [void]$sb.AppendLine("pre{background:#12151b;padding:10px;border-left:3px solid #00d9a3;overflow:auto;font-size:12px}")
    [void]$sb.AppendLine(".h{color:#f59e0b}")
    [void]$sb.AppendLine("</style></head><body>")
    [void]$sb.AppendLine("<h1>Forensic Metadata Report</h1>")
    [void]$sb.AppendLine("<p>Generated: $(Get-Date)</p>")

    foreach ($f in $listBox.Items) {
        $fi = Get-Item -LiteralPath $f
        $nameHtml = [System.Web.HttpUtility]::HtmlEncode($fi.Name)
        $pathHtml = [System.Web.HttpUtility]::HtmlEncode($f)
        $md5 = (Get-FileHash -LiteralPath $f -Algorithm MD5).Hash
        $sha = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash
        $meta = & $exifToolPath -a -G1 -s -- "$f"
        $metaHtml = [System.Web.HttpUtility]::HtmlEncode(($meta -join "`n"))

        [void]$sb.AppendLine("<h2>$nameHtml</h2>")
        [void]$sb.AppendLine("<p><b>Path:</b> $pathHtml</p>")
        [void]$sb.AppendLine("<p><b>Size:</b> $($fi.Length) bytes | <b>Modified:</b> $($fi.LastWriteTime)</p>")
        [void]$sb.AppendLine("<p class='h'><b>MD5:</b> $md5<br><b>SHA256:</b> $sha</p>")
        [void]$sb.AppendLine("<pre>$metaHtml</pre>")
    }
    [void]$sb.AppendLine("</body></html>")
    $sb.ToString() | Out-File -FilePath $sd.FileName -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("HTML report saved.")
})
$tabReport.Controls.Add($btnHtml)

$btnCoc = New-Btn "Chain of Custody" 750 55 250 45 $C_GREEN
$btnCoc.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $sd = New-Object System.Windows.Forms.SaveFileDialog
    $sd.Filter = "Text (*.txt)|*.txt"
    $sd.FileName = "chain_of_custody.txt"
    if ($sd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $lines = @(
        "==================================================",
        "  CHAIN OF CUSTODY - EVIDENCE LOG",
        "  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "  Examiner : $env:USERNAME@$env:COMPUTERNAME",
        "  Tool     : ExifTool GUI Forensics v3.1",
        "==================================================",
        ""
    )

    $i = 1
    foreach ($f in $listBox.Items) {
        $fi = Get-Item -LiteralPath $f
        $lines += "--- Item #$i ---"
        $lines += "Path     : $f"
        $lines += "Size     : $($fi.Length) bytes"
        $lines += "Created  : $($fi.CreationTime)"
        $lines += "Modified : $($fi.LastWriteTime)"
        $lines += "MD5      : $((Get-FileHash -LiteralPath $f -Algorithm MD5).Hash)"
        $lines += "SHA256   : $((Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash)"
        $lines += ""
        $i++
    }

    $lines -join "`r`n" | Out-File -FilePath $sd.FileName -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("Chain of custody log saved.")
})
$tabReport.Controls.Add($btnCoc)

# ============================================================
#  TAB 6 : Case Management
# ============================================================
$tabCase.Controls.Add((New-SectionHeader "Case Notes + File List Snapshot (save / load as JSON)" 10 8 800))

$txtCaseNotes = New-Object System.Windows.Forms.TextBox
$txtCaseNotes.Location = New-Object System.Drawing.Point(10, 45)
$txtCaseNotes.Size = New-Object System.Drawing.Size(1220, 545)
$txtCaseNotes.Multiline = $true
$txtCaseNotes.ScrollBars = "Both"
$txtCaseNotes.Font = Get-SafeFont $FONT_MONO $FONT_MONO 10 ([System.Drawing.FontStyle]::Regular)
$txtCaseNotes.BackColor = $C_INPUT
$txtCaseNotes.ForeColor = $C_ACCENT
$txtCaseNotes.BorderStyle = "FixedSingle"
$txtCaseNotes.Text = @"
CASE NOTES
==========

Case ID     :
Investigator:
Date opened :
Priority    :
Description :

Evidence summary:

Findings:

Next steps:

"@
$tabCase.Controls.Add($txtCaseNotes)

$btnSaveCase = New-Btn "Save Case (JSON)" 10 600 260 42 $C_GREEN
$btnSaveCase.Add_Click({
    $sd = New-Object System.Windows.Forms.SaveFileDialog
    $sd.Filter = "Case JSON (*.case.json)|*.case.json"
    $sd.FileName = "case_$(Get-Date -Format 'yyyyMMdd_HHmm').case.json"
    if ($sd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $case = [ordered]@{
        SavedAt   = (Get-Date).ToString("o")
        Examiner  = "$env:USERNAME@$env:COMPUTERNAME"
        Notes     = $txtCaseNotes.Text
        Files     = @($listBox.Items)
        FileCount = $listBox.Items.Count
    }
    ($case | ConvertTo-Json -Depth 4) | Out-File -FilePath $sd.FileName -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("Case saved.")
})
$tabCase.Controls.Add($btnSaveCase)

$btnLoadCase = New-Btn "Load Case (JSON)" 280 600 260 42 $C_BLUE
$btnLoadCase.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Case JSON (*.case.json)|*.case.json|JSON (*.json)|*.json"
    if ($ofd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    try {
        $case = Get-Content -LiteralPath $ofd.FileName -Raw | ConvertFrom-Json
        if ($case.Notes) { $txtCaseNotes.Text = $case.Notes }
        if ($case.Files) {
            $listBox.Items.Clear()
            foreach ($f in $case.Files) { [void]$listBox.Items.Add($f) }
        }
        [System.Windows.Forms.MessageBox]::Show("Case loaded. Files: $($case.FileCount)")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to load case:`n$_")
    }
})
$tabCase.Controls.Add($btnLoadCase)

$btnSnapshot = New-Btn "Snapshot Hashes To Notes" 550 600 300 42 $C_ORANGE
$btnSnapshot.Add_Click({
    if ($listBox.Items.Count -eq 0) { return }
    $txtCaseNotes.AppendText("`r`n--- SNAPSHOT $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ---`r`n")
    foreach ($f in $listBox.Items) {
        $h = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash
        $txtCaseNotes.AppendText("$h    $(Split-Path $f -Leaf)`r`n")
    }
})
$tabCase.Controls.Add($btnSnapshot)

$btnWipeNotes = New-Btn "Clear Notes" 860 600 180 42 $C_GRAY
$btnWipeNotes.Add_Click({ $txtCaseNotes.Clear() })
$tabCase.Controls.Add($btnWipeNotes)

$btnOpenCaseFolder = New-Btn "Open Desktop Folder" 1050 600 180 42 $C_PURPLE
$btnOpenCaseFolder.Add_Click({
    Start-Process explorer.exe ([Environment]::GetFolderPath("Desktop"))
})
$tabCase.Controls.Add($btnOpenCaseFolder)

# ============================================================
#  Show Form
# ============================================================
[void]$form.ShowDialog()