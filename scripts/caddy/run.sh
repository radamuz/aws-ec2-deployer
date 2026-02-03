echo "¿Quieres instalar Caddy?"
select INSTALL_CADDY in "Sí" "No"; do
  case $INSTALL_CADDY in
    "Sí")
      echo "Has elegido instalar Caddy."
      read -p "Introduce el nombre de dominio: " DOMAIN_NAME
      break
      ;;
    "No")
      echo "Has elegido NO instalar Caddy."
      break
      ;;
    *)
      echo "Opción inválida, prueba otra vez."
      ;;
  esac
done
export DOMAIN_NAME