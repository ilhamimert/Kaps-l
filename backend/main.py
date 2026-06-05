from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import capsules, users, matches

app = FastAPI(
    title="CrossRoads API",
    description="Capsule Dating — Konuma Dayalı Kapsül Eşleşme Uygulaması",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(capsules.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(matches.router, prefix="/api/v1")


@app.get("/")
async def root():
    return {"status": "CrossRoads API çalışıyor", "version": "1.0.0"}


@app.get("/health")
async def health():
    return {"status": "ok"}
