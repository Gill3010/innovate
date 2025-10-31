"""WSGI entry point for Gunicorn."""
import os
import sys
import logging

# Setup logging before anything else
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s'
)
logger = logging.getLogger(__name__)

try:
    logger.info("Importing create_app...")
    from backend.app import create_app
    
    logger.info("Creating app instance...")
    app = create_app()
    
    logger.info("App created successfully")
except Exception as e:
    logger.error(f"Failed to create app: {e}", exc_info=True)
    sys.exit(1)

if __name__ == "__main__":
    app.run()

