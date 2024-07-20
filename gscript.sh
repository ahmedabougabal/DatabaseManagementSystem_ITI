# !/user/bin/bash
function table {
    cd $1
    echo "Connected to database: $(basename $1)" #basename here returns the name of the DB
    #without mentioning the preceding path
    table_menu #function call
}

function table_menu {
    PS3="Choose a Table Option: "
    select option in CreateTable ListTables DropTable InsertIntoTable SelectFromTable DeleteFromTable UpdateTable Exit; do
        case $option in
        "CreateTable")
            # Table Creation Implementation
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
        "Exit")
            break
            ;;
        esac
    done
}
