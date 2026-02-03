echo "¿Deseas asociar una Elastic IP a la instancia EC2 creada?"
select ENABLE_ELASTIC_IP in "Sí" "No"; do
  case $ENABLE_ELASTIC_IP in
    "Sí")
      echo "Has elegido asociar una Elastic IP."
      CREATE_ELASTIC_IP=true
      break
      ;;
    "No")
      echo "Has elegido NO asociar una Elastic IP."
      CREATE_ELASTIC_IP=false
      break
      ;;
    *)
      echo "Opción inválida, prueba otra vez."
      ;;
  esac
done

# Si CREATE_ELASTIC_IP es verdadero, crear y asociar la Elastic IP
if [ "$CREATE_ELASTIC_IP" = true ]; then
  source scripts/elastic-ip/create-and-associate.sh
fi