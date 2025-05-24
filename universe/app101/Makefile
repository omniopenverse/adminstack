APP101-API-PY-FOLDER	=../../../app101-api-py
APP101-WEB-FOLDER		=../../../app101-web
APP101-DB-FOLDER		=../../../app101-db

all:					app101-db-start app101-api-py-start app101-web-start

app101-db-start:
						@docker compose -f $(APP101-DB-FOLDER)/docker-compose.yml up -d --build
app101-db-stop:
						@docker compose -f $(APP101-DB-FOLDER)/docker-compose.yml down
app101-db-logs:
						@docker compose -f $(APP101-DB-FOLDER)/docker-compose.yml logs -f
app101-db-shell:
						@docker compose -f $(APP101-DB-FOLDER)/docker-compose.yml exec -it app101-db bash


app101-api-py-start:
						@docker compose -f $(APP101-API-PY-FOLDER)/docker-compose.yml up -d --build
app101-api-py-stop:
						@docker compose -f $(APP101-API-PY-FOLDER)/docker-compose.yml down
app101-api-py-logs:
						@docker compose -f $(APP101-API-PY-FOLDER)/docker-compose.yml logs -f
app101-api-py-shell:
						@docker compose -f $(APP101-API-PY-FOLDER)/docker-compose.yml exec -it app101-api-py bash


app101-web-start:
						@docker compose -f $(APP101-WEB-FOLDER)/docker-compose.yml up -d --build
app101-web-stop:
						@docker compose -f $(APP101-WEB-FOLDER)/docker-compose.yml down
app101-web-logs:
						@docker compose -f $(APP101-WEB-FOLDER)/docker-compose.yml logs -f
app101-web-shell:
						@docker compose -f $(APP101-WEB-FOLDER)/docker-compose.yml exec -it app101-web bash


clean:					app101-api-py-stop app101-web-stop app101-db-stop

fclean:
						@docker compose -f $(APP101-API-PY-FOLDER)/docker-compose.yml down --volumes
						@docker compose -f $(APP101-WEB-FOLDER)/docker-compose.yml down --volumes
						@docker compose -f $(APP101-DB-FOLDER)/docker-compose.yml down --volumes

re:						clean all

.PHONY:					all \
						app101-api-py-start app101-api-py-stop app101-api-py-logs app101-api-py-shell \
						app101-web-start app101-web-stop app101-web-logs app101-web-shell \
						app101-db-start app101-db-stop app101-db-logs app101-db-shell \
						clean fclean re