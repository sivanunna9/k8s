# Use a lightweight Python image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy application files
COPY app.py /app/

# Install dependencies
RUN pip install flask

# Expose port 8080
EXPOSE 8080

# Start the Flask app
CMD ["python", "app.py"]
