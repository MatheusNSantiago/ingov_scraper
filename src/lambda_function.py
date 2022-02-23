from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import os
from dotenv import load_dotenv  # Caso estiver local

load_dotenv()

# https://robertorocha.info/setting-up-a-selenium-web-scraper-on-aws-lambda-with-python/


def lambda_handler(event, context):
    """Faz um scrape para achar o link da do site in.gov baseado no id da matéria"""

    sumula = event["body"]

    options = Options()
    options.add_argument("--no-sandbox")  # exec with Lambda default user (root)
    options.add_argument("--headless")
    options.add_argument("--single-process")
    options.add_argument("--disable-dev-shm-usage")

    loc_bin = os.getenv("CHROME_BINARIES_PATH", "/opt")  # opt = zipped layers path
    options.binary_location = loc_bin + "/headless-chromium"

    driver = webdriver.Chrome(f"{loc_bin}/chromedriver", options=options)

    try:
        for _, publicacoes in sumula.items():
            for pub in publicacoes:
                # Vai no painel de procura (q esta setado pra procurar o id_materia contido em pub["id"])
                search = f'https://www.in.gov.br/consulta/-/buscar/dou?q="{pub["id"]}"&s=todos&exactDate=all&sortType=0'
                driver.get(search)

                # Pega o link do primeiro resultado
                element = WebDriverWait(driver, 10).until(
                    EC.presence_of_element_located(
                        (By.XPATH, "//h5[@class='title-marker']/a")
                    )
                )
                url_do_ingov = element.get_property("href")
                
                # Troca o url da publicação pelo novo
                pub["url"] = url_do_ingov

    except Exception:
        driver.quit()
        raise Exception("Não conseguiu buscar as urls. Provavelmente o ingov está fora do ar")

    driver.quit()
    return {"body": sumula, "status": "OK"}
