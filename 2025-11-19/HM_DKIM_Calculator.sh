#!/bin/bash
#
# @author: Hermann Magliacane
# @created on 19th November 2025
#
# Mail Parser to retrive fake mail using DKIM
#
# Definizione codici ANSI per i colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Reset colore

# Controllo se si è su windows (WSL) o linux
if grep -qi microsoft /proc/version; then
    echo "Sei su Windows (WSL)"
    OS_WIN="true"
else
    echo "Sei su Linux nativo"
    OS_WIN="false"
fi




MAILDIR="./mail2check"

# Controllo che la cartella esista
if [ ! -d "$MAILDIR" ]; then
    echo "Cartella $MAILDIR non trovata! La genero con un file di esempio"
    mkdir $MAILDIR
    cat <<'EOF' > $MAILDIR/spam-1.eml
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;
 d=example.com; s=mail2025;
 h=from:to:subject:date:message-id:mime-version:content-type;
 bh=47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=;
 b=Y2l0YXRpb25zYXJlY29vbC4uLi4xMjM0NTY3ODkwYWJjZGVmZ2hpamtsbW5vcA==
From: Alice <alice@example.com>
To: Bob <bob@example.net>
Subject: Test DKIM
Date: Wed, 19 Nov 2025 09:30:00 +0100
Message-ID: <12345@example.com>
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8

Hello Bob,
This is a test message to check DKIM parsing.
EOF
    echo "File spam-1.eml generato."
    #exit 1
fi

# Ciclo su tutti i file della cartella
for MAILFILE in "$MAILDIR"/*; do
    echo "=== Analisi file: $MAILFILE ==="

    # Estraggo la prima riga DKIM-Signature
    # DKIM_LINE=$(grep -i "DKIM-Signature" "$MAILFILE" | head -n1)
    DKIM_LINE=$(grep -i "DKIM-Signature" -A 5 "$MAILFILE" | tr -d '\n') # Poiché l'informazione potrebbe essere su più righe, elimino le prime 5 righe successive potendo quindi leggere la DKIM come unica linea e non più linee.

    if [ -z "$DKIM_LINE" ]; then
        echo "Nessuna DKIM-Signature trovata."
        echo
        continue
    fi

    # Estrazione parametri mediante regex Perl (-P) stampando solo la parte trovata(-o). L'opzione \K fa "dimenticare" la parte precedente della regex così da catturare solo ciò che segue.
    DKIM_DOMAIN=$(echo "$DKIM_LINE" | grep -Po 'd=\K[^;]+') # estraggo il dominio firmante (d=...) fino al punto e virgola successivo
    DKIM_SELECTOR=$(echo "$DKIM_LINE" | grep -Po 's=\K[^;]+') # estraggo il selettore DKIM(s=...) fino al punto e virgola successivo
    DKIM_SIGNATURE=$(echo "$DKIM_LINE" | grep -Po 'b=\K[^;]+') # estraggo la firma cifrata (b=...) fino al punto e virogla successivo
    DKIM_BODY_HASH=$(echo "$DKIM_LINE" | grep -Po 'bh=\K[^;]+') # estraggo l'hash del corpo del messaggio (bh=...) fino a punto e virgola successivo
    DKIM_HEADERS=$(echo "$DKIM_LINE" | grep -Po 'h=\K[^;]+') # estraggo l'elenco delle intestazioni firmate (h=...) fino al punto e virgola successivo
    DKIM_CANON=$(echo "$DKIM_LINE" | grep -Po 'c=\K[^;]+') # estraggo il metodo di canonicalizzazione (c=...) fino al punto e virgola successivo. Il Tag Canonical URL conosciuto anche come "link canonico" è un attributo HTML che viene inserito nella sezione head di una pagina web per indicare qual è l'url principale tra più pagine simili o duplicate presenti sullo stesso dominio. Nel contesto DKIM la canonicalizzazione è un concetto fondamentale: serev a stabilire come devono essere tratatti e normalizzati i dati (intestazione e corpo del messaggio) prima di calcolare l'hash e firmarli.

# Tipi di canonicalizzazione
# Il parametro c= nella DKIM-Signature può assumere valori come:
# simple/simple → nessuna tolleranza: il messaggio deve arrivare identico.
# relaxed/relaxed → più permissivo: ignora differenze di spazi, tab, maiuscole/minuscole negli header e normalizza il corpo.
# relaxed/simple → intestazioni tolleranti, corpo rigido.
# simple/relaxed → intestazioni rigide, corpo tollerante.
# Il formato è sempre c=header/body.

    # Output leggibile
    printf "${GREEN}Dominio DKIM:${NC} %s\n" "$DKIM_DOMAIN"
    printf "${YELLOW}Selettore:${NC} %s\n" "$DKIM_SELECTOR"
    printf "${RED}Firma Cifrata:${NC} %.40s...\n" "$DKIM_SIGNATURE"
    printf "${CYAN}Hash Corpo:${NC} %s\n" "$DKIM_BODY_HASH"
    printf "${BLUE}Intestazioni Firmate:${NC} %s\n" "$DKIM_HEADERS"
    printf "${GREEN}Canonicalizzazione:${NC} %s\n" "$DKIM_CANON"

    # Lookup DNS della chiave pubblica
    if [ -n "$DKIM_DOMAIN" ] && [ -n "$DKIM_SELECTOR" ]; then
        if [[ $OS_WIN = "true" ]]; then
                DKIM_KEY=$(nslookup.exe -type=TXT "$DKIM_SELECTOR._domainkey.$DKIM_DOMAIN" | grep -i "v=DKIM1")
        else
                DKIM_KEY=$(dig TXT "$DKIM_SELECTOR._domainkey.$DKIM_DOMAIN" +short)
        fi


        if [ -z "$DKIM_KEY" ]; then
            echo "Chiave pubblica non trovata!"
        else
            echo "Chiave pubblica: $DKIM_KEY"
        fi
    fi

    echo
done
