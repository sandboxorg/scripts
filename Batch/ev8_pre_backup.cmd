powershell -psconsolefile "D:\Program Files\Enterprise Vault\EVShell.psc1" -command "& {set-vaultstorebackupmode evsite prod-journ-001 site}"

powershell -psconsolefile "D:\Program Files\Enterprise Vault\EVShell.psc1" -command "& {set-indexlocationbackupmode prod-journ-001}"