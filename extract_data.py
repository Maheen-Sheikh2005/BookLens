import json
import requests
from bs4 import BeautifulSoup

BASE_URL = "https://books.toscrape.com/"

def scrape_all_categories():
    print("Fetching category links from bookstore...")
    response = requests.get(BASE_URL)
    
    if response.status_code != 200:
        print("Failed to reach the website.")
        return

    soup = BeautifulSoup(response.text, "html.parser")
    
    # 1. Find all category links in the left sidebar
    category_tags = soup.find("div", class_="side_categories").find_all("a")[1:] # Skip first "All Products" link
    
    books_data = []

    for cat_tag in category_tags:
        category_name = cat_tag.text.strip()
        cat_url = BASE_URL + cat_tag["href"]
        
        print(f"Scraping category: {category_name}...")
        cat_response = requests.get(cat_url)
        
        if cat_response.status_code != 200:
            continue
            
        cat_soup = BeautifulSoup(cat_response.text, "html.parser")
        books = cat_soup.find_all("article", class_="product_pod")
        
        for book in books:
            title = book.h3.a["title"]
            price = book.find("p", class_="price_color").text
            stock = book.find("p", class_="instock availability").text.strip()
            
            rating_class = book.find("p", class_="star-rating")["class"]
            rating = rating_class[1] if len(rating_class) > 1 else "None"

            books_data.append({
                "Title": title,
                "Price": price,
                "Stock": stock,
                "Category": category_name,
                "Rating": rating
            })

    # Save all categorized books into raw_books.json
    with open("raw_books.json", "w", encoding="utf-8") as f:
        json.dump(books_data, f, indent=4, ensure_ascii=False)

    print(f"\nSUCCESS! Scraped {len(books_data)} books across multiple categories into raw_books.json")

if __name__ == "__main__":
    scrape_all_categories()