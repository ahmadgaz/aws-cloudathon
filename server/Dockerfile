FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

COPY sql /app/sql

# Expose the port that matches our ECS configuration
EXPOSE 3000

# Run with port 3000 to match our ECS configuration
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000"]
