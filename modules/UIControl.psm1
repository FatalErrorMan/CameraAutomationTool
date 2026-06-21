# ==============================
# プリディレクティブ
# ==============================
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# ==============================
# カメラアプリのAutomationIDから要素を検索
# ==============================
function Get-AutomationElement {
    param (
        [Parameter(Mandatory=$true)] $AutomationId,
        [double]$TimeoutSec = 3
    )

    # カメラアプリの検索元を定義
    $root = [System.Windows.Automation.AutomationElement]::RootElement
    $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, "カメラ")
    
    # カメラアプリウィンドウの取得
    $window = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $condition)
    if (-not $window) { return $null }

    # 指定したIDの要素を取得
    $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty, $AutomationId)
    return $window.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condition)
}

# ==============================
# 指定した要素をクリック
# ==============================
function Invoke-AutomationElement {
    param ($Element)
    
    if ($Element) {
        $pattern = $Element.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
        $pattern.Invoke()
        return $true
    }
    return $false
}

# ==============================
# カメラモードの確認・変更
# ==============================
function Confirm-PhotoMode {
    
    # カメラモードかどうかを判定
    $photoButton = Get-AutomationElement -AutomationId "CaptureButton_0"
    if ($photoButton) {
        if ($photoButton.Current.Name -eq "写真を撮影") {
            Write-Host "現在、写真モードです。" -ForegroundColor Green
            return $true
        } else {
            # カメラボタンをクリックして切り替え
            Write-Host "写真モード以外を検知。写真モードに切り替えます..." -ForegroundColor Yellow
            Invoke-AutomationElement $photoButton
            Start-Sleep -Milliseconds 1000 # 切替待機
        }
        return $true
    }
    Write-Warning "モードの判定に失敗しました。"
    return $false
}

# ==============================
# モジュールとして外部に以下の関数名のみを公開
# ==============================
Export-ModuleMember -Function Get-AutomationElement, Invoke-AutomationElement, Confirm-PhotoMode