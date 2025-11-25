Add-Type -AssemblyName System.Net.HttpListener
$h = New-Object System.Net.HttpListener
$h.Prefixes.Add('http://localhost:9000/')
$h.Start()
Write-Host "Servidor iniciado em http://localhost:9000/"
while ($h.IsListening) {
    $context = $h.GetContext()
    $localPath = $context.Request.Url.LocalPath.TrimStart('/')
    if ($localPath -eq '') { $localPath = 'index.html' }
    $filePath = Join-Path (Get-Location) $localPath
    if (Test-Path $filePath) {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $context.Response.ContentType = 'text/html'
        switch -Regex ($filePath) {
            '\.js$'   { $context.Response.ContentType = 'application/javascript' }
            '\.css$'  { $context.Response.ContentType = 'text/css' }
            '\.yaml$' { $context.Response.ContentType = 'application/x-yaml' }
            '\.yml$'  { $context.Response.ContentType = 'application/x-yaml' }
            '\.png$'  { $context.Response.ContentType = 'image/png' }
        }
        $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    }
    else {
        $context.Response.StatusCode = 404
        $error = [System.Text.Encoding]::UTF8.GetBytes("Arquivo não encontrado: $filePath")
        $context.Response.OutputStream.Write($error, 0, $error.Length)
    }
    $context.Response.OutputStream.Close()
}
