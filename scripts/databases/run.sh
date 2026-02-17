# Start of block Detect whether a database has been deployed.
echo -e "${CYAN}Start of block Detect whether a database has been deployed.${NC}"
if [[ "$DOCKERFILE_PATH" == *postgres* || "$DOCKERFILE_PATH" == *mariadb* || "$DOCKERFILE_PATH" == *oracle* || "$USER_DATA_FILE" == *postgres* || "$USER_DATA_FILE" == *mariadb* || "$USER_DATA_FILE" == *oracle* ]]; then
  # Start of block Would you like to set up the infranettone database?
  echo -e "${CYAN}Start of block Would you like to set up the infranettone database?${NC}"
  echo "${YELLOW}A database has been detected in the Dockerfile or user data file. Would you like to set up the infranettone database?${NC}"
  select SET_UP_DB in "Yes" "No"; do
      case $SET_UP_DB in
          "Yes")
              echo "Setting up the infranettone database..."
              break
              ;;
          "No")
              echo "The infranettone database will not be set up."
              break
              ;;
          *)
              echo "Invalid option, please select 1 or 2."
              ;;
      esac
  done
  echo -e "${CYAN}End of block Would you like to set up the infranettone database?${NC}"
  # End of block Would you like to set up the infranettone database?

  # Start of block If it is a PostgreSQL database.
  echo -e "${CYAN}Start of block If it is a PostgreSQL database.${NC}"
  if [[ "$SET_UP_DB" == "Yes" && ( "$DOCKERFILE_PATH" == *postgres* || "$USER_DATA_FILE" == *postgres* ) ]]; then
    echo "Setting up PostgreSQL database..."
    source scripts/databases/postgresql/run.sh
  fi
  echo -e "${CYAN}End of block If it is a PostgreSQL database.${NC}"
  # End of block If it is a PostgreSQL database.

fi
echo -e "${CYAN}End of block Detect whether a database has been deployed.${NC}"
# End of block Detect whether a database has been deployed.
