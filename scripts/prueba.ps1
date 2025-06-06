Import-Module ActiveDirectory

$csvPath = "C:\ruta\usuarios.csv"
$defaultPassword = ConvertTo-SecureString "Batoi@1234" -AsPlainText -Force

# Estructura base del dominio
$domain = "barcelona.lan"

# Mapeo sede a OU base (según estructura)
$baseOU = "OU=Empresa,DC=barcelona,DC=lan"

# Leer CSV
$usuarios = Import-Csv -Path $csvPath

foreach ($u in $usuarios) {
    $sede = $u.sede
    $dept = $u.dept
    $dni = $u.dni

    # Construir ruta OU para el usuario (p.ej. "OU=Gerencia,OU=Barcelona,OU=Empresa,DC=barcelona,DC=lan")
    $userOU = "OU=$dept,OU=$sede,$baseOU"

    # Buscar usuario por employeeID (dni) en esa OU
    $usuario = Get-ADUser -Filter { employeeID -eq $dni } -SearchBase $userOU -Properties SamAccountName -ErrorAction SilentlyContinue

    if ($usuario) {
        Write-Output "Modificando usuario $($usuario.SamAccountName) en sede $sede, dept $dept"

        # Cambiar SamAccountName y UserPrincipalName
        $newUPN = "$dni@$domain"

        Set-ADUser -Identity $usuario.DistinguishedName `
                   -SamAccountName $dni `
                   -UserPrincipalName $newUPN

        # Cambiar contraseña y forzar cambio
        Set-ADAccountPassword -Identity $usuario.DistinguishedName -Reset -NewPassword $defaultPassword
        Set-ADUser -Identity $usuario.DistinguishedName -ChangePasswordAtLogon $true
    }
    else {
        Write-Warning "Usuario con DNI $dni no encontrado en OU $userOU"
    }
}
