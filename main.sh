#!/bin/bash

DB_FILE="db.csv"
HOME_DIR="HOME"
LOGGED_IN_USERS_FILE="logged_in_users.txt"
SENDMAIL_PATH="/usr/sbin/sendmail"

mkdir -p "$HOME_DIR"
touch "$DB_FILE"
touch "$LOGGED_IN_USERS_FILE"
mapfile -t logged_in_users < "$LOGGED_IN_USERS_FILE" 2>/dev/null || logged_in_users=() #mapfile citeste fisierul in array
#dev/null=ignora erorile 

if [ ! -s "$DB_FILE" ]; then
    echo "id,username,email,password,last_login" > "$DB_FILE"
fi

registerUser() {
  read -p "Introdu username: " username

  if grep -q ",$username," "$DB_FILE"; then
    read -p "Numele deja exista. Reincercati? (y/n): " optiune
    [[ $optiune == "y" ]] && registerUser || menu
    return
  fi

  read -p "Introduceti email: " email
  if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-z]{2,}$ ]]; then
    echo "Email invalid."
    menu
    return
  fi

  while true; do
    read -s -p "Introduceti o parola: " parola1
    echo
    read -s -p "Reintroduceti parola: " parola2
    echo
    if [ "$parola1" = "$parola2" ]; then
      break
    else
      echo "Parolele nu coincid. Reincercati."
    fi
  done

  userID=$(date +%s%N)
  encryptedPass=$(echo -n "$parola1" | sha256sum)
  mkdir -p "$HOME_DIR/$userID"

  printf "$userID,$username,$email,$encryptedPass," >> "$DB_FILE"

  $SENDMAIL_PATH -i -- "$email" << END_OF_EMAIL
Subject: Confirmare cont
To: $email

Contul a fost creat cu succes!
END_OF_EMAIL

  echo "Utilizator adaugat cu succes!"
  menu
}

loginUser() {
  read -p "Introdu username: " username
  read -s -p "Introdu parola: " password
  echo
  encryptedPass=$(echo -n "$password" | sha256sum)

  if grep -q ",$username," "$DB_FILE"; then
    linieUser=$(grep ",$username," "$DB_FILE")
    password_hash=$(echo "$linieUser" | cut -d',' -f4)

    if [[ "$password_hash" == "$encryptedPass" ]]; then
      userID=$(echo "$linieUser" | cut -d',' -f1)
      email=$(echo "$linieUser" | cut -d',' -f3)
      lastLogin=$(date "+%Y-%m-%d %H:%M")
      newLine="$userID,$username,$email,$password_hash,$lastLogin"
      #gaseste linia cu userID ul si o inlocuieste
      sed -i "s|^$userID,.*|$newLine|" "$DB_FILE"

      if [[ ! " ${logged_in_users[*]} " =~ " $username " ]]; then
        logged_in_users+=("$username")
        printf "%s\n" "${logged_in_users[@]}" > "$LOGGED_IN_USERS_FILE"
      fi

      echo "Autentificare reusita. Bun venit, $username!"
    else
      echo "Parola gresita."
    fi
  else
    echo "Numele de utilizator nu exista."
  fi
  menu
}

logoutUser() {
  read -p "Introdu username-ul pentru logout: " username
  found=false

  for i in "${!logged_in_users[@]}"; do
    if [[ "${logged_in_users[$i]}" = "$username" ]]; then
      unset 'logged_in_users[i]'
      found=true
      echo "$username delogat cu succes."
      break
    fi
  done

  if [ "$found" = false ]; then
    echo "$username nu este autentificat."
  fi

  printf "%s\n" "${logged_in_users[@]}" > "$LOGGED_IN_USERS_FILE"
  menu
}

displayLoggedInUsers() {
  if [ ${#logged_in_users[@]} -eq 0 ]; then
    echo "Niciun utilizator autentificat."
  else
    echo "Utilizatori autentificati:"
    printf '%s\n' "${logged_in_users[@]}"
  fi
  menu
}

generateUserReport() {
  read -p "Introdu username-ul: " username
  userID=$(grep ",$username," "$DB_FILE" | cut -d',' -f1)

  if [ -z "$userID" ]; then
    echo "Utilizatorul nu exista."
    menu
    return
  fi

  raportFile="$HOME_DIR/$userID/raport.txt"

  (
    numFiles=$(find "$HOME_DIR/$userID" -type f | wc -l)
    numDirs=$(find "$HOME_DIR/$userID" -type d | wc -l)
    totalSize=$(du -sh "$HOME_DIR/$userID" | cut -f1)

    {
      echo "Raport pentru utilizator: $username"
      echo "Numar fisier: $numFiles"
      echo "Numar directoare: $numDirs"
      echo "Dimensiune totala: $totalSize"
      echo "Generat la: $(date)"
    } > "$raportFile"
  ) & #ruleaza in fundal

  menu
}

menu() {
  echo
  echo "=== Meniu principal ==="
  echo "1. Inregistrare utilizator"
  echo "2. Autentificare"
  echo "3. Delogare"
  echo "4. Afisare utilizatori autentificati"
  echo "5. Generare raport utilizator"
  echo "q. Iesire"
  read -p "Alege o optiune: " opt

  case $opt in
    1) registerUser ;;
    2) loginUser ;;
    3) logoutUser ;;
    4) displayLoggedInUsers ;;
    5) generateUserReport ;;
    q) exit 0 ;;
    *) cowsay "Optiune invalida."; menu ;;
  esac
}

menu