while true; do
    echo "¿Quieres instalar Caddy?"
    select INSTALL_CADDY in "Sí" "No"; do
        case $INSTALL_CADDY in
            "Sí")
                echo "Has elegido instalar Caddy."

                while true; do
                    read -p "Introduce el nombre de dominio: " DOMAIN_NAME

                    if [[ -n "$DOMAIN_NAME" ]]; then
                        echo "Dominio introducido: $DOMAIN_NAME"
                        export DOMAIN_NAME
                        break 2   # sale del select y del while principal
                    else
                        echo "El dominio no puede estar vacío."
                    fi
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
