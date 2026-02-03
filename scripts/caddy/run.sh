
while true; do
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
                                break 3   # sale del select y del while
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
                ;;
            "No")
                echo "Has elegido NO instalar Caddy."
                unset DOMAIN_NAME
                break 2   # sale del select y del while principal
                ;;
            *)
                echo "Opción inválida, prueba otra vez."
                ;;
        esac
    done
done

# Si INSTALL_CADDY
if [[ "$INSTALL_CADDY" == "Sí" ]]; then
    source scripts/caddy/installation.sh
fi