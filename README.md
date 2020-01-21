# docker-alpine-nginx-webapp

## To run
```
docker container run --name testngwebapp -d -p 80:80 vincenthome/docker-alpine-nginx-webapp
```

## Troubleshoot

#### Check Status
```
docker container ls -l   
```

#### Check log errors
```
docker container logs testngwebapp
```
