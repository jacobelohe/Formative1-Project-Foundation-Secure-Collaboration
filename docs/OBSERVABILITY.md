# Runtime health and readiness

SomaQuiz has two simple checks that help show whether the API is running properly.

- `GET /health` is a liveness check. It returns `200` with `{"status":"healthy"}` when the API can answer a request.
- `GET /ready` is a readiness check. It returns `200` with the number of loaded quiz questions when the app can serve quizzes. It returns `503` if no questions are loaded.

The Dockerfile and Docker Compose use `/ready` as the container health check. The CI smoke test also waits for `/ready`, so CI checks that the app is ready to serve quiz data.

## Check the running app

Start the container from the repository root: 

```bash
cp .env.example .env
docker compose up --build -d
```

Then check the API and container status: 

```bash
curl -i http://localhost:8000/health
curl -i http://localhost:8000/ready
docker compose ps
docker compose logs --tail=20 quiz-api
```

A healthy response from `/health` means the API process is answering. A ready response from `/ready` means quiz data is loaded too. In `docker compose ps`, the container should show `healthy`. The logs help you see startup errors if either check does not work.

These are basic health signals for the class project. They do not replace production monitoring or a metrics dashboard.
