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
    if [[ "$response" =~ ^[Nn][Oo]?$ ]]; then
      break
    fi
    if [[ "$response" =~ ^[yY][Ee][Ss]?$ ]]; then
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





#from
fromr=""
function from {
l=$(ls ./data)
from=0
echo select the table 
select fr in $l
do 
if [[ $fr == "" ]]
then 
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
select wh in $meta
do
if [[ $wh == "" ]]
then 
echo enter valid number
else
wtype=$wh
wno=$REPLY
break
fi
done

if [[ $(echo $wtype |cut -d ":" -f 2) == "int" ]]
then 

echo select the condition op
select op in "==" "<=" ">=" "<" ">"
do
if [[ $op == "" ]]
then 
echo enter valid number
else
read -p "Please Enter condition value: " condval
if [[ $condval =~ ^[1-9]+$ ]]
then 
condition_row=$(awk ' BEGIN{FS=":"} { 
if ( $'$wno' '$op' '$condval' ){
print NR
}
} END{ } ' ./data/$fromr )
break
else echo not a number
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
      ;;
    5)
      # Implement select from table functionality
      ;;
    6)

      from
      where
      wherer=($wherer)
      del=""
      for i in "${wherer[@]}"
      do
      del+=$i"d;"
      done
      sed -i "$del" ./data/$fromr

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