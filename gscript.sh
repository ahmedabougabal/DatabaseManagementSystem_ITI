#!/usr/bin/bash
shopt -s extglob
export LC_COLLATE=C #! enable case sensitivity

function table {
  cd "$1"
  echo "Connected to database: $(basename $1)" #basename here returns the name of the DB without mentioning the preceding path
  table_menu
}

function isTableFound() {
  if [[ -e "meta/$1.meta" ]]; then
    return 0
  else
    return 1
  fi
}

function pkValidate() {
  if [ -z "$pk" ]; then
    echo "Primary key can't be NULL/Empty"
    rm "$metaFile"
    return 1
  fi
}

function isUnique() {
  if [[ -f "data/$tableName.data" ]]; then
    if grep -q "^$pk:" "data/$tableName.data"; then
      echo "this $pk already exists inside the table $tableName"
      rm "$metaFile"
      return 1
    fi
  fi
}

function CreateTable() {
  echo "please enter a table name"
  read tableName
  if [[ "$tableName" =~ ^[!@#^*$~()_-,/]$ ]]; then
    echo "invalid table name"
    return 1
  fi
  if isTableFound "$tableName"; then
    echo "Table $tableName Already Exists"
    return 1
  fi
  #! meta file creation
  metaFile="meta/$tableName.meta"
  mkdir -p meta
  touch "$metaFile"

  #! data directory creation
  dataFile="data/$tableName.data"
  mkdir -p data
  touch "$dataFile"

  #* ask for the primary key
  echo "Please type in the primary key column name"
  read pkColName
  echo "Please type in the primary key type (int/string)"
  read pkType

  # primary key validation (check for both NULL and uniqueness)
  pk="${pkColName}:${pkType}"
  if ! pkValidate; then
    return 1
  fi
  if ! isUnique; then
    return 1
  fi

  #* adding new columns
  cols=("$pk")
  while true; do
    echo "Do you want to add another column? (yes/no)"
    # The -r option in the read command is used to prevent backslashes from being interpreted as escape characters
    read -r response
    if [[ "$response" =~ ^[Nn][Oo]?$ ]]; then
      break
    fi
    if [[ "$response" =~ ^[yY][Ee][Ss]?$ ]]; then
      echo "please type in the column name"
      read -r colName
      echo "please type in the column type"
      read -r colType
      cols+=("$colName,$colType")
    fi
  done

  #* now that everything is validated
  for col in "${cols[@]}"; do
    echo "$col" >>"$metaFile"
  done
  echo "Table $tableName is created successfully with primary key '$pkColName'."
}

function ListTables() {
  if [ -d "./DataBases/$DBname/meta" ] && [ -d "./DataBases/$DBname/data" ]; then
    echo "Meta data for the tables of database $DBname is"
    ls "./DataBases/$DBname/meta"/*.meta
    echo "Data for the tables of database $DBname is "
    ls "./DataBases/$DBname/data"/*.data
  else
    echo "no tables yet created"
  fi
}

function table_menu {
  while true; do
    echo "1) CreateTable     2) ListTables      3) DropTable"
    echo "4) InsertIntoTable 5) SelectFromTable 6) DeleteFromTable"
    echo "7) UpdateTable     8) Exit"
    read -p "Choose a Table Option: " choice
    case $choice in
    1 | +[cC][rR][Ee][aA][Tt][eE][Tt][Aa][bB][Ll][eE])
      CreateTable
      ;;
    2 | +[Ll][Ss])
      # Implement list table functionality
      ListTables
      ;;
    3)
      # Implement drop table functionality
      ;;
    4)
      # Implement insertion into table functionality
      ;;
    5)
      # Implement select from table functionality
      ;;
    6)
      # Implement delete from table functionality
      ;;
    7)
      # Implement update table functionality
      ;;
      #* for handling several user attemps to type the word "Exit"
    +([Ee][xX][Ii][tT]) | 8)
      while true; do
        read -p "Are you sure you want to exit? (yes/no): " confirm
        if [[ "$confirm" =~ ^[yY][Ee][Ss]$ ]]; then
          break 2 # Break out of both the inner and outer loops
        elif [[ "$confirm" =~ ^[nN][oO]$ ]]; then
          break # Break out of the inner loop to continue in the outer loop
        else
          echo "Invalid input. Please enter 'yes' or 'no'."
        fi
      done
      ;;
    *)
      echo "Invalid option. Please choose a valid number."
      ;;
    esac
  done
}


table_menu