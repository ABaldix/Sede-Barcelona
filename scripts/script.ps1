#------------------#
# Leer fichero CSV #
#------------------#
$usuarios = Import-Csv "./usuaris.csv"

Foreach ($usuario in $usuarios) {
    $nom = $usuario.nom
    $apellido1 = $usuario.cognom1
    $apellido2 = $usuario.cognom2
    $dni = $usuario.dni
    $sede = $usuario.sede
    $departamento = $usuario.dept
    $descripcion = $usuario.descrip

    # Username variables
    $usrName = ($nom.Substring(0,1) + $apellido1).ToLower()
    $displayName = "$nom $apellido1 $apellido2"

    Write-Host ""
    Write-Host "[USUARIO] " -ForegroundColor Blue -NoNewline
    Write-Host "Creando usuario $usrName con su departamento $departamento..."

    # Variables para OU y grupos
    $ouString = "OU=$departamento,OU=Empresa,DC=barcelona,DC=lan"
    $getOU = Get-ADOrganizationalUnit -SearchBase $ouString -Filter {Name -eq $departamento} -ErrorAction SilentlyContinue

    #--------------------------------------------#
    # Comprobar si existe su grupo, si no crealo #
    #--------------------------------------------#
    
    # Grupo base para el departamento
    $grp = "gg" + $departamento
    $getGg = Get-ADGroup -SearchBase $ouString -Filter {Name -eq $grp} -ErrorAction SilentlyContinue

    # Si el usuario es jefe, usamos grupo específico
    if ($descripcion -eq "Jefe") {
        $grp = "ggJefe" + $departamento
        $jefeOUString = "OU=$departamento,OU=Empresa,DC=barcelona,DC=lan"
        $getJefeGg = Get-ADGroup -SearchBase $jefeOUString -Filter {Name -eq $grp} -ErrorAction SilentlyContinue

        if ($getJefeGg -eq $null) {
            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "No existe un grupo para el jefe del departamento $departamento, creándolo ahora..."
            
            try {
                New-ADGroup -Name $grp -GroupScope Global -Path $jefeOUString -SamAccountName $grp
                Write-Host "[GG] " -ForegroundColor Green -NoNewline
                Write-Host "Grupo $grp creado con éxito, continuando..."
            } catch {
                Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
                Write-Host "Error creando grupo $grp: $($_.Exception.Message)"
                continue
            }
        } else {
            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "Ya existe un grupo para el jefe del departamento $departamento, continuando..."
        }
    } else {
        if ($getGg -eq $null) {
            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "No existe un grupo para el departamento $departamento, creándolo ahora..."

            try {
                New-ADGroup -Name $grp -GroupScope Global -Path $ouString -SamAccountName $grp
                Write-Host "[GG] " -ForegroundColor Green -NoNewline
                Write-Host "Grupo $grp creado con éxito, continuando..."
            } catch {
                Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
                Write-Host "Error creando grupo $grp: $($_.Exception.Message)"
                continue
            }
        } else {
            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "Ya existe un grupo para el departamento $departamento, continuando..."
        }
    }

    #----------------------------------------------#
    # Comprobar si existe el usuario, si no crealo #
    #----------------------------------------------#

    $surName = "$apellido1 $apellido2"
    $principalName = "$usrName@barcelona.lan"
    $passFormat = "Batoi@1234"
    $pass = ConvertTo-SecureString $passFormat -AsPlainText -Force

    $getUsr = Get-ADUser -Filter {SamAccountName -eq $usrName} -SearchBase $ouString -ErrorAction SilentlyContinue

    if ($getUsr -eq $null) {
        Write-Host "[USUARIO] " -ForegroundColor Blue -NoNewline
        Write-Host "No existe el usuario $usrName, creándolo ahora..."

        # Definir home directory y profile path según departamento
        if ($departamento -eq "Comercial") {
            $homeDirUsr = "\\barcelona.lan\DatosBarcelona\AdminDominio\PerfMov\$usrName"
            $profilePath = $homeDirUsr
            $homeDrive = "Z"
        } else {
            $homeDirUsr = "\\barcelona.lan\DatosBarcelona\AdminDominio\PerfOblig\$usrName"
            $profilePath = $homeDirUsr
            $homeDrive = "Z"
        }

        try {
            New-ADUser -GivenName $nom `
                       -Surname $surName `
                       -Name $displayName `
                       -UserPrincipalName $principalName `
                       -DisplayName $displayName `
                       -Description $descripcion `
                       -Office $sede `
                       -SamAccountName $usrName `
                       -AccountPassword $pass `
                       -ChangePasswordAtLogon $false `
                       -Enabled $true `
                       -Path $ouString `
                       -ProfilePath $profilePath `
                       -HomeDrive $homeDrive `
                       -HomeDirectory $homeDirUsr

            Write-Host "[USUARIO] " -ForegroundColor Blue -NoNewline
            Write-Host "Usuario $usrName creado con éxito."

            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "Agregando usuario $usrName al grupo $grp..."

            Add-ADGroupMember -Identity $grp -Members $usrName

            Write-Host "[GG] " -ForegroundColor Green -NoNewline
            Write-Host "Usuario $usrName agregado al grupo $grp con éxito."

        } catch {
            Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
            Write-Host "Error creando usuario $usrName: $($_.Exception.Message)"
            continue
        }
    } else {
        Write-Host "[USUARIO] " -ForegroundColor Blue -NoNewline
        Write-Host "Ya existe el usuario $usrName, continuando con el siguiente..."
    }
}
