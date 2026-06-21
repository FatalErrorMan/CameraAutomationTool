# ==============================
# プリディレクティブ
# ==============================
Import-Module "$PSScriptRoot\modules\Config.psm1"
Import-Module "$PSScriptRoot\modules\UIControl.psm1"
Import-Module "$PSScriptRoot\modules\LowLevelControl.psm1"
Import-Module "$PSScriptRoot\modules\FloatingButton.psm1"
Import-Module "$PSScriptRoot\modules\SettingDialog.psm1"

# ==============================
# iniファイル読み込み設定
# ==============================
$iniPath = Join-Path $PSScriptRoot "設定.ini"
$settings = Get-IniSettings $iniPath

# ==============================
# カメラアプリ用情報
# ==============================
$processName = "WindowsCamera"
$targetTitle = "カメラ"
$cameraRollPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyPictures"), "Camera Roll")

# ==============================
# 古いファイルの削除
# ==============================
# $settings.DestinationPath直下のサブフォルダを対象
# $settings.DeleteLimitMonthで指定したより古いファイルを削除
if($settings.EnableDeleteLimit) {
    # 今月1日の 00:00:00 を取得
    $firstDayOfThisMonth = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    
    # 判定ライン：今月1日から指定月数前を対象とする
    $thresholdDate = $firstDayOfThisMonth.AddMonths(1 - $settings.DeleteLimitMonth)
    
    # 削除処理
    $isDeleted = $false
    Get-ChildItem -Path $settings.DestinationPath -Directory | 
        Where-Object { $_.CreationTime -lt $thresholdDate } | 
        ForEach-Object {
            Write-Host "削除: [$($_.Name)] (作成日: $($_.CreationTime))" -ForegroundColor Yellow
            # -Recurseオプションで中身も同時に削除
            $_ | Remove-Item -Recurse -Force
            $isDeleted = $true
        }
        
    # 削除が発生したときだけ、基準月を通知
    if ($isDeleted) {
        [System.Windows.Forms.MessageBox]::Show("$($thresholdDate.AddMonths(-1).ToString("yyyy年M月"))以前のフォルダを削除しました。", "ワンタッチ撮影")
    }
}

# ==============================
# メインロジック
# ==============================
function Start-CaptureProcess {
    # ------------------------------
    # カメラアプリの起動
    # ------------------------------
    # UWPアプリ特有のサスペンドによって、最小化中のプロセスが拾えない問題があるため
    # 起動の有無にかかわらず起動コマンドを直接叩いてアクティブ化するのがベスト
    Write-Host "カメラアプリを起動します..." -ForegroundColor Yellow
    Start-Process "microsoft.windows.camera:"
    
    # 撮影前の待機(秒)
    Start-Sleep -Seconds $settings.WaitBeforeReleaseShutter
    
    # カメラモードになっているか確認
    if (!(Confirm-PhotoMode)) {
        Write-Error "カメラモードへの切り替えに失敗しました。"
        [System.Windows.Forms.MessageBox]::Show("カメラモードへの切り替えに失敗しました。", "ワンタッチ撮影")
        return
    }
    
    # ------------------------------
    # 撮影
    # ------------------------------
    for ($i = 0; $i -le $settings.RetryCount) {
        Write-Host "試行 $($i+1)回目" -ForegroundColor Gray
        
        # 撮影前のカメラロール内にある最新の画像を取得
        $beforeSnap = Get-ChildItem -Path $cameraRollPath -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1

        # 撮影ボタンをクリック
        $photoButton = Get-AutomationElement -AutomationId "CaptureButton_0"
        if ($photoButton) { Invoke-AutomationElement $photoButton }
        Write-Host "撮影完了、保存処理待ち..." -ForegroundColor Cyan
        
        # 撮影後の待機(秒)
        Start-Sleep -Seconds $settings.WaitAfterReleaseShutter

        # 撮影後のカメラロール内にある最新の画像を取得
        $afterSnap = Get-ChildItem -Path $cameraRollPath -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1

        # 撮影前後のカメラロール内の最新画像を比較し、異なる場合は撮影成功と判定してファイルを移動
        if ($afterSnap -and ($null -eq $beforeSnap -or $beforeSnap.FullName -ne $afterSnap.FullName)) {
            
            # 保存フォルダ名を生成
            $dateFolder = Get-Date -Format "yyyy-MM-dd"
            $targetDir = Join-Path $settings.DestinationPath $dateFolder
            
            # 保存ファイル名を生成
            # $settings.AddPatientNameがTrueの場合は患者名も付加
            $snapName = (Get-Date -Format "HH-mm-ss")
            if($settings.AddPatientName) {
                # Chromeのプロセスを取得
                $chromeProcess = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" }
                # メインウィンドウのタイトルから患者名を抜き出し
                if ($chromeProcess) {
                    $title = $chromeProcess[0].MainWindowTitle
                    if($title -match '【(.+)】.*') { $snapName = $snapName + "_$($Matches[1])" }
                    else { Write-Host "薬歴アプリから患者名を取得できませんでした。患者名を付加せずに保存します。" -ForegroundColor Cyan }
                } else {
                    Write-Host "ブラウザが起動していません。患者名を付加せずに保存します。" -ForegroundColor Cyan
                }
            }
            $snapName = $snapName + $afterSnap.Extension
            
            # 保存先への移動
            if (-not (Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory | Out-Null }
            try {
                $renamedSnap = Rename-Item -Path $afterSnap.FullName -NewName $snapName -PassThru
                Move-Item -Path $renamedSnap.FullName -Destination $targetDir -Force -ErrorAction Stop
                Write-Host "保存完了: $($renamedSnap.Name)" -ForegroundColor Magenta
            } catch {
                Write-Warning "ファイルの移動に失敗しました。アプリがロックしている可能性があります。"
            }
            $cameraResult = $true
            break
        }
        $cameraResult = $false
    }
    
    # 撮影失敗の場合はメッセージを表示
    if (!$cameraResult) {
        Write-Warning "すべてのリトライに失敗しました。"
        [System.Windows.Forms.MessageBox]::Show("撮影に失敗しました。", "ワンタッチ撮影")
    }

    # ------------------------------
    # 終了処理(または最小化)
    # ------------------------------
    $cameraProcess = Get-Process -Name $processName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cameraProcess -and $settings.CloseCamera) {
        Write-Host "カメラアプリを終了しています..." -ForegroundColor Gray
        $cameraProcess | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "カメラアプリの終了が完了しました。" -ForegroundColor Magenta
    } elseif ($cameraProcess -and (-not $settings.CloseCamera) -and $settings.MinimizeCamera) {
        Write-Host "カメラを最小化します..." -ForegroundColor Gray
        Set-WindowMinimize
    }
}

# ==============================
# 最前面ボタンの有無によるメインロジックの実行制御
# ==============================
if ($settings.EnableFloatingButton) {
    Write-Host "常駐ボタンモードで起動しました。"
    $windowInfoResult = Show-FloatingButton `
        -OnClickAction { Start-CaptureProcess } `
        -OnClickSettingAction { param ($iniPath, $settings) Show-SettingDialog -iniPath $iniPath -settings $settings } `
        -iniPath $iniPath `
        -settings $settings
    
    # 返却されたウィンドウの情報を設定に書き戻し
    $settings.WindowX = $windowInfoResult.WindowX
    $settings.WindowY = $windowInfoResult.WindowY
    $settings.Width = $windowInfoResult.Width
    $settings.Height = $windowInfoResult.Height
    Set-IniSettings $iniPath $settings
} else {
    Start-CaptureProcess
}