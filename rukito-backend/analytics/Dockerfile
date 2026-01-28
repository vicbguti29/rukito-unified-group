FROM python:3.9-slim

WORKDIR /app

# Install dependencies from the analytics subfolder
COPY rukito-backend/analytics/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code from the analytics subfolder
COPY rukito-backend/analytics/ .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
