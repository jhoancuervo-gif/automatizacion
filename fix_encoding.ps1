$p1 = 'c:\Users\Administrador\Desktop\PRUEBAS\check_puerto_poe.ps1'
$t1 = [IO.File]::ReadAllText($p1, [Text.Encoding]::UTF8)
Set-Content -Path $p1 -Value $t1 -Encoding UTF8

$p2 = 'c:\Users\Administrador\Desktop\PRUEBAS\menu_principal.ps1'
$t2 = [IO.File]::ReadAllText($p2, [Text.Encoding]::UTF8)
Set-Content -Path $p2 -Value $t2 -Encoding UTF8

$p3 = 'c:\Users\Administrador\Desktop\PRUEBAS\scripts_orbes_nuevas\menu_orbes_nuevas.ps1'
$t3 = [IO.File]::ReadAllText($p3, [Text.Encoding]::UTF8)
Set-Content -Path $p3 -Value $t3 -Encoding UTF8

$p4 = 'c:\Users\Administrador\Desktop\PRUEBAS\scripts_orbe_reintegro\menu_orbes_rein.ps1'
$t4 = [IO.File]::ReadAllText($p4, [Text.Encoding]::UTF8)
Set-Content -Path $p4 -Value $t4 -Encoding UTF8
