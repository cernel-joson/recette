import requests
from bs4 import BeautifulSoup

# --- Helper Function for Scraping ---
def scrape_text_from_url(url):
    """Scrapes all text from a URL and returns it as a string."""
    try:
        http_headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'}
        page = requests.get(url, headers=http_headers, timeout=10)
        page.raise_for_status() # Raises an exception for bad status codes
        soup = BeautifulSoup(page.content, 'html.parser')
        return soup.get_text(separator=' ', strip=True)
    except requests.exceptions.RequestException as e:
        raise Exception(f'Failed to fetch or scrape URL: {e}')
