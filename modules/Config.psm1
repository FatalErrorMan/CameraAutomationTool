# ==============================
# プリディレクティブ
# ==============================
Import-Module "$PSScriptRoot\Config.psm1"
Add-Type -AssemblyName System.Windows.Forms

# ==============================
# iniファイル読み込み
# ==============================
function Get-IniSettings {
    param ([string]$iniPath)
    
    # ハッシュテーブルをデフォルト値で初期化
    $settings = @{
        DestinationPath = "C:\Users\User\Pictures\Camera Roll"
        WaitBeforeReleaseShutter = 1
        WaitAfterReleaseShutter = 1
        RetryCount = 4
        EnableDeleteLimit = $true
        DeleteLimitMonth = 6
        EnableFloatingButton = $true
        CloseCamera = $false
        MinimizeCamera = $true
        AddPatientName = $true
        WindowX = 10
        WindowY = 10
        Width = 100
        Height = 120
    }
    
    if (Test-Path $iniPath) {
        # iniを読み込み、「"="がある行かつ先頭が";"でない行」でフィルタリング
        # その後1行ずつForEachで処理
        Get-Content $iniPath | Where-Object { $_ -match '=' -and $_ -notmatch '^;' } | ForEach-Object {
            # "="で文字列をkeyとvalueに分割して多重代入
            $key, $value = $_.Split('=', 2)
            # 設定値を反映、値が存在しない場合はデフォルト値が活かされる
            if ($key -and $value) {
                $settings[$key] = $value
            }
        }
        # 読み込んだ設定を型変換
        $settings.WaitBeforeReleaseShutter = [int]::Parse($settings.WaitBeforeReleaseShutter)
        $settings.WaitAfterReleaseShutter = [int]::Parse($settings.WaitAfterReleaseShutter)
        $settings.RetryCount = [int]::Parse($settings.RetryCount)
        $settings.EnableDeleteLimit = [bool]::Parse($settings.EnableDeleteLimit)
        $settings.DeleteLimitMonth = [int]::Parse($settings.DeleteLimitMonth)
        $settings.EnableFloatingButton = [bool]::Parse($settings.EnableFloatingButton)
        $settings.CloseCamera = [bool]::Parse($settings.CloseCamera)
        $settings.MinimizeCamera = [bool]::Parse($settings.MinimizeCamera)
        $settings.AddPatientName = [bool]::Parse($settings.AddPatientName)
        $settings.WindowX = [int]::Parse($settings.WindowX)
        $settings.WindowY = [int]::Parse($settings.WindowY)
        $settings.Width= [int]::Parse($settings.Width)
        $settings.Height= [int]::Parse($settings.Height)
        
        # 画面サイズを取得し、不適切な値をフィルタリング
        $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
        if ($settings.WindowX + $settings.Width -gt $primaryScreen.Bounds.Width) {
            $settings.WindowX = $primaryScreen.Bounds.Width - $settings.Width;
        } elseif ($settings.WindowX -lt 0) {
            $settings.WindowX = 0;
        }
        if ($settings.WindowY + $settings.Height -gt $primaryScreen.Bounds.Height) {
            $settings.WindowY = $primaryScreen.Bounds.Height - $settings.Height;
        } elseif ($settings.WindowY -lt 0) {
            $settings.WindowY = 0;
        }
    }
    return $settings
}

# ==============================
# iniファイル書き込み
# ==============================
function Set-IniSettings {
    param ([string]$iniPath, [hashtable]$settings)
    
    # 画面サイズを取得し、不適切な値をフィルタリング
    $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    if ($settings.WindowX + $settings.Width -gt $primaryScreen.Bounds.Width) {
        $settings.WindowX = $primaryScreen.Bounds.Width - $settings.Width;
    } elseif ($settings.WindowX -lt 0) {
        $settings.WindowX = 0;
    }
    if ($settings.WindowY + $settings.Height -gt $primaryScreen.Bounds.Height) {
        $settings.WindowY = $primaryScreen.Bounds.Height - $settings.Height;
    } elseif ($settings.WindowY -lt 0) {
        $settings.WindowY = 0;
    }
        
    # コメントも含めてiniファイルに書き込むため、ヒアドキュメント形式を利用
    $content = @"
;【設定ファイル】
;設定.iniを直接編集する場合は、アプリが起動していない状態にしてください。
;アプリ起動中は、右クリックメニューの「設定」から編集可能です。
;
;撮影画像の保存先を指定してください。
DestinationPath=$($settings.DestinationPath)
;
;カメラのシャッターが切れる前に終了してしまう場合は
;こちらの値を大きくしてみてください。(ミリ秒)
WaitBeforeReleaseShutter=$($settings.WaitBeforeReleaseShutter)
;
;撮影後の画像が日付フォルダにうまく移動されない場合は
;こちらの値を大きくしてみてください。(ミリ秒)
WaitAfterReleaseShutter=$($settings.WaitAfterReleaseShutter)
;
;最初のシャッターでうまく撮影できなかった場合に
;リトライする回数を設定できます。
RetryCount=$($settings.RetryCount)
;
;保存先に存在する○ヶ月前のフォルダを削除する機能を有効にします。
EnableDeleteLimit=$($settings.EnableDeleteLimit)
;
;以下で指定したよりも古いフォルダを削除します。
DeleteLimitMonth=$($settings.DeleteLimitMonth)
;
;最前面に実行ボタンを表示できます。(True / False)
EnableFloatingButton=$($settings.EnableFloatingButton)
;
;カメラアプリを都度閉じます。(True / False)
CloseCamera=$($settings.CloseCamera)
;
;カメラアプリを閉じない場合に最小化します。(True / False)
MinimizeCamera=$($settings.MinimizeCamera)
;
;撮影時に薬歴アプリで開かれている患者名をファイル名に追加します。(True / False)
AddPatientName=$($settings.AddPatientName)
;
;表示位置
WindowX=$($settings.WindowX)
WindowY=$($settings.WindowY)
;
;表示サイズ
Width=$($settings.Width)
Height=$($settings.Height)
"@

    $content | Out-File $iniPath -Encoding utf8
}

# ==============================
# モジュールとして外部に以下の関数名のみを公開
# ==============================
Export-ModuleMember -Function Get-IniSettings, Set-IniSettings