Import-Module ActiveDirectory

# Función para limpiar DNI de caracteres no válidos para nombres de usuario
function CleanDNI {
    param([string]$dni)
    return ($dni -replace '[^a-zA-Z0-9]', '')
}

# Ruta base de las OU
$baseOU = "DC=barcelona,DC=lan"

# Password por defecto (puedes cambiarla aquí)
$defaultPassword = ConvertTo-SecureString "Batoi@1234" -AsPlainText -Force

# Dominio para el UPN
$domain = "barcelona.lan"

# Importar CSV
$usuarios = Import-Csv -Path ".\usuarios.csv"

foreach ($u in $usuarios) {
    if ($u.dept -eq "Barcelona") {
        $nombre = $u.nom
        $cognom1 = $u.cognom1
        $cognom2 = $u.cognom2
        $dni = $u.dni
        $sede = $u.sede
        $dept = $u.dept

        # Limpiar DNI
        $dniClean = CleanDNI $dni

        # Construir la OU donde buscar según sede y departamento
        # Ejemplo: OU=Gerencia,OU=Empresa,DC=barcelona,DC=lan
        # Ajusta si la estructura tiene otra raíz
        $userOU = "OU=$dept,OU=Empresa,$baseOU"

        # Buscar usuario por nombre para mostrar (DisplayName)
        $displayNameSearch = "$nombre $cognom1 $cognom2"

        $usuario = Get-ADUser -Filter {Name -eq $displayNameSearch} -SearchBase $userOU -Properties SamAccountName,UserPrincipalName,DistinguishedName

        if ($usuario) {
            try {
                # Modificar usuario
                Set-ADUser -Identity $usuario.DistinguishedName `
                    -SamAccountName $dniClean `
                    -UserPrincipalName "$dniClean@$domain" `
                    -DisplayName $displayNameSearch

                # Cambiar contraseña
                Set-ADAccountPassword -Identity $usuario.DistinguishedName -Reset -NewPassword $defaultPassword

                # Forzar cambio de contraseña en el próximo inicio de sesión
                Set-ADUser -Identity $usuario.DistinguishedName -ChangePasswordAtLogon $true

                Write-Host "Actualizado usuario: $displayNameSearch con SamAccountName y UPN $dniClean"
            }
            catch {
                Write-Warning "Error actualizando usuario $displayNameSearch: $_"
            }
        }
        else {
            Write-Warning "Usuario no encontrado: $displayNameSearch en OU $userOU"
        }
    }
}
