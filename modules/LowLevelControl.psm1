# ==============================
# Win32APIの使用準備
# ==============================
# (@"～"@はヒアドキュメント形式)
$Win32ApiFunctions = @"
[DllImport("user32.dll")]
public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);

[DllImport("user32.dll")]
public static extern bool SetForegroundWindow(IntPtr hWnd);

[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
"@

# 列挙したWin32API関数をセッション内でコンパイル
# 以後、名前空間 Win32Api 内の Win32ApiNative クラスとしてこれら関数を使用可能
Add-Type -MemberDefinition $Win32ApiFunctions -Name "Win32ApiNative" -Namespace "Win32Api"

# ==============================
# ウィンドウを最小化する関数
# ==============================
function Set-WindowMinimize {
    # カメラアプリのウィンドウハンドルを取得
    $hWnd = [Win32Api.Win32ApiNative]::FindWindow("ApplicationFrameWindow", "カメラ")
    if ($hWnd -ne [IntPtr]::Zero) {
        
        # 強制的にアクティブにする
        [Win32Api.Win32ApiNative]::SetForegroundWindow($hWnd) | Out-Null
        Start-Sleep -Milliseconds 200 # 安定のために一瞬待機
        
        # 仮想キーコード
        $VK_LWIN = 0x5B
        $VK_DOWN = 0x28
        $KEYEVENTF_KEYUP = 0x0002

        # Winキー押下
        [Win32Api.Win32ApiNative]::keybd_event($VK_LWIN, 0, 0, 0)
        # 下矢印押下
        [Win32Api.Win32ApiNative]::keybd_event($VK_DOWN, 0, 0, 0)
        # 下矢印離す
        [Win32Api.Win32ApiNative]::keybd_event($VK_DOWN, 0, $KEYEVENTF_KEYUP, 0)
        # Winキー離す
        [Win32Api.Win32ApiNative]::keybd_event($VK_LWIN, 0, $KEYEVENTF_KEYUP, 0)
    } else {
        Write-Warning "最小化対象のカメラアプリウィンドウが見つかりませんでした。"
    }
}

# ==============================
# モジュールとして外部に以下の関数名のみを公開
# ==============================
Export-ModuleMember -Function Set-WindowMinimize
