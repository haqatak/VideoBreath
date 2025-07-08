#!/bin/bash

# Farger for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starter Vitalparametermonitor Oppsett- og Oppstartskript...${NC}"

# Gå til rotmappen til prosjektet (forutsatt at skriptet kjøres fra scripts/-mappen)
cd "$(dirname "$0")/.."

PYTHON_CODE_DIR="Python/Code"
VENV_DIR="$PYTHON_CODE_DIR/venv"
REQUIREMENTS_FILE="$PYTHON_CODE_DIR/requirements.txt"

# Funksjon for å sjekke om Python 3 er installert
check_python() {
    echo -e "${YELLOW}Sjekker Python 3 installasjon...${NC}"
    if command -v python3 &>/dev/null; then
        echo -e "${GREEN}Python 3 er installert.${NC}"
        PYTHON_CMD="python3"
    elif command -v python &>/dev/null; then
        PY_VERSION=$(python -V 2>&1)
        if [[ "$PY_VERSION" == "Python 3"* ]]; then
            echo -e "${GREEN}Python (som python 3) er installert.${NC}"
            PYTHON_CMD="python"
        else
            echo -e "${RED}Python 3 er ikke funnet. Vennligst installer Python 3 og prøv igjen.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Python 3 er ikke funnet. Vennligst installer Python 3 og prøv igjen.${NC}"
        exit 1
    fi
}

# Funksjon for å opprette og aktivere virtuelt miljø
setup_venv() {
    echo -e "${YELLOW}Setter opp virtuelt miljø i $VENV_DIR...${NC}"
    if [ ! -d "$VENV_DIR" ]; then
        echo "Oppretter virtuelt miljø..."
        if $PYTHON_CMD -m venv "$VENV_DIR"; then
            echo -e "${GREEN}Virtuelt miljø opprettet.${NC}"
        else
            echo -e "${RED}Kunne ikke opprette virtuelt miljø. Sjekk at 'venv' modulen er tilgjengelig for din Python-installasjon.${NC}"
            exit 1
        fi
    else
        echo "Virtuelt miljø eksisterer allerede."
    fi

    echo "Aktiverer virtuelt miljø..."
    # shellcheck source=/dev/null
    source "$VENV_DIR/bin/activate"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Kunne ikke aktivere virtuelt miljø. Prøv å kjøre 'source $VENV_DIR/bin/activate' manuelt.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Virtuelt miljø aktivert.${NC}"
}

# Funksjon for å installere avhengigheter
install_requirements() {
    if [ ! -f "$REQUIREMENTS_FILE" ]; then
        echo -e "${RED}Filen $REQUIREMENTS_FILE ble ikke funnet. Kan ikke installere avhengigheter.${NC}"
        echo -e "${YELLOW}Sørg for at du har en requirements.txt fil i $PYTHON_CODE_DIR med nødvendige pakker.${NC}"
        echo -e "${YELLOW}Eksempel innhold for requirements.txt:${NC}"
        echo -e "${YELLOW}opencv-python${NC}"
        echo -e "${YELLOW}numpy${NC}"
        echo -e "${YELLOW}scipy${NC}"
        echo -e "${YELLOW}flask${NC}"
        echo -e "${YELLOW}flask-cors${NC}"
        echo -e "${YELLOW}pillow${NC}"
        echo -e "${YELLOW}requests${NC}"
        echo -e "${YELLOW}configparser${NC}"
        # Ikke avslutt her, la brukeren potensielt kjøre uten hvis de vet hva de gjør eller har installert manuelt.
        return
    fi

    echo -e "${YELLOW}Installerer avhengigheter fra $REQUIREMENTS_FILE...${NC}"
    if pip install -r "$REQUIREMENTS_FILE"; then
        echo -e "${GREEN}Avhengigheter installert OK.${NC}"
    else
        echo -e "${RED}Kunne ikke installere avhengigheter. Sjekk feilmeldingene ovenfor.${NC}"
        echo -e "${YELLOW}Du må kanskje installere noen systemavhengigheter manuelt (f.eks. for opencv-python).${NC}"
        exit 1
    fi
}

# Hovedlogikk
check_python
setup_venv
install_requirements # Kall denne etter at venv er aktivert

echo -e "\n${GREEN}Oppsett fullført!${NC}"

# Spør brukeren hva som skal startes
echo -e "\nHva vil du starte?"
echo "1) Server"
echo "2) Klient"
echo "3) Både Server og Klient (Server i bakgrunnen)"
echo "4) Avslutt"
read -r -p "Velg et alternativ (1-4): " choice

cd "$PYTHON_CODE_DIR" || exit

case $choice in
    1)
        echo -e "${GREEN}Starter serveren...${NC}"
        $PYTHON_CMD servidor.py
        ;;
    2)
        echo -e "${GREEN}Starter klienten...${NC}"
        $PYTHON_CMD cliente.py
        ;;
    3)
        echo -e "${GREEN}Starter serveren i bakgrunnen...${NC}"
        # Bruk nohup for å la serveren kjøre selv om terminalen lukkes, og omdiriger output
        # For macOS kan det være bedre å bruke 'open -a Terminal.app servidor.py' eller lignende for ny fane
        # For enkelhets skyld, starter vi bare i bakgrunnen med &
        # En mer robust løsning ville bruke screen eller tmux, eller separate terminalvinduer.

        # Prøv å åpne i nytt terminalvindu hvis mulig
        if command -v gnome-terminal &> /dev/null; then
            gnome-terminal -- bash -c "$PYTHON_CMD servidor.py; exec bash" &
        elif command -v konsole &> /dev/null; then
            konsole -e bash -c "$PYTHON_CMD servidor.py; exec bash" &
        elif command -v xterm &> /dev/null; then
            xterm -e bash -c "$PYTHON_CMD servidor.py; exec bash" &
        elif command -v osascript &> /dev/null; then # macOS
             osascript -e "tell app \"Terminal\" to do script \"cd $(pwd) && $PYTHON_CMD servidor.py\""
        else
            echo -e "${YELLOW}Kunne ikke åpne server i nytt terminalvindu automatisk.${NC}"
            echo -e "${YELLOW}Starter serveren i bakgrunnen i denne terminalen. Output vil bli vist her.${NC}"
            $PYTHON_CMD servidor.py &
        fi

        # Vent litt for å la serveren starte før klienten
        echo "Venter 5 sekunder for serveren å starte..."
        sleep 5

        echo -e "${GREEN}Starter klienten...${NC}"
        $PYTHON_CMD cliente.py
        ;;
    4)
        echo -e "${GREEN}Avslutter.${NC}"
        ;;
    *)
        echo -e "${RED}Ugyldig valg. Avslutter.${NC}"
        ;;
esac

# Deaktiver virtuelt miljø ved avslutning (hvis skriptet når hit)
# Dette vil vanligvis ikke skje hvis en komponent startes i forgrunnen
deactivate &>/dev/null || true
echo -e "${GREEN}Skript fullført.${NC}"
