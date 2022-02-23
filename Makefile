.PHONY: help check clean fetch-dependencies docker-build docker-run build-lambda-package deploy-function

# |---------------------------------------------| Config |---------------------------------------------|
nome_func_aws = ingov_scraper
python_version=3.6


# headless_chrome_version = v1.0.0-57
# headless_chrome_branch = dev
# chromedriver_version = 88.0.4324.27

headless_chrome_version = v1.0.0-41
headless_chrome_branch = stable
chromedriver_version = 2.37

# |----------------------------------------| Lambda Emulator |-----------------------------------------|

docker-build:		## create Docker image
	docker-compose build

docker-run:			## run `src.lambda_function.lambda_handler` with docker-compose
	docker-compose run --rm lambda src.lambda_function.lambda_handler 

# |-------------------------------------| Chrome binaries layer |--------------------------------------|

build-chrome-binaries-layer: fetch-dependencies clean
	@echo "- Building chrome-binaries-layer (headless_chrome + chromedriver binaries)"
	@rm chrome_binaries_layer.zip
	@zip -j chrome_binaries_layer.zip bin/*
	@echo "chrome-binaries-layer.zip criado com sucesso"

fetch-dependencies:		## download chromedriver, headless-chrome to `./bin/`
	@mkdir -p bin/

	@echo "- Getting chromedriver"
	@curl -SL# \
	https://chromedriver.storage.googleapis.com/${chromedriver_version}/chromedriver_linux64.zip > chromedriver.zip

	@unzip -qqo chromedriver.zip -d bin/

	@echo "- Getting Headless-chrome"
	
	@curl -SL# https://github.com/adieuadieu/serverless-chrome/releases/download/${headless_chrome_version}/${headless_chrome_branch}-headless-chromium-amazonlinux-2017-03.zip > headless-chromium.zip

	@unzip -qqo headless-chromium.zip -d bin/

    # Clean zips
	@rm headless-chromium.zip chromedriver.zip

# |----------------------------------------| Lambda Function |-----------------------------------------|

deploy-function: build-lambda-package   ## Faz o upload do lambda-package (build.zip) pra aws
	aws lambda update-function-code \
		--region sa-east-1 \
		--function-name ${nome_func_aws} \
		--zip-file fileb://build.zip

config-function:
	@echo "Updating environment variables"
	aws lambda update-function-configuration \
		--region sa-east-1 \
		--function-name ${nome_func_aws} \
		--environment "Variables={PYTHONPATH=/var/task/lib}"

build-lambda-package: clean ## prepares zip archive for AWS Lambda deploy (-> build/build.zip)
	mkdir build
	cp -r src/* build/.
    # cp -r bin build/. # Já que os binários tiveram que virar uma layer (devido ao limite máximo de 50M por função), não tem porque eu incluir eles aqui  
	cp -r lib build/.
	pip${python_version} install -r requirements.txt -t build/lib/.
	cd build; zip -9qr build.zip .
	cp build/build.zip .
	rm -rf build


# |-----------------------------------------| utils |-----------------------------------------|
help: ## Mostra a documentação dos targets (doc fica dps dos ##)
	@python -c 'import fileinput,re; \
	ms=filter(None, (re.search("([a-zA-Z_-]+):.*?## (.*)$$",l) for l in fileinput.input())); \
	print("\n".join(sorted("\033[36m  {:25}\033[0m {}".format(*m.groups()) for m in ms)))' $(MAKEFILE_LIST)

check:		## print versions of required tools
	@docker --version
	@docker-compose --version
	@python3 --version

clean:		## delete pycache, build files
	@rm -rf build build.zip bin/locales bin/*.log */__pycache__/


