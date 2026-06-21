@rem ==============================
@rem スクリプト起動用のランチャーをコンパイル
@rem (Windows標準C#コンパイラを利用)
@rem ==============================
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /r:System.Windows.Forms.dll /win32icon:%~dp0ワンタッチ撮影.ico /out:%~dp0ワンタッチ撮影.exe %~dp0Launcher.cs