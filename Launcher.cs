// ==============================
// プリディレクティブ
// ==============================
using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms; // タスクバーピン止めメッセージボックス用
using System.Linq;          // 起動時オプション引数チェック用

// ==============================
// メイン
// ==============================
class Launcher {
    // エントリポイント
    static void Main(string[] args) {
        // セットアップモードが有効かオプション引数を確認
        bool enableSetupMode = args.Contains("/setup");
        
        // パス設定
        string scriptHost = "powershell.exe";
        string exePath = AppDomain.CurrentDomain.BaseDirectory;
        string scriptPath = Path.Combine(exePath, "TakePhoto.ps1");
        string scriptArguments = "-ExecutionPolicy Bypass -File " + scriptPath;
        
        // プロセス設定
        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = scriptHost;
        startInfo.Arguments = scriptArguments;
        startInfo.WorkingDirectory = exePath;
        startInfo.CreateNoWindow = true;
        startInfo.UseShellExecute = false;
        
        // モード切替
        if (enableSetupMode) {
            // セットアップモード: MessageBoxを表示して、右クリックでのピン留めを促す
            startInfo.WindowStyle = ProcessWindowStyle.Normal;
            MessageBox.Show("タスクバーのアイコンを右クリックしてピン留めしてください。\n終了後、この画面を閉じてください。", "タスクバーへのピン留め");
        } else {
            // 通常モード: TakePhoto.ps1を起動
            startInfo.WindowStyle = ProcessWindowStyle.Hidden;
            Process.Start(startInfo);
        }
    }
}