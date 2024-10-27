# Database reset

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <host> <username> <database> <password>"
    echo "Example: $0 localhost myuser mydb mypassword"
    exit 1
fi

# Assign command-line arguments to variables
HOST=$1
USERNAME=$2
DATABASE=$3
PASSWORD=$4

# Export the password to be used by psql (or use a .pgpass file for security)
export PGPASSWORD=$PASSWORD

# Execute the delete command
psql -h "$HOST" -U "$USERNAME" -d "$DATABASE" -c "DELETE FROM rating_interaction;"
psql -h "$HOST" -U "$USERNAME" -d "$DATABASE" -c "DELETE FROM request_interaction;"

# Unset the password variable for security reasons
unset PGPASSWORD

