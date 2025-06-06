Import-Module ActiveDirectory

# Ruta del CSV con DNIs válidos
$csvPath = "C:\ruta\usuarios.csv"

# Leer DNIs válidos del CSV
$dnivalidos = Import-Csv -Path $csvPath | Select-Object -ExpandProperty DNI

# Buscar todos los usuarios en OU=Empresa y sub-OUs
$usuariosAD = Get-ADUser -Filter * -SearchBase "OU=Empresa,DC=barcelona,DC=lan" -SearchScope Subtree -Properties employeeID

foreach ($usuario in $usuariosAD) {
    $dniUsuario = $usuario.employeeID

    if (-not $dniUsuario) {
        Write-Warning "Usuario $($usuario.SamAccountName) no tiene DNI asignado. No se eliminará."
        continue
    }

    if ($dnivalidos -notcontains $dniUsuario) {
        Write-Output "Eliminando usuario NO listado en CSV: $($usuario.SamAccountName) con DNI $dniUsuario"

        # Eliminar usuario del AD
        # Primero, comentar esta línea y probar con -WhatIf para simular
        # Remove-ADUser -Identity $usuario.DistinguishedName -Confirm:$false

        # Para simular la eliminación sin borrarlo, usa:
        Remove-ADUser -Identity $usuario.DistinguishedName -Confirm:$false -WhatIf
    }
}
