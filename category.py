''' Flask API version of the news categorization and fact-checking system '''

import asyncio
import os
import json
from datetime import datetime
import uuid
from functools import wraps
import logging
from dotenv import load_dotenv

import language_tool_python # Added for grammar correction

from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import google.generativeai as genai
import requests
from bs4 import BeautifulSoup

# Import the fact-checking module
from scrappingAndFactcheck import initialize_fact_checker

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv("key.env")

# Flask app setup
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Configuration (keeping your hardcoded values for now, you lazy but honest developer)
UPLOAD_FOLDER = "uploads"
RESULTS_FOLDER = "results"

# Create directories if they don't exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULTS_FOLDER, exist_ok=True)

# Configure Gemini API (keeping your hardcoded key)
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

# Initialize LanguageTool globally for better performance
_language_tool = None

def get_language_tool():
    """Get or create LanguageTool instance (singleton pattern for better performance)"""
    global _language_tool
    if _language_tool is None:
        logger.info("Initializing LanguageTool...")
        _language_tool = language_tool_python.LanguageTool('en-US')
    return _language_tool

# Decorator for async route handling (because Flask doesn't play nice with async)
def async_route(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            return loop.run_until_complete(f(*args, **kwargs))
        finally:
            pass # Removed loop.close() to prevent premature event loop closure
    return wrapper

def process_input_with_beautiful_soup(input_content):
    """Your existing function - keeping it intact because it actually works"""
    # Check if the input is a URL
    if input_content.startswith("http://") or input_content.startswith("https://"):
        try:
            response = requests.get(input_content)
            response.raise_for_status()  # Raise an exception for bad status codes
            soup = BeautifulSoup(response.text, 'html.parser')
            # Extract text from common elements that hold main content
            paragraphs = soup.find_all('p')
            text_content = ' '.join([p.get_text() for p in paragraphs])
            if not text_content:
                # Fallback to getting all text if no paragraphs are found
                text_content = soup.get_text()
            return text_content.strip()
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching URL: {e}")
            return None
    else:
        return input_content

def correct_grammar_with_languagetool(text):
    """Enhanced grammar correction function using LanguageTool with better error handling"""
    logger.info("Correcting grammar of input with LanguageTool...")
    try:
        tool = get_language_tool()
        
        # Define a list of custom words to avoid false positives
        custom_words = ['Ghee', 'vanaspati', 'misinformation', 'cryptocurrency', 'blockchain']
        
        # Check the text
        matches = tool.check(text)
        
        # Filter out matches for custom words (basic approach)
        filtered_matches = []
        for match in matches:
            # Skip spell-check errors for custom words
            if match.ruleId == 'MORFOLOGIK_RULE_EN_US':
                error_word = text[match.offset:match.offset + match.errorLength].lower()
                if any(custom_word.lower() in error_word for custom_word in custom_words):
                    continue
            filtered_matches.append(match)
        
        # Apply corrections
        corrected_text = language_tool_python.utils.correct(text, filtered_matches)
        
        if corrected_text != text:
            logger.info(f"Grammar corrections applied: {len(filtered_matches)} changes made")
        
        return corrected_text
        
    except Exception as e:
        logger.error(f"Error correcting grammar with LanguageTool: {e}")
        return text  # Return original text if correction fails

def categorize_news_with_gemini(news_text):
    """Your existing categorization function - ain't broken, don't fix it"""
    generation_config = {
        "temperature": 0.2,
        "top_p": 1,
        "top_k": 1,
        "max_output_tokens": 60,
    }

    model = genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        generation_config=generation_config,
    )

    prompt = f"""Categorize the following news text into two aspects:
    1. News Type: 'Real-time News' or 'Evergreen News'.
       - Real-time news refers to current events, breaking news, or topics with a short shelf-life.
       - Evergreen news refers to content that remains relevant over a long period, often educational, how-to, or historical.
    2. Misinformation Domain: 'Health', 'Finance', 'General', or 'Other'.
       - Health misinformation relates to medical treatments, diseases, or public health.
       - Finance misinformation relates to investments, economic claims, or financial advice.
       - General misinformation covers social, political, or miscellaneous topics not falling into Health or Finance.
       - Other is for categories not explicitly listed.

    News Text: {news_text}

    Please provide the output in the format: News Type: [Category], Misinformation Domain: [Category]."""

    try:
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        logger.error(f"Error categorizing with Gemini: {e}")
        return None

async def process_single_news_item(news_item):
    """Process a single news item - this is where the magic happens"""
    try:
        # Extract data from the news item
        news_text = news_item.get('text', '')
        news_url = news_item.get('url', '')  # Support for URLs too
        news_id = news_item.get('id', str(uuid.uuid4()))
        
        if not news_text and not news_url:
            return {
                'id': news_id,
                'error': 'No text or URL provided. Send me something to work with!',
                'status': 'failed'
            }

        # Use URL if text is empty
        input_content = news_url if not news_text else news_text
        
        logger.info(f"Processing news item {news_id}: {input_content[:100]}...")
        
        # Process input (handles both text and URLs)
        processed_content = process_input_with_beautiful_soup(input_content)
        if not processed_content:
            return {
                'id': news_id,
                'error': 'Could not process input content',
                'status': 'failed'
            }

        # Apply grammar correction
        corrected_news_content = correct_grammar_with_languagetool(processed_content)
        
        # Categorize with Gemini
        full_category_output = categorize_news_with_gemini(corrected_news_content)
        if not full_category_output:
            return {
                'id': news_id,
                'error': 'Could not categorize news with Gemini',
                'status': 'failed'
            }

        # Parse the two categories (your existing parsing logic)
        news_type = "N/A"
        misinformation_domain = "N/A"

        if "News Type:" in full_category_output and "Misinformation Domain:" in full_category_output:
            try:
                news_type_start = full_category_output.find("News Type:") + len("News Type:")
                misinformation_domain_start = full_category_output.find("Misinformation Domain:") + len("Misinformation Domain:")

                news_type_end = full_category_output.find(", Misinformation Domain:", news_type_start)
                if news_type_end == -1: # In case there's no comma or Misinformation Domain follows directly
                    news_type_end = len(full_category_output)

                news_type = full_category_output[news_type_start:news_type_end].strip()
                misinformation_domain = full_category_output[misinformation_domain_start:].strip()

            except Exception as e:
                logger.error(f"Error parsing Gemini output: {e}")

        # Create base result
        result = {
            'id': news_id,
            'original_text': news_text,
            'original_url': news_url,
            'processed_content': processed_content,
            'corrected_text': corrected_news_content,
            'raw_gemini_output': full_category_output,
            'news_type': news_type,
            'misinformation_domain': misinformation_domain,
            'status': 'processed',
            'timestamp': datetime.now().isoformat()
        }

        # Call the fact-checker if it's evergreen news (using your existing function)
        if news_type == "Evergreen News":
            logger.info(f"Initiating Evergreen News fact-check for {news_id}...")
            try:
                # The fact-checker returns a FactCheckResult object
                fact_check_result_obj = await initialize_fact_checker(news_type, corrected_news_content, misinformation_domain)
                result.update(fact_check_result_obj.to_dict())
                result['fact_check_completed'] = fact_check_result_obj.success
                
            except Exception as e:
                logger.error(f"Fact-checking failed for {news_id}: {e}")
                result['fact_check_error'] = str(e)
                result['fact_check_completed'] = False
        elif news_type == "Real-time News":
            logger.info(f"Initiating Real-time News fact-check for {news_id}...")
            try:
                fact_check_result_obj = await initialize_fact_checker(news_type, corrected_news_content, misinformation_domain)
                result.update(fact_check_result_obj.to_dict())
                result['fact_check_completed'] = fact_check_result_obj.success
            except Exception as e:
                logger.error(f"Real-time Fact-checking failed for {news_id}: {e}")
                result['fact_check_error'] = str(e)
                result['fact_check_completed'] = False
        else:
            result['fact_check_result'] = 'Not applicable for real-time news'
            result['fact_check_completed'] = False

        return result

    except Exception as e:
        logger.error(f"Error processing news item: {e}")
        return {
            'id': news_item.get('id', 'unknown'),
            'error': f'Processing failed: {str(e)}',
            'status': 'failed'
        }

# Flask routes start here

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint - because you need to know if this thing is still alive"""
    return jsonify({
        'status': 'healthy',
        'message': 'News categorization and fact-checking API is running (surprisingly well)',
        'timestamp': datetime.now().isoformat(),
        'endpoints': ['/health', '/categorize', '/upload', '/results/<filename>']
    })

@app.route('/categorize', methods=['POST'])
@async_route
async def categorize_endpoint():
    """Main categorization and fact-checking endpoint"""
    try:
        # Check if JSON data is provided
        if not request.is_json:
            return jsonify({
                'error': 'Content-Type must be application/json. This is 2024, not 1999!',
                'status': 'failed'
            }), 400

        data = request.get_json()
        
        if not data:
            return jsonify({
                'error': 'No JSON data provided. Send me some news to analyze!',
                'status': 'failed'
            }), 400

        # Handle both single news item and array of news items
        if isinstance(data, dict):
            # Single news item
            if 'news_items' in data:
                news_items = data['news_items']
            else:
                news_items = [data]
        elif isinstance(data, list):
            # Array of news items
            news_items = data
        else:
            return jsonify({
                'error': 'Invalid data format. Expected JSON object or array.',
                'status': 'failed'
            }), 400

        # Process all news items
        results = []
        for news_item in news_items:
            result = await process_single_news_item(news_item)
            results.append(result)

        # Create response
        response_data = {
            'processed_count': len(results),
            'results': results,
            'status': 'completed',
            'timestamp': datetime.now().isoformat()
        }

        # Save results to file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"categorization_results_{timestamp}.json"
        filepath = os.path.join(RESULTS_FOLDER, filename)
        
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(response_data, f, ensure_ascii=False, indent=2)
            response_data['results_file'] = filename
            logger.info(f"Results saved to {filepath}")
        except Exception as e:
            logger.error(f"Failed to save results file: {e}")

        return jsonify(response_data)

    except Exception as e:
        logger.error(f"Categorize endpoint error: {e}")
        return jsonify({
            'error': f'Internal server error: {str(e)}',
            'status': 'failed',
            'message': 'Something went wrong. Time to check the logs!'
        }), 500

@app.route('/upload', methods=['POST'])
@async_route
async def upload_file():
    """Upload JSON file endpoint - for those who prefer files over copy-paste"""
    try:
        if 'file' not in request.files:
            return jsonify({
                'error': 'No file uploaded. Did you forget to attach it?',
                'status': 'failed'
            }), 400

        file = request.files['file']
        
        if file.filename == '':
            return jsonify({
                'error': 'No file selected. Choose a file first!',
                'status': 'failed'
            }), 400

        if not file.filename.endswith('.json'):
            return jsonify({
                'error': 'Only JSON files are accepted. This is a news analyzer, not a media converter!',
                'status': 'failed'
            }), 400

        # Save uploaded file
        filename = secure_filename(file.filename)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_filename = f"{timestamp}_{filename}"
        filepath = os.path.join(UPLOAD_FOLDER, safe_filename)
        file.save(filepath)

        # Read and process the JSON file
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            return jsonify({
                'error': f'Invalid JSON file: {str(e)}. Check your JSON syntax!',
                'status': 'failed'
            }), 400

        # Process the data (reuse the categorization logic)
        if isinstance(data, dict):
            if 'news_items' in data:
                news_items = data['news_items']
            else:
                news_items = [data]
        elif isinstance(data, list):
            news_items = data
        else:
            return jsonify({
                'error': 'Invalid JSON structure. Expected object or array.',
                'status': 'failed'
            }), 400

        # Process all news items
        results = []
        for news_item in news_items:
            result = await process_single_news_item(news_item)
            results.append(result)

        # Create response
        response_data = {
            'uploaded_file': safe_filename,
            'processed_count': len(results),
            'results': results,
            'status': 'completed',
            'timestamp': datetime.now().isoformat()
        }

        # Save results to file
        result_filename = f"upload_results_{timestamp}.json"
        result_filepath = os.path.join(RESULTS_FOLDER, result_filename)
        
        try:
            with open(result_filepath, 'w', encoding='utf-8') as f:
                json.dump(response_data, f, ensure_ascii=False, indent=2)
            response_data['results_file'] = result_filename
        except Exception as e:
            logger.error(f"Failed to save results file: {e}")

        return jsonify(response_data)

    except Exception as e:
        logger.error(f"Upload endpoint error: {e}")
        return jsonify({
            'error': f'Upload processing failed: {str(e)}',
            'status': 'failed'
        }), 500

@app.route('/results/<filename>', methods=['GET'])
def get_results(filename):
    """Get saved results by filename - because you might want to see what you did yesterday"""
    try:
        # Check both upload results and categorization results
        filepath = os.path.join(RESULTS_FOLDER, filename)
        
        if not os.path.exists(filepath):
            return jsonify({
                'error': 'Results file not found. Did you spell it correctly?',
                'status': 'not_found',
                'available_files': os.listdir(RESULTS_FOLDER) if os.path.exists(RESULTS_FOLDER) else []
            }), 404

        with open(filepath, 'r', encoding='utf-8') as f:
            results = json.load(f)
            
        return jsonify(results)
        
    except Exception as e:
        logger.error(f"Get results error: {e}")
        return jsonify({
            'error': f'Failed to retrieve results: {str(e)}',
            'status': 'failed'
        }), 500

@app.route('/list-results', methods=['GET'])
def list_results():
    """List all available result files - for when you forget what you named things"""
    try:
        if not os.path.exists(RESULTS_FOLDER):
            return jsonify({
                'files': [],
                'count': 0,
                'message': 'No results folder found'
            })
            
        files = os.listdir(RESULTS_FOLDER)
        json_files = [f for f in files if f.endswith('.json')]
        
        file_info = []
        for filename in json_files:
            filepath = os.path.join(RESULTS_FOLDER, filename)
            stat = os.stat(filepath)
            file_info.append({
                'filename': filename,
                'size_bytes': stat.st_size,
                'modified': datetime.fromtimestamp(stat.st_mtime).isoformat()
            })
        
        # Sort by modification time (newest first)
        file_info.sort(key=lambda x: x['modified'], reverse=True)
        
        return jsonify({
            'files': file_info,
            'count': len(file_info),
            'message': f'Found {len(file_info)} result files'
        })
        
    except Exception as e:
        logger.error(f"List results error: {e}")
        return jsonify({
            'error': f'Failed to list results: {str(e)}',
            'status': 'failed'
        }), 500

# Error handlers (because things will go wrong, trust me)

@app.errorhandler(413)
def too_large(e):
    return jsonify({
        'error': 'File too large. Keep it under 16MB, we are not Google Drive!',
        'status': 'failed'
    }), 413

@app.errorhandler(404)
def not_found(e):
    return jsonify({
        'error': 'Endpoint not found. Check your URL!',
        'status': 'not_found',
        'available_endpoints': ['/health', '/categorize', '/upload', '/results/<filename>', '/list-results']
    }), 404

@app.errorhandler(500)
def internal_error(e):
    return jsonify({
        'error': 'Internal server error. Time to check the logs!',
        'status': 'failed'
    }), 500

# Main execution (keeping your original terminal input as backup)
def get_input_from_terminal():
    """Your original terminal input function - keeping it as backup"""
    print("Please paste the news content (or URL) and press Enter twice to finish:")
    lines = []
    while True:
        line = input()
        if not line:
            break
        lines.append(line)
    return "\n".join(lines)

if __name__ == "__main__":
    # Check if we're running in terminal mode or API mode
    import sys
    
    if '--terminal' in sys.argv or '-t' in sys.argv:
        # Original terminal mode (for backward compatibility)
        print("Running in terminal mode (original functionality)...")
        news_content = get_input_from_terminal()
        if news_content:
            print("\n--- Input Received ---")
            print(f"Raw Input Length: {len(news_content)} characters")
            print(f"Raw Input: {news_content}")

            processed_content = process_input_with_beautiful_soup(news_content)
            if processed_content:
                print("\n--- Processed Content ---")
                print(f"Processed Length: {len(processed_content)} characters")
                print(f"Processed: {processed_content}")
                print("\nSending to Gemini for categorization...")
                corrected_news_content = correct_grammar_with_languagetool(processed_content)
                if corrected_news_content != processed_content:
                    print("\n--- Grammar Corrected Input (LanguageTool) ---")
                    print(f"Corrected Input: {corrected_news_content}")
                
                full_category_output = categorize_news_with_gemini(corrected_news_content)
                if full_category_output:
                    print(f"\n--- Gemini Raw Output ---")
                    print(full_category_output)
                    
                    # Parse categories and run fact-check if needed
                    news_type = "N/A"
                    misinformation_domain = "N/A"

                    if "News Type:" in full_category_output and "Misinformation Domain:" in full_category_output:
                        try:
                            news_type_start = full_category_output.find("News Type:") + len("News Type:")
                            misinformation_domain_start = full_category_output.find("Misinformation Domain:") + len("Misinformation Domain:")

                            news_type_end = full_category_output.find(", Misinformation Domain:", news_type_start)
                            if news_type_end == -1:
                                news_type_end = len(full_category_output)

                            news_type = full_category_output[news_type_start:news_type_end].strip()
                            misinformation_domain = full_category_output[misinformation_domain_start:].strip()

                        except Exception as e:
                            print(f"Error parsing Gemini output: {e}")

                    print(f"\n--- Gemini Categories ---")
                    print(f"News Type: {news_type}")
                    print(f"Misinformation Domain: {misinformation_domain}")
                    
                    if news_type == "Evergreen News":
                        print("\nInitiating Evergreen News fact-check...")
                        fact_check_result = asyncio.run(initialize_fact_checker(news_type, corrected_news_content, misinformation_domain))
                        print(f"Fact-checking Result: {fact_check_result}")
    else:
        # API mode (default)
        print(" Starting News Categorization & Fact-Checking API...")
        print(" Upload folder:", UPLOAD_FOLDER)
        print(" Results folder:", RESULTS_FOLDER) 
        print(" Endpoints available:")
        print("   GET  /health - Health check")
        print("   POST /categorize - Process JSON data directly")
        print("   POST /upload - Upload JSON file")
        print("   GET  /results/<filename> - Retrieve saved results")
        print("   GET  /list-results - List all result files")
        print("\n Use --terminal or -t flag to run in original terminal mode")
        
        app.run(debug=True, host='0.0.0.0', port=5000)
