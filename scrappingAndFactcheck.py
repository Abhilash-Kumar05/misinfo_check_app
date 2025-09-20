# goal/GENAI/scrappingAndFactcheck.py

import asyncio
import aiohttp
from bs4 import BeautifulSoup
import google.generativeai as genai
import os
import requests
import json
from datetime import datetime
import logging

# Configure logging
logger = logging.getLogger(__name__)

# Configure Gemini API for this module as well
genai.configure(api_key="AIzaSyAZ-RURZ6LIVw7YCG25Y5A2GgbLj0aIXU0")

# Google Custom Search API configuration
GOOGLE_API_KEY = "AIzaSyCxx_8Uxs7i0wTZVt3HE0l4c1oYa8lN8aQ"
GOOGLE_CSE_ID = "f705585dd92b34144"
GOOGLE_SEARCH_URL = "https://www.googleapis.com/customsearch/v1"

# Predefined lists of trusted websites for fact-checking evergreen news by domain
GENERAL_TRUSTED_WEBSITES = [
    "wikipedia.org",
    "britannica.com",
    "nationalgeographic.com",
    "apnews.com",
    "reuters.com",
    "bbc.com/news",
    "nytimes.com",
    "wsj.com",
    "factcheck.org",
    "snopes.com",
    "politifact.com",
]

HEALTH_TRUSTED_WEBSITES = [
    # Indian Government/Health Organizations
    "mohfw.gov.in",
    "icmr.gov.in",
    "aiims.edu",
    "nhp.gov.in",
    "phfi.org",
    "nihfw.org",
    "indianpediatrics.net",
    "fssai.gov.in",
    "mciindia.org",
    "ncdc.gov.in",
    "tmc.gov.in",
    "pgimer.edu.in",
    "sctimst.ac.in",
    # International / Broad Health Organizations & Reputable Sources
    "cdc.gov",
    "mayoclinic.org",
    "medlineplus.gov",
    "fda.gov",
    "health.gov",
    "webmd.com",
    "healthline.com",
    "nhs.uk",
    "health.harvard.edu",
    "heart.org",
    "hopkinsmedicine.org",
    "medicalnewtoday.com",
    "nia.nih.gov",
    "thelancet.com",
    "wikipedia.org",
    "everydayhealth.com",
    "clevelandclinic.org",
    "onlymyhealth.com",
    "health.economictimes.indiatimes.com",
    "maxhealthcare.in",
    "netmeds.com",
    "1mg.com",
    "cabidigitallibrary.org",
]

FINANCE_TRUSTED_WEBSITES = [
    "rbi.org.in",
    "sebi.gov.in",
    "bseindia.com",
    "nseindia.com",
    "moneycontrol.com",
    "economictimes.indiatimes.com",
    "business-standard.com",
    "financialexpress.com",
    "livemint.com",
    "businesstoday.in",
    "crisil.com",
    "icra.in",
    "tradingeconomics.com",
    "investindia.gov.in",
    "ibef.org",
    "pib.gov.in",
    "taxmann.com",
    "caindia.org",
    "policybazaar.com",
    "india.gov.in",
    # Additional general finance trusted sources
    "investopedia.com",
    "bloomberg.com",
    "reuters.com",
    "wsj.com",
    "ft.com",
    "cnbc.com",
    "fidelity.com",
    "zacks.com",
    "fool.com",
    "wikipedia.org",
]

# Map misinformation domains to their respective trusted website lists
DOMAIN_TRUSTED_WEBSITES = {
    "Health": HEALTH_TRUSTED_WEBSITES,
    "Finance": FINANCE_TRUSTED_WEBSITES,
    "General": GENERAL_TRUSTED_WEBSITES,
    "Other": GENERAL_TRUSTED_WEBSITES,
}

class FactCheckResult:
    """Structured result class for fact-checking operations"""
    def __init__(self, news_id=None):
        self.news_id = news_id
        self.trusted_urls = []
        self.scraped_contents = []
        self.summarized_answer = ""
        self.fact_check_assessment = ""
        self.further_education_suggestions = ""
        self.trust_score = 0.0
        self.processing_errors = []
        self.sources_used = []
        self.scraped_content_count = 0
        self.success = False
        self.debug_data = {}

    def to_dict(self):
        """Convert result to dictionary for JSON serialization"""
        return {
            'news_id': self.news_id,
            'trusted_urls': self.trusted_urls,
            'scraped_content_count': self.scraped_content_count,
            'summarized_answer': self.summarized_answer,
            'fact_check_assessment': self.fact_check_assessment,
            'further_education_suggestions': self.further_education_suggestions,
            'trust_score': self.trust_score,
            'processing_errors': self.processing_errors,
            'sources_used': self.sources_used,
            'success': self.success,
            'debug_data': self.debug_data
        }

async def perform_google_search(query, start_index, num_results=10):
    """Perform Google Custom Search API call"""
    params = {
        "key": GOOGLE_API_KEY,
        "cx": GOOGLE_CSE_ID,
        "q": query,
        "num": num_results,
        "start": start_index
    }

    try:
        response = requests.get(GOOGLE_SEARCH_URL, params=params, timeout=15)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        logger.error(f"Error during Google Custom Search API call (page {start_index}): {e}")
        return {}
    except Exception as e:
        logger.error(f"An unexpected error occurred during Google Custom Search (page {start_index}): {e}")
        return {}

async def google_search_and_filter(query, misinformation_domain, max_total_results=50, num_per_request=10):
    """Search Google and filter for trusted domains"""
    logger.info(f"Searching Google for: \"{query}\" in {misinformation_domain} domain...")
    
    if not GOOGLE_API_KEY or not GOOGLE_CSE_ID:
        logger.error("Google API Key or CSE ID not configured")
        return []

    trusted_domains_list = DOMAIN_TRUSTED_WEBSITES.get(misinformation_domain, GENERAL_TRUSTED_WEBSITES)

    all_search_items = []
    for i in range(0, max_total_results, num_per_request):
        start_index = i + 1
        search_results = await perform_google_search(query, start_index, num_per_request)
        if search_results and search_results.get("items"):
            all_search_items.extend(search_results.get("items"))
        else:
            break

    logger.info(f"Found {len(all_search_items)} total search results for '{query}'")

    filtered_urls = []
    for item in all_search_items:
        url = item.get("link")
        if url:
            for trusted_domain in trusted_domains_list:
                if trusted_domain in url and url not in filtered_urls:
                    filtered_urls.append(url)
                    if len(filtered_urls) >= 5:
                        return filtered_urls
    return filtered_urls

async def scrape_url(session, url, retry_limit=3, retry_delay=2):
    """Scrape content from a single URL with retry logic"""
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36"
    }
    
    for attempt in range(retry_limit):
        try:
            async with session.get(url, timeout=10, headers=headers) as response:
                response.raise_for_status()
                html_content = await response.text()
                soup = BeautifulSoup(html_content, 'html.parser')
                
                # Extract text from common elements that hold main content
                paragraphs = soup.find_all('p')
                text_content = ' '.join([p.get_text() for p in paragraphs])
                if not text_content:
                    text_content = soup.get_text()
                return text_content.strip()
        except aiohttp.ClientError as e:
            logger.warning(f"Error fetching {url} (attempt {attempt + 1}/{retry_limit}): {e}")
        except asyncio.TimeoutError:
            logger.warning(f"Timeout fetching {url} (attempt {attempt + 1}/{retry_limit})")
        except Exception as e:
            logger.warning(f"Unexpected error scraping {url} (attempt {attempt + 1}/{retry_limit}): {e}")
        
        if attempt < retry_limit - 1:
            await asyncio.sleep(retry_delay)
            
    return None

async def async_scrape(urls):
    """Asynchronously scrape multiple URLs"""
    logger.info(f"Scraping {len(urls)} URLs...")
    async with aiohttp.ClientSession() as session:
        tasks = [scrape_url(session, url) for url in urls]
        scraped_contents = await asyncio.gather(*tasks)
        return [content for content in scraped_contents if content]

async def fact_check_evergreen_misinformation(input_news_text, scraped_data):
    """Compare input news with trusted sources using Gemini"""
    logger.info("Performing fact-check analysis...")
    
    combined_trusted_content = " ".join(scraped_data)

    model = genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        generation_config={
            "temperature": 0.1,
            "top_p": 1,
            "top_k": 1,
            "max_output_tokens": 300,
        },
    )

    prompt = f"""Given the following original news text and content from trusted sources, analyze if the original news text contains misinformation related to evergreen topics.
    Focus on factual accuracy and consistency with the trusted sources.

    Original News Text: {input_news_text}

    Trusted Sources Content: {combined_trusted_content[:2000]}

    Based on the comparison, state clearly if the Original News Text is likely 'True', 'Potentially Misleading', or 'False'. Also, provide a brief explanation for your assessment."""

    try:
        response = await model.generate_content_async(prompt)
        return response.text.strip()
    except Exception as e:
        logger.error(f"Error during Gemini fact-check: {e}")
        return "Fact-checking failed due to an error."

async def summarize_scraped_data_with_gemini(scraped_data):
    """Summarize scraped data using Gemini"""
    logger.info("Summarizing scraped data...")
    
    combined_content = "\n\n".join(scraped_data)

    model = genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        generation_config={
            "temperature": 0.2,
            "top_p": 1,
            "top_k": 1,
            "max_output_tokens": 500,
        },
    )

    prompt = f"""Based on the following content from trusted sources, provide a concise summary of the key information related to the topic.

    Trusted Sources Content:
    {combined_content[:3000]}

    Summary:"""

    try:
        response = await model.generate_content_async(prompt)
        return response.text.strip()
    except Exception as e:
        logger.error(f"Error during Gemini summarization: {e}")
        return "Summarization failed due to an error."

async def generate_further_education(news_text, misinformation_domain):
    """Generate educational suggestions using Gemini"""
    logger.info("Generating education suggestions...")

    model = genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        generation_config={
            "temperature": 0.3,
            "top_p": 1,
            "top_k": 1,
            "max_output_tokens": 300,
        },
    )

    prompt = f"""Given the original news topic: "{news_text}" (categorized as {misinformation_domain} misinformation), suggest 3-5 key areas or reputable resources for an individual to further educate themselves to avoid similar misinformation in the future. Focus on critical thinking, media literacy, and understanding the {misinformation_domain} domain.

    Suggestions:"""

    try:
        response = await model.generate_content_async(prompt)
        return response.text.strip()
    except Exception as e:
        logger.error(f"Error generating further education: {e}")
        return "Further education suggestions could not be generated."

def calculate_trust_score(fact_check_assessment):
    """Calculate trust score based on fact-check assessment"""
    if "True" in fact_check_assessment:
        return 9.0
    elif "Potentially Misleading" in fact_check_assessment:
        return 5.0
    elif "False" in fact_check_assessment:
        return 1.0
    else:
        return 0.0

def save_debug_data(result, news_text, news_type, misinformation_domain):
    """Save debug data to JSON file"""
    debug_data = {
        "input_news_text": news_text,
        "news_type": news_type,
        "misinformation_domain": misinformation_domain,
        "trusted_urls_found": result.trusted_urls,
        "scraped_contents": result.scraped_contents,
        "trust_score": result.trust_score,
        "fact_check_assessment": result.fact_check_assessment,
        "timestamp": datetime.now().isoformat()
    }
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_filename = f"scraped_data_{misinformation_domain}_{timestamp}.json"
    
    try:
        with open(output_filename, 'w', encoding='utf-8') as f:
            json.dump(debug_data, f, ensure_ascii=False, indent=4)
        logger.info(f"Debug data saved to {output_filename}")
        return output_filename
    except Exception as e:
        logger.error(f"Error saving debug data to JSON: {e}")
        return None

async def initialize_fact_checker(news_type, news_text, misinformation_domain, news_id=None):
    """Main fact-checking function - updated for Flask integration"""
    result = FactCheckResult(news_id=news_id)
    
    if news_type != "Evergreen News":
        result.fact_check_assessment = "Not applicable for real-time news"
        result.success = True
        return result

    logger.info(f"Starting fact-check for evergreen news: {news_text[:100]}...")
    
    try:
        # Search for trusted URLs
        search_query = news_text
        result.trusted_urls = await google_search_and_filter(search_query, misinformation_domain)
        
        if not result.trusted_urls:
            result.processing_errors.append("No trusted sources found")
            result.fact_check_assessment = "N/A - No trusted sources found"
            result.trust_score = 0.0
            return result

        logger.info(f"Found {len(result.trusted_urls)} trusted URLs for scraping")
        result.sources_used = result.trusted_urls.copy()
        
        # Scrape content
        result.scraped_contents = await async_scrape(result.trusted_urls)
        result.scraped_content_count = len(result.scraped_contents)
        
        if not result.scraped_contents:
            result.processing_errors.append("Could not scrape content from any trusted URLs")
            result.fact_check_assessment = "N/A - No content scraped from trusted URLs"
            result.trust_score = 0.0
            return result

        logger.info(f"Successfully scraped content from {result.scraped_content_count} URLs")

        # Summarize scraped data
        result.summarized_answer = await summarize_scraped_data_with_gemini(result.scraped_contents)

        # Generate education suggestions
        result.further_education_suggestions = await generate_further_education(news_text, misinformation_domain)

        # Perform fact-check
        result.fact_check_assessment = await fact_check_evergreen_misinformation(news_text, result.scraped_contents)

        # Calculate trust score
        result.trust_score = calculate_trust_score(result.fact_check_assessment)

        # Save debug data
        debug_filename = save_debug_data(result, news_text, news_type, misinformation_domain)
        if debug_filename:
            result.debug_data['saved_file'] = debug_filename

        result.success = True
        logger.info("Fact-checking completed successfully")

    except Exception as e:
        logger.error(f"Error during fact-checking: {e}")
        result.processing_errors.append(f"Fact-checking failed: {str(e)}")
        result.success = False

    return result

# Backward compatibility function
async def initialize_fact_checker_legacy(news_type, news_text, misinformation_domain):
    """Legacy function for backward compatibility with existing code"""
    result = await initialize_fact_checker(news_type, news_text, misinformation_domain)
    
    if result.success:
        return "Evergreen fact-checking process completed successfully."
    else:
        return f"Fact-checking failed: {'; '.join(result.processing_errors)}"

if __name__ == "__main__":
    # Test the updated system
    test_news_text = "Eating rice makes you fat and should be avoided for weight loss."
    test_news_type = "Evergreen News"
    test_misinformation_domain = "Health"
    
    # Test with new structured result
    result = asyncio.run(initialize_fact_checker(test_news_type, test_news_text, test_misinformation_domain))
    print("=== Fact-Check Result ===")
    print(json.dumps(result.to_dict(), indent=2, ensure_ascii=False))
