# Importar el archivo CSV
$csvFile = "C:\Users\Administrador\Desktop\DatosUsuarios.csv"

# Dominio base de Active Directory
$baseDN = "DC=Aitex-33,DC=lan"

# Leer el archivo CSV
$usuarios = Import-Csv -Path $csvFile -Delimiter "," -Encoding UTF8

# Crear cada usuario
foreach ($usuario in $usuarios) {
    # Validar que el campo "usuario" no esté vacío o tenga un formato inválido
    if ([string]::IsNullOrWhiteSpace($usuario.usuario) -or $usuario.usuario -match '[^a-zA-Z0-9_]') {
        Write-Host "Error: El nombre de usuario '$($usuario.usuario)' tiene un formato incorrecto. O está vacío o contiene caracteres no permitidos."
        continue
    }

    # Validar que el campo "dni" no esté vacío
    if ([string]::IsNullOrWhiteSpace($usuario.dni)) {
        Write-Host "Error: El DNI para el usuario '$($usuario.usuario)' está vacío."
        continue
    }

    # Crear la contraseña en el formato Aitex@<dni>
    $password = "Aitex@$($usuario.dni)"

    # Construir la OU basada en el departamento, solo añadir "-33" a "Empresa" no a los departamentos
    $ouBase = "OU=Empresa-33,$baseDN"

    # Validar que el departamento existe como subOU de Empresa-33
    $ou = "OU=$($usuario.departamento),$ouBase"  # Suponiendo que el campo "departamento" coincide con las subOUs bajo "Empresa-33"
    
    # Comprobar si la OU del departamento existe
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ou'" -ErrorAction SilentlyContinue)) {
        Write-Host "La OU $ou no existe. Creándola..."
        New-ADOrganizationalUnit -Name "$($usuario.departamento)" -Path $ouBase
    }

    # Nombre completo del usuario
    $nombreCompleto = "$($usuario.nombre) $($usuario.apellido1) $($usuario.apellido2)"
    
    # Ruta DN del usuario
    $dnUsuario = "CN=$nombreCompleto,$ou"

    # Crear el usuario
    try {
        New-ADUser -SamAccountName $usuario.usuario `
                   -UserPrincipalName "$($usuario.usuario)@Aitex-33.lan" `
                   -Name $nombreCompleto `
                   -GivenName $usuario.nombre `
                   -Surname "$($usuario.apellido1) $($usuario.apellido2)" `
                   -Description $usuario.descrip `
                   -Department $usuario.departamento `
                   -EmployeeID $usuario.dni `
                   -Path $ou `
                   -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
                   -Enabled $true
        
        Write-Host "Usuario $nombreCompleto creado con éxito en $ou."
    } catch {
        Write-Host "Error al crear el usuario ${nombreCompleto}: $($_.Exception.Message)"
    }
}

