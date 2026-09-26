import json
import psycopg2

# 1. Database Connection Info
DB_HOST = "localhost"
DB_NAME = "bookstore_db"
DB_USER = "-----"           
DB_PASS = "-----" 
DB_PORT = "5432"

try:
    # 2. Connect to PostgreSQL
    print("Connecting to PostgreSQL...")
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        port=DB_PORT
    )
    cursor = conn.cursor()

    # 3. Read your scraped raw_books.json file
    with open('raw_books.json', 'r', encoding='utf-8') as f:
        books_data = json.load(f)

    # 4. Clear old data & insert fresh JSON straight into PostgreSQL
    cursor.execute("TRUNCATE TABLE stg_raw_books;")
    
    insert_query = "INSERT INTO stg_raw_books (raw_json) VALUES (%s::jsonb);"
    cursor.execute(insert_query, (json.dumps(books_data),))

    # 5. Save changes and close
    conn.commit()
    cursor.close()
    conn.close()
    
    print("SUCCESS! Your raw_books.json file has been loaded directly into PostgreSQL!")

except Exception as e:
    print(f"Error: {e}")
