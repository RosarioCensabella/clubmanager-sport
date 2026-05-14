$ErrorActionPreference = "Stop"

if (-not $env:SUPABASE_URL) {
  throw "Manca SUPABASE_URL."
}

if (-not $env:SUPABASE_SERVICE_ROLE_KEY) {
  throw "Manca SUPABASE_SERVICE_ROLE_KEY."
}

$SupabaseUrl = $env:SUPABASE_URL.TrimEnd("/")
$ServiceRoleKey = $env:SUPABASE_SERVICE_ROLE_KEY
$RestUrl = "$SupabaseUrl/rest/v1"
$AuthUrl = "$SupabaseUrl/auth/v1"

$DefaultPassword = "Test1234!"
$DemoEmailDomain = "clubmanager.test"
$DemoClubFiscalCode = "DEMO-CMS-SEED"

function New-Id {
  return ([guid]::NewGuid()).ToString()
}

function New-Headers {
  param([hashtable]$Extra = @{})

  $headers = @{
    "apikey"        = $ServiceRoleKey
    "Authorization" = "Bearer $ServiceRoleKey"
  }

  foreach ($key in $Extra.Keys) {
    $headers[$key] = $Extra[$key]
  }

  return $headers
}

function Get-ErrorBody {
  param($ErrorRecord)

  try {
    $stream = $ErrorRecord.Exception.Response.GetResponseStream()
    if ($null -eq $stream) {
      return $ErrorRecord.Exception.Message
    }

    $reader = New-Object System.IO.StreamReader($stream)
    return $reader.ReadToEnd()
  } catch {
    return $ErrorRecord.Exception.Message
  }
}

function Invoke-Json {
  param(
    [string]$Method,
    [string]$Uri,
    [object]$Body = $null,
    [hashtable]$ExtraHeaders = @{}
  )

  $headers = New-Headers -Extra $ExtraHeaders

  try {
    if ($null -eq $Body) {
      return Invoke-RestMethod `
        -Method $Method `
        -Uri $Uri `
        -Headers $headers
    }

    $json = $Body | ConvertTo-Json -Depth 40 -Compress

    return Invoke-RestMethod `
      -Method $Method `
      -Uri $Uri `
      -Headers $headers `
      -ContentType "application/json; charset=utf-8" `
      -Body $json
  } catch {
    $body = Get-ErrorBody $_
    throw "Errore HTTP su $Method $Uri`n$body"
  }
}

function Invoke-RestInsertOne {
  param(
    [string]$Table,
    [hashtable]$Row
  )

  $uri = "${RestUrl}/${Table}"

  Invoke-Json `
    -Method "Post" `
    -Uri $uri `
    -Body $Row `
    -ExtraHeaders @{ "Prefer" = "return=minimal" } | Out-Null
}

function Invoke-RestUpsertOne {
  param(
    [string]$Table,
    [hashtable]$Row,
    [string]$OnConflict
  )

  $uri = "${RestUrl}/${Table}?on_conflict=${OnConflict}"

  Invoke-Json `
    -Method "Post" `
    -Uri $uri `
    -Body $Row `
    -ExtraHeaders @{ "Prefer" = "resolution=merge-duplicates,return=minimal" } | Out-Null
}

function Invoke-RestDelete {
  param(
    [string]$Table,
    [string]$Filter
  )

  $uri = "${RestUrl}/${Table}?${Filter}"

  try {
    Invoke-Json `
      -Method "Delete" `
      -Uri $uri `
      -ExtraHeaders @{ "Prefer" = "return=minimal" } | Out-Null
  } catch {
    Write-Host "Cleanup ${Table} ignorato: $($_.Exception.Message)"
  }
}

function Get-AuthUsers {
  $allUsers = @()
  $page = 1
  $perPage = 1000

  while ($true) {
    $uri = "${AuthUrl}/admin/users?page=${page}&per_page=${perPage}"
    $response = Invoke-Json -Method "Get" -Uri $uri

    $batch = @()

    if ($response.users) {
      $batch = @($response.users)
    } elseif ($response -is [array]) {
      $batch = @($response)
    }

    $allUsers += $batch

    if ($batch.Count -lt $perPage) {
      break
    }

    $page++
  }

  return $allUsers
}

function Remove-AuthUser {
  param([string]$UserId)

  if ([string]::IsNullOrWhiteSpace($UserId)) {
    return
  }

  $uri = "${AuthUrl}/admin/users/${UserId}"

  try {
    Invoke-Json -Method "Delete" -Uri $uri | Out-Null
  } catch {
    Write-Host "Utente auth non cancellato ${UserId}: $($_.Exception.Message)"
  }
}

function Find-AuthUserByEmail {
  param([string]$Email)

  $target = $Email.ToLowerInvariant()
  $users = Get-AuthUsers

  foreach ($user in $users) {
    $candidate = ""

    if ($null -ne $user.email) {
      $candidate = $user.email.ToString().ToLowerInvariant()
    }

    if ($candidate -eq $target) {
      return $user
    }
  }

  return $null
}

function New-AuthUser {
  param(
    [string]$Email,
    [string]$Password,
    [string]$FirstName,
    [string]$LastName
  )

  $body = @{
    email = $Email
    password = $Password
    email_confirm = $true
    user_metadata = @{
      first_name = $FirstName
      last_name = $LastName
    }
  }

  $uri = "${AuthUrl}/admin/users"

  try {
    return Invoke-Json -Method "Post" -Uri $uri -Body $body
  } catch {
    Write-Host "Creazione auth fallita per ${Email}. Provo a riusare l'utente esistente."
    $existing = Find-AuthUserByEmail -Email $Email

    if ($null -eq $existing) {
      throw
    }

    return $existing
  }
}

Write-Host ""
Write-Host "Pulizia vecchi dati demo..."

$encodedMarker = [uri]::EscapeDataString($DemoClubFiscalCode)
Invoke-RestDelete -Table "clubs" -Filter "fiscal_code=eq.${encodedMarker}"

$existingUsers = Get-AuthUsers

foreach ($user in $existingUsers) {
  $email = ""

  if ($null -ne $user.email) {
    $email = $user.email.ToString().ToLowerInvariant()
  }

  if ($email.EndsWith("@${DemoEmailDomain}")) {
    Remove-AuthUser -UserId $user.id
  }
}

Write-Host "Creazione utenti demo..."

$userSpecs = @(
  @{ Key="admin"; Email="admin.demo@clubmanager.test"; FirstName="Admin"; LastName="Demo"; AppRole="owner"; Note="Unico admin/proprietario club" },

  @{ Key="manager.rossi"; Email="manager.rossi@clubmanager.test"; FirstName="Marco"; LastName="Rossi"; AppRole="team_manager"; Note="Manager su Under 10 e Under 12" },
  @{ Key="manager.bianchi"; Email="manager.bianchi@clubmanager.test"; FirstName="Laura"; LastName="Bianchi"; AppRole="team_manager"; Note="Manager su Under 14 e Juniores" },

  @{ Key="coach.verdi"; Email="coach.verdi@clubmanager.test"; FirstName="Paolo"; LastName="Verdi"; AppRole="coach"; Note="Allenatore su Under 10 e Under 12" },
  @{ Key="coach.neri"; Email="coach.neri@clubmanager.test"; FirstName="Francesca"; LastName="Neri"; AppRole="coach"; Note="Allenatrice su Under 14" },
  @{ Key="coach.blu"; Email="coach.blu@clubmanager.test"; FirstName="Giorgio"; LastName="Blu"; AppRole="coach"; Note="Allenatore su Juniores e Prima Squadra" },

  @{ Key="staff.medico"; Email="staff.medico@clubmanager.test"; FirstName="Dott"; LastName="Medico"; AppRole="staff"; Note="Staff medico" },
  @{ Key="staff.segreteria"; Email="staff.segreteria@clubmanager.test"; FirstName="Sara"; LastName="Segreteria"; AppRole="staff"; Note="Staff segreteria" },

  @{ Key="parent.mario"; Email="genitore.mario@clubmanager.test"; FirstName="Mario"; LastName="Bianchi"; AppRole="parent"; Note="Padre di Emma e Luca" },
  @{ Key="parent.giulia"; Email="genitore.giulia@clubmanager.test"; FirstName="Giulia"; LastName="Bianchi"; AppRole="parent"; Note="Madre di Emma e Luca" },
  @{ Key="parent.sara"; Email="genitore.sara@clubmanager.test"; FirstName="Sara"; LastName="Neri"; AppRole="parent"; Note="Madre di Sofia" },
  @{ Key="parent.luca"; Email="genitore.luca@clubmanager.test"; FirstName="Luca"; LastName="Costa"; AppRole="parent"; Note="Padre di Giulia e Matteo" },
  @{ Key="parent.elena"; Email="genitore.elena@clubmanager.test"; FirstName="Elena"; LastName="Verdi"; AppRole="parent"; Note="Madre di Anna" },
  @{ Key="guardian.paolo"; Email="tutore.paolo@clubmanager.test"; FirstName="Paolo"; LastName="Romano"; AppRole="parent"; Note="Tutore di Francesco e Andrea" },

  @{ Key="athlete.anna"; Email="atleta.anna@clubmanager.test"; FirstName="Anna"; LastName="Verdi"; AppRole="athlete"; Note="Atleta con account" },
  @{ Key="athlete.marco"; Email="atleta.marco@clubmanager.test"; FirstName="Marco"; LastName="Russo"; AppRole="athlete"; Note="Atleta con account" },
  @{ Key="athlete.giulia"; Email="atleta.giulia@clubmanager.test"; FirstName="Giulia"; LastName="Costa"; AppRole="athlete"; Note="Atleta con account e genitore" },
  @{ Key="athlete.luca"; Email="atleta.luca@clubmanager.test"; FirstName="Luca"; LastName="Ferrari"; AppRole="athlete"; Note="Atleta con account su più squadre" }
)

$Users = @{}

foreach ($spec in $userSpecs) {
  $created = New-AuthUser `
    -Email $spec["Email"] `
    -Password $DefaultPassword `
    -FirstName $spec["FirstName"] `
    -LastName $spec["LastName"]

  $Users[$spec["Key"]] = @{
    Id = $created.id
    Email = $spec["Email"]
    FirstName = $spec["FirstName"]
    LastName = $spec["LastName"]
    AppRole = $spec["AppRole"]
    Note = $spec["Note"]
  }

  Write-Host "Creato utente: $($spec["Email"])"
}

Write-Host "Upsert profili..."

foreach ($key in $Users.Keys) {
  $u = $Users[$key]

  Invoke-RestUpsertOne -Table "profiles" -OnConflict "id" -Row @{
    id = $u["Id"]
    email = $u["Email"]
    first_name = $u["FirstName"]
    last_name = $u["LastName"]
    email_verified = $true
  }
}

Write-Host "Creazione club demo..."

$clubId = New-Id

Invoke-RestInsertOne -Table "clubs" -Row @{
  id = $clubId
  owner_user_id = $Users["admin"]["Id"]
  name = "ASD Demo Club"
  sport_primary = "Calcio"
  city = "Catania"
  address = "Via Demo 1"
  email = "segreteria@clubmanager.test"
  phone = "+390000000000"
  website = "https://demo.clubmanager.test"
  fiscal_code = $DemoClubFiscalCode
  season = "2026/2027"
  primary_color = "#176B87"
}

Write-Host "Creazione membership club..."

foreach ($key in $Users.Keys) {
  $u = $Users[$key]
  $role = $u["AppRole"]

  if ($key -eq "admin") {
    $role = "owner"
  }

  Invoke-RestUpsertOne -Table "club_memberships" -OnConflict "club_id,user_id" -Row @{
    club_id = $clubId
    user_id = $u["Id"]
    role = $role
    status = "active"
  }
}

Write-Host "Creazione squadre..."

$Teams = @{
  u10 = New-Id
  u12 = New-Id
  u14 = New-Id
  juniores = New-Id
  primaFemminile = New-Id
}

$teamRows = @(
  @{ id=$Teams.u10; club_id=$clubId; name="Under 10 Mista"; sport="Calcio"; category="Pulcini"; season="2026/2027"; birth_year=2017; gender="mixed"; color="#22C55E"; training_location="Campo A" },
  @{ id=$Teams.u12; club_id=$clubId; name="Under 12"; sport="Calcio"; category="Esordienti"; season="2026/2027"; birth_year=2015; gender="mixed"; color="#3B82F6"; training_location="Campo B" },
  @{ id=$Teams.u14; club_id=$clubId; name="Under 14"; sport="Calcio"; category="Giovanissimi"; season="2026/2027"; birth_year=2013; gender="male"; color="#F97316"; training_location="Campo C" },
  @{ id=$Teams.juniores; club_id=$clubId; name="Juniores"; sport="Calcio"; category="Juniores"; season="2026/2027"; birth_year=2008; gender="male"; color="#8B5CF6"; training_location="Campo Centrale" },
  @{ id=$Teams.primaFemminile; club_id=$clubId; name="Prima Squadra Femminile"; sport="Calcio"; category="Prima Squadra"; season="2026/2027"; birth_year=$null; gender="female"; color="#EC4899"; training_location="Campo Centrale" }
)

foreach ($row in $teamRows) {
  Invoke-RestInsertOne -Table "teams" -Row $row
}

Write-Host "Creazione atleti..."

$Athletes = @{
  emma = New-Id
  lucaBianchi = New-Id
  sofia = New-Id
  matteo = New-Id
  francesco = New-Id
  andrea = New-Id
  anna = New-Id
  marco = New-Id
  giulia = New-Id
  lucaFerrari = New-Id
  nicolo = New-Id
  beatrice = New-Id
  riccardo = New-Id
  chiara = New-Id
}

$athleteRows = @(
  @{ id=$Athletes.emma; club_id=$clubId; user_id=$null; team_id=$Teams.u10; first_name="Emma"; last_name="Bianchi"; date_of_birth="2017-03-12"; jersey_number="7"; sport_role="Ala"; active=$true; medical_certificate_status="valid"; medical_certificate_expiry="2027-03-12"; staff_notes="Ha due genitori collegati." },
  @{ id=$Athletes.lucaBianchi; club_id=$clubId; user_id=$null; team_id=$Teams.u12; first_name="Luca"; last_name="Bianchi"; date_of_birth="2015-09-20"; jersey_number="10"; sport_role="Trequartista"; active=$true; medical_certificate_status="expiring"; medical_certificate_expiry="2026-06-30"; staff_notes="Fratello di Emma." },
  @{ id=$Athletes.sofia; club_id=$clubId; user_id=$null; team_id=$Teams.u12; first_name="Sofia"; last_name="Neri"; date_of_birth="2015-01-08"; jersey_number="3"; sport_role="Difensore"; active=$true; medical_certificate_status="missing"; medical_certificate_expiry=$null; staff_notes="Un solo genitore collegato." },
  @{ id=$Athletes.matteo; club_id=$clubId; user_id=$null; team_id=$Teams.u14; first_name="Matteo"; last_name="Costa"; date_of_birth="2013-11-04"; jersey_number="5"; sport_role="Mediano"; active=$true; medical_certificate_status="pending_review"; medical_certificate_expiry="2026-12-31"; staff_notes="Condivide genitore con Giulia Costa." },
  @{ id=$Athletes.francesco; club_id=$clubId; user_id=$null; team_id=$Teams.u14; first_name="Francesco"; last_name="Romano"; date_of_birth="2013-05-19"; jersey_number="9"; sport_role="Attaccante"; active=$true; medical_certificate_status="expired"; medical_certificate_expiry="2025-12-31"; staff_notes="Collegato a tutore." },
  @{ id=$Athletes.andrea; club_id=$clubId; user_id=$null; team_id=$Teams.u10; first_name="Andrea"; last_name="Romano"; date_of_birth="2017-07-22"; jersey_number="11"; sport_role="Esterno"; active=$true; medical_certificate_status="valid"; medical_certificate_expiry="2027-01-31"; staff_notes="Stesso tutore di Francesco." },
  @{ id=$Athletes.anna; club_id=$clubId; user_id=$Users["athlete.anna"]["Id"]; team_id=$Teams.primaFemminile; first_name="Anna"; last_name="Verdi"; date_of_birth="2006-02-14"; jersey_number="8"; sport_role="Centrocampista"; active=$true; medical_certificate_status="valid"; medical_certificate_expiry="2027-02-14"; staff_notes="Atleta con account collegato." },
  @{ id=$Athletes.marco; club_id=$clubId; user_id=$Users["athlete.marco"]["Id"]; team_id=$Teams.juniores; first_name="Marco"; last_name="Russo"; date_of_birth="2008-10-01"; jersey_number="1"; sport_role="Portiere"; active=$true; medical_certificate_status="valid"; medical_certificate_expiry="2027-04-10"; staff_notes="Atleta con account, senza genitore." },
  @{ id=$Athletes.giulia; club_id=$clubId; user_id=$Users["athlete.giulia"]["Id"]; team_id=$Teams.primaFemminile; first_name="Giulia"; last_name="Costa"; date_of_birth="2007-06-06"; jersey_number="4"; sport_role="Difensore"; active=$true; medical_certificate_status="rejected"; medical_certificate_expiry="2026-05-31"; staff_notes="Account atleta più genitore collegato." },
  @{ id=$Athletes.lucaFerrari; club_id=$clubId; user_id=$Users["athlete.luca"]["Id"]; team_id=$Teams.juniores; first_name="Luca"; last_name="Ferrari"; date_of_birth="2008-12-02"; jersey_number="6"; sport_role="Jolly"; active=$true; medical_certificate_status="valid"; medical_certificate_expiry="2027-05-01"; staff_notes="Atleta con account assegnato a più squadre via team_memberships." },
  @{ id=$Athletes.nicolo; club_id=$clubId; user_id=$null; team_id=$Teams.u12; first_name="Nicolo"; last_name="Greco"; date_of_birth="2015-04-04"; jersey_number="13"; sport_role="Difensore"; active=$true; medical_certificate_status="missing"; medical_certificate_expiry=$null; staff_notes="Atleta senza account e senza genitori." },
  @{ id=$Athletes.beatrice; club_id=$clubId; user_id=$null; team_id=$Teams.u10; first_name="Beatrice"; last_name="Conti"; date_of_birth="2017-08-18"; jersey_number="14"; sport_role="Centrocampista"; active=$true; medical_certificate_status="valid"; medical_certificate_expiry="2027-07-01"; staff_notes="Atleta senza account." },
  @{ id=$Athletes.riccardo; club_id=$clubId; user_id=$null; team_id=$Teams.u14; first_name="Riccardo"; last_name="Marino"; date_of_birth="2013-02-27"; jersey_number="2"; sport_role="Terzino"; active=$true; medical_certificate_status="expiring"; medical_certificate_expiry="2026-07-10"; staff_notes="Caso certificato in scadenza." },
  @{ id=$Athletes.chiara; club_id=$clubId; user_id=$null; team_id=$Teams.primaFemminile; first_name="Chiara"; last_name="Moretti"; date_of_birth="2005-09-09"; jersey_number="21"; sport_role="Attaccante"; active=$true; medical_certificate_status="valid"; medical_certificate_expiry="2027-09-09"; staff_notes="Prima squadra, nessun account." }
)

foreach ($row in $athleteRows) {
  Invoke-RestInsertOne -Table "athlete_profiles" -Row $row
}

Write-Host "Creazione assegnazioni squadra..."

$teamMembershipRows = @(
  @{ team_id=$Teams.u10; user_id=$Users["manager.rossi"]["Id"]; athlete_profile_id=$null; role="team_manager"; status="active" },
  @{ team_id=$Teams.u12; user_id=$Users["manager.rossi"]["Id"]; athlete_profile_id=$null; role="team_manager"; status="active" },
  @{ team_id=$Teams.u14; user_id=$Users["manager.bianchi"]["Id"]; athlete_profile_id=$null; role="team_manager"; status="active" },
  @{ team_id=$Teams.juniores; user_id=$Users["manager.bianchi"]["Id"]; athlete_profile_id=$null; role="team_manager"; status="active" },

  @{ team_id=$Teams.u10; user_id=$Users["coach.verdi"]["Id"]; athlete_profile_id=$null; role="coach"; status="active" },
  @{ team_id=$Teams.u12; user_id=$Users["coach.verdi"]["Id"]; athlete_profile_id=$null; role="coach"; status="active" },
  @{ team_id=$Teams.u14; user_id=$Users["coach.neri"]["Id"]; athlete_profile_id=$null; role="coach"; status="active" },
  @{ team_id=$Teams.juniores; user_id=$Users["coach.blu"]["Id"]; athlete_profile_id=$null; role="coach"; status="active" },
  @{ team_id=$Teams.primaFemminile; user_id=$Users["coach.blu"]["Id"]; athlete_profile_id=$null; role="coach"; status="active" },

  @{ team_id=$Teams.u10; user_id=$Users["staff.medico"]["Id"]; athlete_profile_id=$null; role="staff"; status="active" },
  @{ team_id=$Teams.u12; user_id=$Users["staff.medico"]["Id"]; athlete_profile_id=$null; role="staff"; status="active" },
  @{ team_id=$Teams.u14; user_id=$Users["staff.segreteria"]["Id"]; athlete_profile_id=$null; role="staff"; status="active" },

  @{ team_id=$Teams.u10; user_id=$null; athlete_profile_id=$Athletes.emma; role="athlete"; status="active" },
  @{ team_id=$Teams.u12; user_id=$null; athlete_profile_id=$Athletes.lucaBianchi; role="athlete"; status="active" },
  @{ team_id=$Teams.u12; user_id=$null; athlete_profile_id=$Athletes.sofia; role="athlete"; status="active" },
  @{ team_id=$Teams.u14; user_id=$null; athlete_profile_id=$Athletes.sofia; role="athlete"; status="active" },
  @{ team_id=$Teams.u14; user_id=$null; athlete_profile_id=$Athletes.matteo; role="athlete"; status="active" },
  @{ team_id=$Teams.u14; user_id=$null; athlete_profile_id=$Athletes.francesco; role="athlete"; status="active" },
  @{ team_id=$Teams.u10; user_id=$null; athlete_profile_id=$Athletes.andrea; role="athlete"; status="active" },
  @{ team_id=$Teams.primaFemminile; user_id=$Users["athlete.anna"]["Id"]; athlete_profile_id=$Athletes.anna; role="athlete"; status="active" },
  @{ team_id=$Teams.juniores; user_id=$Users["athlete.marco"]["Id"]; athlete_profile_id=$Athletes.marco; role="athlete"; status="active" },
  @{ team_id=$Teams.primaFemminile; user_id=$Users["athlete.giulia"]["Id"]; athlete_profile_id=$Athletes.giulia; role="athlete"; status="active" },
  @{ team_id=$Teams.juniores; user_id=$Users["athlete.luca"]["Id"]; athlete_profile_id=$Athletes.lucaFerrari; role="athlete"; status="active" },
  @{ team_id=$Teams.u14; user_id=$Users["athlete.luca"]["Id"]; athlete_profile_id=$Athletes.lucaFerrari; role="athlete"; status="active" },
  @{ team_id=$Teams.u12; user_id=$null; athlete_profile_id=$Athletes.nicolo; role="athlete"; status="active" },
  @{ team_id=$Teams.u10; user_id=$null; athlete_profile_id=$Athletes.beatrice; role="athlete"; status="active" },
  @{ team_id=$Teams.u14; user_id=$null; athlete_profile_id=$Athletes.riccardo; role="athlete"; status="active" },
  @{ team_id=$Teams.primaFemminile; user_id=$null; athlete_profile_id=$Athletes.chiara; role="athlete"; status="active" }
)

foreach ($row in $teamMembershipRows) {
  Invoke-RestInsertOne -Table "team_memberships" -Row $row
}

Write-Host "Creazione relazioni genitori/tutori..."

$relationRows = @(
  @{ parent_user_id=$Users["parent.mario"]["Id"]; athlete_profile_id=$Athletes.emma; relation_type="father"; verified=$true },
  @{ parent_user_id=$Users["parent.giulia"]["Id"]; athlete_profile_id=$Athletes.emma; relation_type="mother"; verified=$true },
  @{ parent_user_id=$Users["parent.mario"]["Id"]; athlete_profile_id=$Athletes.lucaBianchi; relation_type="father"; verified=$true },
  @{ parent_user_id=$Users["parent.giulia"]["Id"]; athlete_profile_id=$Athletes.lucaBianchi; relation_type="mother"; verified=$true },

  @{ parent_user_id=$Users["parent.sara"]["Id"]; athlete_profile_id=$Athletes.sofia; relation_type="mother"; verified=$true },

  @{ parent_user_id=$Users["parent.luca"]["Id"]; athlete_profile_id=$Athletes.matteo; relation_type="father"; verified=$true },
  @{ parent_user_id=$Users["parent.luca"]["Id"]; athlete_profile_id=$Athletes.giulia; relation_type="father"; verified=$true },

  @{ parent_user_id=$Users["parent.elena"]["Id"]; athlete_profile_id=$Athletes.anna; relation_type="mother"; verified=$true },

  @{ parent_user_id=$Users["guardian.paolo"]["Id"]; athlete_profile_id=$Athletes.francesco; relation_type="guardian"; verified=$true },
  @{ parent_user_id=$Users["guardian.paolo"]["Id"]; athlete_profile_id=$Athletes.andrea; relation_type="guardian"; verified=$true }
)

foreach ($row in $relationRows) {
  Invoke-RestInsertOne -Table "parent_athlete_relations" -Row $row
}

Write-Host "Creazione inviti demo..."

$invitationRows = @(
  @{
    club_id = $clubId
    team_id = $Teams.u10
    athlete_profile_id = $null
    email = "nuovo.genitore@clubmanager.test"
    role = "parent"
    token = "DEMO-PARENT-SENT-" + (New-Id)
    status = "sent"
    expires_at = (Get-Date).AddDays(14).ToUniversalTime().ToString("o")
    invited_by = $Users["admin"]["Id"]
    accepted_by = $null
  },
  @{
    club_id = $clubId
    team_id = $Teams.u12
    athlete_profile_id = $null
    email = "nuovo.atleta@clubmanager.test"
    role = "athlete"
    token = "DEMO-ATHLETE-SENT-" + (New-Id)
    status = "sent"
    expires_at = (Get-Date).AddDays(14).ToUniversalTime().ToString("o")
    invited_by = $Users["admin"]["Id"]
    accepted_by = $null
  },
  @{
    club_id = $clubId
    team_id = $Teams.u14
    athlete_profile_id = $null
    email = "vecchio.coach@clubmanager.test"
    role = "coach"
    token = "DEMO-COACH-REVOKED-" + (New-Id)
    status = "revoked"
    expires_at = (Get-Date).AddDays(14).ToUniversalTime().ToString("o")
    invited_by = $Users["admin"]["Id"]
    accepted_by = $null
  },
  @{
    club_id = $clubId
    team_id = $Teams.primaFemminile
    athlete_profile_id = $Athletes.anna
    email = $Users["athlete.anna"]["Email"]
    role = "athlete"
    token = "DEMO-ATHLETE-ACCEPTED-" + (New-Id)
    status = "accepted"
    expires_at = (Get-Date).AddDays(14).ToUniversalTime().ToString("o")
    invited_by = $Users["admin"]["Id"]
    accepted_by = $Users["athlete.anna"]["Id"]
  }
)

foreach ($row in $invitationRows) {
  Invoke-RestInsertOne -Table "invitations" -Row $row
}

Write-Host "Scrittura credenziali demo..."

$outputDir = Join-Path (Get-Location) "seed-output"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$credentials = foreach ($key in $Users.Keys) {
  $u = $Users[$key]

  [PSCustomObject]@{
    Key = $key
    Email = $u["Email"]
    Password = $DefaultPassword
    Role = $u["AppRole"]
    Note = $u["Note"]
  }
}

$csvPath = Join-Path $outputDir "demo-users.csv"
$credentials | Sort-Object Role, Email | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csvPath

Write-Host ""
Write-Host "Seed completato correttamente."
Write-Host "Club demo: ASD Demo Club"
Write-Host "Password per tutti gli utenti demo: $DefaultPassword"
Write-Host "CSV credenziali: $csvPath"
Write-Host ""
Write-Host "Account principali:"
Write-Host "Admin: admin.demo@clubmanager.test / $DefaultPassword"
Write-Host "Genitore con 2 figli: genitore.mario@clubmanager.test / $DefaultPassword"
Write-Host "Genitore con 2 figli: genitore.giulia@clubmanager.test / $DefaultPassword"
Write-Host "Atleta con account: atleta.anna@clubmanager.test / $DefaultPassword"
Write-Host "Coach multi-squadra: coach.verdi@clubmanager.test / $DefaultPassword"
Write-Host "Manager multi-squadra: manager.rossi@clubmanager.test / $DefaultPassword"