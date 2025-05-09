#!/bin/bash

max_replicas=5
container_name="clouds-container"
base_port=8080  

while true; do
  
  mem_usage=$(docker stats --no-stream --format "{{.MemUsage}}" $container_name | cut -d"/" -f1 | tr -d "MiB")
  mem_usage=${mem_usage%.*}
  container_count=$(docker ps -q --filter name=$container_name | wc -l)
  echo "Current memory usage of $container_name: $mem_usage MiB"
  echo "Current number of running containers: $container_count"
  if [[ $mem_usage -gt 200 && $container_count -lt $max_replicas ]]; then
    port=$((base_port + container_count))
    
    container_name_unique="${container_name}_$((container_count+1))"

    echo "Memory usage exceeded 200 MiB. Creating new container: $container_name_unique on port $port"

    docker run -d --name $container_name_unique --network my-network --memory 250m \
      -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-container:5432/cloud_db \
      -e SPRING_DATASOURCE_USERNAME=user \
      -e SPRING_DATASOURCE_PASSWORD=${POSTGRES_PASSWORD} \
      -p $port:8080 solomon11/cloud:latest
  elif [[ $container_count -gt 1 && $mem_usage -lt 100 ]]; then
    
    last_container_name="${container_name}_$container_count"
    echo "Memory usage dropped below 100 MiB. Removing container: $last_container_name"
    docker rm -f $last_container_name
  fi

  
  sleep 30
done
