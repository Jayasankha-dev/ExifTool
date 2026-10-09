# ============================================================
#  Advanced ExifTool GUI Manager (Forensics & OSINT)
#  ASCII-only version - no encoding issues
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# ---------------- ExifTool Path Check ----------------
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

$exifToolPath = Join-Path $scriptDir "exiftool.exe"

if (-not (Test-Path -LiteralPath $exifToolPath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "exiftool.exe could not be found!`n`nPlease place exiftool.exe and this script in the same folder.",
        "Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# ---------------- Main Form Window ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Advanced ExifTool GUI Manager (Forensics & OSINT)"
$form.Size = New-Object System.Drawing.Size(1000, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# ---------------- Drag & Drop File/Folder ListBox ----------------
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20, 20)
$listBox.Size = New-Object System.Drawing.Size(350, 480)
$listBox.AllowDrop = $true
$listBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$listBox.HorizontalScrollbar = $true
$form.Controls.Add($listBox)

# ---------------- Metadata Display TextBox ----------------
$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(390, 20)
$txtOutput.Size = New-Object System.Drawing.Size(570, 480)
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = "Both"
$txtOutput.WordWrap = $false
$txtOutput.ReadOnly = $true
$txtOutput.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$txtOutput.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$txtOutput.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 128)
$form.Controls.Add($txtOutput)

# ---------------- Instruction Label ----------------
$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Location = New-Object System.Drawing.Point(20, 510)
$lblInfo.Size = New-Object System.Drawing.Size(350, 30)
$lblInfo.Text = "[+] Drop Files or Folders here..."
$lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblInfo)

# ---------------- Drag and Drop Events ----------------
$listBox.Add_DragEnter({
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
})

$listBox.Add_DragDrop({
    $files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    foreach ($path in $files) {
        if (Test-Path -LiteralPath $path -PathType Container) {
            $allFiles = Get-ChildItem -LiteralPath $path -Recurse -File |
                        Select-Object -ExpandProperty FullName
            foreach ($f in $allFiles) {
                if ($listBox.Items -notcontains $f) { $listBox.Items.Add($f) }
            }
        }
        else {
            if ($listBox.Items -notcontains $path) { $listBox.Items.Add($path) }
        }
    }
})

# ============================================================
#  Buttons & Actions
# ============================================================

# ---------------- 1. View Metadata ----------------
$btnView = New-Object System.Windows.Forms.Button
$btnView.Location = New-Object System.Drawing.Point(20, 550)
$btnView.Size = New-Object System.Drawing.Size(160, 40)
$btnView.Text = "[?] View Metadata"
$btnView.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnView.BackColor = [System.Drawing.Color]::FromArgb(52, 152, 219)
$btnView.ForeColor = [System.Drawing.Color]::White
$btnView.Add_Click({
    if ($listBox.SelectedItem) {
        $selectedFile = $listBox.SelectedItem
        $output = & $exifToolPath -- "$selectedFile"
        $txtOutput.Text = ($output -join "`r`n")
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select a file from the list.",
            "Warning",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$form.Controls.Add($btnView)

# ---------------- 2. Remove Metadata ----------------
$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Location = New-Object System.Drawing.Point(190, 550)
$btnRemove.Size = New-Object System.Drawing.Size(180, 40)
$btnRemove.Text = "[X] Remove All Metadata"
$btnRemove.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnRemove.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
$btnRemove.ForeColor = [System.Drawing.Color]::White
$btnRemove.Add_Click({
    if ($listBox.Items.Count -gt 0) {
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "Are you sure you want to remove metadata from all listed files?",
            "Confirmation",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question)

        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            foreach ($item in $listBox.Items) {
                & $exifToolPath '-all=' -overwrite_original -- "$item" | Out-Null
            }
            [System.Windows.Forms.MessageBox]::Show(
                "Metadata successfully removed from all files!",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information)
            $txtOutput.Text = "Metadata successfully removed for all listed items."
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No files in the list.",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$form.Controls.Add($btnRemove)

# ---------------- 3. Add / Edit Metadata ----------------
$btnAddMeta = New-Object System.Windows.Forms.Button
$btnAddMeta.Location = New-Object System.Drawing.Point(390, 550)
$btnAddMeta.Size = New-Object System.Drawing.Size(180, 40)
$btnAddMeta.Text = "[E] Add/Edit Metadata"
$btnAddMeta.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnAddMeta.BackColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
$btnAddMeta.ForeColor = [System.Drawing.Color]::White
$btnAddMeta.Add_Click({
    if ($listBox.SelectedItem) {
        $selectedFile = $listBox.SelectedItem
        $artist = [Microsoft.VisualBasic.Interaction]::InputBox(
            "Enter Artist / Copyright name:",
            "Add Metadata",
            "JM Production")

        if ($artist) {
            & $exifToolPath "-Artist=$artist" "-Copyright=$artist" -overwrite_original -- "$selectedFile" | Out-Null
            [System.Windows.Forms.MessageBox]::Show(
                "Metadata successfully added!",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information)
            $txtOutput.Text = ((& $exifToolPath -- "$selectedFile") -join "`r`n")
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select a file from the list.",
            "Warning",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$form.Controls.Add($btnAddMeta)

# ---------------- 4. Export Report (CSV) ----------------
$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Location = New-Object System.Drawing.Point(580, 550)
$btnExport.Size = New-Object System.Drawing.Size(180, 40)
$btnExport.Text = "[S] Export Report (CSV)"
$btnExport.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnExport.BackColor = [System.Drawing.Color]::FromArgb(155, 89, 182)
$btnExport.ForeColor = [System.Drawing.Color]::White
$btnExport.Add_Click({
    if ($listBox.Items.Count -gt 0) {
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "CSV Files (*.csv)|*.csv"
        $saveDialog.FileName = "metadata_report.csv"

        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $csvPath = $saveDialog.FileName
            $paths = @($listBox.Items)
            $csv = & $exifToolPath -csv -- $paths
            $csv | Out-File -FilePath $csvPath -Encoding UTF8

            [System.Windows.Forms.MessageBox]::Show(
                "Report successfully saved to:`n$csvPath",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show(
            "No files available to report.",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$form.Controls.Add($btnExport)

# ---------------- 5. Clear List ----------------
$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Location = New-Object System.Drawing.Point(770, 550)
$btnClear.Size = New-Object System.Drawing.Size(190, 40)
$btnClear.Text = "[C] Clear List"
$btnClear.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnClear.BackColor = [System.Drawing.Color]::FromArgb(127, 140, 141)
$btnClear.ForeColor = [System.Drawing.Color]::White
$btnClear.Add_Click({
    $listBox.Items.Clear()
    $txtOutput.Clear()
})
$form.Controls.Add($btnClear)

# ---------------- Show Window ----------------
[void]$form.ShowDialog()