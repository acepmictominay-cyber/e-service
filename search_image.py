import mysql.connector
import requests
import os
from urllib.parse import urlparse

# Database connection
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'azzahra2_multibrand'
}

UNSPLASH_ACCESS_KEY = 'pi9B1UytpH7poYDPk4U_0bEV71DO9FMM7YWYWqz0kew'
PIXABAY_API_KEY = '52864321-2974c3147f14c0680432f7ba8'

def get_products_without_images():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("SELECT kode_barang, nama_produk FROM produk WHERE gambar IS NULL OR gambar = ''")
    products = cursor.fetchall()
    conn.close()
    return products

def search_unsplash(query):
    url = f"https://api.unsplash.com/search/photos?query={query}&client_id={UNSPLASH_ACCESS_KEY}&per_page=1"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        if 'results' in data and data['results']:
            photo = data['results'][0]
            return photo['urls']['regular']
    return None

def search_pixabay(query):
    url = f"https://pixabay.com/api/?key={PIXABAY_API_KEY}&q={query}&image_type=photo&per_page=1"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        if 'hits' in data and data['hits']:
            photo = data['hits'][0]
            return photo['largeImageURL']
    return None

def download_image(url, filename):
    response = requests.get(url)
    if response.status_code == 200:
        # Check if the content is an image (jpg, jpeg, png)
        content_type = response.headers.get('content-type', '')
        if 'image' in content_type and any(ext in content_type for ext in ['jpeg', 'jpg', 'png']):
            # Ensure filename has .png or .jpg extension
            if not filename.lower().endswith(('.png', '.jpg', '.jpeg')):
                if 'png' in content_type:
                    filename += '.png'
                else:
                    filename += '.jpg'
            with open(filename, 'wb') as f:
                f.write(response.content)
            return True
    return False

def update_product_image(kode_barang, image_path):
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    cursor.execute("UPDATE produk SET gambar = %s WHERE kode_barang = %s", (image_path, kode_barang))
    conn.commit()
    conn.close()

def main():
    products = get_products_without_images()
    for kode_barang, nama_produk in products:
        image_url = None
        # Try search using nama_produk in Unsplash
        query = nama_produk.replace('-', ' ')
        image_url = search_unsplash(query)
        if not image_url:
            # If not found, try Pixabay with nama_produk
            image_url = search_pixabay(query)
        if not image_url:
            # If not found, try generic "electronic" in Unsplash
            image_url = search_unsplash("electronic")
        if not image_url:
            # If not found, try Pixabay with "electronic"
            image_url = search_pixabay("electronic")
        if not image_url:
            # If not found, try "laptop" in Unsplash
            image_url = search_unsplash("laptop")
        if not image_url:
            # If not found, try Pixabay with "laptop"
            image_url = search_pixabay("laptop")
        if image_url:
            # Extract filename from URL
            parsed_url = urlparse(image_url)
            filename = os.path.basename(parsed_url.path)
            if not filename:
                filename = f"{kode_barang}.jpg"
            local_path = f"assets/image/{filename}"
            if download_image(image_url, local_path):
                update_product_image(kode_barang, local_path)
                print(f"Updated image for product {kode_barang}")
            else:
                print(f"Failed to download image for {kode_barang}")
        else:
            print(f"No image found for {kode_barang}")

if __name__ == "__main__":
    main()
