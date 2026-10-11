# ============================================================
#  Advanced ExifTool GUI Manager (Forensics & OSINT)
#  Simple + Clean Edition v1.2 - ASCII only
#  Fixed: File lock issue + write fallback
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# ---------------- Colors ----------------
$C_BG      = [System.Drawing.Color]::FromArgb(245, 245, 248)
$C_BTN     = [System.Drawing.Color]::FromArgb(52, 152, 219)
$C_BTN_RED = [System.Drawing.Color]::FromArgb(231, 76, 60)
$C_BTN_GRN = [System.Drawing.Color]::FromArgb(46, 204, 113)
$C_BTN_PUR = [System.Drawing.Color]::FromArgb(155, 89, 182)
$C_BTN_ORA = [System.Drawing.Color]::FromArgb(230, 140, 30)
$C_BTN_GRY = [System.Drawing.Color]::FromArgb(127, 140, 141)

# ---------------- ExifTool Path Check ----------------
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$exifToolPath = Join-Path $scriptDir "exiftool.exe"

if (-not (Test-Path -LiteralPath $exifToolPath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "exiftool.exe not found!`n`nPlace exiftool.exe and this script in the same folder.",
        "Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# ---------------- Safe Image Loader (no file lock) ----------------
function Load-ImageSafe($path) {
    try {
        $fs = New-Object System.IO.FileStream($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $ms = New-Object System.IO.MemoryStream
        $fs.CopyTo($ms)
        $fs.Close()
        $fs.Dispose()
        $ms.Position = 0
        $img = [System.Drawing.Image]::FromStream($ms)
        $clone = New-Object System.Drawing.Bitmap($img)
        $img.Dispose()
        $ms.Dispose()
        return $clone
    }
    catch {
        return $null
    }
}

# ---------------- Main Form ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "ExifTool GUI Manager - Forensics Edition v1.2"
$form.Size = New-Object System.Drawing.Size(1200, 720)
$form.StartPosition = "CenterScreen"
$form.BackColor = $C_BG
$form.MinimumSize = New-Object System.Drawing.Size(1000, 650)

# ---------------- File List ----------------
$lblList = New-Object System.Windows.Forms.Label
$lblList.Location = New-Object System.Drawing.Point(20, 12)
$lblList.Size = New-Object System.Drawing.Size(400, 20)
$lblList.Text = "File Queue  -  drag files or folders here:"
$lblList.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblList)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20, 36)
$listBox.Size = New-Object System.Drawing.Size(400, 500)
$listBox.AllowDrop = $true
$listBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$listBox.HorizontalScrollbar = $true
$listBox.SelectionMode = "MultiExtended"
$form.Controls.Add($listBox)

# ---------------- Preview ----------------
$lblPreview = New-Object System.Windows.Forms.Label
$lblPreview.Location = New-Object System.Drawing.Point(440, 12)
$lblPreview.Size = New-Object System.Drawing.Size(200, 20)
$lblPreview.Text = "Preview:"
$lblPreview.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblPreview)

$picPreview = New-Object System.Windows.Forms.PictureBox
$picPreview.Location = New-Object System.Drawing.Point(440, 36)
$picPreview.Size = New-Object System.Drawing.Size(220, 220)
$picPreview.BackColor = [System.Drawing.Color]::White
$picPreview.SizeMode = "Zoom"
$picPreview.BorderStyle = "FixedSingle"
$form.Controls.Add($picPreview)

# ---------------- Quick Info ----------------
$lblQuick = New-Object System.Windows.Forms.Label
$lblQuick.Location = New-Object System.Drawing.Point(680, 12)
$lblQuick.Size = New-Object System.Drawing.Size(200, 20)
$lblQuick.Text = "File Info:"
$lblQuick.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblQuick)

$txtQuick = New-Object System.Windows.Forms.TextBox
$txtQuick.Location = New-Object System.Drawing.Point(680, 36)
$txtQuick.Size = New-Object System.Drawing.Size(480, 220)
$txtQuick.Multiline = $true
$txtQuick.ScrollBars = "Both"
$txtQuick.WordWrap = $false
$txtQuick.ReadOnly = $true
$txtQuick.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$txtQuick.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$txtQuick.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 128)
$form.Controls.Add($txtQuick)

# ---------------- Metadata Output ----------------
$lblOut = New-Object System.Windows.Forms.Label
$lblOut.Location = New-Object System.Drawing.Point(440, 268)
$lblOut.Size = New-Object System.Drawing.Size(300, 20)
$lblOut.Text = "Metadata Output:"
$lblOut.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblOut)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(440, 292)
$txtOutput.Size = New-Object System.Drawing.Size(720, 244)
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = "Both"
$txtOutput.WordWrap = $false
$txtOutput.ReadOnly = $true
$txtOutput.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$txtOutput.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$txtOutput.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 128)
$form.Controls.Add($txtOutput)

# ---------------- Status Bar ----------------
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(20, 645)
$lblStatus.Size = New-Object System.Drawing.Size(1140, 22)
$lblStatus.Text = "Ready."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(30, 130, 90)
$form.Controls.Add($lblStatus)

# ---------------- Drag & Drop ----------------
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
    $lblStatus.Text = "Loaded $($listBox.Items.Count) file(s)."
})

# ---------------- Preview on Select ----------------
$listBox.Add_SelectedIndexChanged({
    if (-not $listBox.SelectedItem) { return }
    $f = $listBox.SelectedItem

    # Use safe loader - no file lock
    if ($picPreview.Image) { $picPreview.Image.Dispose() }
    $picPreview.Image = Load-ImageSafe $f

    $fi = Get-Item -LiteralPath $f
    $txtQuick.Clear()
    $txtQuick.AppendText("PATH     : $f`r`n")
    $txtQuick.AppendText("SIZE     : $($fi.Length) bytes`r`n")
    $txtQuick.AppendText("CREATED  : $($fi.CreationTime)`r`n")
    $txtQuick.AppendText("MODIFIED : $($fi.LastWriteTime)`r`n")
    $txtQuick.AppendText("ACCESSED : $($fi.LastAccessTime)`r`n")
    $txtQuick.AppendText("EXT      : $($fi.Extension)`r`n")
    $txtQuick.AppendText("READONLY : $($fi.IsReadOnly)`r`n")
    try {
        $md5 = (Get-FileHash -LiteralPath $f -Algorithm MD5).Hash
        $txtQuick.AppendText("MD5      : $md5`r`n")
    } catch {}

    $lblStatus.Text = "Selected: $(Split-Path $f -Leaf)"
})

# ============================================================
#  Buttons Factory
# ============================================================
function New-Button($text, $x, $y, $w, $h, $color) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.Size = New-Object System.Drawing.Size($w, $h)
    $b.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $b.BackColor = $color
    $b.ForeColor = [System.Drawing.Color]::White
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 0
    return $b
}

# --- 1. View Metadata ---
$btnView = New-Button "[?] View Metadata" 20 550 180 40 $C_BTN
$btnView.Add_Click({
    if (-not $listBox.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select a file first.", "Warning")
        return
    }
    $out = & $exifToolPath -- "$($listBox.SelectedItem)"
    $txtOutput.Text = ($out -join "`r`n")
    $lblStatus.Text = "Metadata loaded."
})
$form.Controls.Add($btnView)

# --- 2. Full Raw Dump ---
$btnRaw = New-Button "[R] Full Raw Dump" 210 550 180 40 $C_BTN
$btnRaw.Add_Click({
    if (-not $listBox.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select a file first.", "Warning")
        return
    }
    $out = & $exifToolPath -a -G1 -s -- "$($listBox.SelectedItem)"
    $txtOutput.Text = ($out -join "`r`n")
    $lblStatus.Text = "Full raw dump loaded."
})
$form.Controls.Add($btnRaw)

# --- 3. Remove All Metadata ---
$btnRemove = New-Button "[X] Remove All Metadata" 400 550 200 40 $C_BTN_RED
$btnRemove.Add_Click({
    if ($listBox.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No files in the list.", "Warning")
        return
    }
    $c = [System.Windows.Forms.MessageBox]::Show(
        "Remove ALL metadata from $($listBox.Items.Count) file(s)?",
        "Confirm",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($c -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    # Release image lock first
    if ($picPreview.Image) { $picPreview.Image.Dispose(); $picPreview.Image = $null }

    $ok = 0; $fail = 0
    foreach ($f in $listBox.Items) {
        $r = & $exifToolPath '-all=' -overwrite_original -- "$f" 2>&1
        if ($LASTEXITCODE -eq 0) { $ok++ }
        else {
            # Fallback - in-place write
            $r2 = & $exifToolPath '-all=' -overwrite_original_in_place -- "$f" 2>&1
            if ($LASTEXITCODE -eq 0) { $ok++ } else { $fail++ }
        }
    }
    [System.Windows.Forms.MessageBox]::Show("Done.`nSuccess: $ok`nFailed: $fail", "Result")
    $lblStatus.Text = "Metadata strip: $ok ok, $fail failed."
})
$form.Controls.Add($btnRemove)

# --- 4. Add/Edit Metadata (Multi-field dialog with cross-format tags) ---
$btnAddMeta = New-Button "[E] Add/Edit Metadata" 610 550 190 40 $C_BTN_GRN
$btnAddMeta.Add_Click({
    if (-not $listBox.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select a file first.", "Warning")
        return
    }
    $f = $listBox.SelectedItem

    # IMPORTANT: Release image lock BEFORE writing
    if ($picPreview.Image) { $picPreview.Image.Dispose(); $picPreview.Image = $null }

    # Check if file is read-only
    $fi = Get-Item -LiteralPath $f
    if ($fi.IsReadOnly) {
        $ans = [System.Windows.Forms.MessageBox]::Show(
            "File is READ-ONLY.`n`nRemove read-only attribute?",
            "Read-Only File",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                $fi.IsReadOnly = $false
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Cannot remove read-only: $_")
                return
            }
        } else {
            return
        }
    }

    # -------- Build the metadata editor dialog --------
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Edit Metadata - $(Split-Path $f -Leaf)"
    $dlg.Size = New-Object System.Drawing.Size(620, 580)
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.BackColor = $C_BG

    $fields = @(
        "Artist", "Copyright", "ImageDescription", "XPKeywords",
        "Software", "Make", "Model", "LensModel",
        "DateTimeOriginal", "Rating", "Orientation"
    )

    $boxes = @{}
    $y = 20
    foreach ($tag in $fields) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = "$tag :"
        $lbl.Location = New-Object System.Drawing.Point(20, ($y + 4))
        $lbl.Size = New-Object System.Drawing.Size(150, 20)
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $dlg.Controls.Add($lbl)

        $tb = New-Object System.Windows.Forms.TextBox
        $tb.Location = New-Object System.Drawing.Point(175, $y)
        $tb.Size = New-Object System.Drawing.Size(410, 24)
        $tb.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $dlg.Controls.Add($tb)

        $cur = & $exifToolPath -s -s -s "-$tag" -- "$f" 2>$null
        if ($cur) { $tb.Text = ($cur -join " ") }

        $boxes[$tag] = $tb
        $y += 32
    }

    $btnOkDlg = New-Object System.Windows.Forms.Button
    $btnOkDlg.Text = "Apply"
    $btnOkDlg.Location = New-Object System.Drawing.Point(175, ($y + 10))
    $btnOkDlg.Size = New-Object System.Drawing.Size(130, 38)
    $btnOkDlg.BackColor = $C_BTN_GRN
    $btnOkDlg.ForeColor = [System.Drawing.Color]::White
    $btnOkDlg.FlatStyle = "Flat"
    $btnOkDlg.FlatAppearance.BorderSize = 0
    $btnOkDlg.Add_Click({
        $vals = @{}
        foreach ($key in $script:dlgBoxes.Keys) {
            $vals[$key] = $script:dlgBoxes[$key].Text
        }
        $script:dlgResult = $vals
        $script:dlgAction = "OK"
        $dlg.Close()
    })
    $dlg.Controls.Add($btnOkDlg)

    $btnCancelDlg = New-Object System.Windows.Forms.Button
    $btnCancelDlg.Text = "Cancel"
    $btnCancelDlg.Location = New-Object System.Drawing.Point(315, ($y + 10))
    $btnCancelDlg.Size = New-Object System.Drawing.Size(110, 38)
    $btnCancelDlg.FlatStyle = "Flat"
    $btnCancelDlg.FlatAppearance.BorderSize = 0
    $btnCancelDlg.Add_Click({
        $script:dlgAction = "CANCEL"
        $dlg.Close()
    })
    $dlg.Controls.Add($btnCancelDlg)

    $btnClearDlg = New-Object System.Windows.Forms.Button
    $btnClearDlg.Text = "Clear All Fields"
    $btnClearDlg.Location = New-Object System.Drawing.Point(435, ($y + 10))
    $btnClearDlg.Size = New-Object System.Drawing.Size(150, 38)
    $btnClearDlg.BackColor = $C_BTN_RED
    $btnClearDlg.ForeColor = [System.Drawing.Color]::White
    $btnClearDlg.FlatStyle = "Flat"
    $btnClearDlg.FlatAppearance.BorderSize = 0
    $btnClearDlg.Add_Click({
        foreach ($k in $script:dlgBoxes.Keys) { $script:dlgBoxes[$k].Text = "" }
    })
    $dlg.Controls.Add($btnClearDlg)

    $script:dlgBoxes  = $boxes
    $script:dlgAction = "CANCEL"
    $script:dlgResult = $null

    [void]$dlg.ShowDialog()
    $dlg.Dispose()

    if ($script:dlgAction -ne "OK" -or -not $script:dlgResult) { return }

    # -------- Write with cross-format tag variants --------
    $exifArgs = @()
    $written  = @()

    foreach ($tag in $fields) {
        $v = $script:dlgResult[$tag]
        if ([string]::IsNullOrWhiteSpace($v)) { continue }

        switch ($tag) {
            "Artist" {
                $exifArgs += "-Artist=$v"
                $exifArgs += "-EXIF:Artist=$v"
                $exifArgs += "-XMP-dc:Creator=$v"
                $exifArgs += "-IPTC:By-line=$v"
                $exifArgs += "-XPAuthor=$v"
            }
            "Copyright" {
                $exifArgs += "-Copyright=$v"
                $exifArgs += "-EXIF:Copyright=$v"
                $exifArgs += "-XMP-dc:Rights=$v"
                $exifArgs += "-IPTC:CopyrightNotice=$v"
            }
            "ImageDescription" {
                $exifArgs += "-ImageDescription=$v"
                $exifArgs += "-EXIF:ImageDescription=$v"
                $exifArgs += "-XMP-dc:Description=$v"
                $exifArgs += "-IPTC:Caption-Abstract=$v"
            }
            "XPKeywords" {
                $exifArgs += "-XPKeywords=$v"
                $exifArgs += "-XMP-dc:Subject=$v"
                $exifArgs += "-IPTC:Keywords=$v"
            }
            "LensModel" {
                $exifArgs += "-LensModel=$v"
                $exifArgs += "-EXIF:LensModel=$v"
                $exifArgs += "-XMP-aux:Lens=$v"
            }
            "DateTimeOriginal" {
                $exifArgs += "-DateTimeOriginal=$v"
                $exifArgs += "-EXIF:DateTimeOriginal=$v"
                $exifArgs += "-XMP-photoshop:DateCreated=$v"
            }
            "Rating" {
                $exifArgs += "-Rating=$v"
                $exifArgs += "-XMP:Rating=$v"
            }
            "Orientation" {
                $exifArgs += "-Orientation=$v"
                $exifArgs += "-EXIF:Orientation=$v"
            }
            default {
                $exifArgs += "-$tag=$v"
            }
        }
        $written += "$tag = $v"
    }

    if ($exifArgs.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No fields filled - nothing to write.", "Info")
        return
    }

    # Attempt 1: -overwrite_original
    $args1 = $exifArgs + @("-overwrite_original", "--", $f)
    $result1 = & $exifToolPath @args1 2>&1
    $code1 = $LASTEXITCODE

    $usedMethod = "overwrite_original"
    $result = $result1
    $exitCode = $code1

    # Attempt 2: fallback to -overwrite_original_in_place
    if ($code1 -ne 0) {
        $args2 = $exifArgs + @("-overwrite_original_in_place", "--", $f)
        $result2 = & $exifToolPath @args2 2>&1
        $code2 = $LASTEXITCODE
        if ($code2 -eq 0) {
            $usedMethod = "overwrite_original_in_place (fallback)"
            $result = $result2
            $exitCode = $code2
        } else {
            # Both failed - report attempt 2 as the final
            $usedMethod = "BOTH FAILED"
            $result = $result2
            $exitCode = $code2
        }
    }

    # Verify
    $verify = & $exifToolPath -s -s -s -Artist -Copyright -ImageDescription -XPKeywords -- "$f" 2>&1

    $summary  = "Write method : $usedMethod`r`n"
    $summary += "Exit code    : $exitCode`r`n`r`n"
    $summary += "Attempted to write:`r`n"
    foreach ($w in $written) { $summary += "  * $w`r`n" }
    $summary += "`r`nExifTool output:`r`n"
    $summary += (($result | Out-String).Trim())
    $summary += "`r`n`r`nVerify (read-back):`r`n"
    $summary += (($verify | Out-String).Trim())

    if ($exitCode -eq 0) {
        [System.Windows.Forms.MessageBox]::Show($summary, "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
        $lblStatus.Text = "Metadata applied ($usedMethod)."
    }
    else {
        [System.Windows.Forms.MessageBox]::Show($summary, "ExifTool Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        $lblStatus.Text = "Write failed (code $exitCode)."
    }

    # Reload preview & output
    $picPreview.Image = Load-ImageSafe $f
    $txtOutput.Text = ((& $exifToolPath -- "$f") -join "`r`n")
})
$form.Controls.Add($btnAddMeta)

# --- 5. Strip GPS Only ---
$btnGps = New-Button "[G] Strip GPS Only" 810 550 170 40 $C_BTN_ORA
$btnGps.Add_Click({
    if ($listBox.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No files in the list.", "Warning")
        return
    }
    if ($picPreview.Image) { $picPreview.Image.Dispose(); $picPreview.Image = $null }

    $ok = 0; $fail = 0
    foreach ($f in $listBox.Items) {
        $r = & $exifToolPath '-gps:all=' -overwrite_original -- "$f" 2>&1
        if ($LASTEXITCODE -eq 0) { $ok++ }
        else {
            $r2 = & $exifToolPath '-gps:all=' -overwrite_original_in_place -- "$f" 2>&1
            if ($LASTEXITCODE -eq 0) { $ok++ } else { $fail++ }
        }
    }
    [System.Windows.Forms.MessageBox]::Show("GPS strip done.`nSuccess: $ok`nFailed: $fail", "Result")
    $lblStatus.Text = "GPS strip: $ok ok, $fail failed."
})
$form.Controls.Add($btnGps)

# --- 6. Export CSV ---
$btnCsv = New-Button "[S] Export CSV" 20 600 180 40 $C_BTN_PUR
$btnCsv.Add_Click({
    if ($listBox.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No files in the list.", "Warning")
        return
    }
    $sd = New-Object System.Windows.Forms.SaveFileDialog
    $sd.Filter = "CSV (*.csv)|*.csv"
    $sd.FileName = "metadata_report.csv"
    if ($sd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $paths = @($listBox.Items)
        (& $exifToolPath -csv -- $paths) | Out-File -FilePath $sd.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("CSV saved:`n$($sd.FileName)", "Success")
        $lblStatus.Text = "CSV exported."
    }
})
$form.Controls.Add($btnCsv)

# --- 7. Export JSON ---
$btnJson = New-Button "[J] Export JSON" 210 600 180 40 $C_BTN_PUR
$btnJson.Add_Click({
    if ($listBox.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No files in the list.", "Warning")
        return
    }
    $sd = New-Object System.Windows.Forms.SaveFileDialog
    $sd.Filter = "JSON (*.json)|*.json"
    $sd.FileName = "metadata_report.json"
    if ($sd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $paths = @($listBox.Items)
        (& $exifToolPath -json -- $paths) | Out-File -FilePath $sd.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("JSON saved:`n$($sd.FileName)", "Success")
        $lblStatus.Text = "JSON exported."
    }
})
$form.Controls.Add($btnJson)

# --- 8. Hashes ---
$btnHash = New-Button "[H] Hashes" 400 600 200 40 $C_BTN
$btnHash.Add_Click({
    if (-not $listBox.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select a file first.", "Warning")
        return
    }
    $f = $listBox.SelectedItem
    $txtOutput.Clear()
    $txtOutput.AppendText("=== HASH ANALYSIS ===`r`n$f`r`n`r`n")
    $fi = Get-Item -LiteralPath $f
    $txtOutput.AppendText("Size   : $($fi.Length) bytes`r`n")
    $txtOutput.AppendText("MD5    : $((Get-FileHash -LiteralPath $f -Algorithm MD5).Hash)`r`n")
    $txtOutput.AppendText("SHA1   : $((Get-FileHash -LiteralPath $f -Algorithm SHA1).Hash)`r`n")
    $txtOutput.AppendText("SHA256 : $((Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash)`r`n")
    $lblStatus.Text = "Hashes calculated."
})
$form.Controls.Add($btnHash)

# --- 9. GPS Info ---
$btnGpsInfo = New-Button "[P] GPS Info" 610 600 190 40 $C_BTN_GRN
$btnGpsInfo.Add_Click({
    if (-not $listBox.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select a file first.", "Warning")
        return
    }
    $f = $listBox.SelectedItem
    $lat = & $exifToolPath -s -s -s -n -GPSLatitude -- "$f"
    $lon = & $exifToolPath -s -s -s -n -GPSLongitude -- "$f"
    $alt = & $exifToolPath -s -s -s -n -GPSAltitude -- "$f"

    $txtOutput.Clear()
    $txtOutput.AppendText("=== GPS INFO ===`r`n$f`r`n`r`n")
    if ($lat -and $lon) {
        $txtOutput.AppendText("Latitude  : $lat`r`n")
        $txtOutput.AppendText("Longitude : $lon`r`n")
        $txtOutput.AppendText("Altitude  : $alt m`r`n`r`n")
        $txtOutput.AppendText("Google Maps:`r`n")
        $txtOutput.AppendText("https://maps.google.com/?q=$lat,$lon`r`n`r`n")
        $txtOutput.AppendText("OpenStreetMap:`r`n")
        $txtOutput.AppendText("https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=17/$lat/$lon`r`n")
        $lblStatus.Text = "GPS data found."
    }
    else {
        $txtOutput.AppendText("No GPS data found.`r`n")
        $lblStatus.Text = "No GPS data."
    }
})
$form.Controls.Add($btnGpsInfo)

# --- 10. Open Folder ---
$btnOpen = New-Button "[O] Open Folder" 810 600 170 40 $C_BTN_GRY
$btnOpen.Add_Click({
    if (-not $listBox.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select a file first.", "Warning")
        return
    }
    Start-Process explorer.exe "/select,`"$($listBox.SelectedItem)`""
})
$form.Controls.Add($btnOpen)

# --- 11. Clear List ---
$btnClear = New-Button "[C] Clear List" 990 550 170 90 $C_BTN_GRY
$btnClear.Add_Click({
    $listBox.Items.Clear()
    $txtOutput.Clear()
    $txtQuick.Clear()
    if ($picPreview.Image) { $picPreview.Image.Dispose(); $picPreview.Image = $null }
    $lblStatus.Text = "Cleared."
})
$form.Controls.Add($btnClear)

# ============================================================
#  Show Window
# ============================================================
[void]$form.ShowDialog()
