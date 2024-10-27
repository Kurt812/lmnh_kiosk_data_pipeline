# Creates and activates venv, installs all required libraries, sets up database

# Activate venv
python3 -m venv .venv
source .venv/bin/activate

# Install requirements
if [ -f requirements.txt ]; then
    pip3 install -r requirements.txt
else
    echo "Requirements.txt doesn't exist."
fi    

# Create database, EC2 instance and security group
terraform apply

# Use the environment variables to setup database
source .env
echo "Connecting to database $DATABASE_NAME on host $DATABASE_IP and port 5432 with user $DATABASE_USERNAME."
cd pipeline
psql -d $DATABASE_NAME -p 5432 -h $DATABASE_IP -U $DATABASE_USERNAME -f schema.sql
# Will need to input database password into terminal
cd ..
python3 consumer.py --log-to-file

