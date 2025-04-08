# This file has been copied from the ska-cicd-training-pipeline-machinery repo

# Use the official Python 3.10 image as the base image
FROM python:3.10

# Set the working directory to /app within the container
WORKDIR /app

# Install Poetry, a dependency management tool, in the container
RUN pip install poetry
RUN poetry self add poetry-plugin-export

# Copy the pyproject.toml and poetry.lock* files to the /app directory in the container
# The poetry.lock* allows for an optional lock file, accommodating projects without one
COPY pyproject.toml  poetry.lock* /app/

# Export the dependencies from poetry to a requirements.txt file without hashes
# This is needed for pip to understand and install the dependencies
RUN poetry export -f requirements.txt --output requirements.txt --without-hashes

# Install the Python dependencies specified in requirements.txt
# The `--no-cache-dir` flag prevents pip from caching installed packages, reducing image size
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

# Copy the application source code from the local src directory to the /app directory in the container
COPY ./src/ /app/

# Define the default command to run when the container starts
# This command runs the app using uvicorn with proxy headers enabled, listening on all network interfaces on port 80
CMD ["uvicorn", "ska_sci_ops_setup_validator.run:app", "--proxy-headers", "--host", "0.0.0.0", "--port", "80"]
