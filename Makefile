.PHONY: build cbuild run 

build :
	docker build -t "virts" .

cbuild :
	docker build --progress=plain --no-cache -t "virts" .

run :
	docker run --name virts -p 7900:7900  -d "virts"
	docker exec -it virts bash -l

stop :
	docker stop virts
	docker rm virts
