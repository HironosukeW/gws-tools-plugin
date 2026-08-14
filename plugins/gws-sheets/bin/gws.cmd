@echo off
rem gws ラッパー（PowerShell / コマンドプロンプト用）
rem プラグイン設定に入力された OAuth クライアント情報を gws が読む環境変数へ渡してから、
rem 同じディレクトリの本体を呼び出す。これにより client_secret.json の配置が不要になる。
setlocal
if defined CLAUDE_PLUGIN_OPTION_CLIENT_ID set "GOOGLE_WORKSPACE_CLI_CLIENT_ID=%CLAUDE_PLUGIN_OPTION_CLIENT_ID%"
if defined CLAUDE_PLUGIN_OPTION_CLIENT_SECRET set "GOOGLE_WORKSPACE_CLI_CLIENT_SECRET=%CLAUDE_PLUGIN_OPTION_CLIENT_SECRET%"
"%~dp0gws-bin.exe" %*
exit /b %ERRORLEVEL%
