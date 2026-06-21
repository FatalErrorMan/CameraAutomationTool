# ==============================
# プリディレクティブ
# ==============================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==============================
# 最前面ボタンの表示
# ==============================
function Show-FloatingButton {
    param ([scriptblock]$OnClickAction, [scriptblock]$OnClickSettingAction, [string]$iniPath, [hashtable]$settings)

    # ------------------------------
    # フォーム設定
    # ------------------------------
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "ワンタッチ撮影"
    $form.StartPosition = "Manual"
    $form.Location = New-Object System.Drawing.Point($settings.WindowX, $settings.WindowY)
    $form.Size = New-Object System.Drawing.Size($settings.Width, $settings.Height)
    $form.TopMost = $true
    $form.Opacity = 1.0
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::SizableToolWindow
    
    # ------------------------------
    # ボタン設定
    # ------------------------------
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "撮影"
    $btn.Font = New-Object System.Drawing.Font("Meiryo UI", 16, [System.Drawing.FontStyle]::Bold)
    $btn.Dock = "Fill"
    $btn.BackColor = [System.Drawing.Color]::LightGray
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    # 左クリック: 撮影
    $btn.Add_Click({
        $btn.Enabled = $false
        $btn.Text = "処理中"
        $btn.BackColor = [System.Drawing.Color]::DarkGray
        try {
            & $OnClickAction
        } finally {
            $btn.Enabled = $true
            $btn.Text = "撮影"
            $btn.BackColor = [System.Drawing.Color]::LightGray
        }
    })
    # 右クリック: コンテクストメニュー(設定/終了)
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $settingItem = $contextMenu.Items.Add("設定")
    $settingItem.Add_Click({
        & $OnClickSettingAction -iniPath $iniPath -settings $settings
    })
    $closingItem = $contextMenu.Items.Add("終了")
    $closingItem.Add_Click({ $form.Close() })
    $btn.ContextMenuStrip = $contextMenu
    
    # ------------------------------
    # 表示
    # ------------------------------
    $form.Controls.Add($btn)
    $form.ShowDialog()
    
    # 閉じるときに位置・サイズを返却
    return @{
        WindowX = $form.Location.X
        WindowY = $form.Location.Y
        Width = $form.Size.Width
        Height = $form.Size.Height
    }
}

# ==============================
# モジュールとして外部に以下の関数名のみを公開
# ==============================
Export-ModuleMember -Function Show-FloatingButton
