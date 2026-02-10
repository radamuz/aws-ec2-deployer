echo "¿Quieres instalar Caddy?"

select INSTALL_CADDY in "Sí" "No"; do
    case $INSTALL_CADDY in
        "Sí")
            echo "Has elegido instalar Caddy."

            while true; do
                read -p "Introduce el nombre de dominio: " DOMAIN_NAME

                echo
                echo -e "${YELLOW}Has introducido el nombre:${NC} ${DOMAIN_NAME}"
                echo -e "${YELLOW}¿Es correcto?${NC}"

                select yn in "Sí" "No"; do
                    case $yn in
                        "Sí")
                            echo "Continuamos..."
                            export DOMAIN_NAME
                            break 2   # sale del select yn y del while del dominio
                            ;;
                        "No")
                            echo "Vale, volvemos a introducir el nombre."
                            break     # sale solo del select yn
                            ;;
                        *)
                            echo "Opción inválida, selecciona 1 o 2."
                            ;;
                    esac
                done
            done

            break   # ⬅️ salimos del select principal
            ;;
        "No")
            echo "Has elegido NO instalar Caddy."
            INSTALL_CADDY_OK=false
            unset DOMAIN_NAME
            break   # ⬅️ salimos del select principal
            ;;
        *)
            echo "Opción inválida, prueba otra vez."
            ;;
    esac
done

# Ejecutar solo si toca
if [[ "$INSTALL_CADDY" == "Sí" ]]; then
    while true; do
        echo
        echo -e "${YELLOW}Asegúrate de que el registro DNS${NC} ${DOMAIN_NAME} ${YELLOW}apunta a la IP de tu servidor${NC} ${PUBLIC_IP}"
        echo -e "${YELLOW}¿Ya lo tienes?${NC}"
        select yn in "Sí" "No"; do
            case $yn in
                "Sí")
                    echo "Continuamos..."
                    INSTALL_CADDY_OK=true
                    break 2   # sale del select yn y del while del dominio
                    ;;
                "No")
                    echo "Vale, esperamos."
                    break     # sale solo del select yn
                    ;;
                *)
                    echo "Opción inválida, selecciona 1 o 2."
                    ;;
            esac
        done
    done
fi

if [[ "$INSTALL_CADDY_OK" == "true" ]]; then
    ssh -t -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "mkdir -p ~/$APP_NAME/caddy"
    scp -i "$PEM_KEY_REALPATH" "scripts/caddy/installation.sh" ubuntu@"$PUBLIC_IP":~/$APP_NAME/caddy/
    ssh -t -i $PEM_KEY_REALPATH ubuntu@$PUBLIC_IP "bash ~/$APP_NAME/caddy/installation.sh $DOMAIN_NAME"
fi