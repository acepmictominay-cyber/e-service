from serpapi import GoogleSearch

params = {
  "engine": "google_images",
  "q": "asus laptop",
  "api_key": "60a84e87f8cb7e738d8147165cdcd5cd732d0ff5fd97af5f244b02ae04b9eb97"
}

search = GoogleSearch(params)
results = search.get_dict()

for img in results["images_results"][:5]:
    print(img["original"])
