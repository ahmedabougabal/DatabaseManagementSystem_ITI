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
  if [[ -f "data/$tableName" ]]; then
    if grep -q "^$pk:" "data/$tableName"; then
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
  dataFile="data/$tableName"
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
  #* now that everything is validated
  #* adding new columns
  cols=("$pk")
  while true; do
    echo "Do you want to add another column? (yes/no)"
    # The -r option in the read command is used to prevent backslashes from being interpreted as escape characters
    read -r response
    if [[ "$response" =~ ^[Nn]+$ ]]; then
      break
    fi
    if [[ "$response" =~ ^[Yy]+$ ]]; then
      echo "please type in the column name"
      read -r colName
      echo "please type in the column type"
      read -r colType
      cols+=("${colName}:${colType}")
    fi
  done

  #! REQUIRED FORMAT: id:int,username:string,email:string,birthdate:string
  columns=""
  for col in "${cols[@]}"; do
    if [[ -n "$columns" ]]; then # n flag checks if columns string isnot empty
      columns+=","
    fi
    columns+="$col"
  done
  echo "$columns" >>"$metaFile"
  echo "Table $tableName is created successfully with primary key '$pkColName'."
}

function ListTables() {
  if [ -d "./meta" ] && [ -d "./data" ]; then
    echo "Meta data for the tables is"
    ls "./meta"/*.meta
    echo "Data for the tables is "
    ls "./data"/*
  else
    echo "no tables yet created"
  fi
}

function DropTable() {
  echo "please enter the table name you wish to drop"
  read dropFile
  #* define files to be dropped
  metaFile="./meta/$dropFile.meta"
  dataFile="./data/$dropFile"
  #! check for their existence
  if [[ -e "$metaFile" ]] || [[ -e "$dataFile" ]]; then
    if [[ -e "$metaFile" ]]; then
      rm "$metaFile"
      echo "Meta file $metaFile is dropped successfully."
    fi
    if [[ -e "$dataFile" ]]; then
      rm "$dataFile"
      echo "Data file $dataFile is dropped successfully."
    fi
  else
    echo "Table $dropFile does not exist."
  fi
}

function validateInsertedVals() {
  local -n columns_ref=$1
  local -n validated_vals_ref=$2
  declare -A colTypes

  # Read column names and types from the meta file
  for col in "${columns_ref[@]}"; do
    colName="${col%%:*}"
    colType="${col##*:}"
    colTypes["$colName"]="$colType"
  done

  # Collect values for each column
  for col in "${columns_ref[@]}"; do
    colName="${col%%:*}"
    colType="${col##*:}"

    while true; do
      echo "Please enter value for $colName ($colType):"
      read value

      # Validate value based on its type
      if [[ "$colType" == "int" ]]; then
        if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
          echo "Invalid value for $colName. It should be an integer."
          continue
        fi
      elif [[ "$colType" == "string" ]]; then
        if [[ -z "$value" ]]; then
          echo "Invalid value for $colName. It should be a non-empty string."
          continue
        fi
      fi

      # Check for uniqueness if it's the primary key
      if [[ "${col%%:*}" == "${columns_ref[0]%%:*}" ]]; then
        pk="$value"
        if ! pkValidate; then
          continue
        fi
        if ! isUnique; then
          continue
        fi
      fi

      # Add value to the validated values array
      validated_vals_ref+=("$value")
      break
    done
  done
}

function InsertIntoTable() {
  echo "Please enter the table name to insert into:"
  read tableName

  if ! isTableFound "$tableName"; then
    echo "Table $tableName does not exist."
    return 1
  fi

  local metaFile="meta/$tableName.meta"
  local dataFile="data/$tableName"

  # Read column names and types from the meta file
  IFS=',' read -r -a columns <<<"$(cat "$metaFile")"
  declare -a validated_vals

  # Validate and collect user input
  validateInsertedVals columns validated_vals

  # Join values with colon delimiter and append to the data file
  IFS=:
  echo "${validated_vals[*]}" >>"$dataFile"
  echo "Record inserted successfully into table $tableName."
}

#from
fromr=""
function from {
  l=$(ls ./data)
  from=0
  echo select the table
  select fr in $l; do
    if [[ $fr == "" ]]; then
      echo enter valid number
    else
      from=$fr
      break
    fi
  done
  fromr=$from
}
#from end

#where
wherer=0
function where {
  meta=$(awk ' BEGIN{FS=","} {  
  for(i = 1; i<=NF ; i++)
    {
    print $i
    }
    } END{} ' ./meta/$fromr.meta)
  wtype=-1
  wno=-1
  echo select the condition column
  select wh in $meta; do
    if [[ $wh == "" ]]; then
      echo enter valid number
    else
      wtype=$wh
      wno=$REPLY
      break
    fi
  done

  if [[ $(echo $wtype | cut -d ":" -f 2) == "int" ]]; then

    echo select the condition op
    select op in "==" "<=" ">=" "<" ">"; do
      if [[ $op == "" ]]; then
        echo enter valid number
      else
        read -p "Please Enter condition value: " condval
        if [[ $condval =~ ^[1-9]+$ ]]; then
          condition_row=$(awk ' BEGIN{FS=":"} { 
if ( $'$wno' '$op' '$condval' ){
print NR
}
} END{ } ' ./data/$fromr)
          break
        else
          echo not a number
        fi
      fi
    done
  else
    read -p "Please Enter condition value: " condval
    condition_row=$(
      awk -v condv="$condval" ' BEGIN{FS=":"} { 
if ( $'$wno' == condv){
print NR
}
} END{ } ' ./data/$fromr
    )
  fi
  wherer=$condition_row
}

function selwhere {
  meta=$(awk ' BEGIN{FS=","} {  
  for(i = 1; i<=NF ; i++)
    {
    print $i
    }
    } END{} ' ./meta/$fromr.meta)
  wtype=-1
  wno=-1
  echo select the condition column
  select wh in $meta; do
    if [[ $wh == "" ]]; then
      echo enter valid number
    else
      wtype=$wh
      wno=$REPLY
      break
    fi
  done

  # metaar=($meta)
  # echo ${#metaar[@]}
  declare -i swno=-1
  echo select the selected column
  select wh in all $meta; do
    if [[ $wh == "" ]]; then
      echo enter valid number
    else
      swno=$REPLY-1
      break
    fi
  done

  if [[ $(echo $wtype | cut -d ":" -f 2) == "int" ]]; then
    echo select the condition op
    select op in "==" "<=" ">=" "<" ">"; do
      if [[ $op == "" ]]; then
        echo enter valid number
      else
        read -p "Please Enter condition value: " condval
        if [[ $condval =~ ^[1-9]+$ ]]; then
          awk ' BEGIN{FS=":"} { 
if ( $'$wno' '$op' '$condval' ){
print $'$swno'
}
} END{ } ' ./data/$fromr
          break
        else
          echo not a number
        fi
      fi
    done
  else
    read -p "Please Enter condition value: " condval
    awk -v condv="$condval" ' BEGIN{FS=":"} { 
if ( $'$wno' == condv){
print $'$swno'
}
} END{ } ' ./data/$fromr
  fi
}

function updwhere {
  meta=$(awk ' BEGIN{FS=","} {  
  for(i = 1; i<=NF ; i++)
    {
    print $i
    }
    } END{} ' ./meta/$fromr.meta)
  wtype=-1
  wno=-1
  upv=-1
  # metaar=($meta)
  # echo ${#metaar[@]}
  declare -i uwno=-1
  echo select the column to update
  select wh in $meta; do
    if [[ $wh == "" ]]; then
      echo enter valid number
    else
      read -p "Please Enter updated value: " upvv
      upv=$upvv
      if [[ $REPLY == 1 ]] && [[ $upv == "" ]]; then
        echo primary key cant be empty
      else
        if [[ $(echo $wh | cut -d ":" -f 2) == "int" ]]; then
          if [[ ! $upv =~ ^[1-9]+$ ]]; then
            echo this column takes int
          else
            uwno=$REPLY
            break
          fi
        else
          uwno=$REPLY
          break
        fi
      fi
    fi
  done

  echo select the condition column
  select wh in $meta; do
    if [[ $wh == "" ]]; then
      echo enter valid number
    else
      wtype=$wh
      wno=$REPLY
      break
    fi
  done

  if [[ $(echo $wtype | cut -d ":" -f 2) == "int" ]]; then
    echo select the condition op
    select op in "==" "<=" ">=" "<" ">"; do
      if [[ $op == "" ]]; then
        echo enter valid number
      else
        if [[ $REPLY != 1 ]] && [[ $uwno == 1 ]]; then
          echo primary key must be unique
          break
        fi
        read -p "Please Enter condition value: " condval
        if [[ $condval =~ ^[1-9]+$ ]]; then
          awk -v upval=$upv ' BEGIN{FS=":"} { 
if ( $'$wno' '$op' '$condval' ){
    $'$uwno' = upval
}
print
} END{ } ' OFS=: ./data/$fromr >temp && mv temp ./data/$fromr
          break
        else
          echo not a number
        fi
      fi
    done
  else
    read -p "Please Enter condition value: " condval
    awk -v condv="$condval" -v upval=$upv ' BEGIN{FS=":"} { 
if ( $'$wno' == condv){
    $'$uwno' = upval
}
print
} END{ } ' OFS=: ./data/$fromr >temp && mv temp ./data/$fromr
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
      DropTable
      ;;
    4)
      # Implement insertion into table functionality
      InsertIntoTable
      ;;
    5)
      # Implement select from table functionality
      from
      selwhere
      ;;
    6)

      from
      where
      wherer=($wherer)
      del=""
      for i in "${wherer[@]}"; do
        del+=$i"d;"
      done
      sed -i "$del" ./data/$fromr

      # Implement delete from table functionality

      ;;
    7)
      # Implement update table functionality
      from
      updwhere
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
PS3="Choose a Number: "
function main_menu {
  while true; do
    echo "1) CreateDB     3) ConnectToDB  5) Exit"
    echo "2) ListDB       4) DropDB"
    read -p "Choose a Number: " choice
    case $choice in
    1)
      read -p "Please Enter Database Name: " DBname
      if [ -e "./DataBases/$DBname" ]; then
        echo "Database Already Exists"
      else
        mkdir -p "./DataBases/$DBname"
        echo "Database Created"
      fi
      ;;
    2)
      if [[ -d "./DataBases" ]]; then
        echo "Databases found : "
        ls ./DataBases
      else
        echo "no databases found"
      fi
      ;;
    3)
      read -p "Please Enter Database Name: " DBname
      if [ -e "./DataBases/$DBname" ]; then
        table "./DataBases/$DBname"
      else
        echo "Database doesn't Exist"
      fi
      ;;
    4)
      read -p "Please Enter Database Name: " DBname
      if [ -e "./DataBases/$DBname" ]; then
        rm -r "./DataBases/$DBname"
      else
        echo "Database doesn't Exist"
      fi
      ;;
    +([Ee][xX][Ii][tT]) | 5)
      break
      ;;
    *)
      echo "Invalid option. Please choose a valid number."
      ;;
    esac
  done
}
main_menu
