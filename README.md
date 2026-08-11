# ReadyToGo

Strumento di setup automatico per nuovi PC Windows, ad uso dei tecnici RPM2000. Installa un set standard di software (browser, utility, antivirus opzionale, software del produttore hardware) tramite `winget` e download diretti, con controlli di integrità sui file scaricati prima dell'installazione.

## Struttura del progetto

| File | Descrizione |
|---|---|
| `installer_readytogo.cmd` | Launcher: abilita temporaneamente l'esecuzione di script PowerShell e avvia `script.ps1` |
| `script.ps1` | Script principale con tutta la logica di installazione |
| `README.md` | Questo file |

## Requisiti

- Windows 10/11 con PowerShell 5.1 o superiore
- Connessione a internet
- `winget` disponibile (App Installer da Microsoft Store) — lo script tenta di registrarlo automaticamente se assente
- Privilegi di amministratore (lo script si rilancia da solo con richiesta UAC se avviato da utente standard)

## Utilizzo

1. Copiare la cartella `ReadyToGo` sul PC di destinazione
2. Avviare `installer_readytogo.cmd` (doppio click)
3. Confermare il prompt UAC quando richiesto
4. Rispondere alle domande **S/N** per i software opzionali
5. Se si installa il software del produttore, indicare uno tra `ASUS` / `Dell` / `HP` / `Lenovo`

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

## Note di manutenzione

- Gli URL di terze parti (in particolare quello HP, legato a una build specifica del softpaq) possono cambiare o essere ritirati nel tempo: se un download fallisce, verificare per primo che il link sia ancora valido
- Ogni installazione (tramite `winget` o eseguibile scaricato) riporta in console il proprio codice di uscita, utile per la diagnosi da remoto

## Troubleshooting

- **Winget non disponibile**: lo script tenta la registrazione automatica; se fallisce, installare manualmente "App Installer" dal Microsoft Store
- **Download fallito o file non valido**: lo script segnala l'errore e salta l'installazione corrispondente; controllare la cartella `%USERPROFILE%\Downloads` e la connessione di rete
- **Installazione terminata con codice diverso da 0**: consultare la documentazione del produttore per il significato del codice di uscita specifico
