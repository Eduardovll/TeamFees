$password = "(KwYg4)30b"
$libs = @(
    "libc.so.6",
    "libgcc_s.so.1",
    "libpthread.so.0",
    "libdl.so.2",
    "libm.so.6",
    "libz.so.1"
)

$destPath = "C:\Users\Eduardo.Valle\Documents\Embarcadero\Studio\SDKs\ubuntu22.04.sdk\lib\x86_64-linux-gnu"

foreach ($lib in $libs) {
    Write-Host "Copying $lib..."
    echo $password | & scp -P 22 "administrator@204.12.218.78:/lib/x86_64-linux-gnu/$lib" "$destPath\"
}

Write-Host "Done!"
