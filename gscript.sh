# !/user/bin/bash
shopt -s extglob
export LC_COLLATE=C #! enable case sensitivity

function table {
  cd $1
  echo "Connected to database: $(basename $1)" #basename here returns the name of the DB
  #without mentioning the preceding path
  table_menu #function call
}

function isTableFound() {
  if [[ -e "$1.meta" ]]; then
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
  if [[ -f "$tableName.data" ]]; then
    if grep -q "^$pk:" "$tableName.data"; then
      echo "this $pk already exists inside the table $tableName"
      rm $metaFile
      return 1
    fi
  fi
}

function CreateTable() {
  echo "please enter a table name"
  read tableName
  if [[ ! "$tableName" =~ ^[!@#^*$~()_-]$ ]]; then
    echo "invalid table name"
    return 1
  fi
  if isTableFound $tableName; then
    echo "Table $tableName Already Exists"
    return 1
  fi
  #! meta file creation
  metaFile="$tableName.meta"
  touch metaFile

  #* ask for the primary key
  declare -i pk
  echo "Please type in the primary key"
  read pk

  # primary key validation (check for both NULL and uniqueness)
  if ! pkValidate; then
    return 1
  fi
  if ! isUnique; then
    return 1
  fi

  #* now that everything is validated, write the PK into the tableName.data
  echo "primaryKey :$pk" >>"$metaFile"
  echo "Table $tableName is created successfully with primary key '$pk'."

}

function table_menu {
  PS3="Choose a Table Option: "
  select option in CreateTable ListTables DropTable InsertIntoTable SelectFromTable DeleteFromTable UpdateTable Exit; do
    case $option in
    "CreateTable")
      # Table Creation Implementation
      CreateTable
      ;;
    "ListTables")
      # list tables functionality
      ;;
    "DropTable")
      # Implement drop table functionality
      ;;
    "InsertIntoTable")
      # Implement insertion into table functionality
      ;;
    "SelectFromTable")
      # Implement select from table functionality
      ;;
    "DeleteFromTable")
      # Implement delete from table functionality
      ;;
    "UpdateTable")
      # Implement update table functionality
      ;;
      #* for handling several user attemps to type the word "Exit"
    +([Ee][Xx][Ii][Tt]))
      break
      ;;
    esac
  done
}



table_menu