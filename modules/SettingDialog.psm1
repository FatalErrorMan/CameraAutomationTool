# ==============================
# プリディレクティブ
# ==============================
Import-Module "$PSScriptRoot\Config.psm1"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==============================
# 設定ダイアログ
# ==============================
function Show-SettingDialog {
    param ([string]$iniPath, [hashtable]$settings)
    
    # ------------------------------
    # フォーム作成
    # ------------------------------
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "設定"
    $form.StartPosition = "Manual" # メインウィンドウの上に表示
    $form.Location = New-Object System.Drawing.Point($settings.WindowX, $settings.WindowY)
    $form.Size = New-Object System.Drawing.Size(400, 500) # サイズは固定
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.TopMost = $true

    # ------------------------------
    # 固定値
    # ------------------------------
    $x1Pos = 20
    $x2Pos = 220
    $yPos = 20
    $labelMargin = 20
    $itemMargin = 35
    $xButtonPos = 100
    $yButtonPos = 400
    
    # ------------------------------
    # コントロール作成用関数
    # ------------------------------
    function Add-Label {
        param ([string]$text, [int]$xPos, [int]$yPos)
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $text
        $label.Location = New-Object System.Drawing.Point($xPos, $yPos)
        $label.AutoSize = $true
        $form.Controls.Add($label)
    }

    # ------------------------------
    # ラベルおよび入力欄作成
    # ------------------------------
    Add-Label "保存先のパス" $x1Pos $yPos
    $yPos = $yPos + $labelMargin
    $txtDestPath = New-Object System.Windows.Forms.TextBox
    $txtDestPath.Location = New-Object System.Drawing.Point($x1Pos, $yPos)
    $txtDestPath.Width = 300
    $txtDestPath.Text = $settings.DestinationPath
    $form.Controls.Add($txtDestPath)
    # 参照ボタンの追加
    $btnDestPath = New-Object System.Windows.Forms.Button
    $btnDestPath.Text = "参照"
    $btnDestPath.Location = New-Object System.Drawing.Point(($x1Pos + 305), ($yPos - 2)) # テキストボックスの右隣
    $btnDestPath.Size = New-Object System.Drawing.Size(40, 20)
    $btnDestPath.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "保存先のフォルダを選択してください"
        $folderBrowser.SelectedPath = $txtDestPath.Text
        if ($folderBrowser.ShowDialog() -eq "OK") {
            $txtDestPath.Text = $folderBrowser.SelectedPath
        }
    })
    $form.Controls.Add($btnDestPath)
    $yPos = $yPos + $itemMargin
    
    Add-Label "撮影前の待機時間 (秒):" $x1Pos $yPos
    $numWaitBefore = New-Object System.Windows.Forms.NumericUpDown
    $numWaitBefore.Location = New-Object System.Drawing.Point($x2Pos, $yPos)
    $numWaitBefore.Maximum = 10
    $numWaitBefore.Value = [int]$settings.WaitBeforeReleaseShutter
    $form.Controls.Add($numWaitBefore)
    $yPos = $yPos + $itemMargin

    Add-Label "撮影後の待機時間 (秒):" $x1Pos $yPos
    $numWaitAfter = New-Object System.Windows.Forms.NumericUpDown
    $numWaitAfter.Location = New-Object System.Drawing.Point($x2Pos, $yPos)
    $numWaitAfter.Maximum = 10
    $numWaitAfter.Value = [int]$settings.WaitAfterReleaseShutter
    $form.Controls.Add($numWaitAfter)
    $yPos = $yPos + $itemMargin

    Add-Label "リトライ回数 (回):" $x1Pos $yPos
    $numRetry = New-Object System.Windows.Forms.NumericUpDown
    $numRetry.Location = New-Object System.Drawing.Point($x2Pos, $yPos)
    $numRetry.Maximum = 10
    $numRetry.Value = [int]$settings.RetryCount
    $form.Controls.Add($numRetry)
    $yPos = $yPos + $itemMargin
    
    $chkDelLimit = New-Object System.Windows.Forms.CheckBox
    $chkDelLimit.Text = "指定期間の経過後に画像を削除 (次回起動時より適用)"
    $chkDelLimit.Location = New-Object System.Drawing.Point($x1Pos, $yPos)
    $chkDelLimit.Size = New-Object System.Drawing.Size(350, 20)
    $chkDelLimit.Checked = [bool]::Parse($settings.EnableDeleteLimit)
    $form.Controls.Add($chkDelLimit)
    $yPos = $yPos + $labelMargin
    Add-Label "ヶ月" ($x2Pos + 40) ($yPos + 3)
    $numDelLimit = New-Object System.Windows.Forms.NumericUpDown
    $numDelLimit.Location = New-Object System.Drawing.Point($x2Pos, $yPos)
    $numDelLimit.Width = 40
    $numDelLimit.Maximum = 12
    $numDelLimit.Value = [int]$settings.DeleteLimitMonth
    $form.Controls.Add($numDelLimit)
    $yPos = $yPos + $itemMargin

    $chkFloating = New-Object System.Windows.Forms.CheckBox
    $chkFloating.Text = "画面上にボタンを表示 (次回起動時より適用)"
    $chkFloating.Location = New-Object System.Drawing.Point($x1Pos, $yPos)
    $chkFloating.Size = New-Object System.Drawing.Size(350, 20)
    $chkFloating.Checked = [bool]::Parse($settings.EnableFloatingButton)
    $form.Controls.Add($chkFloating)
    $yPos = $yPos + $itemMargin

    $chkCloseCam = New-Object System.Windows.Forms.CheckBox
    $chkCloseCam.Text = "撮影ごとにカメラアプリを閉じる"
    $chkCloseCam.Location = New-Object System.Drawing.Point($x1Pos, $yPos)
    $chkCloseCam.Size = New-Object System.Drawing.Size(350, 20)
    $chkCloseCam.Checked = [bool]::Parse($settings.CloseCamera)
    $form.Controls.Add($chkCloseCam)
    $yPos = $yPos + $itemMargin

    $chkMinCam = New-Object System.Windows.Forms.CheckBox
    $chkMinCam.Text = "撮影ごとにカメラアプリを最小化する"
    $chkMinCam.Location = New-Object System.Drawing.Point($x1Pos, $yPos)
    $chkMinCam.Size = New-Object System.Drawing.Size(350, 20)
    $chkMinCam.Checked = [bool]::Parse($settings.MinimizeCamera)
    $form.Controls.Add($chkMinCam)
    $yPos = $yPos + $itemMargin
    
    $chkAddName = New-Object System.Windows.Forms.CheckBox
    $chkAddName.Text = "薬歴アプリで開いている患者名をファイル名に追加する"
    $chkAddName.Location = New-Object System.Drawing.Point($x1Pos, $yPos)
    $chkAddName.Size = New-Object System.Drawing.Size(300, 20)
    $chkAddName.Checked = [bool]::Parse($settings.AddPatientName)
    $form.Controls.Add($chkAddName)

    # ------------------------------
    # ボタン作成
    # ------------------------------
    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "保存して閉じる"
    $btnSave.Location = New-Object System.Drawing.Point($xButtonPos, $yButtonPos)
    $btnSave.Size = New-Object System.Drawing.Size(200, 40)
    $btnSave.DialogResult = "OK"
    $form.Controls.Add($btnSave)

    # ------------------------------
    # 保存して閉じられた場合の処理
    # ------------------------------
    if ($form.ShowDialog() -eq "OK") {
        $settings.DestinationPath = $txtDestPath.Text
        $settings.WaitBeforeReleaseShutter = $numWaitBefore.Value
        $settings.WaitAfterReleaseShutter = $numWaitAfter.Value
        $settings.RetryCount = $numRetry.Value
        $settings.EnableDeleteLimit = $chkDelLimit.Checked
        $settings.DeleteLimitMonth = $numDelLimit.Value
        $settings.EnableFloatingButton = $chkFloating.Checked
        $settings.CloseCamera = $chkCloseCam.Checked
        $settings.MinimizeCamera = $chkMinCam.Checked
        $settings.AddPatientName = $chkAddName.Checked
        Set-IniSettings -iniPath $iniPath -settings $settings
    }
}

Export-ModuleMember -Function Show-SettingDialog