from main import scrape_products

def test_scrape_products():
    # Test with a valid search term
    url = "https://www.amazon.co.uk"
    user_agent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.50 Safari/537.36'
    article_name = "laptop"
    product_name, product_price, product_link, product_image = scrape_products(url, user_agent, article_name)
    assert len(product_name) > 0
    assert len(product_price) > 0
    assert len(product_link) > 0
    assert len(product_image) > 0
    
    # Test with an invalid search term
    article_name = "thisisnotavalidsearchterm"
    product_name, product_price, product_link, product_image = scrape_products(url, user_agent, article_name)
    assert len(product_name) == 0
    assert len(product_price) == 0
    assert len(product_link) == 0
    assert len(product_image) == 0
