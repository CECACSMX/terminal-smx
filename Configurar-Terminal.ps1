<#
.SYNOPSIS
    Configura Windows Terminal a tu gusto: colores, fuente, cursor, arranque y ventana.

.DESCRIPTION
    El script hace, en este orden:
      1. Te pregunta, con menus, como quieres Windows Terminal. En cada pregunta,
         Intro (opcion 1) deja ese ajuste como esta.
      2. Apunta el valor que tenia cada ajuste antes de tocarlo, para poder restaurarlo.
      3. Escribe los cambios en el settings.json de Windows Terminal (con copia .bak antes).
      4. Si lo ejecutas dentro de Windows Terminal, veras el cambio al momento y podras repetir.

    Es independiente de Instalar-Terminal.ps1: no necesita Oh My Posh.
    No necesita permisos de administrador.

.PARAMETER Restaurar
    Devuelve los ajustes tocados por este script al valor que tenian la primera vez.

.PARAMETER Prueba
    Modo ensayo: trabaja sobre una copia de settings.json en %TEMP%\terminal-smx-config-prueba.

.EXAMPLE
    .\Configurar-Terminal.ps1

.EXAMPLE
    .\Configurar-Terminal.ps1 -Restaurar

.NOTES
    Ciclo SMX - curso 2026-2027.
    Guarda este archivo en UTF-8 SIN BOM: con BOM falla al lanzarlo desde internet con irm.
    Claves y valores: documentacion oficial de Windows Terminal (learn.microsoft.com/windows/terminal).
#>

[CmdletBinding()]
param(
    [switch]$Restaurar,
    [switch]$Prueba
)

# Si un comando falla, paramos en vez de seguir a ciegas.
$ErrorActionPreference = 'Stop'


# =====================================================================
#  Configuración
# =====================================================================

$CarpetaPrueba = Join-Path $env:TEMP 'terminal-smx-config-prueba'

# Junto a cada settings.json guardamos los valores de antes con esta terminación.
$SufijoOriginal = '.smx-original.json'

$Utf8SinBom = New-Object System.Text.UTF8Encoding $false

# Esquemas de colores que trae Windows Terminal de serie.
$Esquemas = @('Campbell', 'Campbell Powershell', 'Vintage', 'One Half Dark', 'One Half Light', 'Tango Dark', 'Tango Light')

# Fuentes: las Cascadia vienen con Windows Terminal y Consolas con Windows.
$FuenteNerd = 'MesloLGM Nerd Font'
$Fuentes = @('Cascadia Mono', 'Cascadia Code', 'Consolas')

$TamanosFuente = @(10, 12, 14, 16, 20)

# Formas del cursor: valor de settings.json, nombre y dibujo (código Unicode).
$Cursores = @(
    @{ Valor = 'bar';              Nombre = 'Barra';           Dibujo = 0x2503 },
    @{ Valor = 'underscore';       Nombre = 'Subrayado';       Dibujo = 0x2581 },
    @{ Valor = 'filledBox';        Nombre = 'Bloque';          Dibujo = 0x2588 },
    @{ Valor = 'emptyBox';         Nombre = 'Bloque vacío';    Dibujo = 0x25AF },
    @{ Valor = 'doubleUnderscore'; Nombre = 'Doble subrayado'; Dibujo = 0x2017 },
    @{ Valor = 'vintage';          Nombre = 'Clásico';         Dibujo = 0x2583 }
)

# Colores del cursor: color de consola para pintar el menú y su valor hexadecimal.
$ColoresCursor = @(
    @{ Nombre = 'Blanco';   Consola = 'White';   Hex = '#F2F2F2' },
    @{ Nombre = 'Verde';    Consola = 'Green';   Hex = '#16C60C' },
    @{ Nombre = 'Amarillo'; Consola = 'Yellow';  Hex = '#F9F1A5' },
    @{ Nombre = 'Cian';     Consola = 'Cyan';    Hex = '#61D6D6' },
    @{ Nombre = 'Rojo';     Consola = 'Red';     Hex = '#E74856' },
    @{ Nombre = 'Magenta';  Consola = 'Magenta'; Hex = '#B4009E' }
)

$TamanosVentana = @(
    @{ Nombre = 'Pequeña (100 x 25)'; Columnas = 100; Filas = 25 },
    @{ Nombre = 'Mediana (120 x 30)'; Columnas = 120; Filas = 30 },
    @{ Nombre = 'Grande (150 x 40)';  Columnas = 150; Filas = 40 }
)


# =====================================================================
#  Mensajes en pantalla
# =====================================================================

function Write-Paso {
    param([int]$Numero, [int]$Total, [string]$Texto)
    Write-Host ''
    Write-Host "[$Numero/$Total] $Texto" -ForegroundColor Cyan
}

function Write-Ok    { param([string]$Texto) Write-Host "      [OK] $Texto" -ForegroundColor Green }
function Write-Aviso { param([string]$Texto) Write-Host "      [!]  $Texto" -ForegroundColor Yellow }


# =====================================================================
#  Leer y cambiar ajustes dentro del JSON
# =====================================================================
# Un ajuste se nombra con su ruta separada por puntos: "profiles.defaults.font.size"
# es la propiedad size, dentro de font, dentro de defaults, dentro de profiles.

function Get-Ajuste {
    # Devuelve el valor del ajuste, o $null si no existe.
    param($Objeto, [string]$Ruta)
    foreach ($parte in $Ruta.Split('.')) {
        if ($null -eq $Objeto -or -not $Objeto.PSObject.Properties[$parte]) { return $null }
        $Objeto = $Objeto.$parte
    }
    return $Objeto
}

function Test-Ajuste {
    param($Objeto, [string]$Ruta)
    $partes = $Ruta.Split('.')
    $padre = Get-Ajuste $Objeto (($partes | Select-Object -SkipLast 1) -join '.')
    if ($partes.Count -eq 1) { $padre = $Objeto }
    return ($null -ne $padre -and [bool]$padre.PSObject.Properties[$partes[-1]])
}

function Set-Ajuste {
    # Pone el valor; si el valor es $null, quita el ajuste (vuelve a mandar el de fábrica).
    param($Objeto, [string]$Ruta, $Valor)
    $partes = $Ruta.Split('.')
    for ($i = 0; $i -lt $partes.Count - 1; $i++) {
        if (-not $Objeto.PSObject.Properties[$partes[$i]]) {
            if ($null -eq $Valor) { return }
            $Objeto | Add-Member -NotePropertyName $partes[$i] -NotePropertyValue ([pscustomobject]@{})
        }
        $Objeto = $Objeto.($partes[$i])
    }
    $ultima = $partes[-1]
    if ($null -eq $Valor) { $Objeto.PSObject.Properties.Remove($ultima) }
    else { $Objeto | Add-Member -Force -NotePropertyName $ultima -NotePropertyValue $Valor }
}


# =====================================================================
#  Localizar Windows Terminal
# =====================================================================

function Get-RutasSettings {
    # Igual que en Instalar-Terminal.ps1: versión normal, Preview y versión sin tienda.
    $rutas = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    ) | Where-Object { Test-Path $_ }

    if (-not $Prueba) { return @($rutas) }

    # En modo prueba trabajamos sobre copias; si ya existen, seguimos con ellas.
    New-Item -ItemType Directory -Force -Path $CarpetaPrueba | Out-Null
    $copias = @()
    $n = 0
    foreach ($ruta in $rutas) {
        $n++
        $copia = Join-Path $CarpetaPrueba "windows-terminal-$n.json"
        if (-not (Test-Path $copia)) { Copy-Item $ruta $copia }
        $copias += $copia
    }
    return $copias
}

function Read-Settings {
    param([string]$Ruta)
    try { $ajustes = [IO.File]::ReadAllText($Ruta) | ConvertFrom-Json }
    catch {
        # Windows PowerShell 5.1 no entiende los comentarios // que a veces lleva este archivo.
        Write-Aviso "No puedo leer $Ruta (¿tiene comentarios?)."
        return $null
    }
    if ($ajustes.profiles -is [array]) {
        Write-Aviso "Formato antiguo de Windows Terminal en $Ruta. Actualízalo desde Microsoft Store."
        return $null
    }
    return $ajustes
}

function Test-FuenteInstalada {
    param([string]$Cara)
    # Windows apunta las fuentes en el registro: HKCU para tu usuario, HKLM para todo el equipo.
    $claves = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
              'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    foreach ($clave in $claves) {
        $valores = Get-ItemProperty -Path $clave -ErrorAction SilentlyContinue
        if ($valores -and ($valores.PSObject.Properties.Name -like "$Cara*")) { return $true }
    }
    return $false
}


# =====================================================================
#  Preguntas al alumno
# =====================================================================

function Read-Opcion {
    # Muestra una lista numerada y devuelve la posición elegida (empezando en 0).
    # -Colores: color de consola para pintar cada opción ($null = sin color).
    param([string]$Pregunta, [string[]]$Opciones, [object[]]$Colores)

    Write-Host ''
    Write-Host "      $Pregunta"
    for ($i = 0; $i -lt $Opciones.Count; $i++) {
        $linea = '        {0}) {1}' -f ($i + 1), $Opciones[$i]
        if ($Colores -and $Colores[$i]) { Write-Host $linea -ForegroundColor $Colores[$i] }
        else { Write-Host $linea }
    }
    while ($true) {
        $respuesta = Read-Host '      Número (Intro = 1)'
        if (-not $respuesta) { return 0 }
        $n = 0
        if ([int]::TryParse($respuesta, [ref]$n) -and $n -ge 1 -and $n -le $Opciones.Count) { return $n - 1 }
        Write-Aviso "Escribe un número del 1 al $($Opciones.Count)."
    }
}

function Format-Actual {
    # Texto corto con el valor actual; $Defecto es el valor de fábrica cuando no hay ajuste.
    param($Valor, [string]$Defecto)
    if ($null -eq $Valor) { return "$Defecto, de fábrica" }
    if ($Valor -is [pscustomobject]) { return (($Valor.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" }) -join ' / ') }
    return [string]$Valor
}

function Read-Cambios {
    # Hace todas las preguntas y devuelve la lista de cambios: @{ Ruta; Valor }.
    # Valor $null significa "quitar el ajuste".
    param($Ajustes)

    $cambios = New-Object System.Collections.Generic.List[object]
    $dejar = 'Dejar como está'
    $defecto = Get-Ajuste $Ajustes 'profiles.defaults'

    # --- Colores
    Write-Paso 1 3 'Colores'
    $actual = Format-Actual (Get-Ajuste $defecto 'colorScheme') 'Campbell'
    $i = Read-Opcion 'Esquema de colores:' (@("$dejar ($actual)") + $Esquemas)
    if ($i -gt 0) { $cambios.Add(@{ Ruta = 'profiles.defaults.colorScheme'; Valor = $Esquemas[$i - 1] }) }

    # --- Fuente y cursor
    Write-Paso 2 3 'Fuente y cursor'
    $fuentes = @($Fuentes)
    $etiquetas = @($Fuentes)
    if (Test-FuenteInstalada $FuenteNerd) {
        $fuentes = @($FuenteNerd) + $fuentes
        $etiquetas = @("$FuenteNerd (con iconos para Oh My Posh)") + $etiquetas
    }
    $actual = Format-Actual (Get-Ajuste $defecto 'font.face') 'Cascadia Mono'
    $i = Read-Opcion 'Tipo de letra:' (@("$dejar ($actual)") + $etiquetas)
    if ($i -gt 0) {
        $cambios.Add(@{ Ruta = 'profiles.defaults.font.face'; Valor = $fuentes[$i - 1] })
        if ($fuentes[$i - 1] -ne $FuenteNerd -and (Test-Path (Join-Path $HOME '.terminal-smx'))) {
            Write-Aviso 'Tienes Oh My Posh: con esta fuente sus iconos saldrán como cuadrados.'
        }
    }

    $actual = Format-Actual (Get-Ajuste $defecto 'font.size') '12'
    $i = Read-Opcion 'Tamaño de letra:' (@("$dejar ($actual)") + ($TamanosFuente | ForEach-Object { "$_ puntos" }))
    if ($i -gt 0) { $cambios.Add(@{ Ruta = 'profiles.defaults.font.size'; Valor = $TamanosFuente[$i - 1] }) }

    $actual = Format-Actual (Get-Ajuste $defecto 'cursorShape') 'bar'
    $i = Read-Opcion 'Forma del cursor:' (@("$dejar ($actual)") + ($Cursores | ForEach-Object { '{0}  {1}' -f [char]$_.Dibujo, $_.Nombre }))
    if ($i -gt 0) { $cambios.Add(@{ Ruta = 'profiles.defaults.cursorShape'; Valor = $Cursores[$i - 1].Valor }) }

    $actual = Format-Actual (Get-Ajuste $defecto 'cursorColor') 'el del esquema'
    $etiquetas = @($ColoresCursor | ForEach-Object { $_.Nombre })
    $pintura = @($ColoresCursor | ForEach-Object { $_.Consola })
    $i = Read-Opcion 'Color del cursor:' (@("$dejar ($actual)", 'El del esquema de colores') + $etiquetas) (@($null, $null) + $pintura)
    if ($i -eq 1) { $cambios.Add(@{ Ruta = 'profiles.defaults.cursorColor'; Valor = $null }) }
    elseif ($i -gt 1) { $cambios.Add(@{ Ruta = 'profiles.defaults.cursorColor'; Valor = $ColoresCursor[$i - 2].Hex }) }

    # --- Arranque y ventana
    Write-Paso 3 3 'Arranque y ventana'
    # Perfiles visibles: son las pestañas que se pueden abrir (PowerShell, Símbolo del sistema...).
    $perfiles = @($Ajustes.profiles.list | Where-Object { $_.name -and -not $_.hidden })
    if ($perfiles) {
        $id = [string]$Ajustes.defaultProfile
        $actual = ($perfiles | Where-Object { $_.guid -eq $id -or $_.name -eq $id } | Select-Object -First 1).name
        if (-not $actual) { $actual = 'desconocido' }
        $i = Read-Opcion 'Pestaña que se abre al arrancar:' (@("$dejar ($actual)") + ($perfiles | ForEach-Object { $_.name }))
        if ($i -gt 0) {
            $elegido = $perfiles[$i - 1]
            $valor = if ($elegido.guid) { $elegido.guid } else { $elegido.name }
            $cambios.Add(@{ Ruta = 'defaultProfile'; Valor = $valor })
        }
    }

    $carpetas = @(
        @{ Nombre = 'Tu carpeta personal'; Valor = '%USERPROFILE%' },
        @{ Nombre = 'Escritorio';          Valor = [Environment]::GetFolderPath('Desktop') },
        @{ Nombre = 'Documentos';          Valor = [Environment]::GetFolderPath('MyDocuments') }
    )
    $actual = Format-Actual (Get-Ajuste $defecto 'startingDirectory') 'la del perfil'
    $i = Read-Opcion 'Carpeta en la que empieza:' (@("$dejar ($actual)") + ($carpetas | ForEach-Object { "$($_.Nombre): $($_.Valor)" }))
    if ($i -gt 0) { $cambios.Add(@{ Ruta = 'profiles.defaults.startingDirectory'; Valor = $carpetas[$i - 1].Valor }) }

    $actual = Format-Actual (Get-Ajuste $Ajustes 'launchMode') 'default'
    $modo = Read-Opcion 'Cómo se abre la ventana:' @("$dejar ($actual)", 'Ventana normal, centrada', 'Maximizada', 'Pantalla completa (F11 para salir)')
    switch ($modo) {
        1 { $cambios.Add(@{ Ruta = 'launchMode'; Valor = 'default' }); $cambios.Add(@{ Ruta = 'centerOnLaunch'; Valor = $true }) }
        2 { $cambios.Add(@{ Ruta = 'launchMode'; Valor = 'maximized' }) }
        3 { $cambios.Add(@{ Ruta = 'launchMode'; Valor = 'fullscreen' }) }
    }

    # El tamaño solo cuenta en ventana normal: maximizada o a pantalla completa se ignora.
    if ($modo -le 1) {
        $columnas = if ($null -ne $Ajustes.initialCols) { $Ajustes.initialCols } else { 120 }
        $filas = if ($null -ne $Ajustes.initialRows) { $Ajustes.initialRows } else { 30 }
        $actual = "$columnas x $filas"
        if ($null -eq $Ajustes.initialCols -and $null -eq $Ajustes.initialRows) { $actual += ', de fábrica' }
        $i = Read-Opcion 'Tamaño de la ventana (columnas x filas):' (@("$dejar ($actual)") + ($TamanosVentana | ForEach-Object { $_.Nombre }))
        if ($i -gt 0) {
            $cambios.Add(@{ Ruta = 'initialCols'; Valor = $TamanosVentana[$i - 1].Columnas })
            $cambios.Add(@{ Ruta = 'initialRows'; Valor = $TamanosVentana[$i - 1].Filas })
        }
    }

    $actual = Format-Actual (Get-Ajuste $defecto 'backgroundImage') 'sin imagen'
    $i = Read-Opcion 'Imagen de fondo:' @("$dejar ($actual)", 'Sin imagen', 'Tu fondo de escritorio, muy suave')
    if ($i -eq 1) {
        $cambios.Add(@{ Ruta = 'profiles.defaults.backgroundImage'; Valor = $null })
        $cambios.Add(@{ Ruta = 'profiles.defaults.backgroundImageOpacity'; Valor = $null })
    }
    elseif ($i -eq 2) {
        $cambios.Add(@{ Ruta = 'profiles.defaults.backgroundImage'; Valor = 'desktopWallpaper' })
        $cambios.Add(@{ Ruta = 'profiles.defaults.backgroundImageOpacity'; Valor = 0.15 })
    }

    return , $cambios.ToArray()
}


# =====================================================================
#  Guardar y restaurar
# =====================================================================

function Save-Settings {
    param([string]$Ruta, $Ajustes)
    if (-not $Prueba) { Copy-Item $Ruta ("$Ruta.bak-config-" + (Get-Date -Format 'yyyyMMdd-HHmmss')) }
    [IO.File]::WriteAllText($Ruta, ($Ajustes | ConvertTo-Json -Depth 32), $Utf8SinBom)
}

function Save-Originales {
    # Apunta el valor de antes de cada ajuste, solo la primera vez que lo tocamos:
    # así "Restaurar" vuelve a como estaba antes de usar este script, aunque lo ejecutes varias veces.
    param([string]$Ruta, $Ajustes, [object[]]$Cambios)

    $archivo = $Ruta + $SufijoOriginal
    $originales = New-Object System.Collections.Generic.List[object]
    if (Test-Path $archivo) {
        foreach ($o in @(Read-Originales $archivo)) { $originales.Add($o) }
    }
    foreach ($cambio in $Cambios) {
        if ($originales | Where-Object { $_.ruta -eq $cambio.Ruta }) { continue }
        $originales.Add([pscustomobject]@{
            ruta    = $cambio.Ruta
            existia = (Test-Ajuste $Ajustes $cambio.Ruta)
            valor   = (Get-Ajuste $Ajustes $cambio.Ruta)
        })
    }
    # La lista va dentro de un objeto: Windows PowerShell 5.1 guarda y lee mal una lista suelta.
    $contenido = [pscustomobject]@{ ajustes = $originales.ToArray() }
    [IO.File]::WriteAllText($archivo, ($contenido | ConvertTo-Json -Depth 32), $Utf8SinBom)
}

function Read-Originales {
    param([string]$Archivo)
    return @(([IO.File]::ReadAllText($Archivo) | ConvertFrom-Json).ajustes)
}

function Write-AvisoPerfiles {
    # Un ajuste puesto dentro de un perfil manda sobre profiles.defaults: lo avisamos.
    param($Ajustes, [object[]]$Cambios)
    foreach ($cambio in $Cambios) {
        if (-not $cambio.Ruta.StartsWith('profiles.defaults.')) { continue }
        $subruta = $cambio.Ruta.Substring('profiles.defaults.'.Length)
        foreach ($perfil in @($Ajustes.profiles.list)) {
            if (-not $perfil.hidden -and (Test-Ajuste $perfil $subruta)) {
                Write-Aviso "El perfil '$($perfil.name)' tiene su propio $subruta y ahí manda el suyo."
            }
        }
    }
}

function Invoke-Configuracion {
    Write-Host ''
    Write-Host '  Configura Windows Terminal a tu gusto' -ForegroundColor Cyan
    Write-Host '  En cada pregunta, Intro deja el ajuste como está.'
    if ($Prueba) { Write-Aviso "Modo prueba: se trabaja sobre copias en $CarpetaPrueba" }

    $rutas = @(Get-RutasSettings)
    if (-not $rutas) { throw 'No encuentro Windows Terminal, o aún no se ha abierto nunca. Ábrelo una vez y repite.' }

    # $env:WT_SESSION solo existe dentro de Windows Terminal: entonces se ven los cambios al guardar.
    $enDirecto = [bool]$env:WT_SESSION

    do {
        # Las preguntas se hacen sobre el primer settings.json; los cambios van a todos.
        $primero = Read-Settings $rutas[0]
        if (-not $primero) { throw 'No se puede continuar sin leer settings.json.' }
        $cambios = Read-Cambios $primero

        if (-not $cambios) {
            Write-Host ''
            Write-Ok 'No has cambiado nada.'
            return
        }

        Write-Host ''
        foreach ($ruta in $rutas) {
            $ajustes = Read-Settings $ruta
            if (-not $ajustes) { continue }
            Save-Originales $ruta $ajustes $cambios
            foreach ($cambio in $cambios) { Set-Ajuste $ajustes $cambio.Ruta $cambio.Valor }
            Save-Settings $ruta $ajustes
            Write-Ok "Guardado en $ruta"
            Write-AvisoPerfiles $ajustes $cambios
        }

        $confirmado = $true
        if ($enDirecto -and -not $Prueba) {
            Write-Host ''
            $respuesta = Read-Host '      Mira la ventana: ya tiene los cambios. ¿Lo dejamos así? (S/n)'
            $confirmado = $respuesta -notmatch '^[nN]'
        }
    } until ($confirmado)

    Write-Host ''
    if ($enDirecto) { Write-Host '  Terminado.' -ForegroundColor Green }
    else { Write-Host '  Terminado. Abre Windows Terminal para ver los cambios.' -ForegroundColor Green }
    Write-Host '  Algunos ajustes (tamaño y forma de la ventana) se notan al abrir una ventana nueva.'
    Write-Host '  Para volver a como estaba: RESTAURAR-CONFIG.bat'
}

function Invoke-Restauracion {
    $rutas = @(Get-RutasSettings)
    $hecho = $false
    foreach ($ruta in $rutas) {
        $archivo = $ruta + $SufijoOriginal
        if (-not (Test-Path $archivo)) { continue }
        $ajustes = Read-Settings $ruta
        if (-not $ajustes) { continue }

        foreach ($o in (Read-Originales $archivo)) {
            if ($o.existia) { Set-Ajuste $ajustes $o.ruta $o.valor }
            else { Set-Ajuste $ajustes $o.ruta $null }
        }
        Save-Settings $ruta $ajustes
        Remove-Item $archivo
        Write-Ok "Restaurado $ruta"
        $hecho = $true
    }
    if (-not $hecho) { Write-Ok 'No hay nada que restaurar: este script no ha cambiado nada.' }
}


# =====================================================================
#  Programa principal
# =====================================================================

try {
    if ($Restaurar) { Invoke-Restauracion }
    else { Invoke-Configuracion }
}
catch {
    Write-Host ''
    Write-Host "  [X] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host '      No se ha completado. Corrige el problema y vuelve a ejecutar.' -ForegroundColor Red
}
