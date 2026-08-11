# ReadyToGo

Strumento di setup automatico per nuovi PC Windows, ad uso dei tecnici RPM2000. Installa un set standard di software (browser, utility, antivirus opzionale, software del produttore hardware) tramite `winget` e download diretti, con controlli di integrità sui file scaricati prima dell'installazione.

## Struttura del progetto

| File | Descrizione |
|---|---|
| `ReadyToGo.exe` | **Eseguibile compilato (consigliato)** — versione a file singolo di `script.ps1`, generata con PS2EXE. Richiede da sola l'elevazione UAC (manifest `-requireAdmin`), icona incorporata |
| `script.ps1` | Script sorgente con tutta la logica di installazione (usato sia dal launcher `.cmd` sia per generare `ReadyToGo.exe`) |
| `README.md` | Questo file |

## Requisiti

- Windows 10/11
- Connessione a internet
- `winget` disponibile (App Installer da Microsoft Store) — lo script tenta di registrarlo automaticamente se assente
- Privilegi di amministratore (con `ReadyToGo.exe` il prompt UAC scatta automaticamente all'avvio; con lo script `.ps1`/`.cmd` si rilancia da solo se avviato da utente standard)

## Utilizzo

**Opzione consigliata — eseguibile singolo:**
1. Copiare `ReadyToGo.exe` sul PC di destinazione
2. Avviarlo con doppio click
3. Confermare il prompt UAC quando richiesto
4. Rispondere alle domande **S/N** per i software opzionali
5. Se si installa il software del produttore, indicare uno tra `ASUS` / `Dell` / `HP` / `Lenovo`

**Opzione alternativa — script sorgente:**
1. Copiare l'intera cartella `ReadyToGo` sul PC di destinazione
2. Avviare `installer_readytogo.cmd` (doppio click)
3. Seguire gli stessi passaggi 3-5 sopra

## Software installato

**Sempre:**
- Adobe Acrobat Reader DC
- Mozilla Firefox
- Google Chrome
- VLC Media Player
- 7-Zip
- Assistenza RPM2000 (scaricato sul Desktop, non avviato automaticamente)

**Opzionali (a scelta durante l'esecuzione):**
- Intel Driver & Support Assistant
- Quick Heal Antivirus Pro
- LibreOffice
- Software del produttore hardware (ASUS / Dell / HP / Lenovo)

## Sicurezza

- Ogni file scaricato viene verificato prima dell'installazione: dimensione non nulla, header eseguibile valido (`MZ`), e hash SHA256 calcolato e mostrato in console
- Per i file di fornitori esterni che aggiornano periodicamente i propri link (Dell, HP, Firefox, Quick Heal) l'hash non è fissato a un valore pinnato, perché cambierebbe ad ogni aggiornamento del fornitore rompendo lo script; l'hash calcolato viene comunque loggato in console per un controllo manuale
- I privilegi di amministratore vengono richiesti solo per il processo corrente, senza modificare impostazioni di sicurezza di sistema
- `ReadyToGo.exe` non è firmato digitalmente: Windows Defender SmartScreen (o altri antivirus) può segnalarlo come "pubblicatore sconosciuto" al primo avvio — è normale, si procede con "Ulteriori informazioni → Esegui comunque". Firmarlo con un certificato di code-signing eliminerebbe l'avviso

## Note di manutenzione

- Gli URL di terze parti (in particolare quello HP, legato a una build specifica del softpaq) possono cambiare o essere ritirati nel tempo: se un download fallisce, verificare per primo che il link sia ancora valido
- Ogni installazione (tramite `winget` o eseguibile scaricato) riporta in console il proprio codice di uscita, utile per la diagnosi da remoto

## Rigenerare `ReadyToGo.exe`

Se si modifica `script.ps1`, l'eseguibile va ricompilato (non si aggiorna da solo). Da PowerShell su Windows, nella cartella del progetto:

```powershell
Install-Module -Name ps2exe -Scope CurrentUser -Force   # solo la prima volta
Invoke-ps2exe -inputFile ".\script.ps1" -outputFile ".\ReadyToGo.exe" -iconFile ".\icon.ico" -requireAdmin -title "ReadyToGo Setup" -product "ReadyToGo" -company "RPM2000" -version "1.0.0.0" -x64
```

Non usare `-noConsole`: lo script usa `Read-Host`/`Write-Host`/`Pause`, che richiedono una console visibile.

## Troubleshooting

- **Winget non disponibile**: lo script tenta la registrazione automatica; se fallisce, installare manualmente "App Installer" dal Microsoft Store
- **Download fallito o file non valido**: lo script segnala l'errore e salta l'installazione corrispondente; controllare la cartella `%USERPROFILE%\Downloads` e la connessione di rete
- **Installazione terminata con codice diverso da 0**: consultare la documentazione del produttore per il significato del codice di uscita specifico
