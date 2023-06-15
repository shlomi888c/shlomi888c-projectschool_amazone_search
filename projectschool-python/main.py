from selenium import webdriver
from selenium.common import TimeoutException, NoSuchElementException
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys
import time

def open_browser(url, user_agent):
    driver_location = '/usr/local/bin/chromedriver'
    binary_location = '/usr/bin/google-chrome-stable'

    options = webdriver.ChromeOptions()
    options.binary_location = binary_location
    options.add_argument('user-agent={user_agent}')
    options.add_argument('--headless')  # Run Chrome in headless mode (without UI)
    options.add_argument('--disable-gpu')  # Disable GPU acceleration
    options.add_argument('--disable-dev-shm-usage')  # Disable /dev/shm usage
    options.add_argument('--window-size=1920,1080')  # Set window size
    options.add_argument('--disable-extensions')  # Disable Chrome extensions
    options.add_argument('--disable-infobars')  # Disable the "Chrome is being controlled by automated test software" infobar
    options.add_argument('--start-maximized')  # Start Chrome maximized
    options.add_argument('--disable-popup-blocking')  # Disable popup blocking

    driver = webdriver.Chrome(options=options)
    driver.get(url)
    return driver
def search_for_product(driver, article_name):
    while True:
        try:
            search_bar = WebDriverWait(driver, 3).until(
                EC.presence_of_element_located((By.ID, "twotabsearchtextbox")))
        except TimeoutException:
            try:
                search_button = WebDriverWait(driver, 3).until(
                    EC.presence_of_element_located((By.ID, "nav-search-submit-button")))
            except TimeoutException:  # Exception when the ExplicitWait condition occurs
                driver.refresh()
                time.sleep(3)
                continue
            else:
                search_button.click()
                break
        else:
            break
    search_bar.send_keys(article_name, Keys.ENTER)

def get_number_of_pages(driver):
    while True:
        try:
            number_of_pages = WebDriverWait(driver, 3).until(
                EC.presence_of_element_located((By.XPATH, "//*[@class='s-pagination-item s-pagination-button']"))).text
        except TimeoutException:
            print("The total number of pages was not found.")
            number_of_pages = 5
            time.sleep(3)
            continue
        else:
            break
    return number_of_pages

def extract_product_info(driver, url, article_name, number_of_pages):
    product_name = []
    product_price = []
    product_link = []
    product_image = []
    for j in range(int(number_of_pages)):
        driver.get(url + '/s?k=' + article_name + '&page=' + str(j+1))
        while True:
            try:
                products = WebDriverWait(driver, 10).until(
                    EC.presence_of_all_elements_located((By.XPATH,
                                                         '//div[contains(@class, "sg-col-4-of-12 s-result-item s-asin sg-col-4-of-16 sg-col s-widget-spacing-small sg-col-4-of-20")]')))
            except TimeoutException:
                driver.refresh()
                time.sleep(3)
                continue
            else:
                break
        for product in products:
            try:
                name = product.find_element(By.XPATH, ".//h2").text
            except NoSuchElementException:
                name = ""
            product_name.append(name)

            try:
                whole_price = product.find_elements(By.XPATH, './/span[@class="a-price-whole"]')
                fraction_price = product.find_elements(By.XPATH, './/span[@class="a-price-fraction"]')
                if whole_price != [] and fraction_price != []:
                    price = '.'.join([whole_price[0].text, fraction_price[0].text])
                else:
                    price = 0
            except NoSuchElementException:
                price = 0
            product_price.append(price)

            try:
                link = product.find_element(By.XPATH, './/a[@class="a-link-normal s-no-outline"]').get_attribute("href")
            except NoSuchElementException:
                link = ""
            product_link.append(link)

            try:
                image = product.find_element(By.XPATH, './/img[@class="s-image"]')
                image = image.get_attribute("src")
            except NoSuchElementException:
                image = ""
            product_image.append(image)
    return product_name, product_price, product_link, product_image

def close_browser(driver):
    driver.close()

# Main function
def scrape_products(url, user_agent, article_name):
    driver = open_browser(url, user_agent)
    search_for_product(driver, article_name)
    number_of_pages = get_number_of_pages(driver)
    print("Total number of pages: ", number_of_pages)
    product_name, product_price, product_link, product_image = extract_product_info(driver, url, article_name, number_of_pages)
    close_browser(driver)
    return product_name, product_price, product_link, product_image





