while true; do
    read -p "Nombre del aplicativo [aws-ec2-deployer]: " APP_NAME
    APP_NAME=${APP_NAME:-aws-ec2-deployer}
    APP_NAME="${APP_NAME}-iaed"

    echo
    echo -e "${YELLOW}Has introducido el nombre:${NC} ${APP_NAME}"
    echo -e "${YELLOW}¿Es correcto?${NC}"

    select yn in "Sí" "No"; do
        case $yn in
            "Sí")
                echo "Continuamos..."
                export APP_NAME
                break 2   # sale del select y del while
                ;;
            "No")
                echo "Vale, volvemos a introducir el nombre."
                break     # sale solo del select
                ;;
            *)
                echo "Opción inválida, selecciona 1 o 2."
                ;;
        esac
    done
done