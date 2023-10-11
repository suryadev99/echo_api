# --- Build Stage ---
FROM python:3.8-slim as builder

WORKDIR /app

# Install build dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip \
    && pip install --user --no-cache-dir -r requirements.txt

# Let's verify what's installed
RUN pip list --user

# Let's inspect the directory structure to make sure we're copying the right directories later
RUN ls -la /root/.local/bin

# --- Production Stage ---
FROM python:3.8-slim as production

RUN pip install gunicorn

# Set the working directory and create app user
WORKDIR /app
RUN useradd --create-home appuser && chown -R appuser:appuser /app
USER appuser

# Copy only the necessary files
# Copy Python dependencies installed in the builder stage
COPY --from=builder /root/.local /home/appuser/.local
# Copy application files
COPY . /app

# Ensure scripts in .local are usable:
ENV PATH=/home/appuser/.local/bin:$PATH

ENV PYTHONPATH=/home/appuser/.local/lib/python3.8/site-packages:$PYTHONPATH

RUN echo $PYTHONPATH


RUN ls -la /home/appuser/.local/bin

# Environment variables for Flask
ENV FLASK_ENV=production
ENV FLASK_DEBUG=0

# Expose port and set CMD
EXPOSE 5000

CMD ["/home/appuser/.local/bin/gunicorn", "-b", "0.0.0.0:5000", "main:app"]