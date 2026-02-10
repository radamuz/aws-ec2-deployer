echo "¿Quieres establecer una contraseña al usuario postgres?"

select SET_POSTGRES_PASSWORD in "Sí" "No"; do
    case $SET_POSTGRES_PASSWORD in
        "Sí")
            echo "Has elegido establecer una contraseña para el usuario postgres."

                while true; do
                    read -s -p "Introduce la contraseña para el usuario postgres: " POSTGRES_PASSWORD
                    echo
                    read -s -p "Confirma la contraseña para el usuario postgres: " POSTGRES_PASSWORD_CONFIRM
                    echo
    
                    if [[ "$POSTGRES_PASSWORD" == "$POSTGRES_PASSWORD_CONFIRM" ]]; then
                        echo "Contraseña confirmada. Continuamos..."
                        export POSTGRES_PASSWORD
                        break 2   # sale del select yn y del while del dominio
                    else
                        echo "Las contraseñas no coinciden. Por favor, inténtalo de nuevo."
                    fi
                done

            break   # ⬅️ salimos del select principal
            ;;
        "No")
            echo "Has elegido NO establecer una contraseña para el usuario postgres."
            break   # ⬅️ salimos del select principal
            ;;
        *)
            echo "Opción inválida, prueba otra vez."
            ;;
    esac
done

if [[ "$SET_POSTGRES_PASSWORD" == "No" ]]; then
    echo "Continue"
fi

# Arrancar este script de forma interactiva en la máquina para que sea lo más seguro posible!